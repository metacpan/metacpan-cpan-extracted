use v5.24;
use warnings;
use Test::More;
use experimental qw< signatures >;
use FindBin qw< $Bin >;

use MojoX::Authentication::Model;

# Every refused login must cost the same as checking a real password, so
# that response times do not tell known usernames from unknown ones: one
# password check per attempt, whatever the outcome and however many local
# providers there are (never more, or unknown names would be dearer).
# The counter mimics Crypt::Passphrase, which returns at once, hashing
# nothing, for a hash no validator accepts (e.g. a missing or empty one):
# only checks over a hash it accepts are counted.

package CountingPassphrase {
   my $checks = 0;
   sub new { bless {}, shift }
   sub hash_password ($self, $password) { return "fake:$password" }
   sub verify_password ($self, $password, $hash) {
      return 0 unless defined($hash) && $hash =~ m{\Afake:};
      $checks++;
      return $hash eq "fake:$password";
   }
   sub checks_during ($class, $code) {
      $checks = 0;
      $code->();
      return $checks;
   }
}

sub local_provider ($name, $db) {
   return {
      class => 'MojoX::Authentication::Model::Hash',
      args  => {
         name => $name,
         db   => $db,
         secrets_are_cleartext => 1,
         crypt_passphrase => CountingPassphrase->new,
      },
   };
}

sub checks_for ($model, $name, $secret) {
   my $uid;
   my $checks = CountingPassphrase->checks_during(sub {
      $uid = eval { $model->validate_user(undef, $name, $secret, {}) };
   });
   return ($checks, $uid);
}

my @locals = (
   # nopass and empty: e.g. accounts logging in through SAML2 only, or
   # disabled ones; refusing them must cost like an unknown user
   local_provider(hashy => {
      foo    => { secret => 'right' },
      nopass => {},
      empty  => { secret => q{} },
   }),
   local_provider(other => { bob => { secret => 'pw' } }),
);
my $model = MojoX::Authentication::Model->new(providers => \@locals);

for my $case (
   [ 'right password'                    => foo    => 'right', 'hashy/foo' ],
   [ 'wrong password'                    => foo    => 'wrong', undef ],
   [ 'right password, second provider'   => bob    => 'pw',    'other/bob' ],
   [ 'wrong password, second provider'   => bob    => 'nope',  undef ],
   [ 'unknown user, two local providers' => nobody => 'x',     undef ],
   [ 'known user without a secret'       => nopass => 'x',     undef ],
   [ 'known user with an empty secret'    => empty  => 'x',     undef ],
   [ 'empty secret, empty password'      => empty  => q{},      undef ],
) {
   my ($label, $name, $secret, $expected) = $case->@*;
   my ($checks, $uid) = checks_for($model, $name, $secret);
   is $uid, $expected, "$label: outcome";
   is $checks, 1, "$label: exactly one password check";
}

SKIP: {
   skip 'Net::SAML2 0.86 not available', 4
      unless eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 };

   # a default SAML2 first owns every name and takes no passwords: the
   # refusal still costs one check, run by a local provider
   my $saml2 = {
      class => 'MojoX::Authentication::Model::SAML2',
      args  => {
         idp => "$Bin/data/test-idp-metadata.xml",
         sp_configuration => {
            identifier => 'https://srv.example.com/sp',
            key        => "$Bin/../eg/server.key",
         },
      },
   };
   my $shadowed = MojoX::Authentication::Model->new(
      providers => [ $saml2, local_provider(hashy => { foo => { secret => 'right' } }) ]);
   for my $name (qw< foo nobody >) {
      my ($checks, $uid) = checks_for($shadowed, $name, 'right');
      is $uid, undef, "SAML2 first, '$name': refused";
      is $checks, 1, "SAML2 first, '$name': exactly one password check";
   }
}

done_testing();
