package My::DB::Gene::Main;

use My::DB::Gene2Unigene;

use base qw(My::DB::Object);

__PACKAGE__->meta->table('Rose_db_object_g_main');

__PACKAGE__->meta->relationships
(
  unigenes => 
  {
    type      => 'many to many',
    map_class => 'My::DB::Gene2Unigene'
  },
);

__PACKAGE__->meta->auto_initialize(relationship_types => []);

package My::DB::Gene::Main::Manager;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'My::DB::Gene::Main' }

__PACKAGE__->make_manager_methods('gmain');

1;
