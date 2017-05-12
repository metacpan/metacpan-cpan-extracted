#!perl -w
use strict;
use Test::More;

my $module = 'MozRepl::RemoteObject';

my $ok = eval {
    require AnyEvent;
    1;
};
my $err = $@;

my $repl;

$ok and $ok = eval {
    require MozRepl::RemoteObject;
    $repl = MozRepl::RemoteObject->install_bridge(
        repl_class => 'MozRepl::AnyEvent',
    );
    1;
};
if (! $ok) {
    $err ||= $@;
    plan skip_all => "Couldn't connect to Firefox: $err";
} else {
    plan tests => 5;
};

ok "We survived";

# Now test that we peacefully coexist with AnyEvent timers
my $anyevent_timer = 0; # we'll increment this one from an AnyEvent timer
my $counter = AnyEvent->timer(
    after => 0,
    interval => 1,
    cb => sub { diag "AnyEvent timer"; $anyevent_timer++ }
);

# Set up the Javascript timeout that'll trigger in 2 seconds
my $window = $repl->expr(<<'JS');
    window
JS
isa_ok $window, 'MozRepl::RemoteObject::Instance',
    "We got a handle on window";

# Weirdly enough, .setTimeout cannot be passed around as bare function
# Maybe just like object methods in Perl

my @events = ();
my $js_timer_id = $window->setTimeout(sub { 
    push @events, 'in_perl';
    diag "JS timer";
}, 2000);

is_deeply \@events,
    [],
    "Delayed events don't trigger immediately (with Perl callback)";

# Now "sleep" for three seconds:
my $done = 0;
my $t2 = AnyEvent->timer( after => 3, cb => sub { $done++ });

while (! $done) {
    $repl->poll;
    sleep 1;
};

is_deeply \@events,
    ['in_perl'],
    "Delayed triggers trigger eventually (with Perl callback)";
cmp_ok $anyevent_timer, '>=', 3, "At least three timers fired in the meantime ($anyevent_timer)";

