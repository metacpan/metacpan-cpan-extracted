package VCP::Filter::labelmap;

=head1 NAME

VCP::Filter::labelmap - Alter or remove labels from each revision

=head1 SYNOPSIS

  ## From the command line:
   vcp <source> labelmap: "rev_$rev_id" "change_$change_id" -- <dest>

  ## In a .vcp file:

    LabelMap:
            foo-...   <<delete>> # remove all labels beginning with foo-
            F...R     <<delete>> # remove all labels F
            v-(...)   V-$1       # use uppercase v prefixes

=head1 DESCRIPTION

Allows labels to be altered or removed using a syntax similar to
VCP::Filter::map.  This is being written for development use so more
documentation is needed.  See L<VCP::Filter::map|VCP::Filter::map> for
more examples of pattern matching (though VCP::Filter::labelmap does
not use <branch_id> syntax).

=for test_script t/61labelmap.t

=cut

$VERSION = 1 ;

use strict ;
use VCP::Logger qw( lg );
use VCP::Debug qw( :debug );
use VCP::Filter;
use Regexp::Shellish qw( compile_shellish );
use base qw( VCP::Filter );

use fields (
   'MAP_SUB',   ## The rules to apply, compiled in to an anon sub
);

## NOTE: this code is simpler than, but similar to, the same-named
## helper routines in VCP::Filter::map.  That module uses multifield
## patterns and actions, this one uses single field (ie just the
## label) patterns and actions.

sub _parse_expr {
   my ( $type, $v ) = @_;

   my %expr;

   return () unless defined $v;

   if ( $type eq "result" ) {
      return ( delete      => 1, %expr ) if $v eq "<<delete>>";
      return ( keep        => 1, %expr ) if $v eq "<<keep>>";
   }

   $expr{label} = $v;

   die "unable to parse labelmap $type '$v'\n"
      unless defined $expr{label};

   for ( "label" ) {  ## loop is just to mimic code in VCP::Filter::map
      die "newline in '$expr{$_}' of labelmap $type '$v'\n"
         if $expr{$_} =~ tr/\n//;

      die "unescaped '$1' in '$expr{$_}' of labelmap $type '$v'\n"
         if $expr{$_} =~ 
            ( $type eq "pattern"
                ? qr{(?<!\\)(?:\\\\)*([\@#<>\[\]{}\$])}
                : qr{(?<!\\)(?:\\\\)*([\@#<>\[\]*?()]|\.\.\.)|(?<!\$)\{}
            );

      ## We reserve a lot of metacharacters so we can do more later.
      die "illegal escape sequence '$1' in '$expr{$_}' of labelmap $type '$v'\n"
         if $expr{$_} =~ qr{(?<!\\)(?:\\\\)*(\\(?!=\.\.\.)[^\@#<>\[\]{}*?()])};
   }

   return %expr;
}


sub _compile_rule {
   my VCP::Filter::labelmap $self = shift;
   my ( $name, $pattern, $result ) = @_;

   my %pattern_expr = _parse_expr pattern => $pattern;
   my %result_expr  = _parse_expr result  => $result;

   ## The test expression is a single regexp that matches a string
   ## built up from some pieces of the rev metadata.  Right now, only
   ## the name and the branch_id are tested, by someday the labels,
   ## change_id, rev_id, and comment could be tested.  If so, the
   ## comment field would need to come last due to newline issues.

   my $test_expr =
      ! keys %pattern_expr
         ? 1  ## This happens iff the pattern was undef (which
              ## should only happen for the default rule).
         : join(
            "",
            "m'",   ## Note the single-quotish context
            do {
               my $re = compile_shellish( $pattern_expr{label} );
               $re =~ s{(')}{\\`}g;
               $re =~ s{\A\(\?[\w-]*: (.*) \)}{$1}gx; # for readability
                                                      # of dumped code
               $re;
            },
            "'",
         );

   $pattern = defined $pattern ? qq{"$pattern"} : "match all";

   my $result_statement = join(
      "",
      debugging
         ?  qq{lg( '    matched $name ($pattern)' );\n}
         : (),
      $result_expr{keep}
         ? (
            debugging
               ?  qq{lg( "    <<keep>>ing" );\n}
               : (),
            "push \@l, \$_; ## Keep!\n"
         )
      : $result_expr{delete}
         ? (
            debugging
               ?  qq{lg( "    <<delete>>ing" );\n}
               : (),
            "++\$changed; ## Delete!\n",
         )
         : do {
            my $expr = $result_expr{label};
            $expr =~ s{([\\"])}{\\$1}g;
            $expr =~ s{\n}{\\n}g;
            (
               debugging
                  ?  qq{lg( "    rewriting \$_ to '$expr'" );\n}
                  : (),
               qq{push \@l, "$expr";\n},
               qq{++\$changed;\n},
            );
         }
   );

   $result_statement =~ s/^/   /gm;
   $result_statement = "elsif ( $test_expr ) {\n$result_statement}\n";
   $result_statement =~ s/^/   /gm;
   $result_statement;
}


sub _compile_rules {
   my VCP::Filter::labelmap $self = shift;
   my ( $rules ) = @_;

   ## NOTE: making this a closure causes spurious warnings at exit so
   ## we pass $self explicitly.
   my $preamble = <<END_PREAMBLE;
my ( \$self, \$rev ) = \@_;

END_PREAMBLE

   my $rule_number;
   my $code = join( "",
      $preamble,
      "my \@l;\n",
      "my \$changed;\n",
      "for ( \$rev->labels ) {\n",
      debugging
         ? qq{   my \$s = \$_; \$s =~ s/\\n/\\\\n/g; lg( "map testing '\$s' (", \$rev->as_string, ")" );\n\n}
         : (),
      "   if (0) {}\n",
      map( $self->_compile_rule(  @$_ ),
         map( [ "Rule " . ++$rule_number, @$_               ], @$rules ),
         [      "Default Rule",           undef, "<<keep>>" ]
      ),
      "}\n",
      "\$rev->set_labels( \\\@l ) if \$changed;\n",
      "\$self->dest->handle_rev( \$rev );\n",
   );

   $code =~ s/^/   /mg;
   $code = "#line 1 VCP::Filter::labelmap::labelmap_function\n$code";

   $code = "sub {\n$code}";
   debug "labelmap code:\n$code" if debugging;

   return( eval $code
      or die "$@ compiling Map: code:\n",
         do {
            my $w = length( $code =~ tr/\n// + 1 ) ;
            my $ln;
            1 while chomp $code;
            $code =~ s{^}[sprintf "%${w}d|",++$ln]gme;
            "$code\n";
         },
   );
}



sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   $self->{MAP_SUB} = $self->_compile_rules(
      $self->parse_rules_list( $options, "Pattern", "Replacement" )
   );

   return $self ;
}


sub handle_rev {
   my VCP::Filter::labelmap $self = shift;

   $self->{MAP_SUB}->( $self, @_ );
}

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
