package String::Replace;
our $VERSION = '0.02';
use strict;
use warnings;
use Exporter 'import';
use Scalar::Util 'reftype', 'blessed';
use List::MoreUtils 'natatime';
use Carp;

our @EXPORT_OK = ('replace', 'unreplace');
our %EXPORT_TAGS = ('all' => [ @EXPORT_OK ] );

sub __prepare_replace {
	my @l;
	if (@_ == 1 && ref($_[0]) && reftype($_[0]) eq 'HASH') {
		@l = ( %{$_[0]} );
	} elsif (@_ == 1 && ref($_[0]) && reftype($_[0]) eq 'ARRAY') {
		@l = @{$_[0]};
	} else {
		@l = @_;
	}

	croak 'The replace list must have an even number of element' if @l & 1;

	my $it = natatime 2, @l;

	my @repl;
	while (my ($k, $v) = $it->()) {
		push @repl, [qr{\Q$k\E}, $v];
	}

	return \@repl;
}

sub __prepare_unreplace {
	my @l;
	if (@_ == 1 && ref($_[0]) && reftype($_[0]) eq 'HASH') {
		@l = ( %{$_[0]} );
	} elsif (@_ == 1 && ref($_[0]) && reftype($_[0]) eq 'ARRAY') {
		@l = @{$_[0]};
	} else {
		@l = @_;
	}

	croak 'The replace list must have an even number of element' if @l & 1;

	my $it = natatime 2, @l;

	my @repl;
	while (my ($k, $val) = $it->()) {
		my @lv = (ref $val && reftype $val eq 'ARRAY') ? @{$val} : $val;
		for my $v (@lv) {
			push @repl, [qr{\Q$v\E}, $k];
		}
	}

	return \@repl;
}

# This function is the same for replace and unreplace.
sub __execute_replace {
	my ($str, $repl) = @_;

	for my $e (@{$repl}) {
		my ($re, $v) = @{$e};
		$str =~ s/$re/$v/g;
	}

	return $str;
}

sub __execute_replace_in {
	my (undef, $repl) = @_;

	for my $e (@{$repl}) {
		my ($re, $v) = @{$e};
		$_[0] =~ s/$re/$v/g;
	}

	return;
}


sub new {
	my ($class, @param) = @_;
	
	my $self = __prepare_replace(@param);

	return bless $self, $class;
}

sub new_unreplace {
	my ($class, @param) = @_;
	
	my $self = __prepare_unreplace(@param);

	return bless $self, $class;
}


sub __replace_method {
	my $repl = shift;
	
	if (wantarray) {
		return map { __execute_replace($_, $repl) } @_;
	} elsif (defined wantarray) {
		return @_ ? __execute_replace($_[0], $repl) : undef;
	} else {
		__execute_replace_in($_, $repl) for @_;
		return;
	}
}

sub __replace_fun {
	my ($str, @list) = @_;

	return __execute_replace($str, __prepare_replace(@list))
}

sub __unreplace_fun {
	my ($str, @list) = @_;

	return __execute_replace($str, __prepare_unreplace(@list))
}

sub replace {
	croak 'Missing argument to '.__PACKAGE__.'::replace' unless @_;

	if (blessed($_[0]) && $_[0]->isa(__PACKAGE__)) {
		return &__replace_method;
	} else {
		return &__replace_fun;
	}
}

sub unreplace {
	croak 'Missing argument to '.__PACKAGE__.'::unreplace' unless @_;

	if (blessed($_[0]) && $_[0]->isa(__PACKAGE__)) {
		return &__replace_method;
	} else {
		return &__unreplace_fun;
	}
}

1;

=encoding utf-8

=head1 NAME

String::Replace - Performs arbitrary replacement in strings

=head1 SYNOPSIS

  use String::Replace ':all';
  
  print replace('hello name', 'name' => 'world');
  print unreplace('hello world', {'name' => 'world'});
  
  my $r = String::Replace->new('name' => 'world');
  print $r->replace('hello world');

=head1 DESCRIPTION

C<String::Replace> is a small module allowing to performs arbitrary replacement
in strings. Arbitrary means that there is no specific syntax to do so, you can
just replace any arbitrary substring.

The real functionnality of C<String::Replace> is its OO interface which allows
you to prepare and encapsulate replacement to be performed in string. While other
templating systems (all of them ?) allow you to load a template and then to
perform successive series of replacement in it, C<String::Replace> allows you to
load a serie of replacement and then apply them successively to many template.
If this is what you need to do, your code will be simpler to read with C<String::Replace>
and maybe slighly faster due to the preprocessing which can be done.

Standard templating systems are typically used to generate the same web page many
times for different users. C<String::Replace> is rather used to generate a lot
of different content for a single user, or to provide a simple parametrisation
system for code (as is done with SQL in my C<SQL::Exec> module).

=head1 FUNCTIONS

This is a list of the public function of this library. Functions not listed here
are for internal use only by this module and should not be used in any external
code.

Each function of this library (that is C<replace> and C<unreplace>) may be
exported on request. There is also a C<':all'> tag to get everything at once.
Just do :

  use String::Replace ':all';

to have all the functions of the library imported into your current package.

=head2 replace

  my $s = replace(EXPR, LIST);
  my $s = replace(EXPR, HASH);

The C<replace> function take a string and a list of replacement to perform in the
string and return a string where all replacement have been done. the replacement
can be given either as list or as a hash reference.

  replace('this is a string', 'this' => 'that', 'string' => 'chair');
  replace('this is a string', { 'this' => 'that', 'string' => 'chair' });

will both return the string C<'that is a chair'>.

You should not that the replacement will be executed in the order in which they
appear if you give a list but in no particular order if you give a hash reference.
So if a replacement creates a substring that may be replaced by an other replacement
then you should use a list of replacement to be sure of what will be happening.

=head2 unreplace

  my $s = replace(I<EXPR>, I<LIST>);
  my $s = replace(I<EXPR>, I<HASH>);

Performs the opposite of the C<replace> function.

  replace('that is a chair', 'this' => 'that', 'string' => 'chair');
  replace('that is a chair', { 'this' => 'that', 'string' => 'chair' });

will both return the string C<'this is a string'>. The same caveat than for the
C<replace> function will apply.

=head1 Object-Oriented interface

If you wish so, you may also use an object oriented interface to C<String::Replace>.
The object oriented interface will be (slightly) faster than the functionnal one
if you have many strings on which you will perform the same replacement (as some
regexp can be pre-compiled).

=head2 new

  my $r = String::Replace->new(I<LIST>);
  my $r = String::Replace->new(I<HASH>);

This constructor may be called with either a list of replacement to performs or
a reference to a hash describing these replacements. The argument is treated in
the same way as the second argument to the C<replace> function. When created,
the C<replace> method may then be called on the object.

The code:

  my $r = String::Replace->new('this' => 'that', 'string' => 'chair');
  $r->replace('this is a string');

will return the same thing than the example above but the C<$r> object might be
reused.

The same caveat as for the order of the argument to the C<replace> function apply
for this constructor.

=head2 new_unreplace

  my $u = String::Replace->new_unreplace(I<LIST>);
  my $u = String::Replace->new_unreplace(I<HASH>);

This constructor may be called with either a list of replacement a reference to
a hash describing replacements. The argument is treated in the same way as the
second argument to the C<unreplace> function. When created, the C<replace> method
may then be called on the object the execute this I<un-replacement>.

The code:

  my $u = String::Replace->new_unreplace('this' => 'that', 'string' => 'chair');
  $u->replace('that is a chair');

will return the same thing than the example above but the C<$u> object might be
reused.

The same caveat as for the order of the argument to the C<replace> function apply
for this constructor.

=head2 replace

  my $s = $r->replace(I<LIST>);
  my @l = $r->replace(I<LIST>);
  $r->replace(I<LIST>);

This function performs a prepared replacement or I<un-replacement> as described
in the documentation of the C<new> and C<new_unreplace> constructors.

This function is context sensitive: if it is called in list context, it will
apply its replacement in turn to each of its argument and returns a list with
each string where the replacement has been done. If it is called in sink (void)
context, then the replacement are executed in place. If called in scalar context
only the first argument of the C<replace> function is taken and replaced and the
result of this replacement is returned.

The same apply if the object was prepared with C<new_unreplace> instead of C<new>.

=head2 unreplace

  $r->unreplace(LIST);

This method is exactly the same as the C<replace> one and will not distinguish
between object created with the C<new> or the C<new_unreplace> functions. It is
provided only for convenience.

=head1 CAVEATS

As stated above, the order in which the arguments are provided to the functions
of this library may matter. To avoid problem, you should use a non-ambiguous
parametrisation scheme (like prefixing all your variable to be replaced with a
given character).

If this a problem for you, there is a safe version of this library: C<L<String::Replace::Safe>>.
This version will performs all its replacement atomically so the order of the
argument does not matter. However the speed of this version will be approximately
half that of the C<String::Replace> version (according to my test, this does not
depend much on the size of the string, the number of replacement that you want
to perform or the number of replacement actually performed).

In an unambiguous case, the two version of this library should give back exactly
the same results.

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-replace@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Replace>.

=head1 SEE ALSO

There is a safer (and slower) version of this library: C<L<String::Replace::Safe>>.

There is also a lot of templating system on CPAN and a lot of them could let you
achieve the same thing than C<String::Replace> (with the caveat that they are
all centered around the template and not around the replace operation). Some
simple and efficient modules are the followings: C<L<String::Interpolate::Shell>>
and C<L<String::Interpolate::RE>>.

=head1 AUTHOR

Mathias Kende (mathias@cpan.org)

=head1 VERSION

Version 0.02 (January 2013)

=head1 COPYRIGHT & LICENSE

Copyright 2013 © Mathias Kende.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut




