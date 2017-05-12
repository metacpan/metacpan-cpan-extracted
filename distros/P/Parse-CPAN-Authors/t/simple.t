#!perl -T
use strict;
use lib 'lib';
use IO::Zlib;
use Test::Exception;
use Test::More tests => 43;
use_ok('Parse::CPAN::Authors');

my $filename   = "t/01mailrc.txt";
my $gzfilename = "t/01mailrc.txt.gz";

my $fh = IO::Zlib->new( $gzfilename, "rb" )
    || die "Failed to read $filename: $!";
my $contents = join '', <$fh>;
$fh->close;

# try with no filename
chdir "t";
my $p = Parse::CPAN::Authors->new();
is_fine($p);
chdir "..";

# try with the filename
$p = Parse::CPAN::Authors->new($filename);
is_fine($p);

# try with the gzipped filename
$p = Parse::CPAN::Authors->new($gzfilename);
is_fine($p);

# try with the contents
$p = Parse::CPAN::Authors->new($contents);
is_fine($p);

# try with fake filename
throws_ok { Parse::CPAN::Authors->new("xyzzy") } qr/Failed to read/;

# try with fake gzipped filename
throws_ok { Parse::CPAN::Authors->new("xyzzy.gz") } qr/Failed to read/;

sub is_fine {
    my $p = shift;

    isa_ok( $p, 'Parse::CPAN::Authors' );

    my $a = $p->author('AASSAD');
    isa_ok( $a, 'Parse::CPAN::Authors::Author' );
    is( $a->pauseid, 'AASSAD' );
    is( $a->name,    "Arnaud 'Arhuman' Assad" );
    is( $a->email,   'arhuman@hotmail.com' );

    $a = $p->author('AJOHNSON');
    isa_ok( $a, 'Parse::CPAN::Authors::Author' );
    is( $a->pauseid, 'AJOHNSON' );
    is( $a->name,    'Andrew L. Johnson' );
    is( $a->email,   'andrew-johnson@shaw.ca' );

    is_deeply(
        [ sort map { $_->pauseid } $p->authors ],
        [   qw(AADLER AALLAN
                AANZLOVAR AAR AARDEN AARONJJ AARONSCA AASSAD ABARCLAY AJOHNSON)
        ]
    );
}
