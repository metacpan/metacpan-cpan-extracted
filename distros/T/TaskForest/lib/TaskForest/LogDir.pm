################################################################################
#
# $Id: LogDir.pm 211 2009-05-25 06:05:50Z aijaz $
# 
################################################################################

=head1 NAME

TaskForest::LogDir - Functions related to today's log directory

=head1 SYNOPSIS

 use TaskForest::LogDir;

 my $log_dir = &TaskForest::LogDir::getLogDir("/var/logs/taskforest");
 # $log_dir is created if it does not exist

=head1 DOCUMENTATION

If you're just looking to use the taskforest application, the only
documentation you need to read is that for TaskForest.  You can do this
either of the two ways:

perldoc TaskForest

OR

man TaskForest

=head1 DESCRIPTION

This is a simple package that provides a location for the getLogDir
function that's used in a few places.

=head1 METHODS

=cut

package TaskForest::LogDir;
use strict;
use warnings;
use Carp;
use TaskForest::LocalTime;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}

my $log_dir_cached;

# ------------------------------------------------------------------------------
=pod

=over 4

=item getLogDir()

 Usage     : my $log_dir = TaskForest::LogDir::getLogDir($root)
 Purpose   : This method creates a dated subdirectory of its first
             parameter, if that directory doesn't already exist.  
 Returns   : The dated directory
 Argument  : $root -   the parent directory of the dated directory
             $tz -     the timezone of the family, that determines the date
             $reload - If this is true, and we have a cached value,
                       return the cached value
 Throws    : "mkdir $log_dir failed" if the log directory cannot be
             created 

=back

=cut

# ------------------------------------------------------------------------------
sub getLogDir {
    my ($log_dir_root, $tz, $reload) = @_;
    
    #if ($log_dir_cached and !$reload) {
    #    return $log_dir_cached;
    #}

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
    if ($tz) { 
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &TaskForest::LocalTime::ft($tz);
    }
    else {
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &TaskForest::LocalTime::lt();
    }
        
    my $log_dir = sprintf("$log_dir_root/%4d%02d%02d", $year, $mon, $mday);
    unless (-d $log_dir) {
        if (mkdir $log_dir) {
            # do nothing - succeeded
        }
        else {
            croak "mkdir $log_dir failed in LogDir::getLogDir!\n";
        }
    }
    #$log_dir_cached = $log_dir;
    return $log_dir;
}


1;
