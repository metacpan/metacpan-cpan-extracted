use Test::More;
use File::Type;

my $ft = File::Type->new();

use_ok 'Mock::Populate';

my $d = Mock::Populate::date_ranger();
is @$d, 10, 'date_ranger';
like $d->[0], qr/^\d{4}-\d{2}-\d{2}$/, 'date_ranger';
$d = Mock::Populate::date_modifier(3, @$d);
is @$d, 10, 'date_modifier';
like $d->[0], qr/^\d{4}-\d{2}-\d{2}$/, 'date_modifier';
my $t = Mock::Populate::time_ranger();
is @$t, 10, 'time_ranger';
like $t->[0], qr/^\d{2}:\d{2}:\d{2}$/, 'time_ranger';
my $x = Mock::Populate::number_ranger();
is @$x, 10, 'number_ranger';
like $x->[0], qr/^\d\.\d+$/, 'number_ranger';
$x = Mock::Populate::name_ranger();
is @$x, 10, 'name_ranger';
like $x->[0], qr/^\w+\s\w+$/, 'name_ranger';
$x = Mock::Populate::email_modifier(@$x);
is @$x, 10, 'email_ranger';
like $x->[0], qr/^\w+\.\w+\@example\.\w+$/, 'email_ranger';
$x = Mock::Populate::distributor();
is @$x, 10, 'distributor';
like $x->[0], qr/^-?\d+\.\d+$/, 'distributor';
$x = Mock::Populate::shuffler();
is @$x, 10, 'shuffler';
like $x->[0], qr/^\w$/, 'shuffler';
$x = Mock::Populate::string_ranger();
is @$x, 10, 'string_ranger';
like $x->[0], qr/^\w+$/, 'string_ranger';
$x = Mock::Populate::image_ranger();
is @$x, 10, 'image_ranger';
is $ft->checktype_contents($x->[0]), 'image/x-png', 'image_ranger';
$x = Mock::Populate::collate($d, $t);
is @$x, 10, 'collate';
like $x->[0][0], qr/^\d{4}-\d{2}-\d{2}$/, 'collate';
like $x->[0][1], qr/^\d{2}:\d{2}:\d{2}$/, 'collate';

done_testing();
