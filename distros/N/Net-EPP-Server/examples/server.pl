#!perl
# ABSTRACT: an example EPP server built using Net::EPP::Server
use File::Basename qw(dirname basename);
use File::Spec;
use File::Temp;
use IPC::Open3;
use List::Util qw(any);
use Net::EPP::Frame::ObjectSpec;
use Net::EPP::ResponseCodes;
use Net::EPP::Server;
use feature qw(state);
use strict;

=pod

=head1 SYNOPSIS

    server.pl CAFILE

=head1 INTRODUCTION

C<server.pl> is an example implementation of an EPP server that uses
L<Net::EPP::Server>.

When started, it will listen on C<localhost> (C<127.0.0.1> and/or C<::1>) on
port 7000 using a dynamically-generated self-signed certificate.

Its only argument is a path to a CA bundle that is used to validate client
certificates.

=head1 EVENT HANDLERS

EPP business logic is implemented in the following functions:

=over

=item * C<hello_handler()>

=item * C<login_handler()>

=item * C<poll_handler()>

=item * C<check_handler()>

=item * C<info_handler()>

=item * C<create_handler()>

=item * C<update_handler()>

=item * C<renew_handler()>

=item * C<delete_handler()>

=item * C<transfer_handler()>

=item * C<other_handler()>

=back

=head1 AUTHENTICATION

The C<$users> variable is a hashref which maps client IDs to passwords which are
stored in plaintext. Since this script is purely illustrative, this is fine.

C<server.pl> implements the Login Security extension, which is mandatory.

=cut

my $users = {
    'gavin' => 'foo2bar',
};

my $server = Net::EPP::Server->new;

my ($key, $cert) = auto_ssl();

$server->run(
    #
    # generic options
    #
    log_level => 4,

    #
    # TLS-specific options
    #
    SSL_key_file    => $key,
    SSL_cert_file   => $cert,

    #
    # Net::EPP::Server-specific options
    #
    client_ca_file  => $ARGV[0],
    timeout         => 30,
    xsd_file        => File::Spec->catfile(dirname(__FILE__), qw(xsd epp.xsd)),

    handlers => {
        hello       => \&hello_handler,
        login       => \&login_handler,
        poll        => \&poll_handler,
        check       => \&check_handler,
        info        => \&info_handler,
        create      => \&create_handler,
        update      => \&update_handler,
        renew       => \&renew_handler,
        delete      => \&delete_handler,
        transfer    => \&transfer_handler,
        other       => \&other_handler,
    },
);

sub hello_handler {
    return {
        'svID'          => basename(__FILE__),
        'lang'          => [ qw(en) ],
        'objects'       => [ map { Net::EPP::Frame::ObjectSpec->xmlns($_) } qw(domain) ],
        'extensions'    => [ map { Net::EPP::Frame::ObjectSpec->xmlns($_) } qw(secDNS rgp loginSec allocationToken launch ttl) ],
    };
}

sub login_handler {
    my %args = @_;
    my $frame = $args{'frame'};

    my $loginSecURI = Net::EPP::Frame::ObjectSpec->xmlns('loginSec');

    #
    # look for the Login Security extension, it's mandatory
    #
    my $loginSec = any { $_->textContent eq $loginSecURI } $frame->getElementsByTagName('extURI');

    #
    # the Login Security extension URI must be listed and the <pw> element must
    # contain the magic string
    #
    if (!$loginSec || '[LOGIN-SECURITY]' ne $frame->getElementsByTagName('pw')->item(0)->textContent) {
        return $server->generate_error(
            code    => AUTHENTICATION_ERROR,
            msg     => 'The Login Security Extension is mandatory.',
            clTRID  => $args{'clTRID'},
            svTRID  => $args{'svTRID'},
        );
    }

    if ($frame->getElementsByTagNameNS($loginSecURI, 'newPW')->size > 0) {
        return $server->generate_error(
            code    => UNIMPLEMENTED_OPTION,
            msg     => 'Changing password is not currently supported.',
            clTRID  => $args{'clTRID'},
            svTRID  => $args{'svTRID'},
        );
    }

    my $id = $frame->getElementsByTagName('clID')->item(0)->textContent;
    my $pw = $frame->getElementsByTagNameNS($loginSecURI, 'pw')->item(0)->textContent;

    return ($users->{$id} eq $pw ? OK : AUTHENTICATION_ERROR);
}

sub poll_handler {
    return UNIMPLEMENTED_COMMAND;
}

sub check_handler {
    return UNIMPLEMENTED_COMMAND;
}

sub info_handler {
    return UNIMPLEMENTED_COMMAND;
}

sub create_handler {
    return UNIMPLEMENTED_COMMAND;
}

sub update_handler {
    return UNIMPLEMENTED_COMMAND;
}

sub renew_handler {
    return UNIMPLEMENTED_COMMAND;
}

sub delete_handler {
    return UNIMPLEMENTED_COMMAND;
}

sub transfer_handler {
    return UNIMPLEMENTED_COMMAND;
}

sub other_handler {
    return UNIMPLEMENTED_COMMAND;
}

#
# This method dynamically generates a self-signed x509 certificate.
#
sub auto_ssl {
    my $key  = File::Temp::tempnam(File::Spec->tmpdir, 'key_');
    my $cert = File::Temp::tempnam(File::Spec->tmpdir, 'cert_');

    my $pid = open3(undef, undef, undef, qw(openssl req -new -newkey rsa:2048
        -days 7 -nodes -x509 -subj / -keyout), $key, q{-out}, $cert);

    waitpid($pid, 0);

    croak('certificate generation failed') if ($? >> 8 > 0);

    chmod(0400, $key);

    return ($key, $cert);
}
