use 5.008;
use strict;
use warnings;

package Template::Compiled;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Eval::TypeTiny qw( eval_closure );
use Types::Standard qw( -types slurpy Join );
use Type::Params 1.002000 qw( compile_named );
use Carp qw( croak confess );
use B qw( perlstring );

use constant PERL_NATIVE_ALIASES => ($] >= 5.02200);

use Moo;
use namespace::autoclean;

use overload
	'""'         => sub { $_[0]->template },
	'bool'       => sub { !!1 },
	'&{}'        => sub { $_[0]->sub },
	fallback     => 1,
	;

has template => (
	is        => 'ro',
	isa       => Str->plus_coercions( Join["\n"] ),
	required  => !!1,
	coerce    => !!1,
);

has signature => (
	is        => 'ro',
	isa       => Maybe[ArrayRef],
	predicate => !!1,
	required  => !!0,
);

has delimiters => (
	is        => 'lazy',
	isa       => Tuple[Str, Str],
	builder   => sub { [qw/ <? ?> /] },
);

has escape => (
	is        => 'ro',
	isa       => CodeRef->plus_coercions(Str, \&_lookup_escaping),
	required  => !!0,
	predicate => !!1,
	coerce    => !!1,
);

has trim => (
	is        => 'lazy',
	isa       => Bool,
	builder   => sub { !!0 },
);

has outdent => (
	is        => 'lazy',
	isa       => Int,
	builder   => sub { 0 },
);

has post_process => (
	is        => 'ro',
	isa       => CodeRef,
	required  => !!0,
	predicate => !!1,
);

has utils_package => (
	is        => 'lazy',
	isa       => Str,
	builder   => sub { __PACKAGE__ . '::Utils' },
);

has 'sub' => (
	is        => 'lazy',
	isa       => CodeRef,
	builder   => sub {
		my ($code, $env) = $_[0]->_build_code_and_env;
		eval_closure(
			source      => $code,
			environment => $env,
			description => 'template prelude',
		);
	},
);

sub print {
	my $self = shift;
	my $fh   = FileHandle->check($_[0]) ? shift() : undef;
	
	defined($fh)
		? $fh->print( $self->render(@_) )
		: CORE::print( $self->render(@_) );
}

sub render {
	my $self = shift;
	$self->sub->(@_);
}

sub _build_code_and_env {
	my $self = shift;
	
	my @code;
	my %env;
	
	push @code, 'sub {';
	push @code, sprintf('use %s;', $self->utils_package);
	
	push @code, 'sub _ ($);';
	push @code, '*_ = sub ($) { goto $_ESCAPE };';
	$env{'$_ESCAPE'} = \ do { $self->escape or sub { $_[0] } };
	
	push @code, 'local %_;';
	push @code, 'my ($OUT, $INDENT) = (q(), q());';
	push @code, 'our $_OUT_REF = \\$OUT;';
	
	if (PERL_NATIVE_ALIASES) {
		push @code, 'use feature qw( refaliasing );';
		push @code, 'no warnings qw( experimental::refaliasing );';
	}
	
	if ($self->has_signature) {
		push @code, '%_ = %{ $_SIGNATURE->(@_) };';
		$env{'$_SIGNATURE'} = \ do { compile_named(@{ $self->signature }) };
	}
	else {
		push @code, '%_ = (@_==1 and ref($_[0]) eq "HASH") ? %{$_[0]} : @_%2 ? Carp::croak("Expected even-sized list of arguments") : @_;';
	}
	
	if ($self->has_signature) {
		my @sig = @{ $self->signature };
		while (@sig) {
			shift @sig
				while HashRef->check($sig[0]) && !$sig[0]{slurpy};
			
			my $name = shift @sig;
			my $type = shift @sig;
			
			next unless $name =~ /\A[A-Z][A-Z0-9_]*\z/i;
			
			if (Bool->check($type)) {
				$type = $type ? Any : Optional[Any];
			}
			
			unless (PERL_NATIVE_ALIASES) {
				require Data::Alias;
			}
			
			push @code, PERL_NATIVE_ALIASES
				? "\\my \$$name = \\\$_{$name};"
				: "Data::Alias::alias( my \$$name = \$_{$name} );";
			
			if ($type->is_a_type_of(HashRef)) {
				push @code, PERL_NATIVE_ALIASES
					? "\\my \%$name = \$$name;"
					: "Data::Alias::alias( my \%$name = \%{ \$$name } );";
			}
			
			if ($type->is_a_type_of(ArrayRef)) {
				push @code, PERL_NATIVE_ALIASES
					? "\\my \@$name = \$$name;"
					: "Data::Alias::alias( my \@$name = \@{ \$$name } );";
			}
		}
	}
	
	push @code, "#line 1 \"template\"\n";
	
	my $template = $self->template;
	if ($self->trim) {
		$template =~ s/(?:\A\s*)|(?:\s*\z)//gsm;
	}
	
	if (my $outdent = $self->outdent) {
		$outdent > 0
			? ($template =~ s/^\s{0,$outdent}//gsm)
			: ($template =~ s/^\s+//gsm);
	}
	
	my @delims = @{ $self->delimiters };
	my $regexp = join('|', map quotemeta($_), @delims);
	my @parts  = split /($regexp)/, $template;
	
	my $mode = 'text';
	while (@parts) {
		
		my $next = shift @parts;
		
		if ($next eq $delims[0]) {
			$mode = ($mode eq 'text') ? 'code' : confess("Impossible state");
			next;
		}
		
		if ($next eq $delims[1]) {
			$mode = ($mode eq 'code') ? 'text' : confess("Impossible state");
			next;
		}

		my $terminator = $delims[ ($mode eq 'text') ? 0 : 1 ];
		while (@parts and $parts[0] ne $terminator) {
			$next .= shift(@parts);
		}

		if ($mode eq 'text') {
			$code[-1] .= sprintf('$OUT .= %s;', perlstring($next));
			if ($next =~ /\n/sm) {
				my $count = $next;
				$count = ($count =~ y/\n//);
				$code[-1] .= "\n" x $count;
			}
		}
		elsif ($next =~ /\A=/) {
			my ($indent) = map /\A(\s*)/, grep /\S/, split /\n/, substr($next, 1);
			$code[-1] .= sprintf(
				$self->has_escape ? '$OUT .= $_ESCAPE->(do { %s %s });' : '$OUT .= do { %s %s };',
				sprintf("\$INDENT = %s;", perlstring($indent)),
				substr($next, 1),
			);
		}
		else {
			my ($indent) = map /\A(\s*)/, grep /\S/, split /\n/, $next;
			$code[-1] .= sprintf("\$INDENT = %s; %s;", perlstring($indent), $next);
		}
	}
	
	if ($self->trim) {
		push @code, '$OUT =~ s/(?:\A\s*)|(?:\s*\z)//gsm;';
	}
	
	if ($self->has_post_process) {
		push @code, 'do { local *_ = \$OUT; $_POST->($OUT) };';
		$env{'$_POST'} = \ do { $self->post_process };
	}
	else {
		push @code, '$OUT;';
	}
	
	push @code, '}';
	
	#warn join "\n", @code, "";
	return (\@code, \%env);
}

sub _lookup_escaping {
	my $style = shift;
	
	return $style if CodeRef->check($style);
	
	$style = lc $style;
	
	if ($style eq 'html') {
		require HTML::Entities;
		return \&HTML::Entities::encode_entities;
	};
	
	if ($style eq 'xml') {
		require HTML::Entities;
		return \&HTML::Entities::encode_entities_numeric;
	};
	
	croak "Unsupported escaping style '$style'";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Template::Compiled - templates which compile into coderefs

=head1 SYNOPSIS

   use Template::Compiled;
   use Types::Standard -types;
   
   my $template = Template::Compiled->new(
      signature  => [ name => Str, age => Optional[Int] ],
      delimiters => [ qw( [% %] ) ],
      outdent    => 2,
      trim       => 1,
      escape     => 'html',
      template   => q{
         <p>Dear [%= $name %]</p>
         [% if (defined($age)) { %]
         <p>I see you are [%= $age %] years old.</p>
         [% } %]
      },
   );
   
   print $template->( name => 'Alice & Bob', age => 99 );

=head1 DESCRIPTION

Template::Compiled allows you to define a template which will be compiled
into a coderef that renders the template, filling in values. Templates
can contain variables and chunks of Perl code.

Technically, the template is an object which overloads C<< &{} >> so that
it can act like a coderef, but you can get a real coderef by calling
C<< $template->sub >>.

Compiling the coderef might be slower than some other template modules,
but rendering the template should be pretty much as fast as a pure Perl
template module can get. So in a persistent environment, where the same
template may be used over and over, this should be pretty fast.

=head2 Attributes

The class provides a standard Moose-style constructor with the following
attributes.

=over

=item C<< template >> (Str, required) 

The template as a string of text. Details of the template format are
described below. This attribute will coerce from an arrayref of strings
by joining them.

=item C<< signature >> (ArrayRef, optional)

A sub signature for validating arguments passed to the template when
rendering it. Must be suitable for L<Type::Params> C<compile_named>.

=item C<< delimiters >> (Tuple[Str, Str], optional)

The strings which delimit code within the template. The default
delimiters are the PHP-ish C<< <? >> and C<< ?> >>.

=item C<< escape >> (CodeRef, optional)

A coderef to autoescape strings. For example:

   my $template = Template::Compiled->new(
      ...,
      escape => sub {
         my $text = shift;
         HTML::Entities::encode_entities_numeric($text);
      },
   );

As a shortcut, you may say C<< escape => "html" >> or
C<< escape => "xml" >>.

=item C<< trim >> (Bool, optional)

If set to true, leading and trailing whitespace will be trimmed from
the rendered output. (Not from each line!)

Defaults to false.

=item C<< outdent >> (Int, optional)

This many whitespace characters are trimmed from the start of every
line. If negitive, all whitespace is trimmed from the start of every
line.

Defaults to zero.

=item C<< post_process >> (CodeRef, optional)

If provided, this coderef gets a chance to modify the rendered
output right at the end. It should be a coderef manipulating
C<< $_ >>.

=item C<< utils_package >> (Str, optional)

A package to import into the namespace the coderef is compiled in.
Defaults to L<Template::Compiled::Utils> which provides some useful
functions.

=item C<< sub >> (CodeRef, optional)

The whole point of this module is to let us generate this for you.
Don't provide it to the constructor!

The sub doesn't contain any references back to the Template::Compiled
object, so it can be garbage collected by Perl.

   my $template = Template::Compiled->new( ... );
   my $compiled = $template->sub;
   undef $template;   # free memory used by object
   
   print $compiled->( %args );

=back

=head2 Methods

These are not especially necessary, but this module provides some
methods which may make your code a little clearer.

=over

=item C<< $template->render( %args ) >>

Alternative way to write C<< $template->( %args ) >>.

=item C<< $template->print( %args ) >>

Alternative way to write C<< print( $template->( %args ) ) >>.

=item C<< $template->print( $fh, %args ) >>

Alternative way to write C<< $fh->print( $template->( %args ) ) >>.

=back

=head2 Overloads

Template::Compiled overloads the following operations:

=over

=item C<< bool >>

Always true.

=item C<< &{} >>

Returns C<sub>.

=item C<< "" >>

Returns C<template>.

=back

Future versions may overload concatenation to do something useful.

=head1 TEMPLATE FORMAT

Templates are strings with embedded Perl code. Although the delimeters
can be changed, there are two basic forms for the Perl code:

   <?=  EXPR  ?>
   <?   CODE  ?>

The first form evaluates EXPR and appends it to the output string,
escaping it if necessary. (The expression is actually evaluated in
a C<do> block, so may include multiple semicolon-delimited statements,
and has its own lexical scope.)

The second form evaluates CODE but does not automatically append
anything to the output. If you need to append anything to the output
string in your code block, you can do C<< $OUT .= "blah" >> or
C<< echo "blah" >>. (Don't use C<print> because this will print
immediately rather than appending to the output!)

=head2 Variables

Within the template, the following variables are available to you:

=over

=item C<< $OUT >>

The output of the template so far. May be altered or appended to.

=item C<< $INDENT >>

A string of whitespace equivalent to how much this block of code
is indented, minus outdenting.

=item C<< %_ >>

A hash of the arguments provided when rendering the template.

For example, with:

   $template->render( foo => 1, bar => [ 2, 3, 4 ] );

Then:

   <?= $_{foo}    ?>     # 1
   <?= $_{bar}[0] ?>     # 2

If your template declared a signature, then named aliases are
provided for arguments.

   <?
      $foo;       # 1
      $bar;       # [ 2, 3, 4 ]
      
      # And if the signature declared that 'bar' was an
      # ArrayRef, then...
      #
      @bar;       # ( 2, 3, 4 )
   ?>

So, yeah, use signatures.

=back

Scalar variables named with a leading underscore are reserved for
internal use. Avoid them in your templates.

=head2 Functions

Within the template, the following functions are available to you:

=over

=item C<< _($string) >>

The C<< <?= $foo ?> >> syntax automatically passes the variable through
the template's escaping mechanism, but if you're using C<< <? CODE ?> >>
you will need to escape strings manually. The C<< _() >> function can
escape stuff for you.

=item C<< echo($string) >>

Equivalent to C<< $OUT .= $string >>.

Provided by L<Template::Compiled::Utils>, so may not be available if
you're using a different utils package.

=item C<< echof($format, @data) >>

Equivalent to C<< $OUT .= sprintf($format, @data) >>.

Provided by L<Template::Compiled::Utils>, so may not be available if
you're using a different utils package.

=back

=head2 Escaping

The start and end delimiters for code I<< cannot be escaped >>.

But this isn't really as bad as it seems. If you need to output them
literally:

   <? echo '<?' ?>
   <? echo '?'.'>' ?>

If that becomes inconvenient, then you can simply choose different
delimiters.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Template-Compiled>.

=head1 SEE ALSO

L<Template::Perlish> is pretty similar really.

L<Type::Params> provides the signatures for this module.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

