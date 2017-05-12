#!perl

use Test::More tests => 15;
use strict;
use warnings;
use Data::Dumper;
use_ok( 'File::Temp', qw(tempdir) );
use_ok('Config::Properties');

# Set CLEAN to 0 if you want to maintain the generated config files
use constant CLEAN => 1;

$ENV{'PATH'} = '/bin:/usr/bin';

# Check the version output
ok( !system("blib/script/logparser -v") );
ok( !system("blib/script/logparser -h") );

# There should be an error invoking logparser with a null config filex
ok( system("blib/script/logparser -f /dev/null 2>&1") );

my $dir = tempdir( 'CLEANUP' => CLEAN );

SKIP: {
    skip "Unable to create a temp dir with File::Temp to create temporary config files", 10 unless defined $dir;

    # diag("The config dir is $dir");
    my $configFile = File::Temp->new(
        'UNLINK'   => CLEAN,
        'TEMPLATE' => 'logparserXXXXX',
        'SUFFIX'   => '.conf',
        'DIR'      => $dir
    );
    my $configFileName = $configFile->filename;

    # diag("The config file name is $configFileName");
    my $log4perlFile = File::Temp->new(
        'UNLINK'   => CLEAN,
        'TEMPLATE' => 'log4perlXXXXX',
        'SUFFIX'   => '.conf',
        'DIR'      => $dir
    );
    my $log4perlFileName   = $log4perlFile->filename;
    my $propertiesFileName = File::Spec->catfile( $dir, 'logparser.properties' );
    my $storeFileName      = File::Spec->catfile( $dir, 'logparser.store' );
    my $lockFileName       = File::Spec->catfile( $dir, 'logparser.lock' );
    my $logFileName        = File::Spec->catfile( $dir, 'logparser.log' );

    my $testLogFile = File::Temp->new(
        'UNLINK'   => CLEAN,
        'TEMPLATE' => 'testLogXXXXX',
        'SUFFIX'   => '.log',
        'DIR'      => $dir
    );
    my $testLogFileName = $testLogFile->filename;

    createLog4PerlFile( $log4perlFile, $logFileName );
    createConfigFile( $configFile, $storeFileName, $propertiesFileName,
        $lockFileName, $testLogFileName, 'SNMP::LogParserDriver::ExampleDriver' );

    ok( !system("blib/script/logparser -f $configFileName -l $log4perlFile") );
    ok("-r $propertiesFileName");
    my $result = open PROPS, "$propertiesFileName";
  SKIP: {
        skip "Cannot open properties file, skipping rest of tests", 8 unless $result;
        my $properties = loadProperties($propertiesFileName);

        is( $properties->getProperty('counter'), 0 );
        is( $properties->getProperty('lines'),   0 );

        print $testLogFile "Non valid line";
        ok( !system( "blib/script/logparser -f $configFileName -l $log4perlFile" ));

        $properties = loadProperties($propertiesFileName);

        is( $properties->getProperty('counter'), 0 );
        is( $properties->getProperty('lines'),   1 );
        print $testLogFile "Embedded test string in line";

        ok( !system( "blib/script/logparser -f $configFileName -l $log4perlFile" ));
        $properties = loadProperties($propertiesFileName);
        is( $properties->getProperty('counter'), 1 );
        is( $properties->getProperty('lines'),   2 );
    }
}

sub createConfigFile {
    my ( $configFile, $storeFileName, $propertiesFileName, $lockFileName, $testLogFileName, $module ) = @_;
    my $date = localtime();

    print $configFile <<EOF;
# Automatically generated for $0 at $date
storeFile=$storeFileName
propertiesFile=$propertiesFileName
lockFile=$lockFileName
log.test.file=$testLogFileName
log.test.driver=$module
EOF
}

sub createLog4PerlFile {
    my ( $log4perlFile, $logFileName ) = @_;
    print $log4perlFile <<EOF;
log4perl.logger.logparser= DEBUG, Logparser
log4perl.appender.Logparser=Log::Dispatch::FileRotate
log4perl.appender.Logparser.filename=$logFileName
log4perl.appender.Logparser.DatePattern=yyyy-MM-dd-HH
log4perl.appender.Logparser.mode=append
log4perl.appender.Logparser.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logparser.layout.ConversionPattern=%d [%c] %m %n

log4perl.logger = ERROR, Screen
log4perl.appender.Screen=Log::Log4perl::Appender::Screen
log4perl.appender.Screen.Threshold=ERROR
log4perl.appender.Screen.stderr=1
log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern=%d [%c] %m %n
EOF
}

sub loadProperties {
    my $propertiesFileName = shift;
    open PROPS, "$propertiesFileName" or die "Cannot open $propertiesFileName: $!";
    my $properties = Config::Properties->new;
    $properties->load(*PROPS);
    close PROPS;
    return $properties;
}
