use strict;
use warnings;

use Plack::Builder;
use Test::Exception;
use File::Temp;
use Test::More tests => 2;

my $app = sub {
    [
        200,
        ['Content-Type' => 'text/plain'],
        ['OK'],
    ];
};

dies_ok {
    builder {
        enable 'Recorder';
        $app;
    };
};

my $tempfile = File::Temp->new;
close $tempfile;
chmod 0, $tempfile->filename;

dies_ok {
    builder {
        enable 'Recorder', output => $tempfile->filename;
        $app;
    };
};
