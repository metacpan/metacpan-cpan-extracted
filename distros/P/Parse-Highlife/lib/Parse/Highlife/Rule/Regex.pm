package Parse::Highlife::Rule::Regex;

# not needed anymore

# use strict;
# use base qw(Highlife::Rule);
# use Highlife::Utils qw(params);
# 
# sub new
# {
# 	my( $class, @args ) = @_;
# 	my $self = bless Highlife::Rule->new( @args ), $class;
# 	return $self -> _init( @args );
# }
# 
# sub _init
# {
# 	my( $self, $regex )
# 		= params( \@_,
# 				-regex => '',
# 			);
# 	$self->{'regex'} = $regex;
# 	return $self;
# }
# 
# sub parse_from_token
# {
# 	my( $self, $parser, $tokens, $t ) = @_;
# 	return (0,0,0) if $t >= scalar(@{$tokens});
# 
# 	# - try to match regex with next token
# 	# - on match: return result, else return failure
# 	
# 	my $_t = $t;
# 	($_t) = $self->_parse_ignored_tokens( $tokens, $_t );
# 
# 	my $token = $tokens->[$_t];
# 	my $value = $token->{'matched-substring'};
# 	my $regex = $self->{'regex'};
# 	
# 	if( $value =~ /^$regex$/ ) {
# 		return (1, $_t + 1, {'type' => $self->{'name'}, 'ast' => $value});
# 	}
# 	return (0,0,0);
# }

1;
