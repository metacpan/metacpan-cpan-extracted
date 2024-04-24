package Net::SSH::Putty;

=pod

=head1 NAME

Net::SSH::Putty - Perl module to execute SSH sessions with Putty in batch mode

=cut

use warnings;
use strict;
use Moo 2.000001;
use Types::Standard 1.000005 qw(Str ArrayRef);
use namespace::clean 0.25;
use File::Spec;
use Carp;
use File::Temp qw/:POSIX/;

our $VERSION = '0.003'; # VERSION

=head1 SYNOPSIS

    use Net::SSH::Putty;

    my $ssh = Net::SSH::Putty->new({ host => $fqdn, user => $user, password => $password});
    $ssh->exec(['. .bash_profile', $cmd]);

=head1 DESCRIPTION

This module implements a L<Moo> based class to interact with Putty program for non-interactive SSH sessions from MS Windows hosts.

=head2 MOTIVATIONS

Inspiration from this module came from the necessity to have non-interactive SSH session working on Windows. Initially this was attempted
with L<Net::SSH::Any> (using L<Net::SSH::Any::Backend::Plink_Cmd>) with a certain degree of success, but as soon things get more complicated (like
creating multiple SSH sessions using L<threads>) sessions started failing without further explanation or error messages.

The combination of MS Windows, Perl and SSH is historically problematic too.

Since the author didn't need any interaction within the SSH sessions (like executing a command, reading the output and taking some conditional action), a simple
solution would be C<fork> the C<plink.exe> executable with a set of commands already defined (that I'll name of "batch mode" from now).

=head2 ATTRIBUTES

These are the attributes defined for the Net::SSH::Putty class:

=head3 user

Read-only and required for object instantiation.

The SSH login to be used for authentication.

=cut

has user => ( is => 'ro', isa => Str, required => 1, reader => 'get_user' );

=head3 password

The SSH login password to be used for authentication.

=cut

has password =>
  ( is => 'ro', isa => Str, required => 1, reader => 'get_password' );

=head3 host

Read-only and required for object instantiation.

The FQDN to connect through SSH.

=cut

has host => ( is => 'ro', isa => Str, required => 1, reader => 'get_host' );

=head3 putty_path

Read-only.

The complete pathname to the location where Putty program is installed. By default, it is C<C:\Program Files (x86)\Putty>.

=cut

has putty_path => (
    is       => 'ro',
    isa      => Str,
    required => 0,
    reader   => 'get_putty_path',
    default  =>
      sub { File::Spec->catdir( ( 'C:', 'Program Files (x86)', 'PuTTY' ) ) }
);

=head3 output

Read-only.

Stores an array reference containing the last command (executed through the SSH connection) output.

=cut

has output => (
    is       => 'ro',
    isa      => ArrayRef [Str],
    required => 0,
    reader   => 'get_output',
    writer   => '_set_output',
    default  => sub { [] }
);

=head2 METHODS

=head3 get_user

Getter for C<user>.

=head3 get_password

Getter for C<password>.

=head3 get_putty_path

Getter for C<putty_path>.

=head3 get_output

Getter for C<output>.

=head3 get_host

Getter for C<host>.

=head3 exec_plink

Connects to the host with C<plink.exe> and execute the commands passed as parameters.

Expects as parameters an array references with the commands to execute.

Returns true or false (in Perl sense) if the commands were executed successfully or not.

This method also sets the C<output> attribute.

=cut

sub exec_plink {
    my ( $self, $cmds_ref ) = @_;
    confess('command parameter must be an array reference')
      unless ( ref($cmds_ref) eq 'ARRAY' );
    my $log  = tmpnam();
    my $cmds = File::Temp->new();

    foreach my $cmd ( @{$cmds_ref} ) {
        print $cmds "$cmd\n";
    }

    $cmds->close();
    my @params = (
        '-ssh', '-batch', '-l', $self->get_user, '-pw', $self->get_password,
        '-m',   $cmds->filename, $self->get_host, '>', $log, '2>&1',
    );
    my $prog    = File::Spec->catfile( $self->get_putty_path, 'plink.exe' );
    my $cmd     = '"' . $prog . '" ' . join( ' ', @params );
    my $exec_ok = 0;
    my $ret     = system $cmd;

    unless ( $ret == 0 ) {

        if ( $? == -1 ) {
            print "failed to execute: $!\n";
        }
        elsif ( $? & 127 ) {
            printf "child died with signal %d, %s coredump\n",
              ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
        }
        else {
            printf "child exited with value %d\n", $? >> 8;
        }

    }
    else {
        $exec_ok = 1;
    }

    $self->_set_output( $self->_read_out($log) );
    return $exec_ok;
}

sub _read_out {
    my ( $self, $log ) = @_;
    open( my $in, '<', $log ) or croak "Cannot read $log: $!";
    my @log = <$in>;
    close $log or croak "Cannot close $log: $!";
    chomp @log;
    carp 'output file read is empty' unless ( scalar(@log) > 0 );
    return \@log;
}

=head3 download

This methods allow a instance to download a single file with C<psftp.exe> program.

Expects as positional parameters:

=over

=item *

The remote path to the directory containing the file.

=item *

The filename of the file on the remote location.

=item *

The local directory to be used as repository.

=back

The method will C<fork> C<psftp.exe> and execute the commands:

=over

=item 1.

cd

=item 2.

lcd

=item 3.

get

=item 4.

del

=back

In that sequence. Beware that the remote file will be removed from the SSH server then.

Returns true or false (in Perl sense) if the commands were executed successfully or not.

=cut

sub download {
    my ( $self, $remote_dir, $remote_file, $local_dir ) = @_;
    my @cmds = (
        "cd $remote_dir",
        "lcd \"$local_dir\"",
        "get $remote_file",
        "del $remote_file"
    );
    my $cmds = File::Temp->new();

    foreach my $cmd (@cmds) {
        print $cmds "$cmd\n";
    }

    $cmds->close();
    my $log = tmpnam();

    my @params = (
        '-batch', '-l', $self->get_user, '-pw', $self->get_password, '-b',
        $cmds->filename, $self->get_host, '>', $log, '2>&1'
    );
    my $prog    = File::Spec->catfile( $self->get_putty_path, 'psftp.exe' );
    my $cmd     = '"' . $prog . '" ' . join( ' ', @params );
    my $exec_ok = 0;
    my $ret     = system($cmd);

    unless ( $ret == 0 ) {

        if ( $? == -1 ) {
            print "failed to execute: $!\n";
        }
        elsif ( $? & 127 ) {
            printf "child died with signal %d, %s coredump\n",
              ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
        }
        else {
            printf "child exited with value %d\n", $? >> 8;
        }

    }
    else {
        $exec_ok = 1;
    }

    $self->_set_output( $self->_read_out($log) );
    sleep 1;
    unlink $log or warn "Could not remove $log: $!";
    return $exec_ok;
}

=head3 read_log

A experimental method.

You can setup the C<plink.exe> program to generate a log file of the SSH session, but the log contains binary information.

This method tries to read those contents and return an array reference with only the text from it.

Expects as parameter the complete path to this "binary" log file.

=cut

sub read_log {
    my ( $self, $log ) = @_;
    my @log;

    #Incoming packet #0xd, type 94 / 0x5e (SSH2_MSG_CHANNEL_DATA)
    my $data_regex  = qr/^Incoming\spacket.*\(SSH2_MSG_CHANNEL_DATA\)$/;
    my $other_regex = qr/^\w+/;
    open( my $in, '<', $log ) or croak "Cannot read log on $log: $!";
    my $is_data = 0;
    my $line;

    while (<$in>) {
        chomp;

        if ( $_ =~ $data_regex ) {
            $is_data = 1;
            next;
        }

        if ( ($is_data) and ( $_ !~ $other_regex ) ) {
            my @columns = split( /\s{2}/, $_ );

  #  00000000  00 00 01 00 00 00 00 48 20 31 36 3a 34 34 3a 35  .......H 16:44:5
  #00 00 01 00 00 00 00 48 20 31 36 3a 34 34 3a 35
            if ( substr( $columns[2], 0, 8 ) eq '00 00 01' )
            {    # "control" characters, or whatever they really mean
                my @tmp = split( /\s/, substr( $columns[2], 24 ) );

                foreach my $chr (@tmp) {

                    if ( $chr eq '0a' ) {
                        push( @log, $line ) if ( defined($line) );
                        $line = undef;
                    }
                    else {
                        $line .= chr( hex($chr) );
                    }

                }

            }
            else {
                my @tmp = split /\s/, $columns[2];

                # TODO: duplicated code from above
                foreach my $chr (@tmp) {

                    if ( $chr eq '0a' ) {
                        push @log, $line if ( defined($line) );
                        $line = undef;
                    }
                    else {
                        $line .= chr hex $chr;
                    }

                }
            }
            next;
        }

        if ( $_ =~ $other_regex ) {
            $is_data = 0;
        }

    }

    close $in or croak "Cannot read log on $log: $!";;
    return \@log;
}

=head1 LIMITATIONS

This program is a hack, not a robust solution. Keep that in mind if you're going to execute it with any kind of monitoring.

The C<download> method is not very flexible. If you need to download a series of files, it will be inefficient since multiple SFTP sessions
will be open instead of a single one. Maybe in the future this might change.

Also, since C<read_log> is experimental and output redirection on MS Windows requires using C<system> invoking the shell, this might be considered
insecure if malicious values are used during object creation. Taint mode is not active in this module.

=head1 SEE ALSO

=over

=item *

L<Net::SSH::Any>

=item *

L<https://github.com/salva/p5-Net-SSH-Any/issues/2>

=item *

L<Dist::Zilla> is used to setup this distribution.

=item *

L<http://www.putty.org/>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 of Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

This file is part of net-ssh-putty project.

net-ssh-putty is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

net-ssh-putty is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with net-ssh-putty.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
