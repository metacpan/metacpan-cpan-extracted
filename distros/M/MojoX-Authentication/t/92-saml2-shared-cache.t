use v5.24;
use warnings;
use Test::More;
use experimental qw< signatures >;
use FindBin qw< $Bin >;
use File::Temp qw< tempdir >;
use lib "$Bin/lib";

eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';
require TestSAML2;
require MojoX::Authentication::Model;
require MojoX::Authentication::Model::SAML2::Hash;

# Two SAML2 providers (two IdPs) can share one cache, e.g. the same wmdb
# and so the same logged_in table. The same NameID at both IdPs is two
# different users: neither may read, overwrite or wipe the other.

my %cache_for = (
   Hash => sub { MojoX::Authentication::Model::SAML2::Hash->new },
);
if (eval { require MojoX::MojoDbWrap; require Mojo::SQLite; 1 }) {
   require MojoX::Authentication::Model::SAML2::Db;
   $cache_for{Db} = sub {
      my $path = tempdir(CLEANUP => 1) . '/cache.sqlite';
      my $wmdb = MojoX::MojoDbWrap->new(db_url => "sqlite:$path");
      $wmdb->db->query('CREATE TABLE logged_in (k TEXT, expire INTEGER, data TEXT)');
      return MojoX::Authentication::Model::SAML2::Db->new(wmdb => $wmdb);
   };
}

# How the consumer hands the providers to the Model: as objects, or as
# { name, instance } pairs, whose name Model.pod says overrides the
# instance's own. Sessions carry the Model's name: when the instance was
# built with another one (here the default 'saml2', the same for both),
# the Model must either refuse the pair or still keep the users apart.
my %provider_for = (
   'objects' => sub ($name, $cache) {
      return TestSAML2->new(name => $name, cache => $cache);
   },
   'instance, same name' => sub ($name, $cache) {
      return +{
         name     => $name,
         instance => TestSAML2->new(name => $name, cache => $cache),
      };
   },
   'instance, default name' => sub ($name, $cache) {
      return +{ name => $name, instance => TestSAML2->new(cache => $cache) };
   },
);
my %may_refuse = ('instance, default name' => 1);

package FakeController { sub new { bless {}, shift } sub logout { 1 } }

for my $type (sort keys %cache_for) {
   for my $form (sort keys %provider_for) {
      my $label = "$type, $form";
      my $cache = $cache_for{$type}->();
      my @providers = map { $provider_for{$form}->($_, $cache) } qw< corp other >;
      my $model = eval {
         MojoX::Authentication::Model->new(providers => \@providers);
      };
      if (! defined($model)) {
         my $error = $@;
         if ($may_refuse{$form}) {
            is eval { $error->code }, 400, "$label: mismatched names refused";
         }
         else {
            fail "$label: the Model accepts the providers";
            diag $error;
         }
         next;
      }

      my ($corp, $other) = map { $model->provider_named($_) } qw< corp other >;
      my $nameid = 'alice@example.com';
      my $groups = sub ($name) {
         my $user = $model->load_user(undef, "$name/$nameid") // return 'nobody';
         return $user->{data}{groups};
      };

      # attacker first at the other IdP, then the real alice at corp
      $other->next_user({ key => $nameid, groups => 'attacker' });
      $other->parse_assertion('id', 'response');
      $corp->next_user({ key => $nameid, groups => 'admins' });
      $corp->parse_assertion('id', 'response');

      is $groups->('corp'),  'admins',   "$label: corp user keeps its own data";
      is $groups->('other'), 'attacker', "$label: other user does not get corp's data";

      $other->logout(FakeController->new, { provider => 'other', uid => $nameid });
      is $groups->('other'), 'nobody', "$label: logout wipes the other user";
      is $groups->('corp'),  'admins', "$label: logout leaves the corp user alone";
   }
}

done_testing();
