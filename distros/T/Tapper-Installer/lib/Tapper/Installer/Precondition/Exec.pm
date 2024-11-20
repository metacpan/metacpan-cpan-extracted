package Tapper::Installer::Precondition::Exec;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Installer::Precondition::Exec::VERSION = '5.0.3';
use 5.010;
use strict;
use warnings;

use Moose;
use IO::Handle; # needed to set pipe nonblocking
use IO::Select;

extends 'Tapper::Installer::Precondition';




sub set_env_variables
{
        my ($self) = @_;

        $ENV{TAPPER_TESTRUN}         = $self->cfg->{test_run};
        $ENV{TAPPER_SERVER}          = $self->cfg->{mcp_host};
        $ENV{TAPPER_REPORT_SERVER}   = $self->cfg->{report_server};
        $ENV{TAPPER_REPORT_API_PORT} = $self->cfg->{report_api_port};
        $ENV{TAPPER_REPORT_PORT}     = $self->cfg->{report_port};
        $ENV{TAPPER_HOSTNAME}        = $self->cfg->{hostname};
        return;
}


sub install
{
        my  ($self, $exec) = @_;

        my $command = $exec->{command};
        my @options;
        @options = @{$exec->{options}} if $exec->{options};

        if ($exec->{filename}) {
                $command = $exec->{filename};
                my $cmd_full = $self->cfg->{paths}{base_dir}.$command;
                if (not -x $cmd_full) {
                        $self->log_and_exec ("chmod", "ugo+x", $cmd_full);
                        return("tried to execute $cmd_full which is not an execuable and can not set exec flag") if not -x $cmd_full;
                }
        }

        $self->log->debug("executing $command with options ",join (" ",@options));


        pipe (my $read, my $write);
        return ("Can't open pipe:$!") if not (defined $read and defined $write);

        # we need to fork for chroot
        my $pid = fork();
        return "fork failed: $!" if not defined $pid;

        # hello child
        if ($pid == 0) {
                $self->set_env_variables;

                close $read;
                # chroot to execute script inside the future root file system
                my ($error, $output) = $self->log_and_exec("mount -o bind /dev/ ".$self->cfg->{paths}{base_dir}."/dev");
                ($error, $output)    = $self->log_and_exec("mount -t sysfs sys ".$self->cfg->{paths}{base_dir}."/sys");
                ($error, $output)    = $self->log_and_exec("mount -t proc proc ".$self->cfg->{paths}{base_dir}."/proc");
                my $arch = $exec->{arch} // "";
		if ($arch eq 'linux32') {
			Linux::Personality::personality(Linux::Personality::PER_LINUX32());
		}
                chroot $self->cfg->{paths}{base_dir};
                chdir ("/");
                %ENV = (%ENV, %{$exec->{environment} || {} });
                ($error, $output)=$self->log_and_exec($command,@options);
                print( $write $output, "\n") if $output;
                close $write;
                exit $error;
        } else {
                close $write;
                my $select = IO::Select->new( $read );
                my ($error, $output);
        MSG_FROM_CHILD:
                while (my @ready = $select->can_read()){
                        my $tmpout = <$read>;   # only read can be in @ready, since no other FH is in $select
                        last MSG_FROM_CHILD if not $tmpout;
                        $output.=$tmpout;
                }
                if ($output) {
                        my $outfile = $command;
                        $outfile =~ s/[^A-Za-z_-]/_/g;
                        $self->file_save($output,$outfile);
                }
                ($error, $output)=$self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/dev");
                ($error, $output)=$self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/sys");
                ($error, $output)=$self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/proc");
                waitpid($pid,0);
                if ($?) {
                        return("executing $command failed");
                }
                return(0);
        }
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Installer::Precondition::Exec

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Exec;

=head1 NAME

Tapper::Installer::Precondition::Exec - Execute a program inside the installed system

=head1 FUNCTIONS

=head2 set_env_variables

Set environment variables for executed command/program.

=head2 install

This function executes a program inside the installed system. This supersedes
the postinstall script facility of the package precondition and makes this
feature available to all other preconditions.

@param hash reference - contains all information about the program

@return success - 0
@return error   - error string

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
