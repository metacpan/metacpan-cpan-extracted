package Parse::Highlife::Rule::Sequence;

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
	my( $self, $sequence )
		= params( \@_,
				-sequence => [],
			);
	$self->{'sequence'} = $sequence;
	return $self;
}

sub parse_from_token
{
	my( $self, $parser, $tokens, $t ) = @_;
	return (0,0,0) if $t >= scalar(@{$tokens});

	# - try to parse one sub-rule after another
	# - abort on first failure
	# - on success: return result

	my $_t = $t;
	my @result = ();
	my ($_status, $_result);
	foreach my $subrulename (@{$self->{'sequence'}}) {
		my $subrule = $parser->get_rule( $subrulename );
		($_t) = $self->_parse_ignored_tokens( $tokens, $_t );
		($_status, $_t, $_result)	= $subrule->wrap_parse_from_token($parser, $tokens, $_t);
		last unless $_status;
		push @result, $_result;
	}
	
	if( $_status ) {
		return (
			1, 
			$_t, 
			$parser->make_ast_element('group', $self->{'name'}, \@result)
		);
	}
	return (0,0,0);
}

1;
