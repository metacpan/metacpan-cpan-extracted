package VCP::Source::null ;

=head1 NAME

VCP::Source::null - A null source, for testing purposes

=head1 SYNOPSIS

   vcp null:

=head1 DESCRIPTION

Takes no options, delivers no data.

=cut

$VERSION = 1.0 ;

use strict ;

use Carp ;
use VCP::Debug ":debug" ;

use base qw( VCP::Source );

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Source::null $self = $class->SUPER::new( @_ ) ;

   ## Parse the options
   my ( $spec, $options ) = @_ ;

   die "vcp: the null source takes no spec ('$1')\n"
      if $spec =~ m{\Anull:(.+)};

   $self->parse_options(
      $options,
      'TAKESNOOPTIONS' => \undef,
   );

   return $self ;
}


sub handle_header {
   my VCP::Source::null $self = shift ;
   my ( $header ) = @_ ;

   $self->dest->handle_header( $header ) ;
   return ;
}


sub get_rev {
   require File::Spec;
   my ( $r ) = @_;

   die "vcp: can't check out ", $r->as_string, "\n"
      unless $r->action eq "add" || $r->action eq "edit";

   return File::Spec->null;
}


=head1 SEE ALSO

L<VCP::Dest::null>, L<vcp>.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
