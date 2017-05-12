use Modern::Perl;
use Carp;
use String::Util ':all';

sub get_dbh {
    my %conf = parse_conf();

    return DBI->connect(
        $conf{DBI_DSN},
        $conf{DBI_USER},
        $conf{DBI_PASS},
        {
            RaiseError => 1,
            PrintError => 0
        }
    );
}

sub get_mysql_util {
    my %conf = parse_conf();

    return MySQL::Util->new(
        dsn  => $conf{DBI_DSN},
        user => $conf{DBI_USER},
        pass => $conf{DBI_PASS},
        span => 0
    );
}

sub parse_dsn {
    my %conf = parse_conf();

    my %ret;

    foreach my $part ( split /:|;/, $conf{DBI_DSN} ) {
        next unless $part =~ /=/;
        my ( $key, $value ) = split /=/, $part;
        $ret{$key} = $value;
    }

    if ( !defined $ret{host} ) {
        $ret{host} = 'localhost';
    }

    if ( !defined $ret{database} ) {
        if ( !defined $ret{dbname} ) {
            $ret{database} = 'testmysqlutil';
            $ret{dbname}   = 'testmysqlutil';
        }
    }
    elsif ( !defined $ret{dbname} ) {
        $ret{dbname} = $ret{database};
    }

    if ( !defined $ret{port} ) {
        $ret{port} = 3306;
    }

    return %ret;
}

sub get_mysql_cmdline {
    my $with_dbname = shift || 0;

    my %conf = parse_conf();
    my %conn = parse_dsn();

    my $cmd = sprintf "mysql -u %s %s -h %s -P %s",
      $conf{DBI_USER},
      defined $conf{DBI_PASS} ? "-p$conf{DBI_PASS}" : '',
      $conn{host},
      $conn{port};

    $cmd .= " -D $conn{dbname}" if $with_dbname;

    return $cmd;
}

sub drop_db {
    my %conn = parse_dsn();

    my $mysql_cmd = get_mysql_cmdline();
    my $drop_cmd = "-e 'drop database if exists $conn{dbname}'";
    sysprint("$mysql_cmd $drop_cmd");
    
    return ($conn{host}, $conn{dbname});
}

sub load_db {
    my %conf = parse_conf();
    my %conn = parse_dsn();

    my $mysql_cmd  = get_mysql_cmdline();
    my $create_cmd = "-e 'create database $conn{dbname}'";
    sysprint("$mysql_cmd $create_cmd");

    my $cmd =
        "mysql "
      . "-u $conf{DBI_USER} "
      . "-h $conn{host} "
      . "-D $conn{dbname} "
      . "-P $conn{port} ";

    $cmd .= "-p$conf{DBI_PASS} " if $conf{DBI_PASS};

    my $file = 'sql';
    
    if (-e $file) {
    }
    elsif (-e "../t/$file") {
        $file = "../t/$file";
    }
    elsif (-e "t/$file") {
        $file = "t/$file";    
    }
    else {
        confess "can't find $file";
    }
    
    $cmd .= " < $file";
    sysprint($cmd);
    
    return ($conn{host}, $conn{dbname});
}

BEGIN {
    my $conf;

    sub parse_conf {

        return %$conf if $conf;

        my $file = 'CONF';
        if (!-e $file) {
            $file = '../CONF';
        }
            
        open my $fh, $file or die "failed to open $file: $!";

        while (<$fh>) {
            my $trimmed = trim($_);
            next if nocontent($trimmed);
            next if $trimmed =~ /^#/;

            $trimmed =~ /^(\w+)={1}(\w.+)$/;
            my ( $key, $value ) = ($1, $2);
            $conf->{$key} = $value;
        }

        die "missing DBI_DSN from CONF file"  if !$conf->{DBI_DSN};

        if ( $ENV{DBI_USER} ) {
            $conf->{DBI_USER} = $ENV{DBI_USER};
        }
        elsif ( !exists $conf->{DBI_USER} ) {
            $conf->{DBI_USER} = $ENV{USER};
        }

        if ( $ENV{DBI_PASS} ) {
            $conf->{DBI_PASS} = $ENV{DBI_PASS};
        }
        elsif ( !exists $conf->{DBI_PASS} ) {
            print
              "warning:  no password found in CONF file or env var DBI_PASS "
              . "using undef\n";

            $conf->{DBI_PASS} = undef;
        }

        return %$conf;
    }
}

sub sysprint {
    my $cmd = shift;
    
    print "$cmd\n" if $ENV{VERBOSE} or $ENV{TEST_VERBOSE};
    system($cmd);
    die if $?;
}

1;