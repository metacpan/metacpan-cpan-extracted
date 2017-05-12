use strict;
use warnings;

use HTTP::Request::Common;
use File::Temp;
use Plack::Builder;
use Plack::VCR;
use Plack::Test;
use Test::Exception;
use Test::More tests => 5;

dies_ok {
    Plack::VCR->new;
};

my $tempfile = File::Temp->new;
close $tempfile;
unlink $tempfile->filename;

dies_ok {
    Plack::VCR->new(filename => $tempfile->filename);
};

$tempfile = File::Temp->new;
close $tempfile;

my $app = builder {
    enable 'Recorder', output => $tempfile->filename;
    sub {
        [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
    };
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    $cb->(GET '/');
};

chmod 0, $tempfile->filename;

dies_ok {
    Plack::VCR->new(filename => $tempfile->filename);
};

$tempfile = File::Temp->new;
$tempfile->print("Hello, world!\n");
close $tempfile;

my $vcr;

lives_ok {
    $vcr = Plack::VCR->new(filename => $tempfile->filename);
};

dies_ok {
    $vcr->next;
};
