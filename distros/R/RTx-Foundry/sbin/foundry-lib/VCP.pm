package VCP ;

=head1 NAME

VCP - Versioned Copy, copying hierarchies of versioned files

=head1 SYNOPSIS

see the vcp command line.

=head1 DESCRIPTION

This module copies hierarchies of versioned files between repositories, and
between repositories and RevML (.revml) files.

Stay tuned for more documentation.

=head1 METHODS

=over

=for test_scripts t/10vcp.t t/50revml.t

=cut

$VERSION = 0.1 ;

use strict ;
use VCP::Logger qw( lg );

require VCP::Source ;
require VCP::Dest ;

use fields (
   'PLUGINS',     # The VCP::Source to pull data from
) ;


=item new

   $ex = VCP->new( $source, $dest ) ;

where

   $source  is an instance of VCP::Source
   $dest    is an instance of VCP::Dest

=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class;

   my VCP $self = do {
      no strict 'refs' ;
      bless [ \%{"$class\::FIELDS"} ], $class;
   };

   my $w = length $#_;
   for ( my $i = 0; $i <= $#_; ++$i ) {
      lg sprintf "plugin %${w}d is %s", $i, ref $_[$i];
   }

   $self->{PLUGINS} = [ @_ ];

   unless ( grep $_->is_sort_filter, @{$self->{PLUGINS}} ) {
      lg "inserting default ChangeSets filter";
      require VCP::Filter::changesets;
      splice @{$self->{PLUGINS}}, 1, 0,
         VCP::Filter::changesets->new;
   }

   {
      my $dest = $self->{PLUGINS}->[-1];
      for ( reverse @{$self->{PLUGINS}}[0..$#{$self->{PLUGINS}} -1] ) {
         $_->dest( $dest );
         $dest = $_;
      }
   }

   return $self ;
}


=item copy_all

   $vcp->copy_all( $header, $footer ) ;

Calls $source->handle_header, $source->copy_revs, and $source->handle_footer.

=cut

sub copy_all {
   my VCP $self = shift ;

   my ( $header, $footer ) = @_ ;

   my VCP::Source $s = $self->{PLUGINS}->[0];
   $s->handle_header( $header ) ;
   $s->copy_revs() ;
   $s->handle_footer( $footer ) ;

   ## Removing this link allows the dest to be cleaned up earlier by perl,
   ## which keeps VCP::Rev from complaining about undeleted revs.
   $s->dest( undef ) ;
   return ;
}


=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1
