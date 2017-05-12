use strict;
use warnings;
use lib 't/lib';
use OptArgs qw/dispatch/;
use Test::More;
use Test::Output;
use Test::Fatal;

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi/) },
    '<command> COMMAND
    <command> init
    <command> new THREAD
        <command> new issue
        <command> new project
        <command> new task TARG
            <command> new task noopts
            <command> new task pretty
', 'App::optargs on app::multi'
);

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi -i 2/) },
    '<command> COMMAND
  <command> init
  <command> new THREAD
    <command> new issue
    <command> new project
    <command> new task TARG
      <command> new task noopts
      <command> new task pretty
', 'App::optargs on app::multi'
);

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi -i 2 -s x/) },
    '<command> COMMAND
xx<command> init
xx<command> new THREAD
xxxx<command> new issue
xxxx<command> new project
xxxx<command> new task TARG
xxxxxx<command> new task noopts
xxxxxx<command> new task pretty
'
    , 'App::optargs on app::multi'
);

stdout_is(
    sub { dispatch(qw/run App::optargs app::multi -i 2 -s x yy/) },
    'yy COMMAND
xxyy init
xxyy new THREAD
xxxxyy new issue
xxxxyy new project
xxxxyy new task TARG
xxxxxxyy new task noopts
xxxxxxyy new task pretty
', 'App::optargs on app::multi'
);

done_testing();
