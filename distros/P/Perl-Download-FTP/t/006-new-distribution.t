# -*- perl -*-
# t/006-new-distribution.t
use strict;
use warnings;

use Perl::Download::FTP::Distribution;
use Test::More tests =>  9;
use Test::RequiresInternet ('ftp.cpan.org' => 21);

my ($self, $host, $dir);

my $default_host = 'ftp.cpan.org';
my $default_dir  = 'pub/CPAN/modules/by-module';
my $sample = 'Test-Smoke';

# bad args #
{
    local $@;
    eval { $self = Perl::Download::FTP::Distribution->new( [] ); };
    like($@, qr/Argument to constructor must be hashref/,
        "Got expected error message for non-hashref argument");
}

{
    local $@;
    eval { $self = Perl::Download::FTP::Distribution->new(); };
    like($@, qr/^Must provide 'distribution' element/,
        "Got expected error message for absence of 'distribution' element");
}

{
    local $@;
    my $badarg = 'foo';
    eval { $self = Perl::Download::FTP::Distribution->new( {
        $badarg => 'bar',
        distribution => $sample,
    } ); };
    like($@, qr/Argument '$badarg' not permitted in constructor/,
        "Got expected error message for invalid key");
}

SKIP: {
    skip "Set PERL_ALLOW_NETWORK_TESTING to conduct live tests",
        6 unless $ENV{PERL_ALLOW_NETWORK_TESTING};

    {
        local $@;
        my $badhost = 'foo.thenceforward.net';
        eval {
            $self = Perl::Download::FTP::Distribution->new( {
                distribution => $sample,
                host        => $badhost,
                dir         => $default_dir,
                Timeout     => 5,
            } );
        };
        like($@, qr/Cannot connect to $badhost/,
            "Got expected error message for invalid host; Net::FTP option recognized");
    }

    {
        local $@;
        my $baddir = 'foo/bar/baz';
        eval {
            $self = Perl::Download::FTP::Distribution->new( {
                distribution => $sample,
                host        => $default_host,
                dir         => $baddir,
            } );
        };
        like($@, qr/Cannot change to working directory $baddir/,
            "Got expected error message for invalid directory");
    }

    # good args #
    $self = Perl::Download::FTP::Distribution->new( {
        distribution    => $sample,
        host            => $default_host,
        dir             => $default_dir,
    } );
    ok(defined $self, "Constructor returned defined object");
    isa_ok ($self, 'Perl::Download::FTP::Distribution');

    $self = Perl::Download::FTP::Distribution->new( {
        distribution => $sample,
    } );
    ok(defined $self,
        "Constructor returned defined object when using default values for 'host' and 'dir'");
    isa_ok ($self, 'Perl::Download::FTP::Distribution');
}


