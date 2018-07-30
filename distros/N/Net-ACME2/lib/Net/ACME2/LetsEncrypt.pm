package Net::ACME2::LetsEncrypt;

use strict;
use warnings;

use parent qw( Net::ACME2 );

=encoding utf-8

=head1 NAME

Net::ACME2::LetsEncrypt - Let’s Encrypt’s v2 API endpoint

=head1 SYNOPSIS

    my $acme = Net::ACME2::LetsEncrypt->new(

        environment => 'staging',   #default: “production”

        # ... and other arg(s) as described in Net::ACME2
    );

See L<Net::ACME2> for usage examples.

=head1 STAGING VS. PRODUCTION

This class’s constructor accepts an optional C<environment> parameter.
If you set this to C<staging>, you’ll get
L<Let’s Encrypt’s staging server|https://letsencrypt.org/docs/staging-environment/>
rather than the (default) C<production> server.

=cut

use constant {
    DIRECTORY_PATH => '/directory',

    _STAGING_SERVER    => 'acme-staging-v02.api.letsencrypt.org',
    _PRODUCTION_SERVER => 'acme-v02.api.letsencrypt.org',
};

sub HOST {
    my ($class, %opts) = @_;

    if ( my $env = $opts{'environment'} ) {
        if ($env eq 'staging') {
            return _STAGING_SERVER();
        }
        elsif ($env ne 'production') {
            die "Invalid “environment”! ($env)";
        }
    }

    return _PRODUCTION_SERVER();
}

1;
