use Moose;
use DateTime;
use Test::More;

with 'OpusVL::AppKit::RolesFor::Controller::GUI';


sub create_action
{
}

my $obj = __PACKAGE__->new;

my $date = DateTime->new(year => 2010, month => 6, day => 3);
is $obj->date_long($date), 'Thursday, 03 June 2010';
is $obj->date_short($date), '03-Jun-2010';
is $obj->time_long($date), '00:00:00';
is $obj->time_short($date), '00:00';

done_testing;
