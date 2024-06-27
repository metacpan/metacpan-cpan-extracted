use 5.022;

use warnings;
use strict;

use Test::More;

use Multi::Dispatch;
no warnings 'Multi::Dispatch::noncontiguous';

{ package BaseClass;
  multimethod check :common (@args) { 'slurpy BaseClass::check' }
}

{ package DerClass; use base 'BaseClass'; }


sub expect {
    my ($expectation) = @_;
    is( DerClass->check(['arg']), $expectation, $expectation );
}


BEGIN {
    expect 'slurpy BaseClass::check';
}


{ package BaseClass;
  multimethod check :common ($arg) { 'exact BaseClass::check' }
}

BEGIN {
    expect 'exact BaseClass::check';
}


{ package BaseClass;
  multimethod check :common ([$arg]) { 'destructuring BaseClass::check' }
}

BEGIN {
    expect 'destructuring BaseClass::check';
}


{ package BaseClass;
  multimethod check :common (ARRAY $arg :where({@$arg > 0}) )
      { 'constrained BaseClass::check' }
}

BEGIN {
    expect 'constrained BaseClass::check';
}


{ package BaseClass;
  multimethod check :common ([$arg] :where({$arg eq 'arg'}) )
      { 'constrained destructuring BaseClass::check' }
}

BEGIN {
    expect 'constrained destructuring BaseClass::check';
}



{ package DerClass;
  multimethod check :common ($arg)
      { 'constrained exact DerClass::check' }
}

BEGIN {
    expect 'constrained destructuring BaseClass::check';
}


{ package DerClass;
  multimethod check :common ([$arg] :where({$arg eq 'arg'}) )
      { 'constrained destructuring DerClass::check' }
}

BEGIN {
    expect 'constrained destructuring DerClass::check';
}



{ package BaseClass;
  multimethod check :common (['arg'] :where({1}) )
      { 'constrained destructuring literal BaseClass::check' }
}

BEGIN {
    expect 'constrained destructuring literal BaseClass::check';
}

done_testing();

