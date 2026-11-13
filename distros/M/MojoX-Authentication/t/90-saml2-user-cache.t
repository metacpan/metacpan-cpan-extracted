use v5.24;
use warnings;
use Test::More;
use FindBin qw< $Bin >;

eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';
require MojoX::Authentication::Model::SAML2;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# a non-default user_key must be used consistently for caching
my $saml2 = MojoX::Authentication::Model::SAML2->new(
   idp => "$Bin/../eg/idp.xml",
   sp_configuration => {
      identifier => 'https://srv.example.com/sp',
      key        => "$Bin/../eg/server.key",
   },
   user_key => 'email',
);

for my $email (qw< a@example.com b@example.com >) {
   $saml2->_cache_user({ email => $email, fullname => "User $email" });
}
is $saml2->load_user(undef, 'a@example.com')->{fullname}, 'User a@example.com',
   'cached user found by its user_key value';
is $saml2->load_user(undef, 'b@example.com')->{fullname}, 'User b@example.com',
   'different users get different cache slots';

# logout goes through ctr_logout, which passes the current_user wrapper
# as built by MojoX::Authentication::Model::load_user
package FakeController { sub new { bless {}, shift } sub logout { 1 } }
my $wrapper = {
   provider => $saml2->name,
   uid      => 'a@example.com',
   data     => $saml2->load_user(undef, 'a@example.com'),
};
$saml2->logout(FakeController->new, $wrapper);
is $saml2->load_user(undef, 'a@example.com'), undef,
   'logout removes the user from the cache';
ok defined($saml2->load_user(undef, 'b@example.com')),
   'logout leaves other users alone';

is_deeply \@warnings, [], 'no warnings';

done_testing();
