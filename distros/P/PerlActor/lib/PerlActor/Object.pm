package PerlActor::Object;
use fields qw( listener context );
use strict;

#===============================================================================================
# Public Methods
#===============================================================================================

sub new
{
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $self = fields::new($class);
	return $self;
}

sub setListener
{
	my $self = shift;
	$self->{listener} = shift;
}

sub getListener
{
	my $self = shift;
	return $self->{listener};
}

sub setContext
{
	my $self = shift;
	$self->{context} = shift;
}

sub getContext
{
	my $self = shift;
	return $self->{context};
}

sub trim
{
	my $self = shift;
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
