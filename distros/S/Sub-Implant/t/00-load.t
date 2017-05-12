#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Sub::Implant' ) || print "Bail out!\n";
}

diag( "Testing Sub::Implant $Sub::Implant::VERSION, Perl $], $^X" );

{
    package T1;
    use Sub::Implant;
    main::ok(defined &implant, 'default export');
}

{
    package T2;
    use Sub::Implant qw(implant);
    main::ok(defined &implant, 'explicit export');
}


{
    package T3;
    use Sub::Implant implant => {as => 'alleskleber'};
    main::ok(defined &alleskleber, 'renaming export');
}
