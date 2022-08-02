use strict;
use warnings;
use Test::More;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

delete $ENV{SQL_ABSTRACT_MORE_EXTENDS};

{ my $use = eval "use SQL::Abstract::More -extends => 'SQL::Abstract'; 1";
  ok $use, "use SQLAM -extends => SQLA";
}


{ my $use = eval "use SQL::Abstract::More -extends => 'SQL::Abstract'; 1";
  ok $use, "use SQLAM -extends => SQLA -- 2nd invocation" ;
}

{ my $use = eval "use SQL::Abstract::More; 1";
  (my $err = $@) =~ s/ at .*//;
  ok !$use, "use SQLAM -- no -extends : denied : $err";
}

{ my $use = eval "use SQL::Abstract::More -extends => 'Classic'; 1";
  (my $err = $@) =~ s/ at .*//;
  ok !$use, "use SQLAM -extends => 'Classic': $err";
}

done_testing;


