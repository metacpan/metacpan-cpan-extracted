package Parse::Highlife::Rule::Optional;

use strict;
use base qw(Parse::Highlife::Rule);
use Parse::Highlife::Utils qw(params);
use Data::Dump qw(dump);

sub new
{
	my( $class, @args ) = @_;
	my $self = bless Parse::Highlife::Rule->new( @args ), $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, $optional )
		= params( \@_,
				-optional => '',
			);
	$self->{'optional'} = $optional;
	return $self;
}

sub parse_from_token
{
	my( $self, $parser, $tokens, $t ) = @_;
	# - turn list of subrules into a single SEQ() rule
	# - try to parse SEQ() rule
	# - on success: return result, else return failure

	my $subrule = $parser->get_rule( $self->{'optional'} );

	my $_t = $t;
	my ($_status, $_result);
	($_t) = $self->_parse_ignored_tokens( $tokens, $_t );
	($_status, $_t, $_result) = $subrule->wrap_parse_from_token( $parser, $tokens, $_t );

	if( $_status ) {
		return (
			1, 
			$_t,
			$parser->make_ast_element('group', $self->{'name'}, [ $_result ])
		);
	}
	return (
		1,
		$t,
		$parser->make_ast_element('group', $self->{'name'}, [])
	); # always succeeds, since its optional
}

1;
