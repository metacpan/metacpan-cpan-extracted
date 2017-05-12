package VCP::Filter::stringedit;

=head1 NAME

VCP::Filter::stringedit - alter any field character by character

=head1 SYNOPSIS

    StringEdit:
        ## Convert illegal p4 characters to ^NN hex escapes and the
        ## p4 wildcard "..." to a safe string.  The "^" is not an illegal
        ## char, it's replaced with an escape to allow us to use it as
        ## an escape character without the (extremely small) risk of
        ## running across a file name that actually uses it.
        ## Order is significant in this ruleset.
        # field(s)    match          replacement
        name,labels    /([\s@#*%^])/    ^%02x
        name,labels    "..."            ^___

    StringEdit:
        ## underscorify each unwanted character to a single "_"
        name,labels    /[\s@#*%^]/  _

    StringEdit:
        ## underscorify each run of unwanted characters to a single "_"
        name,labels    /[\s@#*%^]*/  _

    StringEdit:
        ## prefix labels that don't start with a letter or underscore:
        labels         /([^a-zA-Z_])/   _%c

=head1 DESCRIPTION

Allows field by field string editing, using Perl regular expressions
to match characters and substrings and sprintf-like replacement
strings.

=head2 Rules

A rule is a triplet of expressions specifying a (1) set of fields to match,
(2) a pattern to match against those fields' contents (matching contents
are removed), and (3) a string to replace each of the removed bits
with.

NOTE 1: the "match" expression uses perl5 regular expressions, not
filename wildcards used in most other places in VCP configurations.

The list of rules is evaluated top down and all rules are applied to
each string.

NOTE 2: The all-rules-apply nature of this filter is different from the
behaviors of the ...Map: filters, which stop after the first matching
rule.  This is because ...Map: filters are rewriting entire strings and
there can be only one result string, while the StringEdit filter may be
rewriting pieces of string and multiple rewrites may be combined to good
effect.

=head2 The Fields List

A comma separated list of field names.  Any field may be edited except
those that begin with "source_".

=head2 The Match Expression

For each field, the match expression is run against the field and, if it
matches, causes all matching portions of string to be replaced.

The match expression is a full perl5 regular expression enclosed in
/.../ delimiters or a plain string, either of which may be enclosed in
'' or "" delimiters if inline spaces are needed (rare, we hope).

=head2 The Replacement Expression

Each match is replaced by one instance of the replacement expression,
optionally enclosed in single or double quotation marks.

The replacement expression provides a limited list of C sprintf style
macros:

    %d      The decimal codes for each character in the match
    %o      The octal codes for each character in the match
    %x      The hex codes for each character in the match

Any non-letter preceded by a backslash "\" character is replaced by
itself.  Some more or less useful examples:

    \% \\ \" \' \` \{ \} \$ \* \+ \? \1

If a punctuation character other than a period (.) or slash "/" follows
a letter macro, it must be escaped using the backslash character (this
is to reserve room in the spec for postfix modifiers like "*", "+", and
"?").  So, to put a literal star (*) after a hex code, you would do
something like "%02x\*".

=for the_future
%x* %x{1} %x{1,} %x{,3} %x{1,3}

The "normal" perl5 letter abbreviations are also allowed:

           \t          tab             (HT, TAB)
           \n          newline         (NL)
           \r          return          (CR)
           \f          form feed       (FF)
           \b          backspace       (BS)
           \a          alarm (bell)    (BEL)
           \e          escape          (ESC)
           \033        octal char      (ESC)
           \x1b        hex char        (ESC)
           \x{263a}    wide hex char   (SMILEY)
           \c[         control char    (ESC)
           \N{name}    named Unicode character

including the following escape sequences are available in constructs
that modify what follows:

           \l          lowercase next char
           \u          uppercase next char
           \L          lowercase till \E
           \U          uppercase till \E
           \E          end case modification
           \Q          quote non-word characters till \E

As shown above, normal sprintf-style options may be included (and are
recommended), so %02x produces results like "%09" (if the match was a
single TAB character) or "%20" (if the match was a SPACE character).
The dot precision modifiers (".3") are not supported, just the leading 0
and the field width specifier.

=head2 Case sensitivity

By default, all patterns are case sensitive.  There is no way to
override this at present; one will be added.

=head2 Command Line Parsing

For large stringedits or repeated use, the stringedit is best specified
in a .vcp file.  For quick one-offs or scripted situations, however, the
stringedit: scheme may be used on the command line.  In this case, each
parameter is a "word" and every triple of words is a ( pattern, result )
pair.

Because L<vcp|vcp> command line parsing is performed incrementally and
the next filter or destination specifications can look exactly like a
pattern or result, the special token "--" is used to terminate the list
of patterns if StringEdit: is used on the command line.  This may also
be the last word in the C<StringEdit:> section of a .vcp file, but that
is superfluous.  It is an error to use "--" before the last word in a
.vcp file.

=for test_script t/61stringedit.t

=cut

$VERSION = 1 ;

use strict ;
use VCP::Logger qw( lg );
use VCP::Debug  qw( :debug );
use VCP::Utils  qw( empty );
use VCP::Filter;
use VCP::Rev;
use base qw( VCP::Filter );

use fields (
   'MAP_SUB',   ## The rules to apply, compiled in to an anon sub
);

sub _err {
   my $replacement_expr = pop;

   my $msg = join "", @_;
   $msg =~ s/\s*\z/ /;

   die $msg, "StringEdit replacement expression '", $replacement_expr, "'\n";
}


sub _compile_replacement_expr {
   my $self = shift;
   my ( $replacement_expr ) = @_;

   local $_ = $replacement_expr;
   my @setup;
   my @out;
   my $match_number = 1;
   my $out_number = 1;

   while ( /\G([^\\%]+|[\\%])/g ) {
      if ( $1 eq "\\" ) {
         if ( /\G([a-zA-Z])/gc ) {
            push @out, qq{\\$1};
            next;
         }

         goto LITERAL if /\G(.)/gc;

         _err "lone backslash at end of ", $replacement_expr;
      }
      elsif ( $1 eq "%" ) {
         /\G(\d*.)/g
            or _err "lone % at end of ", $replacement_expr;

         my $op = $1;

         _err "unknown macro '%$op' in", $replacement_expr
            unless $op =~ /[cdosx]\z/;

         my $ord = $op !~ /s\z/ ? " ord" : "";

         push @setup,
            "my \$_$out_number = sprintf( '%$op',$ord \$$match_number );";

         push @out, "\${_$out_number}";
         ++$match_number;
         ++$out_number;
      }
      else {
      LITERAL:
         my $s = $1;
         $s =~ s/\$/\\\$/g;
         $s =~ s/\@/\\\@/g;
         $s =~ s/'/\\'/g;
         push @out, $s;
      }
   }

   my $out = join "", '"', @out, '"';

   return @setup
      ? join "", map "$_\n", @setup, $out
      : $out;
}


sub _compile_rule {
   my $self = shift;
   my ( $name, $fields, $pattern, $replacement ) = @_;

   my @fields = split /\s*,\s*/, $fields;
   die "no fields specified in stringedit rule $name\n"
      unless @fields;

   die "unkown field name '$_' in StringEdit field list '$fields'\n"
      for grep !VCP::Rev->can( $_ ), @fields;

   my ( $q1, $guts, $q2 ) = $pattern =~ /\A(\/|)(.*)(\1)\z/;

   my $replacement_code = $self->_compile_replacement_expr( $replacement );

   $replacement_code =~ s/^/   /mg;

   map {
      my $field = $_;
      my $code = join( "",
         $q1 eq "/"
            ? "s{$guts}"
            : "s{" . quotemeta( $guts ) . "}",
         "{\n$replacement_code}msge;\n"
      );

      $code =~ s/^/   /mg;

      {
         field => $field,
         code  => $code, 
      }
   } @fields;
}

sub _compile_rules {
   my VCP::Filter::stringedit $self = shift;
   my ( $rules ) = @_;

   ## NOTE: making this a closure causes spurious warnings at exit so
   ## we pass $self explicitly.
   my $preamble = <<END_PREAMBLE;
my ( \$self, \$rev ) = \@_;

END_PREAMBLE

   $preamble .= qq{lg( "stringedit processing ", \$rev->as_string );\n\n}
      if debugging;

   my $rule_number = 0;
   my @rules = map
      $self->_compile_rule( "Rule " . ++$rule_number, @$_ ),
      @$rules;

   my @fields = do {
      my %seen;
      sort grep !$seen{$_}++, map $_->{field}, @rules;
   };

   my $code = join( "",
      $preamble,
      ( map
         {
            my $field = $_;
            my $is_array = $field eq "labels";
            $is_array
               ? (
                  "\$rev->set_$field( [ map {\n",
                  map( $_->{code}, grep $_->{field} eq $field, @rules ),
                  "   \$_;\n} \$rev->$field ] );\n",
               )
               : (
                  "local \$_ = \$rev->$field;\n",
                  map( $_->{code}, grep $_->{field} eq $field, @rules ),
                  "\$rev->set_$field( \$_ );\n",
               )
         } @fields
      ),
      "\$self->dest->handle_rev( \$rev ) if \$self->dest;\n",
   );

   $code =~ s/^/   /mg;
   $code = "#line 1 VCP::Filter::stringedit::stringedit_function\n$code";

   $code = "sub {\n$code}";
   debug "stringedit code:\n$code" if debugging;

   return( eval $code
      or die "$@ compiling\n",
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
      $self->parse_rules_list( $options, "Field(s)", "Match", "Replacement" )
   );

   return $self ;
}


sub handle_rev {
   my VCP::Filter::stringedit $self = shift;

   $self->{MAP_SUB}->( $self, @_ );
}

=head1 LIMITATIONS

There is no way (yet) of telling the stringeditor to continue processing the
rules list.  We could implement labels like C< <<I<label>>> > to be
allowed before pattern expressions (but not between pattern and result),
and we could then impelement C< <<goto I<label>>> >.  And a C< <<next>>
> could be used to fall through to the next label.  All of which is
wonderful, but I want to gain some real world experience with the
current system and find a use case for gotos and fallthroughs before I
implement them.  This comment is here to solicit feedback :).

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
