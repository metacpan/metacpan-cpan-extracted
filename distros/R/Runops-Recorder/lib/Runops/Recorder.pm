package Runops::Recorder;

use 5.010;

use strict;
use warnings;

use Carp;
use File::Path qw(make_path);
use POSIX qw(strftime);

use constant DEFAULT_BUFFER_SIZE => 64 * 1024;

our $VERSION = '0.09';

require XSLoader;
XSLoader::load('Runops::Recorder', $VERSION);

sub import {
    my ($pkg, @opts) = @_;
    
    my $target_dir;
    $target_dir = $opts[0] if defined $opts[0] && $opts[0] !~ /^-/;
    
    unless ($target_dir) {
        unless ($ENV{RR_TARGET_DIR}) {
            $target_dir //= strftime("rr-%Y%m%d_%H%M%S", localtime(time));
        }
        else {
            $target_dir = $ENV{RR_TARGET_DIR};
        }
    }
    
    unless (-e -d $target_dir) {
        make_path $target_dir;
    }
    
    set_target_dir($target_dir);

    my $size = _get_buffer_size(\@opts);
    set_buffer_size($size);
    
    # Set options
    my $opts = 0;

    # This option turns on actual writing to disc for the continous store,
    # it's ment to be disabled when -die is in effect
    $opts |= 0x1;
    $opts ^= 0x1 if grep { $_ eq "-nostore" } @opts;
    
    # This option controls wether the buffer should be dumped into a file 
    # when an exception is thrown
    $opts |= 0x2 if grep { $_ eq "-die"} @opts;

    set_options($opts);
    
    # Maybe disable optimizer
    $^P = 4 if grep { $_ eq "-noopt" } @opts;
    
    init_recorder();
}

my %Size_multiplier = ( 
    G => 1_073_741_824, M => 1_048_576, K => 1024,
    g => 1_000_000_000, m => 1_000_000, k => 1000,
);

sub _get_buffer_size {
    my $opts = shift;
    
    for my $opt (@$opts) {
        if ($opt =~ /^-bs=(\d+(?:\.\d+)?)([GMK])?/i) {
            return $2 ? $1 * $Size_multiplier{$2} : int $1;    
        }
    }
    
    return DEFAULT_BUFFER_SIZE;
}

1;
__END__
=head1 NAME

Runops::Recorder - Runops replacement which saves what is being performed

=head1 SYNOPSIS

  # will save to a rr-<timestamp> directory in the current directory
  perl -MRunops::Recorder <program>

  # will save to a custom directory 
  perl -MRunops::Recorder=my_recording <program>
  
  # and then to view the recording
  rr-viewer <path to recording>
  
=head1 DESCRIPTION

Runops::Recorder is an alternative runops which saves what it does into a file 
that can later be viewed using the rr-viewer tool.

=head1 HOW TO RECORD

Simply use this module and it'll replace perl's standard runloop with its own. By 
default a recording goes into a directory named rr-<date>-_<time>. If you want an 
alternate name just pass it as the first argument to the use (eg -MRunops::Recorder=foo). 

Sometimes perl will optimize away COPs and this may look confusing when viewing. If you 
want to turn of the optimizer pass C<-noopt> when using this module.

It's possible to adjust the buffer size which is how much it'll keep in memory before flushing 
it to disk. This is done by passing C<-bs=SIZE> where SIZE is a number followed by an optional G/M/K/g/m/k 
to denote the multiple. G, M and K are base-2 and g, m, k base-10. So 512K would be 524288 bytes. 
If ommited a default of 64K is used. The minimum size is 128 bytes.

It is possible to prevent continous store to disk with C<-nostore>. This is ment to be used 
with C<-die> that dumps the buffer to disk when an exception occurs.

=head1 VIEWING THE RECORDING

Use the 'rr-viewer' tool. It just takes the path with the recording as an argument. 
Press 'q' to quit or any other key to step to the next event. Press 's' to skip any 
events in the current file until end of recording. Press 'a' to toggle wether we should 
skip whatever is in @INC when the recorder what loaded. Press 'h' for help.

The environment variable RR_AUTORUN tells the viewer to run automaticly. The value 
should be the sleep time until stepping. And yes, it uses Time::HiRes so you can 
give it fracitonal seconds.

If you set RR_SKIP_INC the autorun will not show @INC files as the 'a' option does.

=head1 FUNCTIONS

=over 4

=item dump ( $name )

Dumps the buffer as I<$name> in the recording. Adds .dump to the $name if 
ommited.

=back

=head1 TODO

Record more things such as changes to variables, opened file descriptors etc.

=head1 AUTHOR

Claes Jakobsson, E<lt>claesjac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Claes Jakobsson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
