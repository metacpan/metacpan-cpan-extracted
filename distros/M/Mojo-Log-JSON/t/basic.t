use strict;
use warnings;

use Test::More;
use Capture::Tiny 'capture_stderr';
use Mojo::Log::JSON;

my $time_re = qr/"\d{4}-\d\d-\d\d \d\d:\d\d:\d\d"/;

my $stderr;

subtest defaults => sub {

    ok my $logger = Mojo::Log::JSON->new(), "new";

    $stderr = capture_stderr { $logger->debug("Simple string") };
    like $stderr,
        qr/{"datetime":$time_re,"level":"debug","message":"Simple string"}/,
        "string message ok";

    $stderr = capture_stderr { $logger->debug(qw/ Multi line string /) };
    like $stderr,
        qr/{"datetime":$time_re,"level":"debug","message":"Multi\\nline\\nstring/,
        "multi line message ok";

    $stderr = capture_stderr {
        $logger->debug( { message => "Data structure", foo => 'bar' } );
    };
    like $stderr,
        qr/{"datetime":$time_re,"foo":"bar","level":"debug","message":"Data structure"}/,
        "data structure message ok";
};

subtest include_level => sub {

    ok my $logger = Mojo::Log::JSON->new( include_level => 1 ), "new";

    $stderr = capture_stderr { $logger->debug("Simple string") };
    like $stderr,
        qr/{"datetime":$time_re,"level":"debug","message":"Simple string"}/,
        "include_level on";

    ok $logger = Mojo::Log::JSON->new( include_level => 0 ), "new";

    $stderr = capture_stderr { $logger->debug("Simple string") };
    like $stderr,
        qr/{"datetime":$time_re,"message":"Simple string"}/,
        "include_level off";
};

subtest default_fields_scalar => sub {

    ok my $logger = Mojo::Log::JSON->new( default_fields => { foo => 'bar' } ),
        "new";

    $stderr = capture_stderr { $logger->debug("Simple string") };
    like $stderr,
        qr/{"foo":"bar","level":"debug","message":"Simple string"}/,
        "default_fields [scalar]";

    $logger->default_fields->{wibble} = 'wobble';

    $stderr = capture_stderr { $logger->debug("Simple string") };
    like $stderr,
        qr/{"foo":"bar","level":"debug","message":"Simple string","wibble":"wobble"}/,
        "additional default field";
};

subtest default_fields_coderef => sub {

    my $foo = 10;

    ok my $logger = Mojo::Log::JSON->new(
        default_fields => {
            foo => sub { $foo++ }
        }
        ),
        "new";

    $stderr = capture_stderr { $logger->debug("Simple string") };
    like $stderr,
        qr/{"foo":10,"level":"debug","message":"Simple string"}/,
        "default_fields [coderef]";

    $logger->default_fields->{wibble} = 'wobble';

    $stderr = capture_stderr { $logger->debug("Simple string") };
    like $stderr,
        qr/{"foo":11,"level":"debug","message":"Simple string","wibble":"wobble"}/,
        "additional default field";
};

done_testing;
