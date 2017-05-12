package Parse::Highlife::Rule;

use strict;
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
	my( $self, $name )
		= params( \@_,
				-name => '',
			);
	$self->{'name'} = $name;
	return $self;
}

# abstract
sub parse_from_token { return (0,0,0) }

sub wrap_parse_from_token
{
	my( $self, $parser, $tokens, $t ) = @_;
	#return (0,0,0) if $t >= scalar(@{$tokens});
	
	if( $parser->{'debug'} ) {
		my $classname = ref $self;
			 $classname =~ s/^.*\://g;
		my $_t = $t;
		($_t) = $self->_parse_ignored_tokens( $tokens, $_t ); 
		print ''.('|   ' x $parser->{'current-indent'})."try rule <$self->{name}> as $classname from token #$_t'".($tokens->[$_t] ? $tokens->[$_t]->{'matched-substring'} : '<out-of-range>')."'\n";
		$parser->{'current-indent'} ++;
	}
		
	my @result = $self->parse_from_token( $parser, $tokens, $t );
	
	if( $parser->{'debug'} ) {
		$parser->{'current-indent'} --;
		print ''.('|   ' x $parser->{'current-indent'}).( $result[0] ? "MATCH <$self->{name}>" : '^' )."\n";
	}
	#my $in = <STDIN>;

	my $ast = $result[2];
	if( ref $ast eq 'HASH' && $ast->{'category'} eq 'group' ) {
		foreach my $child (@{$ast->{'children'}}) {
			$child->{'parent'} = $ast;
			$child->{'parent-id'} = $ast->{'id'};
		}
	}
	return @result;
}

sub _parse_ignored_tokens
{
	my( $self, $tokens, $offset ) = @_;
	my $t = $offset;
	while( $t < scalar @{$tokens} ) {
		last unless $tokens->[$t]->{'is-ignored'};
		$t++;
	}
	return ($t); # t = new offset after parsed stuff
}

1;
