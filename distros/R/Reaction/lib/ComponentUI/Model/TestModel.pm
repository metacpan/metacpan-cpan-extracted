package ComponentUI::Model::TestModel;

use lib 't/lib';
use aliased 'Catalyst::Model::Reaction::InterfaceModel::DBIC';

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends DBIC;



__PACKAGE__->meta->make_immutable;


__PACKAGE__->config
  (
   im_class => 'ComponentUI::TestModel',
   db_dsn   => 'dbi:SQLite:t/var/reaction_test_withdb.db',
  );

1;
