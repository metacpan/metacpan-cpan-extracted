=head1 NAME

OpenFrame::WebApp::Session::CacheBase - abstract base for sessions using
Cache::Cache modules

=head1 SYNOPSIS

  # abstract class - cannot be instantiated
  use base qw( OpenFrame::WebApp::Session::CacheBase );

=cut

package OpenFrame::WebApp::Session::CacheBase;

use strict;
use warnings::register;

use Error;
use OpenFrame::WebApp::Error::Abstract;

our $VERSION = (split(/ /, '$Revision: 1.1 $'))[1];

use base qw( OpenFrame::WebApp::Session );

sub cache_class {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub store {
    my $self   = shift;
    my $expiry = $self->get_expiry_seconds;
    my @args   = ($self->id, $self);
    push (@args, "$expiry s") if (defined $expiry);
    $self->cache_class->new()->set( @args );
    return $self->id;
}

sub fetch {
    my $class = shift;
    my $id    = shift || return;
    return $class->cache_class->new({auto_purge_on_get => 1})->get( $id );
}

sub remove {
    my $self = shift;
    my $id   = ref($self) ? $self->id : shift;
    $self->cache_class->new()->remove( $id );
    return $self;
}


1;

=head1 DESCRIPTION

An C<OpenFrame::WebApp::Session> for using C<Cache::Cache> modules.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

Based on C<OpenFrame::AppKit::Session>, by James A. Duncan.

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Cache::Cache>,
L<OpenFrame::WebApp::Sesssion>,
L<OpenFrame::WebApp::Session::MemCache>,
L<OpenFrame::WebApp::Session::FileCache>

=cut
