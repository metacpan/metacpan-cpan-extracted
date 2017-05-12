package Net::PSYC::MMP::State;

use Storable qw(dclone);
use strict;

sub outstate {
    my $self = shift;
    my ($mod, $var, $val) = @_;

    return 1 if ($mod eq ':');
    
    if ($mod eq '=') {
	$self->{'state'}->{$var} = $val;
	return 1;
    } elsif ($mod eq '+') {
	Net::PSYC::_augment($self->{'state'}, $var, $val);
	return 1;
    } elsif ($mod eq '-') {
	return 1 if (Net::PSYC::_diminish($self->{'state'}, $var, $val));
    }
    return 0;
}

sub state {
    {}
}

sub assign {
    my $self = shift;
    my ($var, $val) = @_;

    unless ($val) {
	delete $self->{'vars'}->{$var};
	return 1;
    }
    $self->{'vars'}->{$var} = $val;
    $self->negotiate($val) if ($var eq '_using_modules');
}

sub augment {
    my $self = shift;
    my ($var, $val) = @_; 
    Net::PSYC::_augment($self->{'vars'}, @_);
    
    $self->negotiate($val) if ($var eq '_using_modules');
}

sub diminish {
    my $self = shift;
    Net::PSYC::_diminish($self->{'vars'}, @_);
}

=old
sub new {
    my $class = shift;
    my $obj = shift;
    my $self = {
	'state' => {},
	'vars' => {},
	'state_temp' => {},
	'connection' => $obj,
    };
    return bless $self, $class;
}

sub init { 
    my $self = shift;
    # do state after encoding and stuff has been done, does not make a 
    # difference really
    $self->{'connection'}->hook('send', $self, -10);
    $self->{'connection'}->hook('sent', $self);
    $self->{'connection'}->hook('receive', $self, 10);
    # do encoding-stuff _after_ state. this is essential if _encoding
    # ist stateful.
    return 1;
}

sub send {
    my $self = shift;
    my ($vars, $data) = @_;
#    use Data::Dumper;
#    print STDERR Dumper(@_);
    # the current behaviour is to _set every var that
    # has not changed in 3 packages..
    my $state = $self->{'state'};
    my $state_temp = {};
    my $newvars = {};

    # to bypass automatic state.. use ':'
    foreach (keys %$vars) {

	next if (/^:_/);
	if (/^=_/) {
	    $newvars->{$_} = $vars->{$_};
	    $state_temp->{substr($_, 1)} = [0, $vars->{$_}];
	    next;
	}
	if (/^\+_/) {
	    my $key = substr($_, 1);
	    $newvars->{$_} = $vars->{$_};
	    if (exists $state->{$key}) {
		unless (ref $state->{$key}->[1] eq 'ARRAY') {
		    $state_temp->{$key}->[1] = [ $state->{$key}->[1] ];
		}
		push(@{$state_temp->{$key}->[1]}, $vars->{$_});
	    } else {
		$state_temp->{$key}->[1] = [ $vars->{$_} ];
	    }
	    $state_temp->{$key}->[0] = 0; # we assume it to be consistent
	    next;
	}
	if (/^-_/) {
	    my $key = substr($_, 1);
	    $newvars->{$_} = $vars->{$_};
	    if (exists $state->{$key}) {
		if (ref $state->{$key}->[1] eq 'ARRAY') {
		    $state_temp->{$key}->[1] = grep { $_ eq $vars->{$_} } 
						    @{$state->{$key}->[1]}; 
		} else {
		    if ($state->{$key}->[1] eq $vars->{$_}) {
			$state_temp->{$key}->[0] = -1;	
		    }
		}
	    } else {
		# WOU?
	    }
	    $state_temp->{$key}->[0] = 0; # we assume it to be consistent
	    next;
	}
	
	if (!exists $state->{$_}) {
	    $state_temp->{$_} = [1, $vars->{$_}];
	    $newvars->{$_} = $vars->{$_};
	    next;
	}
	if ($state->{$_}->[1] ne $vars->{$_}) { # var has changed
	    if ($state->{$_}->[0] == 3) { # unset var
		$state_temp->{$_} = [1, $vars->{$_}];
		$newvars->{"=$_"} = '';
	    } elsif ($state->{$_}->[0] > 1) { # decrease counter
		$state_temp->{$_} = [ $state->{$_}->[0] - 1, $state->{$_}->[1]];
	    } elsif ($state->{$_}->[0] != 0) { # nothing set.. 
		$state_temp->{$_} = [1, $vars->{$_}];
	    }
	    $newvars->{$_} = $vars->{$_};
	    next;
	}
	if ($state->{$_}->[1] eq $vars->{$_}) {
	    if ($state->{$_}->[0] == 10 || $state->{$_}->[0] == 0) { 
		# is set anyway
		next;
	    } elsif ($state->{$_}->[0] == 2) {
		$newvars->{"=$_"} = $vars->{$_};
	    } elsif ($state->{$_}->[0] < 2) {
		$newvars->{$_} = $vars->{$_};
	    }
	    $state_temp->{$_} = [$state->{$_}->[0] + 1, $state->{$_}->[1]];
	}
    }

    foreach (keys %$state) {
	next if (exists $newvars->{$_} || exists $vars->{$_});
	
	if ($state->{$_}->[0] == 3) { # unset var
	    $newvars->{"=$_"} = '';
	    $state_temp->{$_} = [ 2, $state->{$_}->[1]];
	    next;
    	}
	$state_temp->{$_} = [ $state->{$_}->[0] - 1, $state->{$_}->[1]]
	    if ($state->{$_}->[0] != 0);
	$newvars->{$_} = '' if ($state->{$_}->[0] > 3);
    }
    
    $self->{'state_temp'} = $state_temp;
    %$vars = %$newvars; 
    return 1;
}

sub sent {
    my $self = shift;
    my ($vars, $data) = @_;
    
    foreach (keys %{$self->{'state_temp'}}) {
	if ($self->{'state_temp'}->{$_}->[0] == -1) {
	    delete $self->{'state'}->{$_};
	    next;
	}
	$self->{'state'}->{$_} = $self->{'state_temp'}->{$_};
    }
    return 1;
}

sub receive {
    my $self = shift;
    my ($vars, $data) = @_;
    
    foreach (keys %{$self->{'vars'}}) {
	unless (exists $vars->{$_}) {
#	    print "used assigned var $_ ($self->{'vars'}->{$_})!\n";
	    $vars->{$_} = $self->{'vars'}->{$_};
	}
    }

    foreach (keys %$vars) {
	if (/^_/) {
	    delete $vars->{$_} if ($vars->{$_} eq '');
	    next;
	}
	my $key = substr($_, 1);
	if (/^=_/) {
#	    print "assigned $key!\n";
	    if ($vars->{$_} eq '') {
		delete $self->{'vars'}->{$key};
		delete $vars->{$_};
		next;
	    }
	    $self->{'vars'}->{$key} = (ref $vars->{$_}) 
		? dclone($vars->{$_}) : $vars->{$_};

	    $vars->{$key} = delete $vars->{$_};
	    next;
	}
	if (/^\+_/) {
	    if (!exists $self->{'vars'}->{$key}) {
		$self->{'vars'}->{$key} = [ delete $vars->{$_} ];
		next;
	    }
	    if (ref $self->{'vars'}->{$key} eq 'ARRAY') {
		push(@{$self->{'vars'}->{$key}}, $vars->{$_});
	    } else {
		$self->{'vars'}->{$key} = [ $self->{'vars'}->{$key},
					  $vars->{$_} ];
	    }
	    delete $vars->{$_};
	    next;
	}
	if (/^-_/) {
	    if (!exists $self->{'vars'}->{$key}) {

	    } elsif (!ref $self->{'vars'}->{$key}) {
		delete $self->{'vars'}->{$key} 
		    if ($self->{'vars'}->{$key} eq $vars->{$_});
	    } elsif (ref $self->{'vars'}->{$key} eq 'ARRAY') {
		my $value = $vars->{$key};
		@{$self->{'vars'}->{$key}} = 
		    grep {$_ ne $value } @{$self->{'vars'}->{$key}};
	    }
	    delete $vars->{$_};
	    next;
	}
    }
    return 1;
}
=cut
1;
