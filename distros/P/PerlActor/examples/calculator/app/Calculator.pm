package Calculator;
use strict;
use fields qw( keyBuffer temp display operation error );

#===============================================================================================
# Public Methods
#===============================================================================================

sub new
{
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $self = fields::new($class);
	$self->_reset();
	return $self;
}

sub pressKey
{
	my $self = shift;
	my $key = shift;
	if ($key =~ /^[+\-X\/]$/)
	{
		$self->_setOperation($key);
	}
	elsif ($key eq '=')
	{
		$self->_performOperation();
	}
	else
	{
		$self->{keyBuffer} .= $key;
		$self->{display} = $self->{keyBuffer};
	}
		
}

sub getDisplay
{
	my $self = shift;
	return $self->{display};
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

sub _reset
{
	my $self = shift;
	$self->{keyBuffer} = '';
	$self->{display}   = '0';
	$self->{temp}      = 0;
}

sub _setOperation
{
	my ($self, $operation) = @_;
	$self->{temp} = $self->{keyBuffer};
	$self->{keyBuffer} = '';
	$self->{operation} = $operation;	
}

sub _performOperation
{
	my $self = shift;
	
	if ($self->{operation} eq '+')
	{
		$self->{temp} = $self->{temp} + $self->{keyBuffer};
	}
	elsif ($self->{operation} eq '-')
	{
		$self->{temp} = $self->{temp} - $self->{keyBuffer};		
	}
	elsif ($self->{operation} eq 'X')
	{
		$self->{temp} = $self->{temp} * $self->{keyBuffer};		
	}
	elsif ($self->{operation} eq '/')
	{
		if ($self->{keyBuffer} != 0)
		{
			$self->{temp} = $self->{temp} / $self->{keyBuffer};
		}
		else
		{
			$self->{error} = 1;
		}
	}
	$self->{keyBuffer} = '';
	$self->{display} = $self->{error} ? 'E' : $self->{temp};
}

# Keep Perl happy.
1;
