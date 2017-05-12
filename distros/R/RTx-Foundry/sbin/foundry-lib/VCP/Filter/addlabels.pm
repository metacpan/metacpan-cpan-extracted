package VCP::Filter::addlabels;

=head1 NAME

VCP::Filter::addlabels - Add labels to each revision

=head1 SYNOPSIS

  ## From the command line:
   vcp <source> addlabels: "rev_$rev_id" "change_$change_id" -- <dest>

  ## In a .vcp file:

    AddLabels:
            rev_$rev_id
            change_$change_id
            # ... etc ...

=head1 DESCRIPTION

Used when you want to track the original rev_id, change_id, branch_id,
etc. each revision had in the source repository by adding a label.
Can be used to turn any piece of metadata in to a label.

Note that the fields

    source_name, source_filebranch_id, source_branch_id,
    source_rev_id, source_change_id

are set by VCP to be the same value as the corresponding fields
without the source prefix (except source_filebranch_id, which is built
from the file name, rooted in the repository, and for cvs
repositories, the branch number in angle brackets.)  These source_*
fields (intended to be immutable in vcp) should be used to make labels
rather than their mutable equivalents which may be changed via a vcp
filter.

There is no way to add labels only to selected revisions at this
time, but if you try to add a label for metadata that is undefined
or empty, it will not be added.

=for test_script t/61addlabels.t

=cut

$VERSION = 1 ;

use strict ;
use VCP::Logger qw( lg );
use VCP::Debug qw( :debug );
use VCP::Filter;
use base qw( VCP::Filter );

use fields (
   'MAP_SUB',   ## The rules to apply, compiled in to an anon sub
);

sub _empty { ! ( defined $_ && length $_ ) }

sub _compile_label_add_routine {
   my VCP::Filter::addlabels $self = shift;
   my ( $label_specs ) = @_;

   my $preamble = <<END_PREAMBLE;
my ( \$self, \$rev ) = \@_;

END_PREAMBLE

   $preamble .= qq{my \$s = \$_; \$s =~ s/\\n/\\\\n/g; lg( "addlabels processing '\$s' (", \$rev->as_string, ")" );\n\n}
      if debugging;

   my @code = ( $preamble );

   for ( @$label_specs ) {
      my ( $l ) = @$_;
      my %f;
      $l =~ s/\$(\w+)/$f{$1}=undef; "' . \$rev->$1 . '"/ge;
      $l =~ s/\$\{[^}]+\}/$f{$1}=undef; "' . \$rev->$1 . '"/ge;
      push @code, join "",
         "\$rev->add_label( '",
         $l,
         "' )",
         keys %f
            ? (
               " if ! grep _empty, ",
               join( ", ", map "\$rev->$_()", sort keys %f )
            )
            : (),
          ";\n";
   }

   push @code, "\$self->dest->handle_rev( \$rev );\n";

   my $code = join "", @code;
   $code =~ s/^/   /mg;

   # NOTE: the sub is a closure and encloses our $self
   $code = "sub {\n$code}";
   debug "addlabels code:\n$code" if debugging;

   return( eval $code
      or die "$@ compiling AddLabels filter:\n",
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

   # Add the default rule.
   my $label_specs = $self->parse_rules_list( $options, "Label Specs" );

   $self->{MAP_SUB} = $self->_compile_label_add_routine( $label_specs );

   return $self ;
}


sub handle_rev {
   my VCP::Filter::addlabels $self = shift;

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
