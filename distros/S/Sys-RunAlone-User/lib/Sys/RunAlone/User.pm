use strict;
use warnings;
package Sys::RunAlone::User;

our $VERSION= '0.01';
#ABSTRACT: make sure only one invocation of a script is active at a time per user

my $silent;
my $retry;
my $pid_file;
my $callback;

1;

sub import {
    shift;
    my($userName) = (getpwuid($>))[0]; 
    my %args= @_;
    $silent   = delete $args{silent};
    $retry    = delete $args{retry};
    $retry    = $ENV{RETRY_SYS_RUNALONE} if exists $ENV{RETRY_SYS_RUNALONE};

    my($dir)  = delete $args{pid_dir};
    my($file) = delete $args{pid_file};
    $callback = delete $args{callback};
    $dir    ||= "/tmp";
    $file   ||= "$userName-$0.lock";

    $pid_file = "$dir/$file";
    
    if ( my @unknown = sort keys %args ) {
        die "Don't know what to do with: @unknown";
    }
    return;
}

sub checkRunning {
    open my($LOCK), "<", $pid_file or return 0;
    chomp(my($pid) = <$LOCK>);
    close($LOCK);
    return kill(0, $pid);
}

INIT {
    no warnings;    
    if ( my $skip= $ENV{SKIP_SYS_RUNALONE_USER} ) {
        print STDERR "Skipping " . __PACKAGE__ . " check for '$0'\n"
          if !$silent and $skip > 1;
    }
    elsif ( checkRunning() ) {
        if ($retry) {
            my ( $times, $sleep )= split ',', $retry;
            $sleep ||= 1;
            while ( $times-- ) {
                sleep $sleep;
                goto ALLOK if !checkRunning();
            }
        }
        if(defined($callback)) {
            $callback->();
        } else {
            print STDERR "A copy of '$0' is already running\n" if !$silent;
        }
        exit 1;
    }

  ALLOK:
       open my($LOCK), ">", $pid_file;
       print $LOCK $$;
       close $LOCK;
}

END {
    open my($LOCK), "<", $pid_file;
    chomp (my($pid) = <$LOCK>);
    close $LOCK;
    unlink $pid_file if ($pid == $$);
}
__END__
=head1 NAME

Sys::RunAlone::User - make sure only one invocation of a script is active at a time per user

=head1 SYNOPSIS

 use Sys::RunAlone::User;
 # code of which there may only be on instance running for user

 use Sys::RunAlone::User silent => 1;
 # be silent if other running instance detected

 use Sys::RunAlone::User retry => 50;
 # retry execution 50 times with wait time of 1 second in between

 use Sys::RunAlone::User retry => '55,60';
 # retry execution 55 times with wait time of 60 seconds in between

 use Sys::RunAlone::User pid_dir => '/tmp';
 # set the directory to store the pid lock files (Default: /tmp)

 use Sys::RunAlone::User pid_file => 'filename.lock';
 # set the filename for the lock file, if this is used for multiple users it is adviseable to use a unique name

 use Sys::RunAlone::User callback => sub { };
 # set a anonymous callback function that will be executed if the script is already running and have reached the retry limit

=head1 DESCRIPTION

Provide a simple way to make sure the script from which this module is
loaded, is only running once on the server.  Optionally allow for retrying
execution until the other instance of the script has finished.

=head1 VERSION

This documentation describes version 0.01.

=head1 METHODS

There are no methods.

=head1 THEORY OF OPERATION

At INIT Time this module will create a PID lock file in the tmp directory
(or where you specified). If one already exists it will check the PID in the
file to see if it's running or not, if it is the script will exit with value 1
and execute the callback if one was provided.

If retry was set the script will continue to try and run, if it reaches the end
of tries it will exit and execute the callback if one was provided.


There are two forms of the retry value:

=over 4

=item times

 use Sys::RunAlone::User retry => 55;  # retry 55 times, with 1 second intervals

Specify the number of times to retry, with 1 second intervals.

=item times,seconds

 use Sys::RunAlone::User retry => '55,60'; # retry 55 times, with 60 second intervals

Specify both the number of retries as well as the number of seconds interval
between tries.

=back

This is particularly useful for minutely and hourly scripts that run a long
and sometimes run into the next period.  Instead of then not doing anything
for the next period, it will start processing again as soon as it is possible.
This makes the chance of catching up so that the period after the next period
everything is in sync again.

=head1 ACKNOWLEDGEMENTS

 Elizabeth Mattijsen for writing the original Sys::RunAlone

=head1 SEE ALSO

L<Sys::RunAlone>.

=head1 AUTHOR

 Madison Koenig <pedlar AT cpan DOT org>

=head1 COPYRIGHT

Copyright (c) 2012 Madison Koenig
All rights reserved.  This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut
