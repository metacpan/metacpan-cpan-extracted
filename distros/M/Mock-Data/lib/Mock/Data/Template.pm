package Mock::Data::Template;
use strict;
use warnings;
use overload '""' => sub { shift->to_string };
require Carp;
use Mock::Data::Util qw( _parse_context _escape_str );
require Mock::Data::Generator;
our @ISA= qw( Mock::Data::Generator );

# ABSTRACT: Create a generator that plugs other templates into a string
our $VERSION = '0.04'; # VERSION


sub new {
	my $class= shift;
	my %self= (@_ == 1 && !ref $_[0])? ( template => $_[0] )
		: (@_ == 1 && ref $_[0] eq 'HASH')? %{$_[0]}
		: @_ > 1? @_
		: Carp::croak("Invalid constructor arguments to $class");
	# Parse now, to report errors
	$self{_compiled}= $class->parse_template($self{template}, { compile => 1 });
	bless \%self, $class;
}


sub template { shift->{template} }


sub compile {
	my $cmp= $_[0]{_compiled};
	return ref $cmp? $cmp : sub { $cmp };
}

sub generate {
	my $cmp= shift->{_compiled};
	return ref $cmp? $cmp->(@_) : $cmp;
}


sub to_string {
	"template('" . shift->template . "')";
}


sub parse_template {
	my ($self, $str, $flags)= @_;
	local $_= $str;
	pos= 0;
	my $ret;
	local $@;
	defined eval { $ret= _parse_template($flags || {}) }
		or Carp::croak("$@ at "._parse_context);
	return $ret;
}

# Parse a template string in $_ from pos($_)
sub _parse_template {
	my @parts;
	my $outer= !$_[0]{inner};
	local $_[0]{inner}= 1 if $outer;
	while (1) {
		# Consume run of literal characters
		push @parts, $1 if $outer? /\G([^{]+)/gc : /\G([^ \t\{\}]+)/gc;
		# at end of template, or beginning of a reference to something
		last unless /\G(?=\{)/gc;
		push @parts, _parse_template_reference(@_);
	}
	# Combine adjacent scalars in the list
	@parts= grep ref $_ || length, @parts;
	for (my $i= $#parts - 1; $i >= 0; --$i) {
		if (!ref $parts[$i] and !ref $parts[$i+1]) {
			$parts[$i] .= splice(@parts, $i+1, 1);
		}
	}
	if ($_[0]{compile}) {
		return @parts == 1 && !ref $parts[0]? $parts[0]
			: sub { join '', map +(ref($_)? $_->(@_) : $_), @parts }
	} else {
		return \@parts;
	}
}

# Parse one of the curly-brace notations
sub _parse_template_reference {
	if (/\G\{([\w:]+)/gc) {
		my $generator_name= $1;
		my (@named_param, @pos_param);
		if (/\G[ \t]+/gc) {
			while (!/\G\}/gc) {
				if (/\G(\w+)=/gc) {
					push @named_param, $1, _parse_template(@_);
				} else {
					push @pos_param, _parse_template(@_);
				}
				/\G[ \t]*/gc;
			}
		} else {
			/\G\}/gc or die "Expected '}'";
		}
		if ($_[0]{compile}) {
			# compile by making a list of which params are function calls, and update lists for only those positions
			my @named_literal= @named_param;
			my @dynamic_named= grep ref $named_param[$_], 0 .. $#named_param;
			my @pos_literal= @pos_param;
			my @dynamic_pos= grep ref $pos_literal[$_], 0 .. $#pos_param;
			if (@named_param) {
				return sub {
					$named_literal[$_]= $named_param[$_]->(@_) for @dynamic_named;
					$pos_literal[$_]= $pos_param[$_]->(@_) for @dynamic_pos;
					$_[0]->call($generator_name, { @named_literal }, @pos_literal);
				}
			} else {
				return sub {
					$pos_literal[$_]= $pos_param[$_]->(@_) for @dynamic_pos;
					$_[0]->call($generator_name, @pos_literal);
				}
			}
		} else {
			return [ $generator_name, (@named_param? { @named_param }:()), @pos_param ];
		}
	}
	return chr hex $1 if /\G\{ [#] ([0-9A-Za-z]+) \}/xgc;
	return '' if /\G\{\}/xgc;
	die "Invalid template notation\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Template - Create a generator that plugs other templates into a string

=head1 SYNOPSIS

  my $mock= Mock::Data->new(
    generators => {
      first_name => ['Alex','Pat'],
      last_name => ['Smith','Jones'],
      name => Mock::Data::Template->new("{first_name} {last_name}"),
      ten_words => "{join word count=10}",
    }
  );

=head1 DESCRIPTION

L<Mock::Data> provides a convenient and simple templating system where C<< "{...}" >> in the
text gets replaced by the output of another generator.  The contents of the curly braces can
be a simple template name (which is found by name in the collection of generators of the current
C<Mock::Data> ) or it can include parameters, both positional and named.

=head2 SYNTAX

  # Call without parameters
  "literal text {template_name} literal text"
  
  # Call with positional parameters
  "literal text {template_name literal_param_1 literal_param_2} literal text"
  
  # Call with named parameters
  "literal text {template_name param5=literal_val} literal text"
  
  # Call with whitespace in parameter (hex escapes)
  "literal text {template_name two{#20}words} literal text"
  
  # Call with zero-length string parameter (prefix => "")
  "literal text {template_name prefix={}}"
  
  # Call with nested templates
  "{template1 text{#20}with{#20}{template2}{#20}embedded}"

=head1 CONSTRUCTOR

=head2 new

  Mock::Data::Template->new($template);
				   ...->new(template => $template);

This constructor only accepts one attribute, C<template>, which will be immediately parsed to
check for syntax errors.  Note that references to other generators are not resolved until the
template is executed, which may cause exceptions if generators of those names are not present
in the C<Mock::Data> instance.

Instances of C<Mock::Data::Template> do not hold references to the C<Mock::Data> or anything in
it, and may be shared freely.

=head1 ATTRIBUTES

=head2 template

The template string that was passed to the constructor

=head1 METHODS

=head2 compile

Return a coderef that executes the generator.

=head2 generate

Evaluate the template on the current L<Mock::Data> and return the string.

=head2 to_string

Templates stringify as C<< "template('original_text')" >>

=head2 parse_template

  my $tree= Mock::Data::Template->parse_template("{a}{b}{c {d}}");
  my $sub=  Mock::Data::Template->parse_template("{a}{b}{c {d}}", { compile => 1 });

Class or instance method.  This parses a template string, returning a scalar, or an
arrayref of parts where scalars are literal strings and arrayrefs represent a call
to another generator.  Arrayrefs in the parameter list of the call to a generator
represent templates, and arrayrefs within that represent call, and arrayrefs within
that represent templates, and so on.

If the C<compile> flag is given, this returns a coderef instead of an arrayref (but
can still return a plain scalar).  The coderef matches the API for generators, taking
a reference to L<Mock::Data> as the first parameter.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.04

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
