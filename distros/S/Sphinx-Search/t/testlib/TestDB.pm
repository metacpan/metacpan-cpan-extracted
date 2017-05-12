package TestDB;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use DBI;
use File::SearchPath qw/searchpath/;
use Path::Class;
use Socket;

__PACKAGE__->mk_accessors(qw/searchd indexer searchd_port dbtable dsn dbuser dbpass dbname dbhost dbport dbsock testdir configfile pidfile/);

our @pids;
our @pidfiles;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->searchd($ENV{SPHINX_SEARCHD} || searchpath('searchd')) unless $self->searchd;
    $self->indexer($ENV{SPHINX_INDEXER} || searchpath('indexer')) unless $self->indexer;
    $self->searchd_port($ENV{SPHINX_PORT} || int(rand(20000))) unless $self->searchd_port;;

    return $self;
}


sub preflight {
    my $self = shift;
    
    my $msg;
    $msg = $self->searchd_check and return $msg;
    $msg = $self->indexer_check and return $msg;
    $msg = $self->db_check and return $msg;
    $msg = $self->files_check and return $msg;
    return;
}

sub searchd_check {
    my $self = shift;
    my $searchd = $self->searchd;
    unless ($searchd && -e $searchd) {
	return "Can't find searchd; set SPHINX_SEARCHD to location of searchd binary in order to run these tests";
    }
    return;
}

sub indexer_check {
    my $self = shift;
    my $searchd = $self->searchd;
    my $indexer = $self->indexer;

    $indexer = Path::Class::file($searchd)->dir->file('indexer')->stringify unless $indexer;
    unless ($indexer && -e $indexer) {
	return "Can't find indexer; set SPHINX_INDEXER to location of indexer binary in order to run these tests";
    }
    $self->indexer($indexer);
    return;
}

sub db_check {
    my $self = shift;

    $self->dbtable(my $dbtable = 'sphinx_test_jjs_092348792');
    $self->dsn(my $dsn = $ENV{SPHINX_DSN} || "dbi:mysql:database=test");
    $self->dbuser(my $dbuser = $ENV{SPHINX_DBUSER} || "root");
    $self->dbpass(my $dbpass = $ENV{SPHINX_DBPASS} || "");
    $self->dbname(( $dsn =~ m!database=([^;]+)! ) ? $1 : "test");
    $self->dbhost(( $dsn =~ m!host=([^;]+)! ) ? $1 : "localhost");
    $self->dbport(( $dsn =~ m!port=([^;]+)! ) ? $1 : "");
    $self->dbsock(( $dsn =~ m!socket=([^;]+)! ) ? $1 : "");

    my $dbi = DBI->connect($dsn, $dbuser, $dbpass, { RaiseError => 0 });
    unless ($dbi) {
	return "Failed to connect to database; set SPHINX_DSN, SPHINX_DBUSER, SPHINX_DBPASS appropriately to run these tests";
    }
    unless ($self->create_db($dbi)) {
	return "Failed to create database table; set SPHINX_DSN, SPHINX_DBUSER, SPHINX_DBPASS appropriately to run these tests";
    }
    return;
}

sub files_check {
    my $self = shift;

    $self->testdir(my $testdir = Path::Class::dir("data")->absolute);
    eval { $testdir->mkpath };
    if ($@) {
	return "Failed to create 'data' directory; skipping tests. Fix permissions to run test";
    }

    $self->pidfile($testdir->file('searchd.pid'));
    push(@pidfiles, $self->pidfile);
    $self->configfile(my $configfile = $testdir->file('sphinx.conf'));
    unless ($self->write_config($configfile)) {
	return "Failed to write config file; skipping tests.  Fix permissions to run test";
    }
    return;
}


sub create_db {
    my ($self, $dbi) = @_;

    my $dbtable = $self->dbtable;
    eval {
	$dbi->do(qq{DROP TABLE IF EXISTS \`$dbtable\`});
	$dbi->do(qq{SET NAMES utf8});
	$dbi->do(qq{CREATE TABLE \`$dbtable\` (
					     \`id\` BIGINT UNSIGNED NOT NULL auto_increment,
					     \`field1\` TEXT,
					     \`field2\` TEXT,
				             \`attr1\` INT NOT NULL,
				             \`lat\` FLOAT NOT NULL,
				             \`long\` FLOAT NOT NULL,
				             \`stringattr\` VARCHAR(100),
					     PRIMARY KEY (\`id\`)) DEFAULT CHARSET=utf8 COLLATE=utf8_bin });
    $dbi->do(qq{INSERT INTO \`$dbtable\` (\`id\`,\`field1\`,\`field2\`,\`attr1\`,\`lat\`,\`long\`,\`stringattr\`) VALUES
		   (1, 'a', 'bb', 2, 0.35, 0.70, ''),
		   (2, 'a', 'bb ccc', 4, 0.70, 0.35, ''),
		   (3, 'a', 'bb ccc dddd', 1, 0.35, 0.70, ''),
		   (4, 'a bb', 'bb ccc dddd', 5, 0.35, 0.70, ''),
		   (5, 'bb', 'bb bb ccc dddd', 3, 1.5, 1.5, 'new string attribute'),
		   ('9223372036854775807', 'xx', 'xx', 9000, 150, 150, ''),
                   (6, "\x{65e5}\x{672c}\x{8a9e}", '', 0, 0, 0, '')
		});
    };
    if ($@) {
	print STDERR "Failed to create/load database table: $@\n";
	return 0;
    }

    return 1;
}

sub write_config {
    my $self = shift;
    my $configfile = $self->configfile;
    my $testdir = $self->testdir;
    my $pidfile = $self->pidfile;

    my $dbhost = $self->dbhost;
    my $dbuser = $self->dbuser;
    my $dbpass = $self->dbpass;
    my $dbname = $self->dbname;
    my $dbport = $self->dbport;
    my $dbsock = $self->dbsock;
    my $dbtable = $self->dbtable;
    my $searchd_port = $self->searchd_port;

    eval {
	my $config = <<EOF;

    source test_jjs_src {
	type = mysql
	sql_host = $dbhost
	sql_user = $dbuser
	sql_pass = $dbpass
	sql_db = $dbname
	sql_port = $dbport
	sql_sock = $dbsock
	sql_query_pre = SET NAMES utf8
	sql_query = SELECT * FROM $dbtable
	sql_attr_uint = attr1
	sql_attr_float = lat
	sql_attr_float = long
        sql_attr_string = stringattr
    }
    index test_jjs_index {
	source = test_jjs_src
	path = $testdir/test_jjs
	html_strip = 0
	min_word_len = 1
	charset_type = utf-8
	charset_table = 0..9, a..z, A..Z->a..z, U+3041->U+30A2, U+3042->U+30A2, U+3043->U+30A4, U+3044->U+30A4, U+3045->U+30A6, U+3046->U+30A6, U+3047->U+30A8, U+3048->U+30A8, U+3049->U+30AA, U+304A->U+30AA, U+304B..U+3062->U+30AB..U+30C2, U+3063->U+30C4, U+3064..U+3082->U+30C4..U+30E2, U+3083->U+30E4, U+3084->U+30E4, U+3085->U+30E6, U+3086->U+30E6, U+3087->U+30E8, U+3088->U+30E8, U+3089..U+308D->U+30E9..U+30ED, U+308E->U+30EF, U+308F..U+3094->U+30EF..U+30F4, U+3095->U+30AB, U+3096->U+30B1, U+309F->U+30FF, U+30A1->U+30A2, U+30A2, U+30A3->U+30A4, U+30A4, U+30A5->U+30A6, U+30A6, U+30A7->U+30A8, U+30A8, U+30A9->U+30AA, U+30AA, U+30AB..U+30C2, U+30C3->U+30C4, U+30C4..U+30E2, U+30E3->U+30E4, U+30E4, U+30E5->U+30E6, U+30E6, U+30E7->U+30E8, U+30E8..U+30ED, U+30EE->U+30EF, U+30EF..U+30F4, U+30F5->U+30AB, U+30F6->U+30B1, U+30FA, U+30FF, U+31F0->U+30AF, U+31F1->U+30B7, U+31F2->U+30B9, U+31F3->U+30C8, U+31F4->U+30CC, U+31F5->U+30CF, U+31F6->U+30D2, U+31F7->U+30D5, U+31F8->U+30D8, U+31F9->U+30DB, U+31FA->U+30E0, U+31FB..U+31FF->U+30E9..U+30ED, U+3400..U+4DB5, U+4E00..U+9FC3, U+F900..U+FAD9, U+FF10..U+FF19->0..9, U+FF21..U+FF3A->a..z, U+FF41..U+FF5A->a..z, U+FF66->U+30F2, U+FF67->U+30A2, U+FF68->U+30A4, U+FF69->U+30A6, U+FF6A->U+30A8, U+FF6B->U+30AA, U+FF6C->U+30E4, U+FF6D->U+30E6, U+FF6E->U+30E8, U+FF6F->U+30C4, U+FF71->U+30A2, U+FF72->U+30A4, U+FF73->U+30A6, U+FF74->U+30A8, U+FF75->U+30AA, U+FF76->U+30AD, U+FF78->U+30AF, U+FF79->U+30B1, U+FF7A->U+30B3, U+FF7B->U+30B5, U+FF7C->U+30B7, U+FF7D->U+30B9, U+FF7E->U+30BB, U+FF7F->U+30BD, U+FF80->U+30BF, U+FF81->U+30C1, U+FF82->U+30C4, U+FF83->U+30C6, U+FF84->U+30C8, U+FF85..U+FF8A->U+30CA..U+30CF, U+FF8B->U+30D2, U+FF8C->U+30D5, U+FF8D->U+30D8, U+FF8E->U+30DB, U+FF8F..U+FF93->U+30DE..U+30E2, U+FF94->U+30E4, U+FF95->U+30E6, U+FF96..U+FF9B->U+30E8..U+30ED, U+FF9C->U+30EF, U+FF9D->U+30F3, U+20000..U+2A6D6, U+2F800..U+2FA1D

    }
    searchd {
	listen = $searchd_port
	log = $testdir/searchd.log
	query_log = $testdir/query.log
	pid_file = $pidfile
    }
EOF
    $config =~ s/sql_sock.*// unless $self->dbsock;
    $config =~ s/sql_port.*// unless $self->dbport;

    open(CONFIG, ">$configfile");
    print CONFIG $config;
    close(CONFIG);
    };
    if ($@) {
	print STDERR "While writing config: $@\n";
	return 0;
    }
    return 1;
}

sub run_indexer {
    my $self = shift;
    my $configfile = $self->configfile;
    my $indexer = $self->indexer;

    my $res = `$indexer --config $configfile test_jjs_index`;
    if ($? != 0 || $res =~ m!ERROR!) {
	print STDERR "Indexer returned $?: $res";
	return 0;
    }
    return 1;
}

sub run_searchd {
    my $self = shift;
    my $configfile = $self->configfile;
    my $pidfile = $self->pidfile;
    my $searchd = $self->searchd;

    my ($pid) = _run_forks(sub {
#	open STDOUT, '>&STDERR';
	open STDIN, '/dev/null';
	open STDOUT, '>/dev/null';
	open STDERR, '>&STDOUT';
	exec("$searchd --config $configfile");
    });

    my $fp;
    unless (socket($fp, PF_INET, SOCK_STREAM, getprotobyname('tcp'))) {
	print STDERR "Failed to create socket: $!";
	return 0;
    }
    my $dest = sockaddr_in($self->searchd_port, inet_aton("localhost"));
    for (0..3) {
	last if -f "$pidfile";
	sleep(1);
    }
    for (0..3) {
	if (connect($fp, $dest)) {
	    close($fp);
	    return 1;
	}
	else {
	    sleep(1);
	}
    }
    return 0;
}

sub _death_handler {
    if (@pids) {
	kill(15, $_) for @pids;
    }
    for my $pidfile (@pidfiles) {
	my $pid = $pidfile->slurp;
	kill(15, $pid) if $pid;
    }

}

sub _run_forks {
    my ($forks) = @_;

    my @newpids;
    if ($forks) {
	$forks = [ $forks ] unless (ref($forks) eq "ARRAY");
	for my $f (@{$forks}) {
	    my $pid = fork();
	    die "Fork failed: $!" unless defined $pid;
	    if ($pid == 0) {
		@pids = ();	# prevent child from killing siblings
		# Child process
		if (ref($f) eq "CODE") {
		    &$f;
		}
		else {
		    print STDERR "Don't know how to run test $f\n";
		}
		exit(0);
	    }
	    # Push PID for killing.
	    push(@pids, $pid);
	    push(@newpids, $pid);
	}

	$SIG{INT} = \&_death_handler;
	$SIG{KILL} = \&_death_handler;
	$SIG{TERM} = \&_death_handler;
	$SIG{QUIT} = \&_death_handler;
    }
    return @newpids;
}


END { 
    _death_handler();
}


1;
