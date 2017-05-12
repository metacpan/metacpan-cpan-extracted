package Parse::Highlife::Token;

use Parse::Highlife::Utils qw(params);
use Data::Dump qw(dump);

sub new
{
	my( $class, @args ) = @_;
	my $self = bless {}, $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, $ignored )
		= params( \@_,
				-ignored => 0,
			);

	$self->{'is-ignored'} = $ignored;
	$self->{'name'} = '';
	return $self;
}

sub is_ignored
{
	my( $self) = @_;
	return $self->{'is-ignored'};
}

# abstract
sub match { return 0 }

1;
