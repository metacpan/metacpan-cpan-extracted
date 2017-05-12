package Sub::Lvalue;

use warnings;
use strict;
#use ex::provide [qw(get set)];
use Carp;

sub import {
	my $pkg = shift;
	my $pk = caller;
	no strict 'refs';
	for (@_ ? @_ : qw(get set)) {
		defined &$_ or croak "$_ is not exported by $pk";
		*{ $pk . '::' . $_ } = \&$_;
	}
}
=head1 NAME

Sub::Lvalue - use lvalue subroutines with ease

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Simply put get and set blocks at the end of your lvalue sub.
Please note, no comma or semicolon between statements are allowed (in case of semicolon only last statement will be take an action)

	use Sub::Lvalue;

	sub mysub : lvalue {
		get {
			return 'result for get';
		}
		set {
			my $set_value = shift;
			# ...
		}
	}

	mysub() = 'test'; # will invoke set block with argument 'test';
	print mysub(); # will invoke get block without arguments. result will be returned to print;

	sub readonly : lvalue {
		get {
			return 'readonly value';
		}
	}
	
	print readonly();  # ok
	readonly = 'test'; # fails

	sub writeonly : lvalue {
		set {
			my $set_value = shift;
			# ...
		}
	}
	
	writeonly = 'test'; # ok
	print writeonly();  # fails

=head1 EXPORT

There are 2 export functions: C<set> and C<get>. If you don't want to use export, you may use full names

	sub mysub : lvalue {
		Sub::Lvalue::get {
			return 'something';
		}
		Sub::Lvalue::set {
			my $set_value = shift;
		}
	}

=head1 FUNCTIONS

=head2 set

invoked with argument from right side

=cut

sub set (&;@) : lvalue {
	my $code = shift;
	if (@_) {
		tied($_[0])->set($code);
	}else{
		tie $_[0], 'Sub::Lvalue::tiecallback', undef, $code;
	}
	$_[0];
}

=head2 get

invoked without arguments. the returned value passed out

=cut

sub get (&;@) : lvalue {
	my $code = shift;
	if (@_) {
		tied($_[0])->get($code);
	}else{
		tie $_[0], 'Sub::Lvalue::tiecallback', $code, undef;
	}
	$_[0];
}

=head1 RENAMING

From it's creation in 2009 till 2016 this module has name L<lvalue>.
In 2010 there were appeared module L<Lvalue>.

During years, there were semantic conflict between Lvalue and lvalue.
But this days PAUSE threats CPAN module names case insensitive that leads us to name conflict.

After all, there is another great module L<LV>. As stated by its author, some part of it was inspired by C<lvalue>.

I decided to eliminame original name L<lvalue> and to keep original source code if someone needs it under the name L<Sub::Lvalue>

=head1 AUTHOR

Mons Anderson, <mons@cpan.org>

=head1 BUGS

None known

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package Sub::Lvalue::tiecallback;

use strict;
use Sub::Name;
use Carp;
our @CARP_NOT = 'lvalue';

sub set {
	$_[0]->[1] = $_[1];
}
sub get {
	$_[0]->[0] = $_[1];
}

sub TIESCALAR {
	my ($pkg,$get,$set) = @_;
	my $caller = (caller(2))[3];
	subname $caller.':get',$get if $get;
	subname $caller.':set',$set if $set;
	$get or $set or croak "Neither set nor get passed";
	return bless [$get,$set,$caller],$pkg;
}
sub FETCH {
	my $self = shift;
	defined $self->[0] or croak "$self->[2] is writeonly";
	goto &{ $self->[0] };
}
sub STORE {
	my $self = shift;
	defined $self->[1] or croak "$self->[2] is readonly";
	goto &{ $self->[1] };
}

1;
