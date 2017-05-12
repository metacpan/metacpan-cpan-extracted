use strict;
use warnings;
use lib 't/lib';
use IO::Capture::Stdout;
use OptArgs qw/dispatch/;
use Test::More;
use Test::Output;
use Test::Fatal;

$OptArgs::COLOUR = 0;

sub eval_output_is (&$$) {
    my $sub = shift;
    my $ref = shift;
    my $msg = shift;

    my $capture = IO::Capture::Stdout->new();

    $capture->start();
    $sub->();
    $capture->stop();

    my $VAR1;
    my $str = $capture->read;
    eval $str;

    is_deeply $VAR1, $ref, $msg;
}

like exception { dispatch(qw/run app::multi/) }, qr/usage:.* init .* new /s,
  'no arguments';

eval_output_is sub { dispatch(qw/run app::multi init/) },
  { _caller => 'app::multi::init' }, 'init';

like exception { dispatch(qw/run app::multi init -q/) },
  qr/error:.*unexpected .*-q/si, 'unexpected option';

# abbreviations

$OptArgs::ABBREV = 0;

like exception { dispatch(qw/run app::multi in/) }, qr/error/i,
  'No abbreviation';

$OptArgs::ABBREV = 1;

eval_output_is(
    sub { dispatch(qw/run app::multi i/) },
    { _caller => 'app::multi::init' },
    'abbrev i'
);

eval_output_is(
    sub { dispatch(qw/run app::multi ini/) },
    { '_caller' => 'app::multi::init' },
    'abbrev ini'
);

eval_output_is(
    sub { dispatch(qw/run app::multi ne p/) },
    { _caller => 'app::multi::new::project' },
    'abbrev ne p'
);

# sorting

$OptArgs::SORT = 0;

like exception { dispatch(qw/run app::multi new -h/) },
  qr/help.* project .* issue /s,
  'unordered';

$OptArgs::SORT = 1;

like exception { dispatch(qw/run app::multi new -h/) },
  qr/help.* issue .* project /s,
  'sorted';

done_testing();
