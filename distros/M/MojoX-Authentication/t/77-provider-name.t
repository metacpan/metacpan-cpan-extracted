use v5.24;
use warnings;
use Test::More;
use experimental qw< signatures >;

use MojoX::Authentication::Model;
use MojoX::Authentication::Model::Hash;

# The Model decides each provider's name (the one sessions carry) and
# writes it into the provider, so that a provider scoping anything by
# its own name (e.g. SAML2 cache keys) uses the same one. A provider
# that cannot or will not take the name is a configuration error.

package RwName    { use Moo; has name => (is => 'rw') }
package RoName    { use Moo; has name => (is => 'ro', default => 'ro-own') }
package FixedName { sub new { bless {}, shift } sub name { 'fixed' } }
package NoName    { sub new { bless {}, shift } }

package main;

sub model (@providers) {
   return MojoX::Authentication::Model->new(providers => \@providers);
}

sub hash_provider (@args) {
   return MojoX::Authentication::Model::Hash->new(db => {}, @args);
}

{
   my $instance = hash_provider();    # own name: the default 'hashy'
   my $model = model({ name => 'local', instance => $instance });
   is $model->provider_named('local'), $instance, 'instance known by the given name';
   is $instance->name, 'local', 'the given name is written into the instance';
   is $model->provider_named('hashy'), undef, 'the old name is not known';
}

{
   my $instance = hash_provider(name => 'mine');
   my $model = model($instance);
   is $model->provider_named('mine'), $instance, 'an object keeps its own name';
   is $instance->name, 'mine', '... and the name is unchanged';
}

{
   my $instance = RwName->new;
   my $model = model($instance);
   is $model->provider_named('unnamed-0'), $instance, 'a provider without a name gets one';
   is $instance->name, 'unnamed-0', '... and it is written into the provider';
}

{
   my $instance = NoName->new;
   my $model = model({ name => 'bare', instance => $instance });
   is $model->provider_named('bare'), $instance, 'no name method: named by the Model only';
}

for my $case (
   [ 'read-only name'        => RoName->new,    q{'ro-own'} ],
   [ 'name ignoring its arg' => FixedName->new, q{'fixed'}  ],
) {
   my ($label, $instance, $old) = $case->@*;
   my $model = eval { model({ name => 'corp', instance => $instance }) };
   my $error = $@;
   ok !defined($model), "$label: refused";
   is eval { $error->code }, 400, "$label: 400";
   like eval { $error->message }, qr{from \Q$old\E to 'corp'}, "$label: message names both";
}

# one instance registered twice would answer to the last name only, so
# the first registration would scope its data under the wrong name
for my $case (
   [ 'twice as object' => sub ($x) { ($x, $x) } ],
   [ 'twice by name'   => sub ($x) {
         ({ name => 'one', instance => $x }, { name => 'two', instance => $x })
      } ],
) {
   my ($label, $twice) = $case->@*;
   my $model = eval { model($twice->(hash_provider())) };
   my $error = $@;
   ok !defined($model), "same instance $label: refused";
   is eval { $error->code }, 400, "same instance $label: 400";
}

done_testing();
