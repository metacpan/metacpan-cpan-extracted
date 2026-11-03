#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
    use_ok('Monitoring::Sneck::Config') || print "Bail out!\n";
    use_ok('Monitoring::Sneck')         || print "Bail out!\n";
}

my $dir = tempdir( CLEANUP => 1 );

# Writes a file with the given content.
sub write_file {
    my ( $file, $content ) = @_;
    open( my $fh, '>', $file ) or die( 'failed to write "' . $file . '"... ' . $! );
    print $fh $content;
    close($fh);
    return $file;
}

# Returns the errors of a sneck format config string as "where: message" strings.
sub errors_of {
    my ($content) = @_;
    return [ map { $_->{where} . ': ' . $_->{message} } Monitoring::Sneck::Config->new( { raw => $content } )->errors ];
}

# Writes a config and runs it, returning the data section.
my $config_count = 0;
sub run_config {
    my ($content) = @_;
    $config_count++;
    my $file = write_file( $dir . '/run' . $config_count . '.conf', $content );
    my $returned = Monitoring::Sneck->new(
        { config => $file, compliance_state_file => $dir . '/state' . $config_count . '.json' } )->run;
    is( $returned->{error}, 0, 'config ' . $config_count . ' ran without error' )
        || diag( $returned->{errorString} );
    return $returned->{data};
}

#
# config checking
#
is_deeply( errors_of("a|perl:file_age -f /tmp/x\n%b|perl:http\n!c||perl:dns -H 'www.example.org'\n"),
    [], 'good perl checks' );
is_deeply(
    errors_of("a|perl:../etc\n%b|perl:Http -H x\n!c||perl:\nd|perl:http -s 'Welcome\n"),
    [
        'line 1: check "a" has a perl check name that is not valid, it must be a-z, 0-9, and _, starting with a letter',
        'line 2: debug check "b" has a perl check name that is not valid, it must be a-z, 0-9, and _, starting with a letter',
        'line 3: compliance check "c" has a perl check name that is not valid, it must be a-z, 0-9, and _, starting with a letter',
        'line 4: check "d" has unbalanced quotes in its perl check args',
    ],
    'bad perl checks'
);
is_deeply( errors_of("a|/usr/bin/perl:x\n"), [], 'only perl: at the start is a perl check' );
is_deeply(
    errors_of("a|/bin/true\n\@b|checks=a|perl:file_age -f /tmp/x\n\@c|checks=a|/usr/sbin/service perl:x restart\n"),
    [ 'line 2: restart "b" can not be a perl check' ],
    'restarts can not be perl checks'
);
is_deeply( errors_of("a|perl:file_age -f /tmp/x\n\@b|checks=a|/usr/sbin/service httpd restart\n"),
    [], 'restarts may watch perl checks' );

#
# running them
#
my $file = write_file( $dir . '/age', 'some data' );
{
    # Monitoring::Sneck::Checks being there or not, a failed load is the same
    local $INC{'Monitoring/Sneck/Checks.pm'} = undef;
    my $data = run_config("a|perl:file_age -f $file\n");
    is( $data->{checks}{a}{exit},  -1,                                          'not loadable is -1' );
    is( $data->{checks}{a}{error}, 'failed to load Monitoring::Sneck::Checks', 'and why' );
    is( $data->{errored},          1,                                           'counted as errored' );
}

SKIP: {
    skip( 'Monitoring::Sneck::Checks is not installed', 15 ) if !eval { require Monitoring::Sneck::Checks; 1 };

    my $data = run_config( "AGE_FILE=$file\n"
            . "fresh|perl:file_age -f %AGE_FILE% -w 60 -c 120\n"
            . "small|perl:file_age -f %AGE_FILE% -W '1024:' -C '100:'\n"
            . "%seen|perl:file_age -f %AGE_FILE%\n"
            . "!there||perl:file_age -f $dir/nope\n"
            . "base|perl:base\n"
            . "missing|perl:no_such_check\n"
            . "QUOTE='\n"
            . "quotes|perl:file_age -f %QUOTE%\n" );
    is( $data->{checks}{fresh}{exit}, 0, 'OK' );
    like( $data->{checks}{fresh}{output}, qr/^FILE_AGE OK - \Q$file\E is \d+ seconds old and 9 bytes \|/, 'its output' );
    is( $data->{checks}{fresh}{ran}, "perl:file_age -f $file -w 60 -c 120", 'variables put in place' );
    ok( !exists( $data->{checks}{fresh}{error} ), 'no error' );
    is( $data->{checks}{small}{exit},  2, 'CRITICAL, quoted args' );
    is( $data->{debugs}{seen}{exit},   0, 'debug check' );
    is( $data->{compliance}{there}{exit}, 2, 'compliance check' );
    is( $data->{checks}{base}{exit},   -1, 'base is -1' );
    is( $data->{checks}{base}{error},  'failed to load perl check base', 'and why' );
    like( $data->{checks}{base}{output}, qr/^base is what checks are built on/, 'with the output' );
    is( $data->{checks}{missing}{exit}, -1, 'a check not there is -1' );
    is( $data->{checks}{quotes}{exit}, 3, 'quotes unbalanced once vars are in is UNKNOWN' );
    is( $data->{checks}{quotes}{output}, 'FILE_AGE UNKNOWN - args have unbalanced quotes', 'and says so' );
    is( $data->{critical}, 1, 'counted' );
    is( $data->{errored},  2, 'the -1s are errored' );
    is( $data->{unknown},  1, 'the unbalanced quotes are unknown' );
}

done_testing();
