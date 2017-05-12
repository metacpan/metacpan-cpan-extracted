package CStyle;

use strict;
use warnings;

use Parse::PlainConfig;
use Parse::PlainConfig::Constants;
use base qw(Parse::PlainConfig);
use vars qw(%_globals %_parameters %_prototypes);

%_globals = (
    comment          => '//',
    'delimiter'      => ':=',
    'list delimiter' => ',',
    'hash delimiter' => '->',
    'subindentation' => 4,
    );

%_parameters = (
    'admin email' => PPC_SCALAR,
    'db'          => PPC_HASH,
    'hosts'       => PPC_ARRAY,
    'note'        => PPC_HDOC,
    'nodefault'   => PPC_SCALAR,
    );

%_prototypes = (
    'declare acl' => PPC_ARRAY,
    'declare foo' => PPC_SCALAR
    );

1;

__DATA__
// Okay, this is only a little C'ish, I'm mixing my language memes a 
// wee bit.
// 
// admin email:  email address of the admin
admin email := root@localhost   

// db: host, database, username, and password for database access
db :=
    host->localhost,
    database->sample.db,
    username->dbuser,
    password->dbpass

// hosts:  list of hosts to monitor
hosts := localhost,host1.foo.com,host1.bar.com

note := This is a note, but not a
    very long note.  With this odd 
    selection of delimiters it looks
    even more weird.
           EOF             

  // Let's throw some random ACLs out there
  declare acl loopback := 127.0.0.1,localhost
  declare acl localnet := 192.168.0.0/24,192.168.35.0/24

// nodefault is just a scalar parameter that has no default setting

