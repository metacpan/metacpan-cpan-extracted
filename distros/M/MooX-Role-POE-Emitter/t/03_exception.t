use Test::More tests => 8;
use strict; use warnings FATAL => 'all';

{
  package
    MyEmitter;
  use strict; use warnings FATAL => 'all';
  use Moo;
  with 'MooX::Role::POE::Emitter';
}

eval {; MyEmitter->new( object_states => '' ) };
ok $@, 'empty string object_states dies';

my $emitter = MyEmitter->new;
for (qw/ _start _stop _default subscribe unsubscribe /) {
  eval {; $emitter->set_object_states([ $emitter => [ $_ ] ]) };
  ok $@, "disallowed state $_ dies";
}

eval {; $emitter->timer };
ok $@, 'empty timer() call dies';
eval {; $emitter->timer_del };
ok $@, 'empty timer_del() call dies';
