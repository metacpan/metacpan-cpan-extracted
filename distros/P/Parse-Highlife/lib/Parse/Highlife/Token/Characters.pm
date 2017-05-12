package Parse::Highlife::Token::Characters;

use base qw(Parse::Highlife::Token);
use Parse::Highlife::Utils qw(params extend_match);

sub new
{
	my( $class, @args ) = @_;
	my $self = bless Parse::Highlife::Token->new( @args ), $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, $characters )
		= params( \@_, 
				-characters => '',
			);
	$self->{'characters'} = $characters;
	return $self;
}

sub match
{
	my( $self, $string, $offset ) = @_;
	my $c = $offset;
	while( $c < length $string ) {
		my $found = 0;
		foreach my $char (@{$self->{'characters'}}) {
			my $x = substr( $string, $c, 1 );
			$found = 1 if $char eq $x;
		}
		last unless $found;
		$c++;
	}
	if( $c > $offset ) {
		return
			extend_match(
				$string,
				{
					'token-classname' 		=> ref $self,
					'matched-substring'		=> substr( $string, $offset, $c - $offset ),
					'first-offset'				=> $offset,
				}
			);	
	}
	return 0;
}

1;
