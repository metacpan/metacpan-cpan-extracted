package Plack::Middleware::BlockHeaderInjection;

# ABSTRACT: block header injections in responses

use v5.12;
use warnings;

use parent qw( Plack::Middleware );

use Plack::Util;
use Plack::Util::Accessor qw( logger status );

our $VERSION = 'v1.1.1';


sub call {
    my ( $self, $env ) = @_;

    # cache the logger
    $self->logger( $env->{'psgix.logger'} || sub { } )
      unless defined $self->logger;

    $self->status(500) unless $self->status;

    my $res = $self->app->($env);

    Plack::Util::response_cb(
        $res,
        sub {
            my $res = shift;

            # Sanity check headers

            my $hdrs = $res->[1];

            my $i = 0;
            while ( $i < @{$hdrs} ) {
                my $val = $hdrs->[ $i + 1 ];
                if ( $val =~ /[\n\r]/ ) {
                    my $key = $hdrs->[$i];
                    $self->log( error => "possible header injection detected in ${key}" );
                    $res->[0] = $self->status;
                    Plack::Util::header_remove( $hdrs, $key );
                }
                $i += 2;
            }

        }
    );

}

# Note: ideas borrowed from XSRFBlock


sub log {
    my ( $self, $level, $msg ) = @_;
    $self->logger->(
        {
            level   => $level,
            message => "BlockHeaderInjection: ${msg}",
        }
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::BlockHeaderInjection - block header injections in responses

=head1 VERSION

version v1.1.1

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = ...

  $app = builder {
    enable 'BlockHeaderInjection',
      status => 500;
    $app;
  };

=head1 DESCRIPTION

This middleware will check responses for injected headers. If the
headers contain newlines, then the return code is set to C<500> and
the offending header(s) are removed.

A common source of header injections is when parameters are passed
unchecked into a header (such as the redirection location).

An attacker can use injected headers to bypass system security, by
forging a header used for security (such as a referrer or cookie).

=head1 ATTRIBUTES

=head2 <status

The status code to return if an invalid header is found. By default,
this is C<500>.

=for Pod::Coverage log

=head1 SUPPORT FOR OLDER PERL VERSIONS

Since v1.1.0, this module requires Perl v5.12 or later.

Future releases may only support Perl versions released in the last ten years.

If you need this module on Perl v5.8, please use one of the v1.0.x versions of this module.  Signficant bug or security
fixes may be backported to those versions.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/HTTP_header_injection>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection>
and may be cloned from L<git://github.com/robrwo/Plack-Middleware-BlockHeaderInjection.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was supported by
Foxtons, Ltd L<https://www.foxtons.co.uk>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014,2020,2023 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
