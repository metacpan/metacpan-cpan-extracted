#!perl -T
use warnings;
use strict;

use Test::More tests => 32;
use MojoX::Log::Dispatch;
#some test from Log::Dispatche module
use File::Spec;
use File::Temp qw( tempdir );
use Log::Dispatch::File;
use Log::Dispatch::Handle;
use Log::Dispatch::Null;
use Log::Dispatch::Screen;


use IO::File;

my $tempdir = tempdir( CLEANUP => 1 );
my $dispatch = MojoX::Log::Dispatch->new();


ok( $dispatch, "created MojoX::Log::Dispatch object" );


=over 4

=item debug

=item info

=item notice

=item warning (=warn for Mojo::Log compatibility )

=item error

=item critical

=item alert

=item emergency (=fatal for Mojo::Log compatibility )
=cut

# Test Log::Dispatch::File
{
    my $warning_log = File::Spec->catdir( $tempdir, 'emerg.log' );
	my $dispatch = MojoX::Log::Dispatch->new();
    $dispatch->add( Log::Dispatch::File->new( name => 'warning_file1',
                                              min_level => 'warning',
                                              filename => $warning_log ) );

    ok( $dispatch->is_warning, "ok is_warning");
    ok( $dispatch->is_warn, "ok is_warn");
    ok( $dispatch->is_error, "ok is_error");
    ok( $dispatch->is_critical, "ok is_critical");
    ok( $dispatch->is_alert, "ok is_alert");
    ok( $dispatch->is_emergency, "ok is_emergency");
    ok( $dispatch->is_fatal, "ok is_fatal");
    ok( $dispatch->is_err, "ok is_err");
    ok( $dispatch->is_emerg, "ok is_emerg");
    ok( $dispatch->is_crit, "ok is_crit");
    ok( !$dispatch->is_debug, "it isnt debug");
    ok( !$dispatch->is_info, "it isnt info");
    ok( !$dispatch->is_notice, "it isnt notice");
   
    
}    

# Test Log::Dispatch::File
{
    my $emerg_log = File::Spec->catdir( $tempdir, 'emerg.log' );
	my $dispatch = MojoX::Log::Dispatch->new();
    $dispatch->add( Log::Dispatch::File->new( name => 'file1',
                                              min_level => 'emerg',
                                              filename => $emerg_log ) );

    ok( $dispatch->is_emerg, "ok is_emerg");
    ok(!$dispatch->is_error, "ok it isnt is_error");
    $dispatch->info("info level 1\n" );
    $dispatch->emerg("emerg level 1\n");

    my $debug_log = File::Spec->catdir( $tempdir, 'debug.log' );

    $dispatch->add( Log::Dispatch::File->new( name => 'file2',
                                              min_level => 'debug',
                                              filename => $debug_log ) );

    $dispatch->log(  'info',  "info level 2\n" );
    $dispatch->log(  'emerg',  "emerg level 2\n" );

    # This'll close them filehandles!
    undef $dispatch;

    open my $emerg_fh, '<', $emerg_log
        or die "Can't read $emerg_log: $!";
    open my $debug_fh, '<', $debug_log
        or die "Can't read $debug_log: $!";

    my @log = <$emerg_fh>;
    is( $log[0], "emerg level 1\n",
        "First line in log file set to level 'emerg' is 'emerg level 1'" );

    is( $log[1], "emerg level 2\n",
        "Second line in log file set to level 'emerg' is 'emerg level 2'" );

    @log = <$debug_fh>;
    is( $log[0], "info level 2\n",
        "First line in log file set to level 'debug' is 'info level 2'" );

    is( $log[1], "emerg level 2\n",
        "Second line in log file set to level 'debug' is 'emerg level 2'" );
}

# max_level test
{
    my $max_log = File::Spec->catfile( $tempdir, 'max.log' );

    my $dispatch = MojoX::Log::Dispatch->new();
    $dispatch->add( Log::Dispatch::File->new( name => 'file1',
                                              min_level => 'debug',
                                              max_level => 'crit',
                                              filename => $max_log ) );

    $dispatch->emerg("emergency\n" );
    $dispatch->crit( "critical\n" );

    undef $dispatch; # close file handles

    open my $fh, '<', $max_log
        or die "Can't read $max_log: $!";
    my @log = <$fh>;

    is( $log[0], "critical\n",
        "First line in log file with a max level of 'crit' is 'critical'" );
}

# Log::Dispatch single callback
{
    my $reverse = sub { my %p = @_;  return reverse $p{message}; };
    my $dispatch = MojoX::Log::Dispatch->new( callbacks => $reverse );

    my $string;
    $dispatch->add( Log::Dispatch::String->new( name => 'foo',
                                                string => \$string,
                                                min_level => 'warning',
                                                max_level => 'alert',
                                              ) );

    $dispatch->warning('esrever' );

    is( $string, 'reverse',
        "callback to reverse text" );
}

# Log::Dispatch multiple callbacks
{
    my $reverse = sub { my %p = @_;  return reverse $p{message}; };
    my $uc = sub { my %p = @_; return uc $p{message}; };

    my $dispatch = MojoX::Log::Dispatch->new( callbacks => [ $reverse, $uc ] );

    my $string;
    $dispatch->add( Log::Dispatch::String->new( name => 'foo',
                                                string => \$string,
                                                min_level => 'warning',
                                                max_level => 'alert',
                                              ) );

    $dispatch->log(  'warning' => 'esrever' );

    is( $string, 'REVERSE',
        "callback to reverse and uppercase text" );
    ok($dispatch->is_error, "it is error");
    ok(!$dispatch->is_emergency, "it is not emergency");  
    ok(!$dispatch->is_info, "it is not info");
    ok(!$dispatch->is_fatal, "it is not fatal");   
}

# Log::Dispatch::Output single callback
{
    my $reverse = sub { my %p = @_;  return reverse $p{message}; };

    my $dispatch = MojoX::Log::Dispatch->new;

    my $string;
    $dispatch->add( Log::Dispatch::String->new( name => 'foo',
                                                string => \$string,
                                                min_level => 'warning',
                                                max_level => 'alert',
                                                callbacks => $reverse ) );

    $dispatch->log( 'warning' => 'esrever' );

    is( $string, 'reverse',
        "Log::Dispatch::Output callback to reverse text" );
}

# Log::Dispatch::Output multiple callbacks
{
    my $reverse = sub { my %p = @_;  return reverse $p{message}; };
    my $uc = sub { my %p = @_; return uc $p{message}; };

    my $dispatch = MojoX::Log::Dispatch->new;

    my $string;
    $dispatch->add( Log::Dispatch::String->new( name => 'foo',
                                                string => \$string,
                                                min_level => 'warning',
                                                max_level => 'alert',
                                                callbacks => [ $reverse, $uc ] ) );

    $dispatch->log(  'warning' => 'esrever' );

    is( $string, 'REVERSE',
        "Log::Dispatch::Output callbacks to reverse and uppercase text" );
}

# test level paramter to callbacks
{
    my $level = sub { my %p = @_; return uc $p{level}; };

    my $dispatch = MojoX::Log::Dispatch->new( callbacks => $level );

    my $string;
    $dispatch->add( Log::Dispatch::String->new( name => 'foo',
                                                string => \$string,
                                                min_level => 'warning',
                                                max_level => 'alert',
                                                stderr => 0 ) );

    $dispatch->log( 'warning' => 'esrever' );

    is( $string, 'WARNING',
        "Log::Dispatch callback to uppercase the level parameter" );
}

# dispatcher exists
{
    my $dispatch = MojoX::Log::Dispatch->new;

    $dispatch->add
        ( Log::Dispatch::Screen->new( name => 'yomama',
                                      min_level => 'alert' ) );

    ok( $dispatch->output('yomama'),
        "yomama output should exist" );

    ok( ! $dispatch->output('nomama'),
        "nomama output should not exist" );
}


package Log::Dispatch::String;

use strict;

use Log::Dispatch::Output;

use base qw( Log::Dispatch::Output );


sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %p = @_;

    my $self = bless { string => $p{string} }, $class;

    $self->_basic_init(%p);

    return $self;
}

sub log_message
{
    my $self = shift;
    my %p = @_;

    ${ $self->{string} } .= $p{message};
}

# Used for testing Log::Dispatch::Screen
package Test::Tie::STDOUT;

sub TIEHANDLE
{
    my $class = shift;
    my $self = {};
    $self->{string} = shift;
    ${ $self->{string} } ||= '';

    return bless $self, $class;
}

sub PRINT
{
    my $self = shift;
    ${ $self->{string} } .= join '', @_;
}

sub PRINTF
{
    my $self = shift;
    my $format = shift;
    ${ $self->{string} } .= sprintf($format, @_);
}

#line 10000
package Croaker;

sub croak
{
    my $log = shift;

    $log->log_and_croak( level => 'error', message => 'croak' );
}












