use strict;
use warnings;

use RT::Extension::MandatoryOnTransition::Test tests => undef;

use_ok('RT::Extension::MandatoryOnTransition');

diag "Test RequiredFields without a ticket";
{
    my ($core, $cf) = RT::Extension::MandatoryOnTransition->RequiredFields(
			   Queue => 'General',
                           From => 'open',
                           To   => 'resolved',
                       );
    is( $core->[0], 'TimeWorked', 'Got TimeWorked for required core');

    my $must_values;
    ($core, $cf, my $roles, $must_values, my $role_groups ) = RT::Extension::MandatoryOnTransition->RequiredFields(
                           From => "''",
                           To   => 'resolved',
                           Queue => 'General',
                       );

    is( $core->[0], 'TimeWorked', 'Got TimeWorked for required core');
    is( $cf->[0], 'Test Field', 'Got Test Field for required custom field');
    is_deeply( $roles, [], 'Empty roles');

    is( (ref $must_values->{'Test Field3'}), 'HASH', 'Got a hash for Test Field3 must values');
    is( (ref $must_values->{'Test Field3'}{'must_be'}), 'ARRAY', 'Got an array for must be values');
    is( (ref $must_values->{'Test Field4'}{'must_not_be'}), 'ARRAY', 'Got an array for must not be values');
    is( $must_values->{'Test Field3'}{'must_be'}->[0], 'normal', "First must be value is 'normal'");
    is( $must_values->{'Test Field4'}{'must_not_be'}->[0], 'down', "First must not be value is 'down'");

    is_deeply( $role_groups, {}, "Empty role group hash");
}

diag "Test RequiredFields with a ticket";
{
    my $t = RT::Test->create_ticket(
         Queue => 'General',
         Subject => 'Test Mandatory On Resolve',
         Content => 'Testing',
         );

    ok( $t->id, 'Created test ticket: ' . $t->id);

    my ($core, $cf, $roles, $must_values, $role_groups) = RT::Extension::MandatoryOnTransition->RequiredFields(
                           Ticket => $t,
                           To   => 'resolved',
                       );

    is( $core->[0], 'TimeWorked', 'Got TimeWorked for required core');
    is( $cf->[0], 'Test Field', 'Got Test Field for required custom field');
    is_deeply( $roles, [], 'Empty roles');

    is( (ref $must_values->{'Test Field3'}), 'HASH', 'Got a hash for Test Field3 must values');
    is( (ref $must_values->{'Test Field3'}{'must_be'}), 'ARRAY', 'Got an array for must be values');
    is( (ref $must_values->{'Test Field4'}{'must_not_be'}), 'ARRAY', 'Got an array for must not be values');
    is( $must_values->{'Test Field3'}{'must_be'}->[0], 'normal', "First must be value is 'normal'");
    is( $must_values->{'Test Field4'}{'must_not_be'}->[0], 'down', "First must not be value is 'down'");
    is_deeply( $role_groups, {}, "Empty role group hash");
}

done_testing;
