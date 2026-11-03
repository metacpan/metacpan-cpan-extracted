package Monitoring::Sneck::Checks::pid_file;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::pid_file - checks the process in a PID file is running

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    nginx_pid|perl:pid_file -f /var/run/nginx.pid -n nginx
    unbound_pid|perl:pid_file -f /var/run/local_unbound.pid

=head1 DESCRIPTION

Reads the PID file and checks the process is running, through kill 0,
which works without being able to signal it. A PID file that is not
there, or does not start with a PID, is CRITICAL, as is the process not
running, or with --name, being something else, as for a PID used again
after the one it was for died.

--name is checked through L<Proc::ProcessTable>, against the process
name, which Linux cuts to 15 characters.

=head1 OPTIONS

- -f, --file :: The PID file. Required.

- -n, --name :: The name the process must have.

=cut

sub option_spec { return ( 'file|f=s', 'name|n=s' ) }

sub required { return ('file') }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $file    = $self->opt('file');
	my $content = read_file( $file, err_mode => 'quiet' );
	return $self->finish( $self->CRITICAL, 'can not read ' . $file . ', ' . $! ) if !defined($content);
	my ($pid) = $content =~ /\A\s*([0-9]+)/;
	return $self->finish( $self->CRITICAL, $file . ' does not have a PID' ) if !defined($pid) || $pid < 1;

	# EPERM means it is there, just not ours to signal
	if ( !kill( 0, $pid ) && !$!{EPERM} ) {
		return $self->finish( $self->CRITICAL, $pid . ' from ' . $file . ' is not running' );
	}

	my $is = '';
	if ( defined( $self->opt('name') ) ) {
		require Proc::ProcessTable;
		my ($process) = grep { $_->pid == $pid } @{ Proc::ProcessTable->new->table };
		my $name = defined($process) ? $process->fname // '' : '';
		if ( $name ne $self->opt('name') ) {
			return $self->finish( $self->CRITICAL,
					  $pid
					. ' from '
					. $file . ' is '
					. ( $name eq '' ? 'not known' : $name )
					. ', not '
					. $self->opt('name') );
		}
		$is = ' ' . $name;
	} ## end if ( defined( $self->opt('name') ) )

	return $self->finish( $self->OK, $pid . $is . ' from ' . $file . ' is running' );
} ## end sub check

1;
