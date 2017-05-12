package TestX::CatalystX::ExtensionB::Model::BookDB;

use strict;
use File::ShareDir;
use base 'Catalyst::Model::DBIC::Schema';

my $path = File::Spec->rel2abs( File::ShareDir::module_dir( 'TestX::CatalystX::ExtensionB' ) );

__PACKAGE__->config
( 
    schema_class    => 'TestX::CatalystX::ExtensionB::Schema',
    connect_info    =>
    {   
        dsn             => "dbi:SQLite:$path/root/db/bookdb.db",
        user            => '',
        password        => '',
        on_connect_do   => q{PRAGMA foreign_keys = ON},
    }
);


1;
