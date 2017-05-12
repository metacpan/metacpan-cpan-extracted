use strict;
use warnings;
use v5.10.1;
use Test::More;
use Plack::App::DAIA::Test;

use lib 't';
use SampleDAIAApp;

my $app = SampleDAIAApp->new( errors => 1 );

# adds warnings
test_daia_psgi $app,
    'foo:bar' => sub {
        is(scalar $_->document, 1, 'returned a document');
    },
    'doz:bar' => sub {
        is(scalar $_->document, 0, 'returned no document');
    };

# does not add any warnings
test_daia $app,
    'foo:bar' => sub {
        is(scalar $_->document, 1, 'returned a document');
    },
    'doz:bar' => sub {
        is(scalar $_->document, 1, 'returned a document');
    };

$app = SampleDAIAApp->new( warnings => 0 );
test_daia_psgi $app,
    'doz:bar' => sub {
        is(scalar $_->document, 1, 'returned a document');
    };

done_testing;
