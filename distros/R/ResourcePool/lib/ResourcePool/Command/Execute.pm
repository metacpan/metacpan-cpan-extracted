#*********************************************************************
#*** ResourcePool::Command::Execute
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Execute.pm,v 1.10 2013-04-16 10:14:44 mws Exp $
#*********************************************************************
package ResourcePool::Command::Execute;

use ResourcePool::Command::Exception;
use vars qw($VERSION);
use Data::Dumper;

$VERSION = "1.0107";

sub execute($$@) {
	my ($self, $command, @addargs) = @_;
	my $try = $self->{MaxExecTry};
	my @rc = ();
	my $rep;

	$command->_resetReports();
	do {
 		$rep = ResourcePool::Command::Execute::Report->new();
		eval {
			$command->init();
		};
		$rep->setInitException($@);
		if (! $rep->getInitException()) {
			my $plain_rec = $self->get();
			if (defined $plain_rec) {
				eval {
					$command->preExecute($plain_rec);
				};
				$rep->setPreExecuteException($@);
				if (! $rep->getPreExecuteException()) {
					eval {
						@rc = $command->execute($plain_rec, @addargs);
					};
					$rep->setExecuteException($@);
					if (! $rep->getExecuteException()) {
						$self->executePostExecute($command, $rep, $plain_rec);
						#$self->executeRevertExecute($command, $rep, $plain_rec);
					} else {
						reportException($rep->getExecuteException(), 'execute');
						#$self->executeRevertExecute($command, $rep, $plain_rec);
					}
				} else {
					reportException($rep->getPreExecuteException(), 'preExecute');
				}
				if ($rep->tobeRepeated()) {
					$self->fail($plain_rec);
				} else {
					$self->free($plain_rec);
				}
			}
			$self->executeCleanup($command, $rep);
		} else {
			reportException($rep->getInitException(), 'init');
		}
		$command->_addReport($rep);
	} while ($rep->tobeRepeated() && ($try-- > 0));
	if (!$rep->ok()) {
		die ResourcePool::Command::Exception->new(
			  $rep->getException()
			, $command
			, ($self->{MaxExecTry} - $try) || 1
		);
	}
	if (wantarray) {
		return @rc;
	} else {
		return $rc[0];
	}
}

sub executePostExecute($$$$) {
	my ($self, $command, $rep, $plain_rec) = @_;
	eval {
		$command->postExecute($plain_rec);
	};
	$rep->setPostExecuteException($@);
	if ($rep->getPostExecuteException()) {
		reportIgnoredException($rep->getPostExecuteException(), 'postExecute');
	}
}

#sub executeRevertExecute($$$$) {
#	my ($self, $command, $rep, $plain_rec) = @_;
#	eval {
#		$command->revertExecute($plain_rec);
#	};
#	$rep->setRevertExecuteException($@);
#	if ($rep->getRevertExecuteException()) {
#		reportIgnoredException($rep->getRevertExecuteException(), 'revertExecute');
#	}
#}

sub executeCleanup($$$) {
	my ($self, $command, $rep) = @_;
	eval {
		$command->cleanup();
	};
	$rep->setCleanupException($@);
	if ($rep->getCleanupException()) {
		reportIgnoredException($rep->getCleanupException(), 'cleanup');
	}
}


sub getExceptionMessage($) {
	my ($ex) = @_;
	if (ref($ex)) {
		if (ResourcePool::Command::Execute::Report::isNoFailoverException($ex)) {
			return Dumper($ex->rootException());
		} else {
			return Dumper($ex);
		}
	} else {
		return $ex;
	}
}

sub reportException($$) {
	my ($ex, $method) = @_;
	warn('ResourcePool::Command->' . $method . '() failed: ' 
		. getExceptionMessage($ex)
	);
}

sub reportIgnoredException($$) {
	my ($ex, $method) = @_;
	warn('ResourcePool::Command->' . $method . '() ignored exception: ' 
		. getExceptionMessage($ex)
	);
}

package ResourcePool::Command::Execute::Report;
use vars qw($VERSION);

$VERSION = "1.0100";

sub new($) {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    return $self;
}

sub setInitException($$) {
	my ($self, $ex) = @_;
	$self->{InitException} = $ex;
}

sub setPreExecuteException($$) {
	my ($self, $ex) = @_;
	$self->{PreExecuteException} = $ex;
}

sub setExecuteException($$) {
	my ($self, $ex) = @_;
	$self->{ExecuteException} = $ex;
}

sub setPostExecuteException($$) {
	my ($self, $ex) = @_;
	$self->{PostExecuteException} = $ex;
}

sub setCleanupException($$) {
	my ($self, $ex) = @_;
	$self->{CleanupException} = $ex;
}

sub setRevertExecuteException($$) {
	my ($self, $ex) = @_;
	$self->{RevertExecuteException} = $ex;
}


sub getInitException($) {
	my ($self) = @_;
	return $self->{InitException};
}

sub getPreExecuteException($) {
	my ($self) = @_;
	return $self->{PreExecuteException};
}

sub getExecuteException($) {
	my ($self) = @_;
	return $self->{ExecuteException};
}

sub getPostExecuteException($) {
	my ($self) = @_;
	return $self->{PostExecuteException};
}

sub getCleanupException($) {
	my ($self) = @_;
	return $self->{CleanupException};
}

sub getRevertExecuteException($) {
	my ($self) = @_;
	return $self->{RevertExecuteException};
}

sub getException($) {
	my ($self) = @_;
	return $self->{InitException} 
		|| $self->{PreExecuteException}
		|| $self->{ExecuteException}
		|| $self->{PostExecuteException}
		|| $self->{CleanupException};
}

sub ok($) {
	my ($self) = @_;

	return !$self->getInitException()
		&& !$self->getPreExecuteException()
		&& !$self->getExecuteException
		&& !$self->getPostExecuteException;
}

#sub revertOk($) {
#	my ($self) = @_;
#	return $self->getPostExecuteException()
#		&& !$self->getRevertExecuteException();
#}

sub tobeRepeated($) {
	my ($self) = @_;

#	printf("tobeRepeated %d %d\n", (!$self->ok()), isNoFailoverException($self->getExecuteException()));
	return (!$self->ok()) && !isNoFailoverException($self->getException());
}

sub isNoFailoverException($) {
	my ($ex) = @_;
	my $rc;
	eval {
		$rc = $ex->isa('ResourcePool::Command::NoFailoverException');
	};
	if (! $@) {
		return $rc;	
	}
	return 0; # default, do failover
}
1;
