use 5.022;
use warnings;
use strict;

use Test::More;

{ use Time::HiRes 'time'; my $start; BEGIN { $start = time(); } diag 'startup: ', time() - $start; }

use Multi::Dispatch;

#package Iterator {
#    multimethod new :common (%args) {
#        bless {from=>0, step=>1, %args, next=>$args{from}}, $class;
#    }
#
#    multimethod next () {
#        return if $self->{next} > $self->{to};
#        (my $curr, $self->{next}) = ($self->{next}, $self->{next} + $self->{step});
#        return $curr;
#    }
#
#    multimethod seq :common ($to) {
#        $class->new(from=>0, to=>$to-1);
#    }
#
#    multimethod seq :common ($from, $to :where({$from <= $to})) {
#        $class->new(from=>$from, to=>$to);
#    }
#
#    multimethod seq :common ($from, $to :where({$from > $to}) ) {
#        $class->new(from=>$from, to=>$to, step=>-1);
#    }
#
#    multimethod seq :common ($from, $then, $to) {
#        $class->new(from=>$from, to=>$to, step=>$then-$from);
#    }
#}
#
#my $iter;
#
#my $counter = 0;
#$iter = Iterator->seq(10);
#while (defined(my $next = $iter->next)) {
#    ok $next == $counter++ => 'Iterator->seq(10)';
#}
#
#$counter = 1;
#$iter = Iterator->seq(1 => 10);
#while (defined(my $next = $iter->next)) {
#    ok $next == $counter++ => 'Iterator->seq(1 => 10)';
#}
#
#$counter = 10;
#$iter = Iterator->seq(10 => 1);
#while (defined(my $next = $iter->next)) {
#    ok $next == $counter-- => 'Iterator->seq(10 => 1)';
#}
#
#$counter = 1;
#$iter = Iterator->seq(1, 3 => 10);
#while (defined(my $next = $iter->next)) {
#    ok $next == $counter => 'Iterator->seq(1, 3 => 10)';
#    $counter += 2;
#}



package Demo {
    multimethod objmeth ($arg)                   { "base objmeth 1" }
    multimethod objmeth ($arg1, $arg2)           { "base objmeth 2" }
    multimethod objmeth ($arg, @etc)             { "base objmeth N" }

    multimethod classmeth :common ($arg)          { "$class base classmeth 1" }
    multimethod classmeth :common ($arg1, $arg2)  { "$class base classmeth 2" }
}

package Demo::Der {
    use base 'Demo';

    multimethod objmeth ($arg)                   { "der objmeth 1" }
    multimethod objmeth ($arg1, $arg2, $arg3)    { "der objmeth 3" }

    multimethod classmeth :common ($arg1, $arg2)  { "$class der classmeth 2" }
}

my $baseobj = bless {id=>'B'}, 'Demo';
my $derobj  = bless {id=>'D'}, 'Demo::Der';

is eval { $baseobj->objmeth(); },  undef()          => '$baseobj->objmeth()';
is        $baseobj->objmeth(1..1), 'base objmeth 1' => '$baseobj->objmeth(1..1)';
is        $baseobj->objmeth(1..2), 'base objmeth 2' => '$baseobj->objmeth(1..2)';
is        $baseobj->objmeth(1..3), 'base objmeth N' => '$baseobj->objmeth(1..3)';
is        $baseobj->objmeth(1..9), 'base objmeth N' => '$baseobj->objmeth(1..9)';

is eval { $derobj->objmeth(); },  undef()          => '$derobj->objmeth()';
is        $derobj->objmeth(1..1), 'der objmeth 1'  => '$derobj->objmeth(1..1)';
is        $derobj->objmeth(1..2), 'base objmeth 2' => '$derobj->objmeth(1..2)';
is        $derobj->objmeth(1..3), 'der objmeth 3'  => '$derobj->objmeth(1..3)';
is        $derobj->objmeth(1..9), 'base objmeth N' => '$derobj->objmeth(1..9)';


is eval { Demo->classmeth(); },      undef()            => 'Demo->classmeth()';
is(       Demo->classmeth(1..1),     'Demo base classmeth 1' => 'Demo->classmeth(1..1)' );
is(       Demo->classmeth(1..2),     'Demo base classmeth 2' => 'Demo->classmeth(1..2)' );
is eval { Demo->classmeth(1..3); },  undef()            => 'Demo->classmeth(1..3)';

is eval { Demo::Der->classmeth(); },      undef()            => 'Demo::Der->classmeth()';
is(       Demo::Der->classmeth(1..1),     'Demo::Der base classmeth 1' => 'Demo::Der->classmeth(1..1)' );
is(       Demo::Der->classmeth(1..2),     'Demo::Der der classmeth 2'  => 'Demo::Der->classmeth(1..2)' );
is eval { Demo::Der->classmeth(1..3); },  undef()            => 'Demo::Der->classmeth(1..3)';


is eval { $baseobj->classmeth(); },      undef()            => '$baseobj->classmeth()';
is(       $baseobj->classmeth(1..1),     'Demo base classmeth 1' => '$baseobj->classmeth(1..1)' );
is(       $baseobj->classmeth(1..2),     'Demo base classmeth 2' => '$baseobj->classmeth(1..2)' );
is eval { $baseobj->classmeth(1..3); },  undef()            => '$baseobj->classmeth(1..3)';

is eval { $derobj->classmeth(); },      undef()            => '$derobj->classmeth()';
is(       $derobj->classmeth(1..1),     'Demo::Der base classmeth 1' => '$derobj->classmeth(1..1)' );
is(       $derobj->classmeth(1..2),     'Demo::Der der classmeth 2'  => '$derobj->classmeth(1..2)' );
is eval { $derobj->classmeth(1..3); },  undef()            => '$derobj->classmeth(1..3)';

done_testing();
