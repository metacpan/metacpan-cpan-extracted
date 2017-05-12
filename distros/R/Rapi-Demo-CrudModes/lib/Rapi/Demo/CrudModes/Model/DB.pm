package Rapi::Demo::CrudModes::Model::DB;

use strict;
use warnings;

use Moo;
extends 'Catalyst::Model::DBIC::Schema';

use RapidApp::Util qw(:all);

use Try::Tiny;

__PACKAGE__->config(
    schema_class => 'Rapi::Demo::CrudModes::DB',
    
    connect_info => {
        #dsn => 'dbi:SQLite:creaturezoo.db', #<-- Note: this gets set in Rapi::Demo::CrudModes
        user => '',
        password => '',
        sqlite_unicode => q{1},
        on_connect_call => q{use_foreign_keys},
        quote_names => q{1},
    },
    
    RapidDbic => {
      hide_fk_columns => 1,
      grid_params => {
         '*defaults' => { # Defaults for all Sources
            updatable_colspec   => ['*'],
            creatable_colspec   => ['*'],
            destroyable_relspec => ['*']
         }, # ('*defaults')
         BravoNote => {
            # Turning off the add form will cause adding items to fail, except
            # when the grid is opened via link from the parent Bravo grid:
            use_add_form => 0
         }
      }, # (grid_params)
      TableSpecs => {
        Alpha => {
          title       => 'Alpha Row',
          title_multi => 'Alpha Rows',
        },
        Bravo => {
          title             => 'Bravo',
          title_multi       => 'Bravos',
          display_column    => 'title',
          auto_editor_type  => 'combo',
        },
      
      }, # (TableSpecs)
   } # (RapidDbic)
);


sub _auto_deploy_schema {
  my $self = shift;
  my $schema = $self->schema;
  
  try {
    # This will barf if the table doesn't exist:
    $schema->resultset('Alpha')->count;
  }
  catch {
    warn join("","\n",
      "  ** Auto-Deploying fresh schema ", (ref $self),'/',(ref $schema),' **',
      "\n"
    );
    
    $schema->txn_do( sub {
      $schema->deploy;
      $schema->_auto_populate if ($schema->can('_auto_populate')); #<-- future
    });
  };
};


1;
