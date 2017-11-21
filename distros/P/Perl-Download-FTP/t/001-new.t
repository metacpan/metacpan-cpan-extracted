# -*- perl -*-
# t/001-new.t
use strict;
use warnings;

use Perl::Download::FTP;
use Test::More (tests => 8);
use Test::RequiresInternet ('ftp.cpan.org' => 21);

my ($self, $host, $dir);

my $default_host = 'ftp.cpan.org';
my $default_dir  = '/pub/CPAN/src/5.0';

# bad args #
{
    local $@;
    eval { $self = Perl::Download::FTP->new( [] ); };
    like($@, qr/Argument to constructor must be hashref/,
        "Got expected error message for non-hashref argument");
}

{
    local $@;
    my $badarg = 'foo';
    eval { $self = Perl::Download::FTP->new( { $badarg => 'bar' } ); };
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
            $self = Perl::Download::FTP->new( {
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
            $self = Perl::Download::FTP->new( {
                host        => $default_host,
                dir         => $baddir,
            } );
        };
        like($@, qr/Cannot change to working directory $baddir/,
            "Got expected error message for invalid directory");
    }

    # good args #
    $self = Perl::Download::FTP->new( {
        host        => $default_host,
        dir         => $default_dir,
    } );
    ok(defined $self, "Constructor returned defined object");
    isa_ok ($self, 'Perl::Download::FTP');

    $self = Perl::Download::FTP->new();
    ok(defined $self, "Constructor returned defined object when using default values");
    isa_ok ($self, 'Perl::Download::FTP');
}


