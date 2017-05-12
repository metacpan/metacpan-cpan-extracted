use strict;
use warnings;
use Test::More;

use RDF::Sesame;

plan tests => 10;

SKIP: {

    # do we have all that's needed to run this test?
    my $uri    = $ENV{SESAME_URI};
    my $r_name = $ENV{SESAME_REPO};
    skip 'SESAME_URI environment not set', 10  unless $uri;
    skip 'SESAME_REPO environment not set', 10 unless $r_name;
    eval "use Test::RDF";
    skip "Test::RDF needed for testing repository dump", 10
        if $@ || $ENV{MINIMAL_TEST};

    my $conn = RDF::Sesame->connect( uri => $uri );
    my $repo = $conn->open($r_name);
    $repo->clear();  # make sure it's empty
    $repo->upload_uri( 'file:t/dc.rdf' );

    # try a simple extraction
    {
        my $rdf = $repo->extract( format => 'ntriples' );
        rdf_eq(
            ntriples => \$rdf,
            rdfxml   => 't/dc.rdf',
            'extract to scalar return value',
        );
    }

    # try extraction to a filehandle
    {
        my $rdf;
        open my $fh, '>', \$rdf;
        $repo->extract(
            format => 'turtle',
            output => $fh,
        );
        close $fh;
        rdf_eq(
            turtle => \$rdf,
            rdfxml => 't/dc.rdf',
            'extract to a filehandle',
        );
    }

    # try extraction to a named file
    SKIP: {
        eval "use File::Temp";
        skip "File::Temp needed for testing repository dump to file", 1
            if $@;

        my ($fh, $filename) = File::Temp::tempfile();
        close $fh;
        $repo->extract(
            format => 'rdfxml',
            compress => 'none',  # explicitly set no compression
            output => $filename,
        );
        rdf_eq(
            rdfxml => $filename,
            rdfxml => 't/dc.rdf',
            'extract to a filename',
        );
    }

    # pseudo-compress the RDF as it's extracted
    {
        my $rdf = $repo->extract(
            format => 'turtle',
            compress => {
                init => sub {
                    my ($fh) = @_;
                    print $fh 'init.';
                    my $context = 1;
                    return \$context;
                },
                content => sub {
                    my ($context, $fh, $content) = @_;
                    if ( $$context ) {
                        print $fh 'content.';
                        $$context = 0;
                    }
                },
                finish => sub {
                    my ($context, $fh) = @_;
                    print $fh 'finish.';
                },
            },
        );
        is( $rdf, 'init.content.finish.', '"pseudo-compression" worked' );
    }

    # make sure the gzip compression works
    SKIP: {
        eval 'use Compress::Zlib';
        skip 'Compress::Zlib needed to test streaming gzip compression', 2
            if $@;

        eval { $repo->extract( format => 'turtle', compress => 'gz' ) };
        like( $@, qr/Bad file descriptor/, 'gz broken with in-memory RDF' );

        my ($fh, $filename) = File::Temp::tempfile();
        $repo->extract(
            format   => 'turtle',
            compress => 'gz',
            output   => $fh,
        );
        close($fh);
        my $rdf_gz = do {
            local $/;  # slurp
            open my $fh, '<', $filename or die $!;
            <$fh>;
        };
        my $rdf = Compress::Zlib::memGunzip($rdf_gz);
        rdf_eq(
            turtle => \$rdf,
            rdfxml => 't/dc.rdf',
            'gzipped output',
        );
    }

    # make sure that niceOutput still produces the right RDF
    {
        my $rdf = $repo->extract(
            format  => 'turtle',
            options => [qw( niceOutput )],
        );
        rdf_eq(
            turtle => \$rdf,
            rdfxml => 't/dc.rdf',
            'extract with niceOutput',
        );
    }

    # try some error conditions
    eval { $repo->extract() };
    like( $@, qr/No serialization format specified/, 'no extract format' );

    SKIP: {
        eval 'use Test::MockModule';
        skip 'Test::MockModule needed to simulate extraction error', 1 if $@;

        my $lwp = Test::MockModule->new('LWP::UserAgent');
        $lwp->mock(
            post => sub {
                return HTTP::Response->new( 400, 'simulated failure' );
            }
        );
        eval { $repo->extract( format => 'rdfxml' ) };
        like( $@, qr/simulated failure/, 'server error on extraction' );
    }

    ok($repo->clear, 'clearing repository');
}
