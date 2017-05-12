=head1 NAME

OpenFrame::WebApp::Session::MemCache - sessions using Cache::MemoryCache

=head1 SYNOPSIS

  use OpenFrame::WebApp::Session::MemCache;

  # see OpenFrame::WebApp::Session

=cut

package OpenFrame::WebApp::Session::MemCache;

use strict;
use warnings::register;

use Cache::MemoryCache;

use base qw( OpenFrame::WebApp::Session::CacheBase );

use constant cache_class => "Cache::MemoryCache";

our $VERSION = (split(/ /, '$Revision: 1.2 $'))[1];

1;

=head1 DESCRIPTION

An C<OpenFrame::WebApp::Session> using C<Cache::MemoryCache>.

Inherits its interface from L<OpenFrame::WebApp::Session::CacheBase>.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Cache::MemoryCache>,
L<OpenFrame::WebApp::Sesssion>,
L<OpenFrame::WebApp::Sesssion::CacheBase>,
L<OpenFrame::WebApp::Sesssion::FileCache>

=cut
