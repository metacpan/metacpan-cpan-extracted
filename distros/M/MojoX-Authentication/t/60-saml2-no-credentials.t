use v5.24;
use warnings;
use Test::More;
use experimental qw< signatures >;
use FindBin qw< $Bin >;

eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';

use MojoX::Authentication::Model;

my $saml2 = {
   class => 'MojoX::Authentication::Model::SAML2',
   args  => {
      idp => "$Bin/../eg/idp.xml",
      sp_configuration => {
         identifier => 'https://srv.example.com/sp',
         key        => "$Bin/../eg/server.key",
      },
   },
};
# a sub: Model::Hash writes into the db it is given (see t/80)
sub hash_provider {
   return {
      class => 'MojoX::Authentication::Model::Hash',
      args  => { db => { foo => { secret => 'right' } },
                 secrets_are_cleartext => 1 },
   };
}

# The first provider that claims a username owns it. SAML2 claims every
# username by default and never checks credentials: when it comes first
# it shadows the local provider, when it comes last it gets the names
# that nobody before claims.
# Whatever the reason, a refused login is always the same 401.
sub refused_ok ($model, $label, $name, $secret) {
   my $uid = eval { $model->validate_user(undef, $name, $secret, {}) };
   my $error = $@;    # copy: evals below reset $@
   is $uid, undef, "$label: no uid";
   like "$error", qr{Unauthorized}, "$label: refused like a wrong password";
}

{
   my $model = MojoX::Authentication::Model->new(
      providers => [ hash_provider(), $saml2 ]);
   refused_ok($model, 'SAML2 last, unknown user', nobody => 'whatever');
   refused_ok($model, 'SAML2 last, wrong password', foo => 'wrong');
   is eval { $model->validate_user(undef, foo => 'right', {}) }, 'hashy/foo',
      'SAML2 last: valid local credentials work';
}

{
   my $model = MojoX::Authentication::Model->new(
      providers => [ $saml2, hash_provider() ]);
   refused_ok($model, 'SAML2 first, unknown user', nobody => 'whatever');
   refused_ok($model, 'SAML2 first, wrong password', foo => 'wrong');
   refused_ok($model, 'SAML2 first, local credentials shadowed',
      foo => 'right');
}

done_testing();
