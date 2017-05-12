package Template::Jade::Document;
use strict;
use warnings FATAL => 'all';

use feature ':5.12';

use Moose;
use DateTime;
use Text::Markdown::Discount;
use Template::Jade::Helpers qw(:all);

with 'Template::Jade::BufferedIO';

has '_fh_code' => (
	isa  => 'FileHandle'
	, is => 'ro'
	, default => sub { 
		open(my $fh, '+>', \my $output) or die $!;
		$fh;
	}
	, predicate => '_has_fh_code'
);

has 'fh_output' => (
	isa  => 'FileHandle'
	, is => 'ro'
);

has 'parent' => ( isa => 'Str', is => 'rw', predicate => 'has_parent' );

has 'includes' => (
	isa => 'HashRef'
	, is => 'rw'
	, default => sub { +{} }
	, traits => ['Hash']
	, handles => {
		'_add_include'         => 'set'	
		, '_has_include_cache' => 'defined'
	}
);

has 'blocks' => (
	isa => 'HashRef[ArrayRef]'
	, is => 'rw'
	, default => sub { +{} }
	, traits => ['Hash']
	, handles => {
		'_add_block'   => 'set'	
		, '_get_block' => 'get'	
	}
);

has 'compile_debug' => (
	isa => 'Bool'
	, is => 'ro'
	, default => 0
);

sub BUILD {
	my $self = shift;
	if ( $self->_has_fh_code ) {
		$self->_fh_code->flush;
	}
}

sub process {
	my $self = shift;

	my $fh_i    = $self->fh_input;
	my $fh_code = $self->_fh_code;


	##################
	## GENERATE SUB ##
	##################

	## Handle DOCTYPE which can only exist on :1
	{
		my $line = $self->_readline;
		if ( $. == 1 ) {
			if ( $line =~ /^doctype (.*)/ ) {
				printf( $fh_code qq{\tprint "%s";}, quotemeta gen_doctype($1) );
			}
			elsif ( $line =~ qr/^ \s* extends \s+ (?<extends>(\S+))/x ) {
				$self->parent($1);
			}
			## neither doctype nor extends
			else {
				$self->_buffer_push( $line );
			}
		}
		## provided fh not at :1
		else {
			$self->_buffer_push( $line );
		}
	}

	while ( ! eof $fh_i or $self->_buffer_length ) {
		$self->parse_tree;
	}

	$fh_code->flush;

	if ( $self->has_parent ) {
		if ( $self->compile_debug ) {
			warn sprintf(
				"In %s spawning parent: %s\n"
				, $self->filename
				, $self->parent
			)
		}
		my $sub = $self->meta->name->new(
			filename => $self->parent
			, blocks => $self->blocks	
			, compile_debug => $self->compile_debug
		)->process;

		return $sub;
	}
	else {
		my $output;
		{
			local $/ = undef;
			seek( $fh_code, 0, 0 );
			$output = <$fh_code>;
		}

		if ( $self->compile_debug ) {
			say "\n"x2;
			say "COMPILE DEBUG";
			say "=============";
			say $output;
		}
 
		my $sub = eval (START_SUB . $output . END_SUB);
		die $@ if $@;

		## Wrap the sub
		return sub {
			my $args = shift;
			if ( defined $args->{meta} ) {
				confess 'META is for me not, you'
			}
			else {
				$args->{meta}= {
					compile_time => DateTime->now->ymd('-')
					, includes   => $self->includes
				};
			}

			if ( my $fh = $self->fh_output ) {
				open ( local(*STDOUT), '>&', $fh ) or die $!;
				$sub->($args);
			}
			else {
				open ( local(*STDOUT), '>', \my $output ) or die $!;
				$sub->($args);
				return $output
			}
		};

	}

}

sub parse_tree {
	my $self = shift;
	my $fh_code = $self->_fh_code;

	my $input_line = $self->_readline;
	return '' unless $input_line;

	state $atom_include   = qr/include \s+ (?<include>(\S+))/x;
	state $atom_block     = qr/block \s+ (?<block>.+)/x;
	state $atom_comment   = qr/(?<comment>[\/]{2}-?)   \s*   (?<text>.*)/x;
	state $atom_jade_code = qr/(?<jadecode>if|unless|each|else|case)/x;
	state $atom_perl_expr = qr/\- \s+ (?<perlexpr>.+) /x;
	state $atom_submarkup = qr/(?<submarkup>:markdown) \s* $/x;

	state $atom_html_with_attribute = qr/
		(?<tag>  (?:[a-zA-Z0-9_.#-]*[a-zA-Z0-9]) (?:\((?:[^()]++|(?-1))*+\))? )
		(?<tagmodes> (?: [.=:] | != )? )
	/x;

	$input_line =~  qr/
		^
		(?<leftpad>\s*)
		(?:
			$atom_block
			|$atom_include
			|$atom_jade_code
			|$atom_perl_expr
			|$atom_submarkup
			|$atom_comment
			|$atom_html_with_attribute
		)
		\s* (?<text>.+)?
	/x;
	
	my ( $leftpad, $tag, $tagmodes, $text, $jade_code, $perl_expr, $comment, $submarkup, $include, $block )
		= @+{qw/leftpad tag tagmodes text jadecode perlexpr comment submarkup include block/};
		
	my $state = {
		leftpad    => $+{leftpad}
		, block    => $+{block}
		, tag      => $+{tag}
		, tagmodes => $+{tagmodes}
		, text     => $+{text}
		, comment  => $+{comment}
		, code     => $+{code}
		, include  => $+{include}
	};
	
	## Handles indent
	my $indent;
	if ( $leftpad ) { # perl's truthy is valid for whitespace
		if ( $leftpad =~ /\t | \t/ ) {
			die "ERROR mixing tabs and spaces on left margin\n";
		}
		else {
			$indent = ( length @{[$leftpad =~ m/[\t ]+/g]}[0] );
		}
	}

	######################
	## HANDLE OPEN TAGS ##
	######################

	if ( $include ) {
		unless ( $self->_has_include_cache($include) ) {
			open my $fh, '<', $include or die $!;
			my $compile = $self->meta->name->new(
				fh_input => $fh
			)->process;
			$self->_add_include( $include => $compile );
		}
		printf( $fh_code qq/\n\$META{includes}{q{%s}}->();\n/, $include );
	}

	elsif ( $block ) {
		if ( $self->has_parent ) {
		}
		else {
			my $content = $self->_get_block($block);
			for ( @$content ) {
				$self->_buffer_push($_);
			}
		}
	}

	elsif ( $jade_code ) {
		if ($jade_code =~ /if|unless|else/) {
			printf( $fh_code qq{\n%s %s \{}, $jade_code, ($text?"($text)":'') );
		}
		else {
			die __PACKAGE__ . " code structure [$jade_code] is not yet supported\n";
		}
	}

	elsif ( $perl_expr ) {
		printf( $fh_code qq{\n%s}, $perl_expr );
	}

	## Handles // and //-
	elsif ( $comment ) {
		# Ignore '//-' just toss it all.
		if ( $comment eq '//' ) {
			printf( $fh_code qq{\n\tprint "\\n%s%s\\n%s%s";}, $leftpad, quotemeta "<!--", $leftpad, $text );
		}
	}	

	## Handles regular Jade/HTML5 w/ & wo/ text
	elsif ( $tag ) {
		printf( $fh_code qq{\n\tprint "\\n%s%s";}, $leftpad, gen_open_tag($tag) );
	
		if ( $text ) {
			## If we have inline tokens
			if ( $tagmodes ) {

				## Handles inline tags, ex `span: small: a(href="/")`
				if ( $tagmodes eq ':' ) {
					$self->_buffer_push( $leftpad . $text );
					$self->parse_tree();
				}

				## Trigger perl interpolation, `tag=`
				if ( $tagmodes =~ /=/ ) {
					## Optimization for simple var, `tag=var`
					if ( $text =~ /^\s*\w+\s*$/ ) {
						printf(
							$fh_code
							qq{\n\tprint "\\n%s\$TEMPLATE{%s}";}
							, $leftpad
							, quotemeta $text
						);
					}
					## Code wrapped in sub.
					elsif ( $tagmodes eq '!=' ) {
						printf( $fh_code qq{\n\tprint "\\n%s" . } . printf_inline_sub(0) , $leftpad , $text );
					}
					else {
						printf( $fh_code qq{\n\tprint "\\n%s" . } . printf_inline_sub(1) , $leftpad , $text );
					}
				}
			}
			else {
				printf( $fh_code qq{\n\tprint "\\n%s%s";}, $leftpad, quotemeta $text );
			}
		}

	}

	my @buffer;

	## Passthrough or recursion cases
	while( my $next = $self->_readline() ) {
		if ( $next =~ m/^$leftpad\s+/ ) {

			# If it is text, output it.
			if (
				$tagmodes && $tagmodes eq '.'
				or $comment && $comment eq '//'
				or $next =~ s/(?<!\S)\|\s*//
			) { 
				printf( $fh_code qq{\n\tprint "\\n%s";}, quotemeta $next );
				next;
			}
			elsif ( $comment && $comment eq '//-' ) {
				next;
			}
			elsif ( $submarkup ) {
				$next =~ s/^\s*//;
				push @buffer, $next;
				next;
			}
			elsif ( $block && $self->has_parent ) {
				push @buffer, $next;
				next;
			}
			# If it's not text put it back on the buffer and recurse
			else {
				$self->_buffer_push( $next );
				$self->parse_tree;
			}
		}

		# If we're done with the block (deindention)
		else {
			$self->_buffer_push( $next );
			$tagmodes = undef;
			last;
		}

	}

	#######################
	## HANDLE CLOSE TAGS ##
	#######################
	
	if ( $include ) {}
	elsif ( $jade_code ) {
		printf( $fh_code qq{\n%s}, '}' );
	}
	elsif ( $comment ) {
		# if comment is //- toss it
		if ( $comment eq '//' ) {
			printf( $fh_code qq{\n\tprint "\\n%s%s";}, $leftpad, quotemeta "-->" );
		}
	}
	elsif ( $submarkup ) {
		my @lines = split /\\n\s*/, Text::Markdown::Discount::markdown( join '\n', @buffer );
		for ( @lines ) {
 			printf( $fh_code qq{\n\tprint "\\n%s%s";}, $leftpad, quotemeta $_ );
		}
	}
	elsif ( $block && $self->has_parent ) {
		$self->_add_block($block, \@buffer);
	}
	elsif ( $tag ) {
		# XXX this would be sexy if I cached tag information
		my $end_tag = gen_close_tag( $tag );
		if ( $end_tag ) {
			printf( $fh_code qq{\n\tprint "\\n%s%s";}, $leftpad, quotemeta $end_tag );
		}
	}

	return 1;

}

1;
