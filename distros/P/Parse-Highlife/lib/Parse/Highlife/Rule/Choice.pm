package Parse::Highlife::Rule::Choice;

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
	my( $self, $choice )
		= params( \@_,
				-choice => [],
			);
	$self->{'choice'} = $choice;
	return $self;
}

sub parse_from_token
{
	my( $self, $parser, $tokens, $t ) = @_;
	return (0,0,0) if $t >= scalar(@{$tokens});

	# - try to parse one sub-rule after another
	# - return result on first success
	# - if no success: return failure

	my $_t;
	my ($_status, $_result);
	foreach my $subrulename (@{$self->{'choice'}}) {
		my $subrule = $parser->get_rule( $subrulename );
		$_t = $t;
		($_t) = $self->_parse_ignored_tokens( $tokens, $_t );
		($_status, $_t, $_result) = $subrule->wrap_parse_from_token( $parser, $tokens, $_t );
		last if $_status;
	}

	if( $_status ) {
		return (
			1, 
			$_t, 
			$parser->make_ast_element('group', $self->{'name'}, [ $_result ])
		);
	}
	return (0,0,0);
}

1;
