package Perlbal::Plugin::ForwardedFor;

use strict;
use warnings;
use Perlbal;

our $VERSION = '0.02';

my $target_header;

sub load {
    Perlbal::register_global_hook( 'manage_command.forwarded_for', sub {
        my $mc = shift->parse(qr/^forwarded_for\s+=\s+(.+)\s*$/,
                  "usage: FORWARDED_FOR = <new_name>");

        ($target_header) = $mc->args;

        return $mc->ok;
    } );

    return 1;
}

sub register {
    my ( $self, $svc ) = @_;

    $svc->register_hook(
        'ForwardedFor',
        'backend_client_assigned',
        sub { rewrite_header( @_, $target_header ) },
    );

    return 1;
} 

sub rewrite_header {
    my ( $svc, $target_header ) = @_;
    my $headers     = $svc->{'req_headers'};
    my $header_name = 'X-Forwarded-For';
    my $forwarded   = $headers->header($header_name);
    my $DELIMITER   = q{, };
    my $EMPTY       = q{};

    my @ips = split /$DELIMITER/, $forwarded;
    my $ip  = pop @ips;

    $headers->header( $target_header, $ip );

    if (@ips) {
        $headers->header( $header_name, join $DELIMITER, @ips );
    } else {
        # actually, i wish we could delete it
        $headers->header( $header_name, $EMPTY );
    }

    return 0;
}

1;

__END__

=head1 NAME

Perlbal::Plugin::ForwardedFor - Rename the X-Forwarded-For header in Perlbal

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This plugin changes the header Perlbal will use to delcare itself as a proxy.

Usually Perlbal will - perl RFC - add itself to X-Forwarded-For, but this
plugins allows you to change that to any header you want, so you could differ
Perlbal from other possible proxies the user might have.

In your Perlbal configuration:

    LOAD ForwardedFor

    CREATE SERVICE http_balancer
      SET role      = reverse_proxy
      SET pool      = machines
      SET plugins   = ForwardedFor
      FORWARDED_FOR = X-Perlbal-Forwarded-For

=head1 SUBROUTINES/METHODS

=head2 load

Register a global hook and check for configuration problems.

=head2 register

Register a service hook to run a callback to rewrite the header.

=head2 rewrite_header

The function that is called as the callback.

Rewrites the I<X-Forwarded-For> to whatever header name you specified in the
configuration file.

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 BUGS

This plugin is on Github and you can file issues on:

L<http://github.com/xsawyerx/perlbal-plugin-forwardedfor/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perlbal::Plugin::ForwardedFor

You can also look for information at:

=over 4

=item * Github issue tracker:

L<http://github.com/xsawyerx/perlbal-plugin-forwardedfor/issues>

=item * Github page:

L<http://github.com/xsawyerx/perlbal-plugin-forwardedfor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perlbal-Plugin-ForwardedFor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perlbal-Plugin-ForwardedFor>

=item * Search CPAN

L<http://search.cpan.org/dist/Perlbal-Plugin-ForwardedFor/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

