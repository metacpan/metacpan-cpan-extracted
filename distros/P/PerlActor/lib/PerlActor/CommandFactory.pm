package PerlActor::CommandFactory;
use strict;
use base 'PerlActor::Object';

#===============================================================================================
# Public Methods
#===============================================================================================

sub create
{
	my $self = shift;
	my $commandName = shift;

	return $self->create('Null')
		unless $commandName;

	my @commandArgs = @_;
	my $error = '';
	
	#TODO Refactor by extracting standard namespaces 
	foreach my $class ("PerlActor::Command::$commandName", "PerlActor::Command::Web::$commandName", $commandName)
	{
		unless ($error = $self->_compile($class))
		{
			return $class->new(@commandArgs) 
		}
		last unless ($error =~ /Can't locate/);
	}
	
	return $self->create('Unknown', $error);

}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

sub _compile
{
	my $self = shift;
	my $class = shift;
	return if (eval "require $class");
	return $@;
}

# Keep Perl happy.
1;
