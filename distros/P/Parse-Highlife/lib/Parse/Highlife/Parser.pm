package Parse::Highlife::Parser;

use strict;
use Parse::Highlife::Utils qw(params dump_tokens);
use Parse::Highlife::Rule::Sequence;
use Parse::Highlife::Rule::Choice;
use Parse::Highlife::Rule::Repetition;
use Parse::Highlife::Rule::Optional;
#use Parse::Highlife::Rule::Literal; # not needed anymore
#use Parse::Highlife::Rule::Regex; # not needed anymore
use Parse::Highlife::Rule::Token;
use Parse::Highlife::Token::Characters;
use Parse::Highlife::Token::Delimited;
use Parse::Highlife::Token::Regex;
use Parse::Highlife::Tokenizer;
use Parse::Highlife::AST;
use Data::Dump qw(dump);
$Data::Dump::INDENT = ".   ";

sub new
{
	my( $class, @args ) = @_;
	my $self = bless {}, $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, @args ) = @_;
	$self->{'tokenizer'} = Parse::Highlife::Tokenizer -> new();
	$self->{'rules'} = {};
	$self->{'top-rule'} = '';
	$self->{'current-indent'} = 0;
	$self->{'rulename-counter'} = 0;
	$self->{'debug'} = 0;
	return $self;
}

sub make_ast_element
{
	my( $self, @args ) = @_;
	return Parse::Highlife::AST->new( @args );
}

sub get_unique_rulename
{
	my( $self ) = @_;
	$self->{'rulename-counter'} ++;
	return '#AUTORULE-'.$self->{'rulename-counter'};
}

sub toprule
{
	my( $self, $name )
		= params( \@_, 
				-name => '',
			);
	$self->{'top-rule'} = $name;
	return 1;
}

sub get_rule
{
	my( $self, $rulename ) = @_;
	die "ERR: I do not know about a rule named '$rulename'\n"
		unless exists $self->{'rules'}->{$rulename};
	return $self->{'rules'}->{$rulename};
}

sub get_token
{
	my( $self, $tokenname ) = @_;
	return $self->{'tokenizer'}->get_token( $tokenname );
}

sub rename_rule
{
	my( $self, $old_name, $new_name ) = @_;
	if( exists $self->{'rules'}->{$old_name} ) {
		$self->{'rules'}->{$new_name} = $self->{'rules'}->{$old_name};
		$self->{'rules'}->{$new_name}->{'name'} = $new_name;
		delete $self->{'rules'}->{$old_name};
	}
	return $self;
}

sub rule
{
	#print join(',',@_)."\n";
	my( $self, 
			$name, $ignored,
			$sequence, $choice, $repetition, $min, $max, $optional, $literal, $token,
			$start, $end, $escape, $characters, $regex )
		= params( \@_, 
				-name => '',
				-ignored => 0,
				
				# rules
				-sequence => '',
				-choice => '', 
				-repetition => '', -min => 0, -max => 0,
				-optional => '', 
				-literal => '',
				-token => '',

				# tokens encapsulated in rules of type "token"
				-start => '', 
				-end => '', 
				-escape => "\\",
				-characters => [],
				-regex => '',
			);			
	my @args = splice( @_, 1 );
	
	#dump(\@args);
	#print "($ignored)\n";

	die "ERR: rule has no name.\n" unless length $name;
	die "ERR: rule '$name' is alreay defined.\n"
		if exists $self->{'rules'}->{$name};

	my $rule;	
	if( ref $sequence ) {
		$rule = Parse::Highlife::Rule::Sequence -> new( @args );
	}
	elsif( ref $choice ) {
		$rule = Parse::Highlife::Rule::Choice -> new( @args );
	}
	elsif( length $repetition ) {
		$rule = Parse::Highlife::Rule::Repetition -> new( @args );
	}
	elsif( length $optional ) {
		$rule = Parse::Highlife::Rule::Optional -> new( @args );
	}
	elsif( length $token ) { # NOTE: this is only for internal use, because
													 # the programmer does not know the names of
													 # defined tokens (because they are auto-generated)
		$rule = Parse::Highlife::Rule::Token -> new( @args );
	}
	elsif( length $literal ) {
		# create a regex-token in the tokenizer
		# and a rule that matches that fixed string
		my $t = $self->{'tokenizer'}->token(
			-name => '#AUTOTOKEN-'.$name,
			-ignored => $ignored,
			-regex => quotemeta $literal,
		);
		$rule = $self->rule( -name => $name, -token => $t->{'name'} );
	}
	elsif( length $regex ) {
		# create a regex-token in the tokenizer
		# and a rule that matches that type of token
		my $t = $self->{'tokenizer'}->token(
			-name => '#AUTOTOKEN-'.$name,
			-ignored => $ignored,
			-regex => $regex,
		);
		$rule = $self->rule( -name => $name, -token => $t->{'name'} );
	}
	elsif( scalar @{$characters} ) {
		# create a characters-token in the tokenizer
		# and a rule that matches that type of token
		my $t = $self->{'tokenizer'}->token(
			-name => '#AUTOTOKEN-'.$name,
			-ignored => $ignored,
			-characters => $characters,
		);
		$rule = $self->rule( -name => $name, -token => $t->{'name'} );
	}
	elsif( length $start && length $end ) {
		# create a delimited-token in the tokenizer
		# and a rule that matches that type of token
		my $t = $self->{'tokenizer'}->token(
			-name => '#AUTOTOKEN-'.$name,
			-ignored => $ignored,
			-start => $start,
			-end => $end,
			-escape => $escape
		);
		$rule = $self->rule( -name => $name, -token => $t->{'name'} );
	}	
	else {
		die "ERR: incomplete rule definition.\n";
	}
	
	$self->{'rules'}->{$name} = $rule;
	
	return $rule;
}

sub parse
{
	my( $self, $string ) = @_;

	#dump($self->{'rules'});
	#dump($self->{'tokenizer'}->{'tokennames'});
	#dump($self->{'tokenizer'}->{'tokens'});

	my $tokens = $self->{'tokenizer'}->tokenize( $string );
	#dump_tokens($tokens);
		
	# the return value of each parser function:
	# [0] = status flag (1 = success, 0 = failure)
	# [1] = the token offset after the last token parsed for the result
	# [2] = the result (abstract syntax tree)
	my ($status, $t, $ast)
		= $self->_parse_rule_from_token( $self->{'top-rule'}, $tokens, 0 );
	die "ERR: failed to parse string.\n" if $status == 0;
	#print "parsed #$t tokens of ".scalar(@{$tokens})."\n";
	
	my $_t;
	($_t) = Parse::Highlife::Rule::_parse_ignored_tokens( undef, $tokens, $t );
	if( $_t < scalar @{$tokens} ) {
		my @_tokens = splice @{$tokens}, $_t, 10;
	
		print "INFO: there are unparsed tokens after the parsed rule.\n";
		print "The tokens after the syntax error are:\n";
		dump_tokens(\@_tokens);
		print "...\n";
		exit;
		#dump($tokens->[$_t]);
	}

	#dump($self->{'rules'});
	return $ast;
}

sub _parse_rule_from_token
{
	my( $self, $rulename, $tokens, $t ) = @_;
	#return (0,0,0) if $t >= scalar(@{$tokens});
	return (0,0,0) unless exists $self->{'rules'}->{$rulename};
	my $rule = $self->{'rules'}->{$rulename};
	return $rule->wrap_parse_from_token( $self, $tokens, $t );
}

1;


