#!perl -T

use Test::More tests => 22;

use_ok('Number::Bytes::Human');

# testing the OO way

my $human = Number::Bytes::Human->new(bs => 1000, si => 1);
isa_ok($human, 'Number::Bytes::Human');

is($human->format(1E7), '10MB');
is($human->parse('10MB'), 1E7);

is($human->set_options(zero => '-'), $human);
is($human->format(0), '-');
is($human->parse('-'), 0);

# Add tests from bug report
#   https://rt.cpan.org/Public/Bug/Display.html?id=118814
$human = Number::Bytes::Human->new( bs => 1024, precision => 2 );

is($human->parse('.5G'), 536870912);
is($human->parse('0.5G'), 536870912);
is($human->parse('0.50G'), 536870912);
is($human->parse('0.500G'), 536870912);
is($human->parse('0.5000G'), 536870912);

is($human->parse('1G'), 1073741824);
is($human->parse('1.5G'), 1610612736);
is($human->parse('1.50G'), 1610612736);
is($human->parse('1.500G'), 1610612736);
is($human->parse('1.5000G'), 1610612736);

is($human->parse('1T'), 1099511627776);
is($human->parse('1.5T'), 1649267441664);
is($human->parse('1.50T'), 1649267441664);
is($human->parse('1.500T'), 1649267441664);
is($human->parse('1.5000T'), 1649267441664);
