use v5.24;
use warnings;
use Test::More;

use MojoX::Authentication::Model;

# a provider that never knows any user
package NoUsers {
   sub new { bless {}, shift }
   sub name { 'none' }
   sub load_user { return }
   sub tamed_user_record { $_[1] }
}

# a provider that knows exactly one user
package OneUser {
   sub new { my ($class, $name, $user) = @_; bless { name => $name, user => $user }, $class }
   sub name { $_[0]{name} }
   sub load_user { my ($self, $c, $uid) = @_; return $uid eq $self->{user} ? { uid => $uid } : undef }
   sub handles_username { my ($self, $c, $name) = @_; return $name eq $self->{user} ? 1 : undef }
   sub tamed_user_record { $_[1] }
}

# a provider whose records carry secret material, and keep it in storage
package Stored {
   sub new { bless { db => { alice => { pin => 1234, groups => ['staff'] } } }, shift }
   sub name { 'stored' }
   sub load_user { my ($self, $c, $uid) = @_; return $self->{db}{$uid} }
   sub tamed_user_record { my ($self, $user) = @_; my %u = %$user; delete $u{pin}; return \%u }
}

# a provider that can load users but says nothing about what is safe to
# expose
package Untamed { sub new { bless {}, shift } sub name { 'untamed' } sub load_user { return {} } }

my $model = MojoX::Authentication::Model->new(providers => [NoUsers->new]);

# Mojolicious::Plugin::Authentication treats any true value as a loaded
# user, so an unknown uid must give back nothing
is $model->load_user(undef, 'none/nobody'), undef,
   'load_user returns undef when the provider does not know the uid';

# the session can name a provider that is no longer configured (renamed,
# removed): that is "nobody logged in", not an error on every page
my $loaded = eval { $model->load_user(undef, 'gone/nobody') };
is $@, '', 'load_user with an unknown provider does not die';
is $loaded, undef, 'load_user with an unknown provider returns undef';

# provider_name_for asks providers in order, until one handles the name
$model = MojoX::Authentication::Model->new(providers => [
   { class => 'MojoX::Authentication::Model::Hash',
     args  => { db => { foo => { secret => 'x' } } } },
   OneUser->new(other => 'bob'),
]);
is $model->provider_name_for(undef, 'foo'), 'hashy',
   'provider_name_for: user of the first provider';
is $model->provider_name_for(undef, 'bob'), 'other',
   'provider_name_for: a provider that does not handle the name is skipped';

# current_user data is what tamed_user_record leaves, as a copy: changing
# it (e.g. in a template) must not change the provider's storage
my $stored = Stored->new;
$model = MojoX::Authentication::Model->new(providers => [ $stored ]);
my $alice = $model->load_user(undef, 'stored/alice');
is_deeply $alice && $alice->{data}, { groups => ['staff'] },
   'load_user: data is the record from tamed_user_record';
push $alice->{data}{groups}->@*, 'admins';
$alice->{data}{pin} = 0;
is_deeply $stored->{db}{alice}, { pin => 1234, groups => ['staff'] },
   'load_user: changing the data leaves the provider storage alone';

# a provider with load_user must have tamed_user_record, at construction
eval { MojoX::Authentication::Model->new(providers => [ Untamed->new ]) };
like "$@", qr{tamed_user_record}, 'provider without tamed_user_record refused';

done_testing();
