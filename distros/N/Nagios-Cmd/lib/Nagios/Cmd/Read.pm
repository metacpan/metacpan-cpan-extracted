###########################################################################
#                                                                         #
# Nagios::Cmd::Read                                                       #
# Written by Albert Tobey <albert.tobey@priority-health.com>              #
# Copyright 2003, Albert P Tobey                                          #
#                                                                         #
# This program is free software; you can redistribute it and/or modify it #
# under the terms of the GNU General Public License as published by the   #
# Free Software Foundation; either version 2, or (at your option) any     #
# later version.                                                          #
#                                                                         #
# This program is distributed in the hope that it will be useful, but     #
# WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       #
# General Public License for more details.                                #
#                                                                         #
###########################################################################
package Nagios::Cmd::Read;
use vars qw( @ISA $do_lock $do_seek );
use Fcntl qw(:flock SEEK_SET);
use Carp;
use Symbol;
use POSIX qw( O_RDONLY O_NONBLOCK O_EXCL );
@ISA = qw( Exporter Nagios::Cmd );

$do_lock = undef;
$do_seek = undef;

##
## NOTE: the sys* functions are used to better resemble what Nagios actually does
## and to avoid problems with buffering.  Although seek() is useless when working
## with fifo's, it is necessary when using a regular file.  This is used for doing
## testing and debugging.  The seek() does not cause any problems when used on a
## fifo.
##

=head1 NAME

Nagios::Cmd

=head1 DESCRIPTION

A module for reading a fifo or regular file similar to the way Nagios does.

=head1 SYNOPSIS

 use Nagios::Cmd;
 use Nagios::Cmd::Read;
 use POSIX qw/mkfifo/;

 my $fifo = '/var/tmp/test.pipe';
 mkfifo( $fifo, 600 );
 my $writer = Nagios::Cmd->new( $fifo );
 my $reader = Nagios::Cmd::Read->new( $fifo );

 $writer->service_check('SSH', 'localhost', 0, 'version 1 waiting');
 print $reader->readcmd(), " was written to $fifo\n";

=head1 METHODS

=over 4

=item new()

Pass in the name of a fifo to open and read from.  The fifo must already exist.

 my $reader = Nagios::Cmd::Read->new( $fifo );

=cut

sub new {
    croak "$_[1] is not a pipe!" unless ( -p $_[1] );
    new_anyfile(@_);
}

=item new_anyfile()

Same as new, but can be any type of file such as regular files or /dev/null.

 my $reader = Nagios::Cmd::Read->new_anyfile( '/tmp/commands.txt' );

=cut

sub new_anyfile {
    my( $type, $cmdfile ) = @_;
    croak "$cmdfile does not exist!" unless ( -e $cmdfile );

    # open it as much like Nagios does as is possible from perl
    my $fh = gensym;
    sysopen( $fh, $cmdfile, O_RDONLY|O_NONBLOCK|O_EXCL )
        || croak "could not sysopen $cmdfile for reading: $!";

    bless \$fh, $type;
}

=item readcmd()

Read a single command.  Just like in Nagios, the filehandle is kept open for the
duration of the program.  If the target file is a regular file, sysseek() will
be used to rewind to the top of the file (which may not be what you want).

To turn of seeking for regular files, call $object->seek(undef);.

=cut

sub readcmd {
    my $self = shift;

    flock( $$self, LOCK_EX ) if ( $do_lock );

    sysseek( $$self, 0, SEEK_SET ) if ( $do_seek );
    my $rv = readline $$self;

    flock( $$self, LOCK_UN ) if ( $do_lock );

    return $rv;
}

=item seek()

Turn seek on/off.  Default is off.

 $reader->seek(undef); # turn off seeking
 $reader->seek(1);     # turn it back on

 Nagios::Cmd::Read::seek(undef);

=cut

sub seek {
    if ( !-f ${$_[0]} ) {
        carp "enabling seek for a named pipe or other special file!!!";
    }
    $do_seek = $_[1]
}

=item safe()

Turn use of flock() on/off.  Setting it to a defined value will enable
flock()ing of filehandles before reading.  Setting to undef turns it off.

 $reader->lock(1);     # turn on use of flock() around reads
 $reader->lock(undef); # turn it off

 Nagios::Cmd::Read::lock(1);

=cut

sub lock { $do_lock = $_[1] }

=back

=head1 AUTHOR

Al Tobey <tobeya@cpan.org>

=cut

sub DESTROY {
    close( ${$_[0]} );
}

1;
