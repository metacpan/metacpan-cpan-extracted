package Parse::Highlife::Tokenizer;

use Parse::Highlife::Utils qw(params offset_to_coordinate get_source_info extend_match);
use Parse::Highlife::Token::Regex;
use Parse::Highlife::Token::Delimited;
use Parse::Highlife::Token::Characters;

use Data::Dump qw(dump);

sub new
{
	my( $class, @args ) = @_;
	my $self = bless {}, $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, @args ) = @_;
	$self->{'tokens'} = [];
	$self->{'tokennames'} = []; # to preserve order
	$self->{'debug'} = 1;
	return $self;
}

sub get_token
{
	my( $self, $tokenname ) = @_;
	my $pos = -1;
	my $p = 0;
	for( my $p = 0; $p < scalar @{$self->{'tokennames'}}; $p++ ) {
		if( $self->{'tokennames'}->[$p] eq $tokenname ) {
			$pos = $p;
			last;
		}
	}
	die "ERR: I do not know about a token named '$tokenname'\n"
		if $pos == -1;
	return $self->{'tokens'}->[$pos];
}

sub token
{
	my( $self, $name, $regex, $start, $end, $escape, $characters )
		= params( \@_, 
				-name => '', 
				-regex => '', 
				-start => '',
				-end => '', 
				-escape => "\\",
				-characters => '',
			);
	my @args = splice( @_, 1 );

	die "ERR: token has no name.\n" unless length $name;

	my $token;

	# try to find a same token definition that can be reused
	my $already_defined = 0;
	foreach my $t ( @{$self->{'tokens'}} ) {
		if( 
			( length $regex && 
				ref $t eq 'Parse::Highlife::Token::Regex' && 
				$t->{'regex'} eq $regex )
			||
			( length $start && length $end && 
				ref $t eq 'Parse::Highlife::Token::Delimited' && 
				$t->{'start'} eq $start &&
				$t->{'end'} eq $end )
			||
			( length $characters && 
				ref $t eq 'Parse::Highlife::Token::Characters' && 
				$t->{'characters'} eq $characters )			
		)
		{	
			$token = $t;
			$already_defined = 1;
			last;
		}
	}

	if( ! $already_defined ) {	
	
		if( length $regex ) {
			$token = Parse::Highlife::Token::Regex -> new( @args );
		}
		elsif( length $start && length $end ) {
			$token = Parse::Highlife::Token::Delimited -> new( @args );
		}
		elsif( length $characters ) {
			$token = Parse::Highlife::Token::Characters -> new( @args );
		}
		else {
			die "ERR: incomplete token definition.\n";
		}
		
		$token->{'name'} = $name;
		
		push @{$self->{'tokens'}}, $token;
		push @{$self->{'tokennames'}}, $name;
	}	
	return $token;
}

sub tokenize
{
	my( $self, $string ) = @_;
	my $tokens = [];
	
	my $i = 0;
	my $unknown_characters = '';
	while( $i < length $string ) {
		# find the first matching token
		my $found = 0;
		my $match;
		for( my $t = 0; $t < @{$self->{'tokens'}}; $t++ ) {
			my $tokenname = $self->{'tokennames'}->[$t];
			my $token = $self->{'tokens'}->[$t];
			$match = $token -> match( $string, $i ); # returns 0 oder hash with info
			if( $match ) {
				$match->{'token-name'} = $tokenname; # only the Tokenizer knows this
				$match->{'is-ignored'} = $token -> is_ignored();
				$i = $match->{'offset-after-match'};
				$found = 1;
				last;
			}
		}
		if( $found ) {
			# save unknown token
			if( length $unknown_characters ) {
				my $unknown = 
					extend_match(
						$string,
						{
							'token-classname' 		=> 'Parse::Highlife::Token::Unknown',
							'matched-substring'		=> $unknown_characters,
							'first-offset'				=> $i - length( $unknown_characters ),
							'token-name'					=> '',
						}
					);
				$unknown->{'is-ignored'} = 1; # unknown tokens are ignored (good?)
				push @{$tokens}, $unknown;
 				$unknown_characters = '';
			}
			push @{$tokens}, $match;
		}
		else {
			$unknown_characters .= substr $string, $i, 1;
			$i ++;
		
			#my( $line, $column ) = offset_to_coordinate( $string, $i );
			#print "ERR: could not find a matching token at line $line, column $column:\n\n";
			#print get_source_info( $string, $i );
			#exit;
		}
	}
	return $tokens;
}

1;
