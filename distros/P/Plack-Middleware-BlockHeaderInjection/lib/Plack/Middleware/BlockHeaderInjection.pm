package Plack::Middleware::BlockHeaderInjection;

# ABSTRACT: block header injections in responses

use v5.24;
use warnings;

use parent qw( Plack::Middleware );

use Plack::Util;
use Plack::Util::Accessor qw( logger status clean );

use experimental qw( signatures );

our $VERSION = 'v1.3.0';


sub prepare_app($self) {

    $self->status(500) unless $self->status;
    $self->clean( !!$self->clean );
}

sub call( $self, $env ) {

    # cache the logger
    $self->logger( $env->{'psgix.logger'} || sub { } )
      unless defined $self->logger;

    my $res = $self->app->($env);

    Plack::Util::response_cb(
        $res,
        sub {
            my $res = shift;

            # Sanity check headers

            my $hdrs = $res->[1];

            my $i = 0;
            while ( $i < $hdrs->@* ) {
                my ( $key, $val ) = ( $hdrs->[$i], $hdrs->[ $i + 1 ] );
                if ( $self->clean && $val =~ s/[\N{U+00}\n\r]+/ /gm ) {
                    Plack::Util::header_set( $hdrs, $key, $val );
                }
                if ( $val =~ /[\N{U+00}-\N{U+1f}]/ ) {
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


sub log( $self, $level, $msg ) {
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

version v1.3.0

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = ...

  $app = builder {
    enable 'BlockHeaderInjection',
      status => 500;
    $app;
  };

=head1 DESCRIPTION

This middleware will check response headers for control characters (codes 0 through 31) (which also includes newlines that can be used for header injections).
These  are not allowed according to the L<PSGI specification|https://metacpan.org/pod/PSGI#Headers>.
If they are found, then it will the return code is set to C<500> and the offending header(s) are removed.

A common source of header injections is when parameters are passed
unchecked into a header (such as the redirection location).

An attacker can use injected headers to bypass system security, by
forging a header used for security (such as a referrer or cookie).

=head1 ATTRIBUTES

=head2 status

The status code to return if an invalid header is found. By default,
this is C<500>.

=head2 clean

When this is true, null bytes, newlines and carriage returns are changed into whitespace rather than rejected.
This should be set when there are legitimate multi-line headers that need to be cleaned up for L<PSGI>.

This defaults to false.

Added in v1.3.0

=for Pod::Coverage log

=head1 SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.24 or later.

Future releases may only support Perl versions released in the last ten years.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/HTTP_header_injection>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection>
and may be cloned from L<https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Plack-Middleware-BlockHeaderInjection/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The initial development of this module was supported by
Foxtons, Ltd L<https://www.foxtons.co.uk>.

=head1 CONTRIBUTOR

=for stopwords Graham Knop

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2026 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
