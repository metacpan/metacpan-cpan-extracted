# $Id: Makefile.PL,v 3.3 2004/01/09 22:43:13 lachoy Exp $

# See 'README' for the environment variables we use in builds without
# intervention.
#
# To use manual configuration: 'perl Makefile.PL MANUAL=1'

use strict;
use ExtUtils::MakeMaker;

my ( $EXTRA_INFO );

 # Available SPOPS DBI drivers (when we start testing with more
 # databases, we add them here)

my %SUPPORTED_DBD_DRIVERS = map { $_ => 1 }
                                qw( ASAny mysql ODBC Pg SQLite InterBase );
$SUPPORTED_DBD_DRIVERS{Oracle} = \&set_oracle_env;
$SUPPORTED_DBD_DRIVERS{Sybase} = \&set_sybase_env;

 # File we write the configuration info to

my $CONFIG_FILE = 'spops_test.conf';

# My arguments (so we don't just eat all the ones E::MM might actually
# want
my %MY_ARGS = map { $_ => 1 } qw( MANUAL );

{
    # Read in command-line arguments

    my ( %OPT );
    my @mm_args = ();
    while ( my $arg = shift @ARGV ) {
        my ( $k, $v ) = split /\s*=\s*/, $arg, 2;
        if ( $MY_ARGS{ $k } ) {
            $OPT{ $k } = $v;
        }
        else {
            push @mm_args, $arg;
        }
    }
    @ARGV = @mm_args;

    print '=' x 40, "\n",
          qq(NOTE: Build process changed as of version 0.65. Default\n),
          qq(build is now automated. See README for details.\n),
          '=' x 40, "\n\n";

    # If the config file already exists, then skip all this goop and
    # write out the Makefile

    if ( -f $CONFIG_FILE ) {
        my $use_existing = ( $OPT{MANUAL} )
                           ? lc get_response( 'You appear to have an existing configuration ' .
                                              'file. Re-use it? (Y/n)', 'Y' )
                           : 'y';
        if ( $use_existing eq 'y' ) {
            write_makefile();
            exit(0);
        }
    }

    my ( $dbi_driver, $dbi_dsn, $dbi_user, $dbi_password )
                                        = check_dbi( %OPT );
    my ( $ldap_host, $ldap_port, $ldap_base_dn, $ldap_bind_dn, $ldap_password )
                                        = check_ldap( %OPT );
    open( CONF, "> $CONFIG_FILE" )
                    || die "Cannot open $CONFIG_FILE for writing! Error: $!";
    print CONF <<CONFIG;
DBI_driver:    $dbi_driver
DBI_dsn:       $dbi_dsn
DBI_user:      $dbi_user
DBI_password:  $dbi_password
LDAP_host:     $ldap_host
LDAP_port:     $ldap_port
LDAP_base_dn:  $ldap_base_dn
LDAP_bind_dn:  $ldap_bind_dn
LDAP_bind_password: $ldap_password
$EXTRA_INFO
CONFIG
    close( CONF );
    write_makefile();
}



# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub write_makefile {
  WriteMakefile(
    'NAME'         => 'SPOPS',
    'VERSION_FROM' => 'SPOPS.pm',
    'AUTHOR'       => 'Chris Winters <chris@cwinters.com>',
    'ABSTRACT'     => 'Data abstraction layer used for object persistence and security',
    'PREREQ_PM'    => { 'Carp::Assert'      => 0.17,
                        'Class::Date'       => 1.00,
                        'Class::Factory'    => 1.00,
                        'Class::Fields'     => 0.14,
                        'Class::ISA'        => 0.32,
                        'Class::Accessor'   => 0.17,
                        'Data::Dumper'      => 2.00,
                        'Log::Dispatch'     => 2.00,
                        'Log::Log4perl'     => 0.35,
                        'Devel::StackTrace' => 0.90,
                        'Storable'          => 1.00,
                        'Test::More'        => 0.41,
                        'Time::Piece'       => 1.07,
                        #'Class::Observable' => 0.03,
                        } );
}


# Find out about a DBI test

sub check_dbi {
    my ( %OPT ) = @_;
    eval { require DBI };
    if ( $@ ) {
        print "You don't appear to have DBI installed; skipping DBI tests.\n";
        return ();
    }
    if ( $OPT{MANUAL} ) {
        my $do_test  = lc get_response( "Would you like to run tests using DBI? (Y/n)\n", 'Y' );
        if ( $do_test ne 'y' ) {
            print "Skipping DBI tests due to lack of interest.\n";
            return ();
        }
        print "\n";
    }

    my @dbd_available = ();
    foreach my $dbd ( keys %SUPPORTED_DBD_DRIVERS ) {
        eval "require DBD::$dbd";
        push @dbd_available, $dbd   unless ( $@ );
    }

    my $dbd_available_string = join ', ', sort @dbd_available;

    my $dbi_driver = _get_dbi_driver( $dbd_available_string, %OPT );
    unless ( $dbi_driver ) {
        print "Skipping DBI tests since no driver specified.\n";
        return ();
    }

    if ( $dbi_driver eq 'ODBC' and ! $OPT{MANUAL} ) {
        print "Skipping DBI tests: ODBC specification must be run ",
              "with 'perl Makefile.PL MANUAL=1'\n";
        return ();
    }

    my ( $odbc_driver );
    if ( $dbi_driver eq 'ODBC' ) {
        print "\n";
        print "You've chosen ODBC as your DBD. However, SPOPS needs to know\n",
              "what type of database is working behind the ODBC driver.\n";
        $odbc_driver = get_response( "Choose a database behind the scenes " .
                                     "($dbd_available_string)\n" .
                                     "(MS SQL users should enter 'Sybase')" );
    }

    # Use this to ensure the environment is setup properly for the
    # DBD driver to run

    if ( ref $SUPPORTED_DBD_DRIVERS{ $dbi_driver } eq 'CODE' ) {
        $SUPPORTED_DBD_DRIVERS{ $dbi_driver }->();
    }

    my $dbi_dsn = _get_dbi_dsn( $dbi_driver, %OPT );
    unless ( $dbi_dsn ) {
        print "Skipping DBI tests since DSN not fully specified\n";
        return ();
    }
    $dbi_dsn = "DBI:$dbi_driver:$dbi_dsn";
    my $dbi_user = _get_dbi_user( %OPT );
    my $dbi_pass = _get_dbi_password( $dbi_user, %OPT );
    print "Please note: you might want to remove the file \n",
          "'$CONFIG_FILE' after the tests have run since it \n",
          "contains user/password information.\n\n";

    $dbi_driver = $odbc_driver if ( $odbc_driver );
    return ( $dbi_driver, $dbi_dsn, $dbi_user, $dbi_pass );
}

sub _get_dbi_driver {
    my ( $available, %OPT ) = @_;
    if ( $OPT{MANUAL} ) {
        return get_response( "Choose a DBI driver to test.\n" .
                             "(Available in SPOPS and on your system: $available)\n" );
    }
    if ( $ENV{DBI_DSN} ) {
        my ( $driver ) = $ENV{DBI_DSN} =~ /^dbi:(\w*):/i;
        return $driver;
    }
    return $ENV{DBI_DRIVER}
}

sub _get_dbi_dsn {
    my ( $dbi_driver, %OPT ) = @_;
    my ( $given_dsn ) = $ENV{DBI_DSN} =~ /:([^:]*)$/;
    return $given_dsn unless ( $OPT{MANUAL} );
    print "\n";
    return get_response( "Please enter the tail end of the DSN to use\n" .
                         "for the driver you chose. Enter what would come\n ".
                         "after 'DBI:$dbi_driver:' in the normal connection.\n",
                         $given_dsn );
}

sub _get_dbi_user {
    my ( %OPT ) = @_;
    return $ENV{DBI_USER} unless ( $OPT{MANUAL} );
    print "\n";
    return get_response( "Please enter a username to connect to the\n" .
                         "specified data source.This user should be\n" .
                         "able to create and remove tables in the database.\n",
                         $ENV{DBI_USER} );
}

sub _get_dbi_password {
    my ( $dbi_user, %OPT ) = @_;
    return $ENV{DBI_PASS} unless ( $OPT{MANUAL} );
    print "\n";
    return get_response( "Please enter the password for user ($dbi_user)\n",
                         $ENV{DBI_PASS} );
}


# Find out whether to run LDAP test

sub check_ldap {
    my ( %OPT ) = @_;
    eval { require Net::LDAP };
    if ( $@ ) {
        print "You don't appear to have Net::LDAP installed; skipping LDAP tests.\n";
        return ();
    }
    unless ( $OPT{MANUAL} ) {
        my $host = $ENV{LDAP_HOST} || 'localhost';
        my $port = $ENV{LDAP_PORT} || 389;
        return ( $host, $port, $ENV{LDAP_BASE_DN},
                 $ENV{LDAP_BIND_DN}, $ENV{LDAP_BIND_PASS} );
    }


    my $do_test = lc get_response( "Would you like to run tests using LDAP? (Y/n)\n", 'Y' );
    if ( $do_test ne 'y' ) {
        print "Skipping LDAP tests due to lack of interest.\n";
        return ();
    }
    print "\n";

    print "We need some information about your LDAP setup to run tests:\n";
    my $ldap_host = lc get_response( "  Host? (localhost)    ", 'localhost' );
    my $ldap_port = lc get_response( "  Port? (389)          ", 389 );
    my $ldap_base_dn = get_response( "  Base DN?             ", $ENV{LDAP_BASE_DN} );
    print "I will create an OU and entries under ($ldap_base_dn) for testing,\n",
          "and then remove the OU when I'm finished.\n";
    my $ldap_bind_dn = get_response( "  Bind DN? (anonymous) ", 'anonymous bind' );
    $ldap_bind_dn = ( $ldap_bind_dn eq 'anonymous bind' ) ? '' : $ldap_bind_dn;
    my ( $ldap_password );
    if ( $ldap_bind_dn ) {
        $ldap_password = get_response( "  Bind password?       " );
    }
    return ( $ldap_host, $ldap_port, $ldap_base_dn, $ldap_bind_dn, $ldap_password );
}


# Set the sybase environment as necessary

sub set_sybase_env {
    my $sybhome = $ENV{SYBASE} || 'undefined';
    my $syb_set = lc get_response( "Current value of SYBASE environment " .
                                   "variable: [$sybhome]. Is this " .
                                   "correct? (Y/n)", 'Y' );
    if ( $syb_set ne 'y' ) {
        my $syb_env = get_response( 'Enter a value for the SYBASE ' .
                                    'environment variable',
                                    '/opt/sybase' );
        $EXTRA_INFO .= "ENV_SYBASE:     $syb_env\n";
    }
    print "\n";
}


# Set the oracle environment as necessary.

sub set_oracle_env {
    my $orahome = $ENV{ORACLE_HOME} || 'undefined';
    my $ora_set = lc get_response( "Current value of ORACLE_HOME environment " .
                                   "variable: [$orahome]. Is this " .
                                   "correct? (Y/n)", 'Y' );
    if ( $ora_set ne 'y' ) {
        my $ora_env = get_response( 'Enter a value for the ORACLE_HOME ' .
                                    'environment variable',
                                    '/home/oracle/OraHome1' );
        $EXTRA_INFO .= "ENV_ORACLE_HOME:  $ora_env\n";
    }
    print "\n";
}


# Generic routine to read a response from the command-line (defaults,
# etc.) Note that return value has whitespace at the end/beginning of
# the routine trimmed.

sub get_response {
    my ( $msg, $default ) = @_;
    print $msg;
    $default = join( ', ', @{ $default } ) if ( ref $default eq 'ARRAY' );
    my $show_default = $default || 'no default';
    print " <$show_default> ";
    my $response = <STDIN>;
    chomp $response;
    $response = $default if ( $response =~ /^\s*$/ );
    $response =~ s/^\s+//;
    $response =~ s/\s+$//;
    return $response;
}


