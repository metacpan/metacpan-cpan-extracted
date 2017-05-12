package Parse::GLSL;
# ABSTRACT: Parse OpenGL Shader Language files into an abstract syntax tree
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';
use parent qw(Parser::MGC);
use Text::Tabs ();

our $VERSION = '0.002';

=head1 NAME

Parse::GLSL - extract an Abstract Syntax Tree from GLSL text

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Parse::GLSL;
 use Data::Dumper;
 my $parser = Parse::GLSL->new;
 my $txt = '';
 while(my $line = <DATA>) {
   if($line =~ /^\s*#\s*(?:(.*))$/) {
     my $cmd = $1;
     warn "Had directive [$cmd]\n";
   } else {
     $txt .= $line;
   }
 }
 print Dumper $parser->from_string($txt);

=head1 DESCRIPTION

Warning: This is a preview release, and the entire API is subject to change several times over the next
few releases.

This module provides basic parsing for the OpenGL Shading Language (currently dealing with fragment and
vertex shaders, eventually will be expanded to cover geometry, tesselation and compute shaders as well).

The GLSL document is parsed using L<Parser::MGC>, rather than the reference 3D Labs GLSL parser implementation,
and a Perl data structure is generated as output.

Currently very basic variable checking is performed - vars must be declared before use, so this would raise
an error:

 void main(void) {
   vec2 tex_coord;
   vec2 c = unknown_var * tex_coord.st;
 }

Further checks are planned in future versions.

The exact nature of the data structure returned is subject to change, so it's not currently documented.

=head1 METHODS

=cut

=head2 new

Constructor - see L<Parser::MGC> for full details. This is defined here to override the standard
string delimiter to " since C strings don't use the ' delimiter. Not that strings have much place
in GLSL per se...

=cut

sub new {
	my $class = shift;
	my %args = @_;
	$args{string_delim} = qr/"/ unless exists $args{string_delim};
	my $debug = delete $args{debug};
	my $self = $class->SUPER::new(%args);
	$self->{debug} = $debug || 0;
	# Predefined vars
	# FIXME These are type-specific and version-specific - fragment vars and vertex vars are not the
	# same, should differentiate depending on how that's going to be handled (subclasses?)
	$self->{variables}->{$_} = { 'defined' => 1 } for qw(gl_Position gl_NormalMatrix gl_Normal gl_Vertex gl_ModelViewMatrix);

	# Predefined macros - each takes $self as the first parameter, and maybe some other stuff if we end up supporting those.
	# Note that these are the literal strings, *not* the built-in perl vars of the same names.
	$self->{macro} = {
		'__FILE__' => sub { my $self = shift; $self->current_file },
		'__LINE__' => sub { my $self = shift; $self->current_line },
		'__VERSION__' => sub { my $self = shift; $self->current_version },
	};
	$self;
}

=head2 where_am_i

Reports current position in line if $self->{debug} is set to 2 or above.

=cut

sub where_am_i {
	my $self = shift;
	return unless $self->{debug} > 1;

	my $note = shift || (caller(1))[3];
	my ($lineno, $col, $text) = $self->where;
	my $len = length($text);
	my $target_pos = $col;
	$target_pos++ while $target_pos < length($text) && substr($text, $target_pos, 1) =~ /^\s/;
	$target_pos++;
	substr $text, ($target_pos >= length($text) ? length($text) : $target_pos), 0, "\033[01;00m";
	substr $text, $col, 0, "\033[01;44m";
	$text = sprintf '%-80.80s', Text::Tabs::expand($text);
	printf "%s %d,%d %d %s\n", $text, $col, $lineno, $len, $note;
}

=head2 parse

Parse the given GLSL string.

=cut

sub parse {
	my $self = shift;

	$self->where_am_i;
	$self->sequence_of(sub {
		$self->parse_item
	});
}

=head2 parse_item

Parse an "entry" in the GLSL text. Currently this consists of top-level variable declarations and function
declarations.

=cut

sub parse_item {
	my $self = shift;

	$self->where_am_i;
	$self->any_of(
		sub {
		# Try to extract a variable definition
			my $decl = $self->parse_declaration or return;
			$self->expect(';');
			$decl
		},
		sub { $self->parse_function },
	);
}

=head2 parse_declaration

Parse a variable declaration.

=cut

sub parse_declaration {
	my $self = shift;

	$self->where_am_i;
	$self->sequence_of(sub {
		[ $self->maybe(sub { $self->token_kw(qw(uniform varying in out)); }), $self->parse_type, $self->parse_definition(1) ]
	});
}

=head2 parse_definition

Parse a "definition" (x = y), currently this also includes bare identifiers so that it works with
L</parse_declaration> but this behaviour is subject to change.

=cut

sub parse_definition {
	my $self = shift;
	my $defining = shift;

	$self->list_of(',', sub {
		$self->where_am_i;
		my $var = $self->token_ident or return;
		$self->{variables}->{$var} = {
			'defined' => 1
		} if $defining;
		print "Parsing the definition for [$var]\n" if $self->{debug};
		die "Variable $var not defined?" unless $self->{variables}->{$var};
		my $expr;
		my $assignment;
		$self->maybe(sub {
			if($defining) {
				($assignment) = $self->expect('=');
			} else {
				($assignment) = $self->expect(qr{([*/+-]?)=});
			}
			$expr = $self->parse_expression or return;
			$self->{variables}->{$var}->{expression} = $expr;
		});
		if(defined $expr) {
			return [ $var, $assignment, $expr ];
		} else {
			return [ $var ];
		}
	});
}

=head2 parse_type

Parse the variable type.

=cut

sub parse_type {
	my $self = shift;
	$self->token_kw(qw(int float vec2 vec3 vec4));
}

=head2 parse_parameter

Parse the parameters for a function definition.

=cut

sub parse_parameter {
	my $self = shift;

	$self->where_am_i;
	$self->list_of(
		',',
		sub {
			$self->any_of(
				# FIXME there are other parameter types!
				sub { $self->token_kw(qw(void)) },
			)
		}
	);
}

=head2 parse_function

Parse a function definition and code block.

=cut

sub parse_function {
	my $self = shift;

	$self->where_am_i;
	$self->sequence_of(sub {
		[
			$self->token_kw(qw(int float vec2 vec3 vec4 void)),
			$self->token_ident,
			$self->scope_of('(', sub {
				$self->where_am_i;
				$self->list_of(',', sub { $self->parse_parameter })
			}, ')'),
			$self->parse_block
		]
	});
}

=head2 parse_block

Parse a block of statements (including the { ... } delimiters).

=cut

sub parse_block {
	my $self = shift;
	$self->where_am_i;
        $self->scope_of( "{", sub { $self->parse_statements }, "}" );
}

=head2 parse_statement

Parse a single statement. This includes the trailing ; since it's a terminator not a
separator in GLSL.

=cut

sub parse_statement {
	my $self = shift;

	$self->where_am_i;
	$self->any_of(
		sub { $self->parse_loopy_thing; },
		sub { my $decl = $self->parse_declaration or return; $self->expect(';'); $decl },
		sub { my $def = $self->parse_definition; $self->expect(';'); $def },
	);
}

=head2 parse_loopy_thing

Handle control statements like if, while, that sort of thing. Any comments about the name of
this method should consider the first line in the L</DESCRIPTION>.

=cut

sub parse_loopy_thing {
	my $self = shift;
	$self->any_of(
		sub {
			my $kw = $self->token_control_keyword or return;
			print "Have statement [$kw]\n" if $self->{debug};
			[ $kw, $self->parse_expression, $self->parse_block ]
		}
	);
}

=head2 token_control_keyword

Parse a 'control keyword' (or 'loopy_thing' if you've been reading the other methods). That means
if, while, and anything else that C<does(expression) { block }>.

=cut

sub token_control_keyword {
	my $self = shift;
	$self->token_kw(qw(
		if while
	));
}

=head2 parse_expression

Parse an expression, such as fract(c) or 1 + 3 / 12 * vec3(1.0).

=cut

sub parse_expression {
	my $self = shift;

	$self->where_am_i;
	$self->any_of(
		sub { $self->scope_of('(', sub { $self->commit; $self->parse_expression }, ')') },
		sub {
			[ $self->parse_nested_expression, $self->token_operator, $self->parse_nested_expression ]
		},
		sub { $self->parse_nested_expression },
	);
}

=head2 parse_nested_expression

Parse the bit inside an expression ... so not really a nested expression, more like an
expression atom or component maybe?

=cut

sub parse_nested_expression {
	my $self = shift;
	$self->where_am_i;
	$self->any_of(
		sub {
			$self->where_am_i;
			my $func = $self->token_function or return;
			print "Using function [$func]\n" if $self->{debug};
			[
				$func,
				$self->scope_of('(', sub {
					$self->commit;
					$self->list_of(',', sub {
						$self->parse_expression
					});
				}, ')')
			]
		},
		sub { $self->token_float },
		sub { $self->token_glsl_ident },
	);
}


=head2 token_operator

hey look it's a binary operator

=cut

sub token_operator {
	my $self = shift;
	$self->where_am_i;
	$self->expect(qr{[*+/-]|>=|<=|>|<|==|!=});
}

=head2 token_function

Known built-in functions. Eventually these will be extracted to a separate definition block
so that parameter types + counts can be verified.

=cut

sub token_function {
	my $self = shift;
	$self->token_kw(qw(
		radians degrees sin cos tan asin acos atan sinh cosh tanh asinh acosh atanh pow exp
		log exp2 log2 sqrt inversesqrt abs sign floor trunc round roundEven ceil fract mod
		min max clamp mix step smoothstep isnan isinf length distance dot cross normalize
		faceforward reflect refract matrixCompMult transpose inverse outerProduct lessThan
		lessThanEqual greaterThan greaterThanEqual equal notEqual any all not textureSize
		texture textureProj textureLod textureGrad textureOffset texelFetch texelFetchOffset
		textureProjLod textureProjGrad textureProjOffset textureLodOffset textureGradOffset
		textureProjLodOffset textureProjGradOffset dFdx dFdy fwidth noise1 noise2 noise3
		noise4 vec2 vec3 vec4 ftransform
	));
}

=head2 token_preprocessor_directive

Parse a preprocessor directive.

Note that '#' is perfectly valid as a directive.

=cut

sub token_preprocessor_directive {
	my $self = shift;
	$self->token_kw(qw(
		define
		undef
		if
		ifdef
		ifndef
		else
		elif
		endif
		error
		pragma
		extension
		version
		line
	));
}

=head2 token_macro

Pick up on #defined (macro) values.

=cut

sub token_macro {
	my $self = shift;
	$self->token_kw(keys %{$self->{macro}});
}

=head2 expand_macro

Attempt to expand the given macro.

=cut

sub expand_macro {
	my $self = shift;
	my $macro = shift;
	my $code = $self->macro($macro, @_) or return undef;
	return $code->($self);
}

=head2 token_glsl_ident

A GLSL identifier. Somewhat vague term, currently includes variables and
qualified pieces (colour.r).

=cut

sub token_glsl_ident {
	my $self = shift;
	$self->where_am_i;
	[ $self->token_ident, $self->maybe(sub { $self->expect('.'); $self->token_ident }) ]
}

=head2 parse_statements

Parse more than one statement.

=cut

sub parse_statements {
	my $self = shift;
	$self->sequence_of(sub { $self->parse_statement });
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<http://www.opengl.org> - particularly the official "Orange Book"

=item * L<OpenGL::Shader> - if you want to use shaders with Perl

=item * reference 3d Labs GLSL compiler

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2012. Licensed under the same terms as Perl itself.
