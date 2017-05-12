################################################################################
#
# $Id: Logs.pm 211 2009-05-25 06:05:50Z aijaz $
#
################################################################################

=head1 NAME

TaskForest::Logs - Functions related to logging 

=head1 SYNOPSIS

 use TaskForest::Logs qw/$log/;

 &TaskForest::Logs::init($banner); # print $banner and initialize the logger
                                   # this will also tie stdout to $log->info() 
                                   # and stderr to $log->error()

 # $log is a logger.  See Log::Log4perl
 $log->debug("Debug message");
 $log->info("Info message");
 $log->warn("Warn message");
 $log->error("Error message");
 $log->fatal("Fatal message");

 &TaskForest::Logs::resetLogs();
 # This will delete the error file if it is empty, and also untie
 # STDOUT and STDERR

=cut


package TaskForest::Logs;

use strict;
use warnings;
use Exporter;
use Data::Dumper;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/$log/;

use Log::Log4perl qw(get_logger :levels :nowarn);
use Log::Log4perl::Layout;
use Log::Log4perl::Level;

use TaskForest::OutLogger;
use TaskForest::ErrLogger;

our $log;
my $iappender;
my $eappender;
my $iobj;
my $eobj;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}


END {
    cleanup();
}
    
sub init {
    my $banner = shift;
    
    my $options = &TaskForest::Options::getOptions();
    my $log_dir = &TaskForest::LogDir::getLogDir($options->{log_dir});

    my $log_file = "$log_dir/$options->{log_file}";
    my $err_file = "$log_dir/$options->{err_file}";

    my $files = "$log_file\n$err_file";

    my $levels = { debug => $DEBUG, info => $INFO, warn => $WARN, error => $ERROR, fatal => $FATAL };
    
    # Define a category logger
    $log = get_logger("ENoor");
    $log->level($levels->{$options->{log_threshold}});

    # Define a layout
    my $layout = Log::Log4perl::Layout::PatternLayout::Multiline->new("%d %6p %4L:%-32F{1} - %m%n");

    if (!$options->{log}) {
        return;
    }

    # Define 2 file appenders
    if ($iappender and $eappender) {
        $iappender->file_switch($log_file);
        $eappender->file_switch($err_file);
        $iappender->threshold($levels->{$options->{log_threshold}});
    }
    else {
        print "$files\n";
        $iappender = Log::Log4perl::Appender->new( "Log::Log4perl::Appender::File",
                                                   filename  => $log_file,
                                                   mode      => 'append');
        
        $eappender = Log::Log4perl::Appender->new( "Log::Log4perl::Appender::File",
                                                   filename  => $err_file,
                                                   mode      => 'append');
        
        $iappender->threshold($levels->{$options->{log_threshold}});
        $eappender->threshold($WARN);

        $iappender->layout($layout);
        $eappender->layout($layout);
        
        $log->add_appender($iappender);
        $log->add_appender($eappender);
    }
    
    
    $iobj = tie (*STDOUT, 'TaskForest::OutLogger');    
    $eobj = tie (*STDERR, 'TaskForest::ErrLogger');    

    if ($banner) { 
        print "********************************************************************************\n$banner\n";
    }
    
}

sub resetLogs {
    my $options = &TaskForest::Options::getOptions();

    my $err_file = "$options->{log_dir}/$options->{err_file}";
    
    unless (-s $err_file) {
        if ($log) { 
            $log->info("Deleting error log because it is empty\n");
        }
        unlink $err_file;
    }
    else {
        # need to send email
    }
    
    if ($iobj) { 
        undef $iobj;
        untie(*STDOUT);
    }
    if ($eobj) { 
        undef $eobj;
        untie(*STDERR);
    }
    undef $log;
}

sub cleanup {
    my $exit_code = $?;

    my $message = "Exiting $exit_code";

    #print "$message\n";

    resetLogs();    

}
    
    


1;
