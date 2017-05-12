# ABSTRACT: Plack middleware to set X-Frame-Options.

package Plack::Middleware::XFrameOptions::All;
BEGIN {
  $Plack::Middleware::XFrameOptions::All::VERSION = '0.2';
}

use strict;
use warnings;

=head1 NAME

Plack::Middleware::XFrameOptions::All - Plack middleware to set X-Frame-Options.

=head1 VERSION

version 0.2

=head1 DESCRIPTION

This module will setup X-Frame-Options header to protect clickjacking issue.
This header has been supported by IE8+, Fx 3.6.9+, Google Chrome.

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
	enable 'XFrameOptions::All', policy => 'sameorigin'; // or 'deny'
    }

=cut

use parent 'Plack::Middleware';

use Plack::Util;
use Plack::Util::Accessor qw/policy/;

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);
    Plack::Util::response_cb($res, sub {
	my $res = shift;

	my $h = Plack::Util::headers($res->[1]);

	# Only process text/html.
	my $ct = $h->get('Content-Type') or return;
	return unless $ct =~ qr{text/html};

	$h->set('X-Frame-Options', $self->policy);
    });
}

sub prepare_app {
    my $self = shift;
    $self->policy('sameorigin') unless defined $self->policy;
}

=head1 AUTHOR

Gea-Suan Lin, C<< <gslin at gslin.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Gea-Suan Lin.

This software is released under 3-clause BSD license. See
L<http://www.opensource.org/licenses/bsd-license.php> for more
information.

=cut

1;