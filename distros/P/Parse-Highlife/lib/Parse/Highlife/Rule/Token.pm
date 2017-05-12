package Parse::Highlife::Rule::Token;

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
	my( $self, $token )
		= params( \@_,
				-token => '',
			);
	$self->{'token'} = $token;
	return $self;
}

sub parse_from_token
{
	my( $self, $parser, $tokens, $t ) = @_;
	return (0,0,0) if $t >= scalar(@{$tokens});

	my $_t = $t;
	($_t) = $self->_parse_ignored_tokens( $tokens, $_t );
	my $token = $tokens->[$_t];

	if( $token->{'token-name'} eq $self->{'token'} ) {
		return (
			1, 
			$_t + 1, 
			$parser->make_ast_element('leaf', $self->{'name'}, $token->{'matched-substring'})
		);
	}
	return (0,0,0);
}

1;
