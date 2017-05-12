package Passwd::DB;

use DB_File;
use strict;
use Fcntl;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(getpwnam getpwuid);

@EXPORT_OK = qw(mgetpwnam setpwinfo rmpwnam init_db modpwinfo);

$VERSION = '1.05';

my %_DB_Global = ();
$_DB_Global{'Database'} = $ENV{'PWDDatabase'};
$_DB_Global{'CFlags'} = O_CREAT;  # found in Fcntl

# Preloaded methods go here.

sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;
    if ((scalar(@_) >= 3) || (scalar(@_) < 1)) {
        croak "$class: $class->new('/path/to/database_file' [, 'create'])";
    }
    $self->{'CLASS'} = $class;
    $self->init_db(@_);
    return $self;
}

sub init_db ($;$) {
    my ($self, $db, $create) = @_;
    if (ref($self)) {
	$self->{'Database'} = $db;
    } else {
	if ($self eq 'Passwd::DB') {
	    $_DB_Global{'Database'} = $db;
	} else {
	    $_DB_Global{'Database'} = $self;
	    $create = $db;
	    $db = $self;
	}
    }
    $create =~ tr/A-Z/-z/;
    if ($create eq 'create' || $create == 1) {
        _create_db($db);
    }
#    print "Using PasswordDB functions on $Database\n";
}

sub _create_db ($) {
    my ($db) = @_;
    my (%dbm);

    tie (%dbm, 'DB_File', $db, $_DB_Global{'CFlags'}|2, 0640, $DB_HASH) or do {
	croak "Couldn't create $db : $!";
    };
    untie (%dbm);
}

sub getpwnam ($) {
    my ($self, $login) = @_;
    my (%dbm, @info, $db);

    if (ref($self)) {
	$db = $self->{'Database'};
    } else {
	$login = $self;
	$db = $_DB_Global{'Database'};
    }

    tie (%dbm, 'DB_File', $db, 0, 0400, $DB_HASH) or do {
	croak "Couldn't access $db : $!";
    };
    if (!defined($dbm{$login})) {
        untie %dbm;
        return;
    }
    @info = (split(':',$dbm{$login}));
    if (scalar(@info) == 7) {
        splice (@info,4,0, "");
        splice (@info,4,0, "");
        untie %dbm;
        return @info;
    }
    untie %dbm;
    return;
}

sub getpwuid ($) {
    my ($self, $uid) = @_;
    my (%dbm, @info, $key, $db);

    if (ref($self)) {
	$db = $self->{'Database'};
    } else {
	$uid = $self;
	$db = $_DB_Global{'Database'};
    }

    tie (%dbm, 'DB_File', $db, 0, 0400, $DB_HASH) or do {
        croak "Couldn't access $db : $!";
    };
    foreach $key (keys %dbm) {
        @info = (split(':',$dbm{$key}));
        if ($info[2] == $uid) {
            if (scalar(@info) == 7) {
                splice (@info,4,0, qw(0 0));
            }
            untie %dbm;
            return (@info);
        }
    }
    untie %dbm;
    return;
}

sub mgetpwnam ($) { # same as getpwnam without quota and comment
    my ($self, $login) = @_;
    my (%dbm, @info, $db);

    if (ref($self)) {
	$db = $self->{'Database'};
    } else {
	$login = $self;
	$db = $_DB_Global{'Database'};
    }

    tie (%dbm, 'DB_File', $db, 0, 0400, $DB_HASH) or do {
        croak "Couldn't access $db : $!";
    };
    if (!defined($dbm{$login})) {
        untie %dbm;
        return;
    }
    @info = (split(':',$dbm{$login}));
    untie %dbm;
    if (scalar(@info) == 7) {
        return (@info);
    }
    return;
}
sub modpwinfo (@) {
    my ($self, @info) = @_;
    my (%dbm, $loginfo, $db, $size, $err);

    if (ref($self)) {
	$db = $self->{'Database'};
	$size = scalar(@info);
    } else {
	$size = unshift @info, $self;
	$db = $_DB_Global{'Database'};
    }

    if ($size != 7) {
        croak "Incorrect number of arguments for modpwinfo";
    }
    tie (%dbm, 'DB_File', $db, 2, 0600, $DB_HASH) or do {
        croak "Couldn't access $db : $!";
    };
    if (!defined($dbm{$info[0]})) {
	return 2;
    }
    $loginfo = join(':',@info);
    $dbm{$info[0]} = $loginfo;
    $err = (!defined($dbm{$info[0]}));
    untie %dbm;

    return $err;
}

sub setpwinfo (@) {
    my ($self, @info) = @_;
    my (%dbm, $loginfo, $db, $size, $err);

    if (ref($self)) {
	$db = $self->{'Database'};
	$size = scalar(@info);
    } else {
	$size = unshift @info, $self;
	$db = $_DB_Global{'Database'};
    }

    if ($size != 7) {
        croak "Incorrect number of arguments for setpwinfo";
    }
    tie (%dbm, 'DB_File', $db, 2, 0600, $DB_HASH) or do {
        croak "Couldn't access $db : $!";
    };
    $loginfo = join(':',@info);
    $dbm{$info[0]} = $loginfo;
    $err = (!defined($dbm{$info[0]}));
    untie %dbm;

    return $err;
}

sub rmpwnam ($) {
    my ($self, $login) = @_;
    my (%dbm, $db);

    if (ref($self)) {
	$db = $self->{'Database'};
    } else {
	$login = $self;
	$db = $_DB_Global{'Database'};
    }

    tie (%dbm, 'DB_File', $db, 2, 0600, $DB_HASH) or do {
        croak "Couldn't access $db : $!";
    };
    my $err = delete $dbm{$login};
    untie %dbm;

    if (!defined($err)) {
        return 1;
    }
    return 0;
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Passwd::DB - Perl module for manipulating a password file stored in a BerkeleyDB hash

=head1 SYNOPSIS

  use Passwd::DB;

  $db = Passwd::DB->new("/usr/local/databases/db_ftp_users");
  $db = Passwd::DB->new("/usr/local/databases/db_ftp_users", 'create');
  @info = $db->getpwnam('bob');
  @info = $db->getpwuid('100');
  @minfo = $db->mgetpwnam('bob');
  $err = $db->modpwinfo(@minfo);
  $err = $db->setpwinfo(@minfo);
  $err = $db->rmpwnam('bob');

  use Passwd::DB qw(init_db getpwnam getpwuid mgetpwnam modpwinfo setpwinfo rmpwnam);

  Passwd::DB->init_db("/usr/local/databases/db_ftp_users");
  Passwd::DB->init_db("/usr/local/databases/db_ftp_users", 1);
  init_db("/usr/local/db_bob",1);
  @info = getpwnam('bob');
  @info = getpwuid('100');
  @minfo = mgetpwnam('bob');
  $err = modpwinfo(@minfo);
  $err = setpwinfo(@minfo);
  $err = rmpwnam('bob');


=head1 DESCRIPTION

Passwd::DB provides basic password routines.  It augments getpwnam and getpwuid functions with setpwinfo, modpwinfo, rmpwnam, mgetpwnam.  The routines can be used both in object context or straight.  When used in non-object context a call to init_db is required to initialize the global data base structure.  This does mean that you can have only one active database when used in non-object context.

new and init_db can be called with an optional second argument.  If it is set to 1 or 'create' the database will be created if it doesn't already exist.

getpwnam and getpwuid are the same as their respective core counterparts.

setpwinfo and modpwinfo are called with arrays containing (in order):
 name, crypted_password, uid, gid, gecos, home_directory, shell

rmpwnam is called with a scalar containing the login name.

mgetpwnam returns the same array that getpwnam returns without the 'unused' age or comment fields.

setpwinfo does a create/modify of the user.
modpwinfo only does a modify, it will return an error if the user doesn't exist.

rmpwnam removes the user with the given login.  It returns an error if the user doesn't exist.

Right now all functions croak when they can't open the database.  This will change if the majority of people don't like this behavior.

Error return values:
  < 0   system error occurred, error value should be in $!
    0   no error
    1   operation failed
    2   operation failed because user does not exist


=head1 Exported functions on the OK basis

    getpwnam
    getpwuid
    mgetpwnam
    modpwinfo
    setpwinfo
    rmpwnam
    init_db

=head1 AUTHOR

Eric Estabrooks, eric@urbanrage.com

=head1 SEE ALSO

perl(1).

=cut
