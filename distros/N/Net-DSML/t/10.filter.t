use Test::More tests => 72;

BEGIN {
  require "t/common.pl";
}

use Net::DSML::Filter;

my $ty = "final";
my $at = "cn";
my $vl = "Bunny";

diag( " " );
diag( "Testing Net::DSML::Filter $Net::DSML::Filter::VERSION" );
my @tests = do { local $/=""; <DATA> };

my $filter = Net::DSML::Filter->new();
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( $filter->subString( { type =>"initial", attribute => "cn", value => "jay" } ));
ok( $filter->present( { attribute => "cn" } ));
ok( $filter->equalityMatch( { attribute => "cn", value => "me" } ));
ok( $filter->greaterOrEqual( { attribute => "cn", value => "jay" } ));
ok( $filter->lessOrEqual( { attribute => "cn", value => "jay" } ));
ok( $filter->approxMatch( { attribute => "cn", value => "jay" } ));
ok( $filter->extensibleMatch( { value => "jay" } ));

$filter = Net::DSML::Filter->new();
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[0],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->subString( { type => $ty, attribute => $at, value => $vl } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[0],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->subString( { type => \$ty, attribute => \$at, value => \$vl } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[0],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->subString( { type =>"initial", attribute => "cn", value => "Bugs" } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[1],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->subString( { type =>"any", attribute => "cn", value => "ugs" } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[2],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->present( { attribute => "cn" } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[3],$filter->getFilter()));


$filter = Net::DSML::Filter->new();
$filter->present( { attribute => $at } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[3],$filter->getFilter()));


$filter = Net::DSML::Filter->new();
$filter->present( { attribute => \$at } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[3],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->equalityMatch( { attribute => "cn", value => "jay bird" } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[4],$filter->getFilter()));

$vl = "jay bird";

$filter = Net::DSML::Filter->new();
$filter->greaterOrEqual( { attribute => "cn", value => "jay bird" } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[5],$filter->getFilter()));


$filter = Net::DSML::Filter->new();
$filter->greaterOrEqual( { attribute => $at, value => $vl } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[5],$filter->getFilter()));


$filter = Net::DSML::Filter->new();
$filter->greaterOrEqual( { attribute => \$at, value => \$vl } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[5],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->lessOrEqual( { attribute => "cn", value => "jay bird" } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[6],$filter->getFilter()));


$filter = Net::DSML::Filter->new();
$filter->lessOrEqual( { attribute => $at, value => $vl } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[6],$filter->getFilter()));


$filter = Net::DSML::Filter->new();
$filter->lessOrEqual( { attribute => \$at, value => \$vl } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[6],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->approxMatch( { attribute => "cn", value => "jay bird" } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[7],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->approxMatch( { attribute => $at, value => $vl } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[7],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->approxMatch( { attribute => \$at, value => \$vl } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[7],$filter->getFilter()));

$filter = Net::DSML::Filter->new();
$filter->extensibleMatch( { name => "uid=bugs,ou=people,dc=company,dc=com", value => "jay bird", dnAttributes => "true" } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[8],$filter->getFilter()));

$at = "uid=bugs,ou=people,dc=company,dc=com";
$ty = "true";
$filter = Net::DSML::Filter->new();
$filter->extensibleMatch( { name => $at, value => $vl, dnAttributes => $ty } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[8],$filter->getFilter()));


$filter = Net::DSML::Filter->new();
$filter->extensibleMatch( { name => \$at, value => \$vl, dnAttributes => \$ty } );
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( compare_test($tests[8],$filter->getFilter()));

__DATA__
<filter><substrings name="cn"><final>Bunny</final></substrings></filter>

<filter><substrings name="cn"><initial>Bugs</initial></substrings></filter>

<filter><substrings name="cn"><any>ugs</any></substrings></filter>

<filter><present name="cn"/></filter>

<filter><equalityMatch name="cn"><value>jay bird</value></equalityMatch></filter>

<filter><greaterOrEqual name="cn"><value>jay bird</value></greaterOrEqual></filter>

<filter><lessOrEqual name="cn"><value>jay bird</value></lessOrEqual></filter>

<filter><approxMatch name="cn"><value>jay bird</value></approxMatch></filter>

<filter><extensibleMatch name="uid=bugs,ou=people,dc=company,dc=com" dnAttributes="true"><value>jay bird</value></extensibleMatch></filter>

