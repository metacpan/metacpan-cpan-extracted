use strict;
use warnings;
use Config;
use Test::More;

BEGIN {
  for (qw(Test::LeakTrace Moose)) {
    eval "use $_";
    if ($@) {
	plan 'skip_all' => "$_ missing";
	exit(0);
    }
  }
}

use Set::Object;

{
    package Foo;
    use Moose;
    1;
}

{
    no strict;
    note join ' ', map {$Config{$_}} qw(osname archname);
    note 'perl version ', $];
    note $_,'-',${"${_}::VERSION"} for qw{Moose Set::Object Test::LeakTrace};
}

my $set;
{
    $set = Set::Object->new;
    no_leaks_ok {
        {
            my $obj = Foo->new;
            $set->insert($obj);
            $set->remove($obj);
        }
    } 'Testing Set::Object for leaking';
}

{
    $set = Set::Object::Weak->new;
    no_leaks_ok {
        {
            my $obj = Foo->new;
            $set->insert($obj);
            $set->remove($obj);
        }
    } 'Testing Set::Object::Weak for leaking';
}

done_testing;
