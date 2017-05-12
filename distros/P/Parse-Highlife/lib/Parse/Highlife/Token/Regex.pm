package Parse::Highlife::Token::Regex;

use base qw(Parse::Highlife::Token);
use Parse::Highlife::Utils qw(params extend_match);

use Data::Dump qw(dump);

sub new
{
	my( $class, @args ) = @_;
	my $self = bless Parse::Highlife::Token->new( @args ), $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, $regex )
		= params( \@_, 
				-regex => '',
			);
	$self->{'regex'} = $regex;
	return $self;
}

sub match
{
	my( $self, $string, $offset ) = @_;
	my $tail = substr $string, $offset;
	my $regex = '^('.$self->{'regex'}.')';
	if( $tail =~ /$regex/ ) {
		my ($match) = $tail =~ /$regex/;
		return
			extend_match(
				$string,
				{
					'token-classname' 		=> ref $self,
					'matched-substring'		=> $match,
					'first-offset'				=> $offset,
				}
			);
	}
	return 0;
}

1;
