package Net::PSYC::State;

use strict;
our $VERSION = '0.1';

use strict;

# module implementing psyc-state-maintainance for objects...
#
# the state of mmp-vars is maintained by the connection
# object!
#
# right know I am not quite happy to have 2 objects for state. the wrapper and

sub new {
    my $class = shift;
    my $unl = shift;
    my $self = {
#	'co' => {},
	'o' => {},
# this is temporary out-state. just to keep keep in mind variables which 
# have been set manually by the api. these variables are really assigned
# when a tcp packet is send.
	'to' => {},
# ci is the in
	'ci' => {},
	'i' => {},
    };
    return bless $self, $class; 
}

#   sendmsg ( target, mc, data, vars[, source || mmp-vars ] )
sub sendmsg {
    my $self = shift;
    my $s = $self->{'o'};
    my $vars = $_[3];
    if (exists $s->{$_[0]}) {
	foreach (keys %{$s->{$_[0]}}) {
	    if (!exists $vars->{$_}) {
		$vars->{$_} = '';
	    } elsif ($vars->{$_} eq $s->{$_}) {
		delete $vars->{$_};
	    }
	}
    }
}

#   msg ( source, mc, data, vars )
sub msg {
    my $self = shift;
    my ($source, $vars) = ($_[0], $_[3]);
    my $s;

    if (exists $vars->{'_context'}) {
	return unless (exists $self->{'ci'}->{$vars->{'_context'}});
	$s = $self->{'ci'}->{$vars->{'_context'}};
    } else {
	return unless (exists $self->{'i'}->{$source});
	$s = $self->{'i'}->{$source};
    }

    foreach (keys %$s) {
	$vars->{$_} = $s->{$_} unless (exists $vars->{$_});
    }
}

#	    ( source, key, value )
sub diminish {
    my $self = shift;
    my ($source, $key, $value, $iscontext) = @_;
    my $s = ($iscontext) ? $self->{'ci'} : $self->{'i'};

    return unless (exists $s->{$source});
    Net::PSYC::_diminish($s->{$source}, $key, $value);
}

sub augment {
    my $self = shift;
    my ($source, $key, $value, $iscontext) = @_;
    my $s = ($iscontext) ? $self->{'ci'} : $self->{'i'};

    $s->{$source} = {} unless (exists $s->{$source});
    Net::PSYC::_augment($s->{$source}, $key, $value);
}

sub assign {
    my $self = shift;
    my ($source, $key, $value, $iscontext) = @_;
    my $s = ($iscontext) ? $self->{'ci'} : $self->{'i'};

    $s->{$source} = {} unless (exists $s->{$source});
    $s->{$source}->{$key} = $value;
}

# new API ( we will see how good it works )
sub outstate {
    my $self = shift;
    my ($mod, $key, $value, $t, $iscontext) = @_;

    $self->{'o'}->{$t} = {} unless (exists $self->{'o'}->{$t});
    my $o = $self->{'o'}->{$t};
    
    if ($mod eq ':') {
	return 0 if (exists $o->{$key} && $o->{$key} eq $value);
	return 1;
    }

    # to implement automated state here we would need to
    # return 0 if the var is not to be send and fill everything else
    # into $to. TODO
    
    if ($mod eq '=') {
	$o->{$key} = $value;
    } elsif ($mod eq '+') {
	Net::PSYC::_augment($o, $key, $value);
    } elsif ($mod eq '-') {
	Net::PSYC::_diminish($o, $key, $value);
    }
    return 1; # 1 means: render it..
}

# i dont like that name. returns vars currently set.
#
sub state {
    my $self = shift;
    my ($target, $iscontext) = @_;

    return (exists $self->{'to'}->{$target} ? delete $self->{'to'}->{$target} 
					    : {});
}

1;
