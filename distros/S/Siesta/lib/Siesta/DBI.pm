use strict;
package Siesta::DBI;
use Siesta::Config;
use base 'Class::DBI::BaseDSN';
__PACKAGE__->set_db( 'Main', @Siesta::Config::STORAGE );
__PACKAGE__->mk_classdata('load_alias');

=head1 NAME

Siesta::DBI - base class extending Class::DBI

=head1 DESCRIPTION

most things in the system will be a subclass of Siesta::DBI, giving

=head1 METHODS

=head2 load_alias( $name )

Sets the load_alias of a class to be $name.  This is used in
conjunction with ->load to provide a shortcut to a serialised item.

=head2 load( $id_or_name )

Attempt to retrieve an object using either it's well-known name or the
row id.

It's used like so:

 package User;
 use base 'Siesta::DBI';
 __PACKAGE__->load_alias( 'email' );

 # time passes ...
 my $user =  User->load( 'jay@front-of.quick.stop';

=cut

sub load {
    my $class = shift;
    my $id = shift;
    if ($id =~ /^\d+$/) {
        return $class->retrieve($id);
    }
    my ($item) = $class->search( $class->load_alias => $id );
    return unless $item;
    return $item;
}


=head1 init_db

run the database creation script that lives in __DATA__

=cut

sub init_db {
    my $class = shift;
    my $dbh = $class->db_Main;
    my $sql = join ( '', (<DATA>) );

    for my $statement (split /;/, $sql) {
        if ($dbh->{Driver}{Name} eq 'SQLite') {
            $statement =~ s/auto_increment//g;
            $statement =~ s/,?FOREIGN .*$//mg;
            $statement =~ s/TYPE=INNODB//g;
        }
        $statement =~ s/\#.*$//mg; # strip # comments
        next unless $statement =~ /\S/;
        eval { $dbh->do($statement) };
        die "$@: $statement" if $@;
    }
    return 1;
}


1;
__DATA__

# Yes, the FOREIGN KEY definitions are fugly, it's all because we
# don't/can't pass them to SQLite

CREATE TABLE member (
        id              INTEGER PRIMARY KEY auto_increment,
        email           VARCHAR(255) NOT NULL UNIQUE,
        password        VARCHAR(13),
        bouncing        INT,
        lastbounce      INT,
        nomail          INT
) TYPE=INNODB;

CREATE TABLE list (
        id              INTEGER PRIMARY KEY auto_increment,
        name            VARCHAR(20) NOT NULL UNIQUE,
        owner           INT,
        post_address    VARCHAR(255),
        return_path     VARCHAR(255)
        ,FOREIGN KEY (owner) REFERENCES member(id)
)  TYPE=INNODB;

CREATE TABLE subscription (
        id              INTEGER PRIMARY KEY auto_increment,
        list            INT NOT NULL,
        member          INT NOT NULL
        ,FOREIGN KEY (member) REFERENCES member(id)
        ,FOREIGN KEY (list)   REFERENCES list(id)
) TYPE=INNODB;

CREATE TABLE plugin (
        id              INTEGER PRIMARY KEY auto_increment,
        queue           VARCHAR(20) NOT NULL,
        name            VARCHAR(20) NOT NULL,
        rank            INT,
        list            INT NOT NULL,
        personal        INT
        ,FOREIGN KEY (list) REFERENCES list(id)
) TYPE=INNODB;

CREATE TABLE pref (
        id              INTEGER PRIMARY KEY auto_increment,
        plugin          INTEGER NOT NULL,
        member          INTEGER,
        name            VARCHAR(255) NOT NULL,
        value           VARCHAR(255)
        ,FOREIGN KEY (plugin) REFERENCES plugin(id)
        ,FOREIGN KEY (member) REFERENCES member(id)
) TYPE=INNODB;

# deferred messages
CREATE TABLE deferred (
        id              INTEGER PRIMARY KEY auto_increment,
        expires         INTEGER,        # epoch time at which it's considered dead
        who             INTEGER NOT NULL,        # who can release it
        why             VARCHAR(255),   # just a comment?
        plugins         VARCHAR(255),   # this could become too small,
                                        # in the case of extreme installs
        message         TEXT
        ,FOREIGN KEY (who) REFERENCES member(id)
) TYPE=INNODB;
