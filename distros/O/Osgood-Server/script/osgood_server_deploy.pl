#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Pod::Usage;
use Getopt::Long;

use Osgood::Server;

my ( $help, $deploy, $ddl, $drop_tables ) = ( 0, 1, 0, 1 );

GetOptions(
    'help|?'   => \$help,
    'deploy|d' => \$deploy,
    'ddl'      => \$ddl,
    'drop'     => \$drop_tables,
);

pod2usage(1) if $help;

my $schema = Osgood::Server->model('OsgoodDB')->schema;

if ( $ddl ) {
    $schema->create_ddl_dir(
        [ 'SQLite', 'MySQL' ],
        $Osgood::Server::VERSION,
        Osgood::Server->path_to('sql')
    );
}
elsif ( $deploy ) {
    $schema->deploy({ add_drop_table => $drop_tables });

} else {
    pod2usage(1);
}

1;

