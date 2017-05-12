package Perlbal::Plugin::ExpandSSL;

use strict;
use warnings;
use Perlbal;
use Crypt::X509;
use MIME::Base64;
use File::Slurp;

our $VERSION = '0.02';

my %registry = ();
my %headers  = (
    X_FORWARDED_SSL_S_DN_CN => 'subject_cn',
);


sub load {1}

sub register {
    my ( $self, $svc ) = @_;
    $svc->register_hook(
        'ExpandSSL',
        'start_proxy_request',
        sub { expand_ssl(@_) },
    );

    build_registry( $svc->{'ssl_cert_file'} );

    return 1;
}

sub build_registry {
    my $file = shift;
    my @pem  = read_file($file);
    my $pem  = serialize_pem(@pem);
    my $der  = decode_base64($pem);
    my $cert = Crypt::X509->new( cert => $der );

    if ( $cert->error ) {
        my $error = $cert->error;
        warn "ERROR: $error\n";
        return 1;
    }

    foreach my $header ( keys %headers ) {
        my $method = $headers{$header};
        $registry{$header} = $cert->$method;
    }

    return 0;
}

sub serialize_pem {
    my @pem       = @_;
    my $PEM_BEGIN = '-----BEGIN CERTIFICATE-----';
    my $PEM_END   = '-----END CERTIFICATE-----';
    my $pem;

    foreach my $line (@pem) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        chomp $line;
        $line or next;
        
        if ( $line eq $PEM_BEGIN or $line eq $PEM_END ) {
            next;
        }

        $pem .= "$line\n";
    }

    return $pem;
}

sub expand_ssl {
    my $svc         = shift;
    my $req_headers = $svc->{'req_headers'};

    foreach my $header ( keys %registry ) {
        $req_headers->header( $header, $registry{$header} );
    }

    return 0;
}

sub unregister {
    # clearing registry
    %registry = ();

    return 1;
}

sub unload {1}

1;

__END__

=head1 NAME

Perlbal::Plugin::ExpandSSL - Add a custom header according to the SSL of a
service

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This plugin adds a custom header according to information it reads off the SSL
certificate of a service you've configured.

Since Perlbal speaks plain HTTP to backends (while being able to serve HTTPS to
clients), the backend does not know whether the client tried to reach HTTPS or
HTTP.

This plugin reads the certificate Perlbal is configured to serve the user, and
adds an according header to the backend so it knows.

In your Perlbal configuration:

    LOAD ExpandSSL

    CREATE SERVICE https_balancer
      SET role          = reverse_proxy
      SET pool          = machines
      SET plugins       = ExpandSSL
      SET enable_ssl    = on
      SET ssl_key_file  = /etc/perlbal/certs/mydomain.key
      SET ssl_cert_file = /etc/perlbal/certs/mydomain.crt
      SET plugins       = ExpandSSL

=head1 SUBROUTINES/METHODS

=head2 register

Register a service hook to run a callback to build a registry of headers for
each request.

=head2 build_registry

The is the function being called to create the registry. It starts by decoding
the cert file and then building the registry using a hardcoded headers hash.

Don't like it? Patches are welcome! :)

=head2 serialize_pem

Takes a PEM-formatted certification file (the type you give Perlbal or your
regular webserver to serve to the client) and returns only the Base 64 portion
of it.

Basicaly it removed the header and footer in a clean manner.

=head2 expand_ssl

Sets the special headers from the registry. This uses the I<start_proxy_request>
hook.

=head2 unregister

Clears up the registry.

=head2 load

Nothing.

=head2 unload

Nothing.

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 BUGS

This plugin is on Github and you can file issues on:

L<http://github.com/xsawyerx/perlbal-plugin-expandssl/issues>

=head1 SUPPORT

This module sports B<100% test coverage>, but in case you have more issues...

You can find documentation for this module with the perldoc command.

    perldoc Perlbal::Plugin::ExpandSSL

You can also look for information at:

=over 4

=item * Github issue tracker:

L<http://github.com/xsawyerx/perlbal-plugin-expandssl/issues>

=item * Github page:

L<http://github.com/xsawyerx/perlbal-plugin-expandssl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perlbal-Plugin-ExpandSSL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perlbal-Plugin-ExpandSSL>

=item * Search CPAN

L<http://search.cpan.org/dist/Perlbal-Plugin-ExpandSSL/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

