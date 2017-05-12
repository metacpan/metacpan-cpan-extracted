package Parse::Highlife::Rule::Repetition;

use strict;
use base qw(Parse::Highlife::Rule);
use Parse::Highlife::Utils qw(params);

sub new
{
	my( $class, @args ) = @_;
	my $self = bless Parse::Highlife::Rule->new( @args ), $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, $repetition, $min, $max )
		= params( \@_,
				-repetition => '',
				-min => 0,
				-max => 0, # 0 = unlimited
			);
	$self->{'repetition'} = $repetition;
	$self->{'min'} = $min;
	$self->{'max'} = $max;
	return $self;
}

sub parse_from_token
{
	my( $self, $parser, $tokens, $t ) = @_;
	# - turn list of subrules into a single SEQ() rule
	# - try to parse SEQ() rule until failure
	# - if no success at all: return failure, else return result
	
	my $subrule = $parser->get_rule( $self->{'repetition'} );

	my $_t = $t;
	my ($_status, $_result);
	my @results;
	my $n = 0;
	while (1) {
		my $prev_t = $_t;
		($_t) = $self->_parse_ignored_tokens( $tokens, $_t );
		($_status, $_t, $_result) = $subrule->wrap_parse_from_token( $parser, $tokens, $_t );
		unless ($_status) {
			$_t = $prev_t;
			last;
		}
		push @results, $_result;
		$n++;
	}
	
	if( scalar @results >= $self->{'min'} &&
			( scalar @results <= $self->{'max'} || $self->{'max'} == 0 ) ) {
		return (
			1,
			$_t,
			$parser->make_ast_element('group', $self->{'name'}, \@results)
		);
	}
	else {
		return(0,0,0);
	}
}

1;
