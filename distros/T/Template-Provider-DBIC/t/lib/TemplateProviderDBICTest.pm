package # hide from PAUSE
    TemplateProviderDBICTest;

use strict;
use warnings;

use TestSchema;


# This method removes the test SQLite database in t/var/DBIxClass.db and then
# creates a new database, populating it with test content.
sub init_schema {
    my $self    = shift;
    my $db_file = 't/var/TestSchema.db';
    
    unlink($db_file)   if -e $db_file;
    mkdir('t/var') unless -d 't/var';
    
    my $dsn = "dbi:SQLite:${db_file}";
    
    my $schema = TestSchema->compose_connection(
        'TestSchema' => $dsn, '', ''
    );
    $schema->storage->on_connect_do( ['PRAGMA synchronous = OFF'] );
    
    $schema->deploy();
    $schema->populate('Template', [
        [ qw/name modified content/ ],
        [ 'test', '2007-03-02 00:00:00',
          '[% SET result = "success" %]This test was a [% result %]' ]
    ]);
    
    return $schema;
}



1;
