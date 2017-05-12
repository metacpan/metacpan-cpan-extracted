package Parse::Token::Lite;
use Moose;
use Data::Dump;
use Log::Log4perl qw(:easy);
use Parse::Token::Lite::Token;
use Parse::Token::Lite::Rule;
Log::Log4perl->easy_init($ERROR);

our $VERSION = '0.200'; # VERSION
# ABSTRACT: Simply parse String into tokens with rules which are similar to Lex.



has rulemap => ( is=>'rw', default=>sub{return {};});


has data	=> ( is=>'rw' );


has state_stack	=> ( is=>'rw', default=>sub{[]} );

has rulemap => (is=>'rw', required=>1);
sub BUILD{
	my $self = shift;
	foreach my $key (keys %{$self->rulemap}){
        $self->rulemap->{$key} = [map{ Parse::Token::Lite::Rule->new($_) }@{$self->rulemap->{$key}}];
	}
}


sub from{
	my $self = shift;
	my $data = shift;
	
	$self->data($data);
	$self->state_stack([]); # reset state.
	
	return 1;
}


sub parse{
	my $self = shift;
	my $data = shift;
	$self->from($data) if defined $data;
	
	my @tokens;
	while(!$self->eof){
		my @ret = $self->nextToken;
		push(@tokens,\@ret) if wantarray;
	}
	return @tokens if wantarray;
	return 1;
}


sub currentRules{
    my $self = shift;
    return $self->rulemap->{$self->state};
}


sub nextToken{
	my $self = shift;
 
	foreach my $rule ( @{$self->currentRules} ){
        my $pat = $rule->re;
		my $matched = $self->data =~ m/^$pat/s;
		if( $matched ){
			my $rest = $';
			$self->data($rest);

			if( $rule->state ){
				foreach my $state (@{$rule->state}) {
					if( $state =~ /([+-])(.+)/ ){
						if( $1 eq '-' ){
							$self->end($2);
						}
						else{
							$self->start($2);
						}
					}
					else{
						die "invalid state_action '$state'";
					}
				}
			}
			
            my $token = Parse::Token::Lite::Token->new(rule=>$rule,data=>$&);
            
			my @funcret;
			if( $rule->func ){
				@funcret = $rule->func->($self,$token);
			}

            if( wantarray ){
                return $token,@funcret;
            }
            else{
                return $token;
            }
		}
	}
	die "not matched for first of '".substr($self->data,0,5)."..'";
}



sub eof{
	my $self = shift;
	return length($self->data)?0:1;
}


sub start{
	my $self = shift;
	my $state = shift;
	
	if( $state ne $self->state ){
		DEBUG ">>> START '$state'";
		push(@{$self->state_stack}, $state)
	}
	else{
		DEBUG ">>> KEEP  '$state'";
	}
}

sub end{
	my $self = shift;
	my $state = shift;
	DEBUG "<<< STOP  '$state'";
	return pop(@{$self->state_stack});
}


sub state{
	my $self = shift;
	return 'MAIN' if( @{$self->state_stack} == 0 );
	return $self->state_stack->[@{$self->state_stack}-1];
}

has flags => ('is'=>'rw', default=>sub{ return {}; } );


sub setFlag{
	my $self = shift;
	my $flag = shift;
	$self->flags->{$flag} = 1;
}


sub resetFlag{
	my $self = shift;
	my $flag = shift;
	delete( $self->flags->{$flag} );
}

sub isSetFlag{
	my $self = shift;
	my $flag = shift;
	return defined( $self->flags->{$flag} );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Token::Lite - Simply parse String into tokens with rules which are similar to Lex.

=head1 VERSION

version 0.200

=head1 SYNOPSIS

	use Parse::Token::Lite;

	my %rules = (
		MAIN=>[
			{ name=>'NUM', re=> qr/\d[\d,\.]*/ },
			{ name=>'STR', re=> qr/\w+/ },
			{ name=>'SPC', re=> qr/\s+/ },
			{ name=>'ERR', re=> qr/.*/ },
		],
	);

	my $parser = Parse::Token::Lite->new(rulemap=>\%rules);
	$parser->from("This costs 1,000won.");
	while( ! $parser->eof ){
		my ($token,@extra) = $parser->nextToken;
		print $token->rule->name."-->".$token->data."<--\n";
	}

Results are

	STR -->This<--
	SPC --> <--
	STR -->costs<--
	SPC --> <--
	NUM -->1,000<--
	STR -->won<--
	ERR -->.<--

=head1 ATTRIBUTES

=head2 rulemap

rulemap contains hash refrence of rule objects grouped by STATE.
rulemap should have 'MAIN' item.

	my %rule = (
		MAIN => [
			Parse::Token::Lite::Rule->new(name=>'any', re=>qr/./),
		],
	);
	$parser->rulemap(\%rule);

In constructor, it can be replaced with hash reference descripting attributes of L<Parse::Token::Lite::Rule> class, intead of Rule Object.

	my %rule = (
		MAIN => [
			{name=>'any', re=>qr/./}, # ditto
		],
	);
	my $parser = Parse::Token::Lite->new( rulemap=>\%rule );

=head2 data

'data' is set by from() method.
'data' contains a rest of text which is not processed by nextToken().
Please remember, 'data' is changing.

If a length of 'data' is 0, eof() returns 1.

=head2 state_stack

At first time, it contains ['MAIN'].
It is reset by from().

=head1 METHODS

=head2 from($data_string)

Setting data to parse.

This causes resetting state_stack.

=head2 parse()

=head2 parse($data)

On Scalar context : Returns 1
On Array context : Returns array of [L<Parse::Token::Lite::Token>,@return_values_of_callback].

Parse all tokens on Event driven.
Just call nextToken() during that eof() is not 1.

Defined $data causes calling from($data).

You should set a callback function at 'func' attribute in 'rulemap' to do something with tokens.

=head2 currentRules()

Returns an array reference of rules of current state. 

See L<Parse::Token::Lite::Rule>.

=head2 nextToken()

On Scalar context : Returns L<Parse::Token::Lite::Token> object.
On Array context : Returns (L<Parse::Token::Lite::Token>,@return_values_of_callback).

	my ($token, @ret) = $parser->nextToken;
	print $token->rule->name . '->' . $token->data . "\n";

See L<Parse::Token::Lite::Token> and L<Parse::Token::Lite::Rule>.

=head2 eof()

Returns 1 when no more text is.

=head2 start($state)

=head2 end()

=head2 end($state)

Push/Pop the state on state_stack to implement AUTOMATA.

Also, this is called by a 'state' definition of L<Parse::Token::Lite::Rule>.

You can set rules as Lexer like.

	my $rulemap = {
		MAIN => [
			{ name=>'QUOTE', re=>qr/'/, func=>
				sub{ 
					my ($parser,$token) = @_;
					$parser->start('STATE_QUOTE'); # push
				}
			},
			{ name=>'ANY', re=>qr/.+/ },
		],
		STATE_QUOTE => [
			{ name=>'QUOTE_PAIR', re=>qr/'/, func=>
				sub{ 
					my ($parser,$token) = @_;
					$parser->end('STATE_QUOTE'); # pop
				}
			},
			{ name=>'QUOTED_TEXT', re=>qr/.+/ }
		],
	};

You can also do it in simple way.

	my $rulemap = {
		MAIN => [
			{ name=>'QUOTE', re=>qr/'/, state=>['+STATE_QUOTE'] }, # push
			{ name=>'ANY', re=>qr/.+/ },
		],
		STATE_QUOTE => [
			{ name=>'QUOTE_PAIR', re=>qr/'/, state=>['-STATE_QUOTE] }, #pop
			{ name=>'QUOTED_TEXT', re=>qr/.+/ }
		],
	};

=head2 state()

Returns current state by peeking top of 'state_stack'.

=head1 SEE ALSO

See L<Parse::Token::Lite::Token> and L<Parse::Token::Lite::Rule>.

And see 'samples' directory in source.

=head1 AUTHOR

khs <sng2nara@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by khs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
