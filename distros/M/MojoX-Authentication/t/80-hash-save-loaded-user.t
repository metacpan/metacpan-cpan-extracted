use v5.24;
use warnings;
use Test::More;

use File::Temp ();
use MojoX::Authentication::Model::Hash;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# db given as a hash: keys are usernames
my $model = MojoX::Authentication::Model::Hash->new(
   db => { foo => { secret => 'old', fullname => 'Foo' } });
$model->_adjust_db;  # what create() does after new()

# round trip: what load_user gives back must be accepted by save_user
my $user = $model->load_user(undef, 'foo');
$user->{secret} = 'new';
eval { $model->save_user($user) };
is $@, '', 'save_user accepts a user as returned by load_user';

my $reloaded = $model->load_user(undef, 'foo');
is $reloaded && $reloaded->{secret}, 'new', 'saved changes are visible under the same username';
is_deeply \@warnings, [], 'no warnings';

# db given as an array: records are keyed by their username
my $from_array = MojoX::Authentication::Model::Hash->create({},
   db => [ { username => 'baz', secret => 'x' } ]);
is $from_array->load_user(undef, 'baz')->{secret}, 'x',
   'array input is keyed by username';

# db given as JSON, either inline or in a file
my $json = '[ { "username": "qux", "secret": "y" } ]';
my $from_json = eval { MojoX::Authentication::Model::Hash->create({}, db => $json) };
is $@, '', 'JSON string input accepted';
is $from_json && $from_json->load_user(undef, 'qux')->{secret}, 'y',
   'JSON string input is loaded';

my $file = File::Temp->new(SUFFIX => '.json');
print {$file} $json;
close $file;
my $from_file = eval { MojoX::Authentication::Model::Hash->create({}, db => $file->filename) };
is $@, '', 'JSON file input accepted';
is $from_file && $from_file->load_user(undef, 'qux')->{secret}, 'y',
   'JSON file input is loaded';

# invalid input is rejected loudly
for my $case (
   [ 'array record without username' => [ { secret => 'x' } ], qr{username} ],
   [ 'scalar reference'              => \'whatever',           qr{invalid input} ],
) {
   my ($label, $db, $error) = $case->@*;
   eval { MojoX::Authentication::Model::Hash->create({}, db => $db) };
   like $@, $error, "$label is rejected";
}

# the db passed in belongs to the caller and must be left alone
my %input = (bar => { secret => 'clear' });
MojoX::Authentication::Model::Hash->create({},
   db => \%input, secrets_are_cleartext => 1);
is_deeply \%input, { bar => { secret => 'clear' } },
   'create does not modify the db passed in';

my @input = ({ username => 'bar', secret => 'clear' });
MojoX::Authentication::Model::Hash->create({},
   db => \@input, secrets_are_cleartext => 1);
is_deeply \@input, [ { username => 'bar', secret => 'clear' } ],
   'create does not modify the array db passed in';

done_testing();
