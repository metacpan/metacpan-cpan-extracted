use Test::More;

use_ok 'Mock::Populate';

# TODO Test contents for looks_like_a_number, etc, instead.
my $d = Mock::Populate::date_ranger();
is @$d, 10, 'date_ranger';
$d = Mock::Populate::date_modifier(3, @$d);
is @$d, 10, 'date_modifier';
my $t = Mock::Populate::time_ranger();
is @$t, 10, 'time_ranger';
my $x = Mock::Populate::number_ranger();
is @$x, 10, 'number_ranger';
$x = Mock::Populate::name_ranger();
is @$x, 10, 'name_ranger';
$x = Mock::Populate::email_modifier(@$x);
is @$x, 10, 'email_ranger';
$x = Mock::Populate::distributor();
is @$x, 10, 'distributor';
$x = Mock::Populate::shuffler();
is @$x, 10, 'shuffler';
$x = Mock::Populate::string_ranger();
is @$x, 10, 'string_ranger';
$x = Mock::Populate::image_ranger();
is @$x, 10, 'image_ranger';
$x = Mock::Populate::collate($d, $t);
is @$x, 10, 'collate';

done_testing();
