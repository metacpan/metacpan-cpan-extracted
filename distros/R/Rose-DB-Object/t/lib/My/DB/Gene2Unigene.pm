package My::DB::Gene2Unigene;

use My::DB::Gene::Main;
use My::DB::Unigene::Main;

use base qw(My::DB::Object);

__PACKAGE__->meta->table('Rose_db_object_g_ug');

__PACKAGE__->meta->auto_initialize(with_relationships => 0);

package My::DB::Gene2Unigene::Manager;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'My::DB::Gene2Unigene' }

__PACKAGE__->make_manager_methods('gug');

1;
