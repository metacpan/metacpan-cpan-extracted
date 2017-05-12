package Parse::Highlife::Compiler;

use strict;
use Parse::Highlife::Utils qw(dump_tokens dump_ast);
use Parse::Highlife::Parser;
use Parse::Highlife::Transformer;

use File::Slurp qw(read_file);
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
	$self->{'parser'} = Parse::Highlife::Parser -> new();	
	$self->{'transformer'} = Parse::Highlife::Transformer -> new();
	
	# the following set of tokenizer, parser and transformer
	# is used to tokenize, parse and transform grammars in
	# a common syntax to create a parser (this grammar makes it
	# possible to define tokens and rules in a more consisten way)
	$self->{'grammar-parser'} = undef;
	$self->{'grammar-transformer'} = undef;
	
	return $self;
}

sub _create_grammar_analyser
{
	my( $self ) = @_;

 	my $p = Parse::Highlife::Parser -> new();
 	
	$p -> rule( -name => 	'grammar', -repetition => 'definition' );	
	$p -> rule( -name => 		'definition', -sequence => [ 'rule-name', 'ignored', 'def-mark', 'rule', 'def-end' ] );

	$p -> rule( -name => 			'ignored', -optional => 'ignored-text' );
	$p -> rule( -name => 				'ignored-text', -literal => 'ignored' );
	
	$p -> rule( -name => 			'rule-name', -regex => '[a-zA-Z\-]+' );

	$p -> rule( -name => 			'rule', -repetition => 'subrule', -min => 1 );
	$p -> rule( -name => 			'subrule', -choice => [ 'token-delimited', 'token-literal', 'token-regex', 'rule-sequence', 'rule-repetition', 'rule-optional', 'rule-choice', 'rule-name' ] );
	$p -> rule( -name => 				'token-regex', -start => '/', -end => '/' );
	$p -> rule( -name => 				'token-delimited', -sequence => [ 'quoted-string', 'dots', 'quoted-string' ] );
	$p -> rule( -name => 				'token-literal', -sequence => [ 'quoted-string' ] );
	$p -> rule( -name => 					'quoted-string', -choice => [ 'single-quoted-string', 'double-quoted-string' ] );
	$p -> rule( -name => 						'single-quoted-string', -start => "'", -end => "'" );
	$p -> rule( -name => 						'double-quoted-string', -start => '"', -end => '"' );
	$p -> rule( -name => 				'rule-sequence', -sequence => [	'open-paren', 'rules', 'close-paren' ] );
	$p -> rule( -name => 				'rule-repetition', -sequence => [ 'open-curly', 'rule', 'amount-spec', 'close-curly' ] );
	$p -> rule( -name => 					'amount-spec', -sequence => [ 'number', 'dots', 'limit' ] );
	$p -> rule( -name => 						'number', -regex => '\d+' );
	$p -> rule( -name => 						'limit', -choice => [ 'number', 'star' ] );
	$p -> rule( -name => 				'rule-optional', -sequence => [ 'open-bracket', 'rule', 'close-bracket' ] );
	$p -> rule( -name => 				'rule-choice', -sequence => [ 'open-edge', 'rules', 'close-edge' ] );
	$p -> rule( -name => 					'rules', -repetition => 'rule' );

	$p -> rule( -name => 			'star', -literal => '*' );
	$p -> rule( -name => 			'def-mark', -literal => ':' );
	$p -> rule( -name => 			'open-paren', -literal => '(' );
	$p -> rule( -name => 			'close-paren', -literal => ')' );
	$p -> rule( -name => 			'open-curly', -literal => '{' );
	$p -> rule( -name => 			'close-curly', -literal => '}' );
	$p -> rule( -name => 			'open-bracket', -literal => '[' );
	$p -> rule( -name => 			'close-bracket', -literal => ']' );
	$p -> rule( -name => 			'open-edge', -literal => '<' );
	$p -> rule( -name => 			'close-edge', -literal => '>' );
	$p -> rule( -name => 			'pipe', -literal => '|' );
	$p -> rule( -name => 			'dots', -literal => '..' );
	$p -> rule( -name => 			'def-end', -literal => ';' );

	$p -> rule( -name => 	'multiline-comment', -ignored => 1, -start => '/*', -end => '*/' );
	$p -> rule( -name => 	'singleline-comment', -ignored => 1, -regex => "\#[^\n]*\n" );
	$p -> rule( -name => 	'space', -ignored => 1, -characters => [' ',"\n","\t","\r"] );
	
 	$p->toprule( -name => 'grammar' );
 	
 	#dump($p->{'tokenizer'}->{'tokens'});
 	#dump($p->{'rules'});
 	#exit;
 	
	my $t = Parse::Highlife::Transformer -> new();

	$t -> transformer( -rule => 'token-delimited', -fn => sub {
		my( $transformer, $ast, $compiler ) = @_;
		my $start = $ast->first_child()->first_child()->first_child();
		my $end = $ast->third_child()->first_child()->first_child();
		my $rulename = $self->{'parser'}->get_unique_rulename();
		$compiler->rule( -name => $rulename, -start => $start, -end => $end );
		return $compiler->{'grammar-parser'}->make_ast_element('leaf', 'rule-name', $rulename);
	});
	
	$t -> transformer( -rule => 'token-regex', -fn => sub {
		my( $transformer, $ast, $compiler ) = @_;
		my $regex = $ast->{'children'};
		my $rulename = $self->{'parser'}->get_unique_rulename();
		$compiler->rule( -name => $rulename, -regex => $regex );
		return $compiler->{'grammar-parser'}->make_ast_element('leaf', 'rule-name', $rulename);
	});
	
	$t -> transformer( -rule => 'token-literal', -fn => sub {
		my( $transformer, $ast, $compiler ) = @_;
		my $literal = $ast->first_child()->first_child()->first_child();		
		my $rulename = $self->{'parser'}->get_unique_rulename();
		$compiler->rule( -name => $rulename, -literal => $literal );
		return $compiler->{'grammar-parser'}->make_ast_element('leaf', 'rule-name', $rulename);
	});

	$t -> transformer( -rule => 'rule-repetition', -fn => sub {
		my( $transformer, $ast, $compiler ) = @_;
 		$ast = $transformer->transform_children( $ast, $compiler );
		my $subrule = $ast->second_child()->first_child();
		my $min = $ast->third_child()->first_child()->first_child();
		my $max = $ast->third_child()->third_child()->first_child()->first_child();
		   $max = 0 if $max eq '*';
		my $rulename = $self->{'parser'}->get_unique_rulename();
		$compiler->rule( -name => $rulename, -ignored => 0, -repetition => $subrule, -min => $min, -max => $max );
		return $compiler->{'grammar-parser'}->make_ast_element('leaf', 'rule-name', $rulename);
	});
	
	$t -> transformer( -rule => 'rule-optional', -fn => sub {
		my( $transformer, $ast, $compiler ) = @_;
 		$ast = $transformer->transform_children( $ast, $compiler );
		my $subrule = $ast->second_child()->first_child();
		my $rulename = $self->{'parser'}->get_unique_rulename();
		$compiler->rule( -name => $rulename, -ignored => 0, -optional => $subrule );
		return $compiler->{'grammar-parser'}->make_ast_element('leaf', 'rule-name', $rulename);
	});
	
	$t -> transformer( -rule => 'rule-choice', -fn => sub {
		my( $transformer, $ast, $compiler ) = @_;
		my @subrules;
		foreach my $subrule (@{$ast->second_child()->first_child()->{'children'}}) {
			my $_subrule = $transformer->transform_children( $subrule, $compiler );
	 		push @subrules, $_subrule->first_child()->first_child();
 		}
		my $rulename = $self->{'parser'}->get_unique_rulename();
		$compiler->rule( -name => $rulename, -ignored => 0, -choice => [ @subrules ] );
		return $compiler->{'grammar-parser'}->make_ast_element('leaf', 'rule-name', $rulename);
	});
	
	$t -> transformer( -rule => 'rule', -fn => sub {
		my( $transformer, $ast, $compiler ) = @_;
 		$ast = $transformer->transform_children( $ast, $compiler );
		if( scalar @{$ast->{'children'}} > 1 ) {
			my @subrules = map { $_->first_child()->first_child() } @{$ast->{'children'}};
			my $rulename = $self->{'parser'}->get_unique_rulename();
			$compiler->rule( -name => $rulename, -sequence => \@subrules );
			return $compiler->{'grammar-parser'}->make_ast_element('leaf', 'rule-name', $rulename);
		}
		else {
			my $rulename = $ast->first_child()->first_child()->first_child();
			return $compiler->{'grammar-parser'}->make_ast_element('leaf', 'rule-name', $rulename);;
		}
	});
	
 	$t -> transformer( -rule => 'definition', -fn => sub {
 		my( $transformer, $ast, $compiler ) = @_;
 		$ast = $transformer->transform_children( $ast, $compiler );
 		my $rulename = $ast->first_child()->first_child();
 		my $ignored = $ast->second_child()->first_child() ? 1 : 0;
		my $old_rulename = $ast->nth_child(4)->first_child();
 			 
 		#print "\n-- def --\n";
		#print "($rulename)($ignored)->($old_rulename)\n"; 		
		#dump_ast($ast);

		$self->{'parser'}->rename_rule( $old_rulename, $rulename );
		$self->{'grammar-ignore-list'}->{$rulename} = $ignored;
 		return $ast;
 	});

	$self->{'grammar-ignore-list'} = {}; # flag for each named rule
	$self->{'grammar-parser'} = $p;
	$self->{'grammar-transformer'} = $t;
	return 1;
}

sub grammar
{
	my( $self, $grammar ) = @_;
	$self->_create_grammar_analyser();
	
	# transform the actual grammar into the actual parser
	# (this will define new tokens and rules)
	
	my $ast = $self->{'grammar-parser'}->parse( $grammar );
	#dump_ast($ast);
	#exit;

	# we have to give $self
	$self->{'grammar-transformer'}->transform( $ast, $self );
	#dump($self->{'parser'}->{'tokenizer'}->{'tokennames'});
	#dump($self->{'parser'}->{'tokenizer'}->{'tokens'});
	#dump($self->{'parser'}->{'rules'});
	
	foreach my $rulename (keys %{$self->{'grammar-ignore-list'}}) {
		my $rule = $self->{'parser'}->get_rule( $rulename );
		if( ref $rule eq 'Parse::Highlife::Rule::Token' ) {
 			# set ignored-flag
 			my $token = $self->{'parser'}->get_token( $rule->{'token'} );
 			$token->{'is-ignored'} = $self->{'grammar-ignore-list'}->{$rulename};
 		}	
	}

	#dump_ast($ast);
	#dump($self->{'parser'}->{'tokenizer'});
	#dump($self->{'parser'}->{'rules'});
	
	#dump($self->{'grammar-parser'});
	#exit;
}

sub rule
{
	my( $self, @args ) = @_;
	return $self->{'parser'}->rule( @args );
}

sub toprule
{
	my( $self, @args ) = @_;
	return $self->{'parser'}->toprule( @args );
}

sub transformer
{
	my( $self, @args ) = @_;
	return $self->{'transformer'}->transformer( @args );
}

sub stringifier
{
	my( $self, @args ) = @_;
	return $self->{'transformer'}->stringifier( @args );
}

sub readfile
{
	my( $self, $filename ) = @_;
	return read_file( $filename );
}

sub parse
{
	my( $self, $string ) = @_;
	my $ast = $self->{'parser'}->parse( $string );
	#dump_ast($ast);
	return $ast;
}

sub transform
{
	my( $self, $ast, @args ) = @_;
	my $new_ast = $self->{'transformer'}->transform( $ast, @args );
	#dump_ast($new_ast);
	return $new_ast;
}

sub stringify
{
	my( $self, $ast, @args ) = @_;
	return $self->{'transformer'}->stringify( $ast, @args );
}

sub compile
{
	my( $self, @filenames ) = @_;
	my $stringified = '';
	foreach my $file (@filenames) {
		my $string 		= $self->readfile( $file );
		my $ast 			= $self->parse( @filenames );
		my $new_ast 	= $self->transform( $ast );
		$stringified .= $self->stringify( $new_ast );
	}
	return $stringified;
}

sub link
{
	my( $binary_filename ) = @_;
	# ...
}

1;
