use 5.008001;
use strict;
use warnings;

package MooX::XSConstructor;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moo 1.006000 ();
use Scalar::Util qw(blessed);
use Hook::AfterRuntime;

my $safe_spec = qr/\A(index|required|is|isa|builder|default|lazy|predicate|clearer|reader|writer)\z/;

sub is_suitable_class {
	my $self  = shift;
	my ($klass, $maybe_spec) = @_;
	
	my $ba = $klass->can('BUILDARGS');
	return if !$ba;
	return if $ba != \&Moo::Object::BUILDARGS;
	return if $klass->can('FOREIGNBUILDARGS');
	
	my %spec = %{ $maybe_spec or Moo->_constructor_maker_for($klass)->all_attribute_specs };
	my @attributes = sort { $spec{$a}{index} <=> $spec{$b}{index} } keys %spec;
	
	for my $attr (@attributes) {
		if ($spec{$attr}{isa} and !blessed($spec{$attr}{isa})) {
			return;
		}
		if ($spec{$attr}{isa} and !$spec{$attr}{isa}->can('compiled_check')) {
			return;
		}
		if ($spec{$attr}{default} and not $spec{$attr}{lazy}) {
			return;
		}
		if ($spec{$attr}{builder} and not $spec{$attr}{lazy}) {
			return;
		}
		if (my @unsafe = grep { $_ !~ $safe_spec } keys %{ $spec{$attr} }) {
			# print Dumper \@unsafe;
			return;
		}
	}
	
	return "yay!";
}

sub setup_for {
	my $self  = shift;
	my ($klass) = @_;
	
	my %spec = %{ Moo->_constructor_maker_for($klass)->all_attribute_specs };
	return unless $self->is_suitable_class($klass, \%spec);
	
	my @optlist =
		map {
			my $attrbang = my $attr = $_;
			$attrbang .= '!' if $spec{$attr}{required};
			$spec{$attr}{isa} ? ($attrbang, $spec{$attr}{isa}) : ($attrbang);
		}
		sort { $spec{$a}{index} <=> $spec{$b}{index} }
		keys %spec;
	
	require Class::XSConstructor;
	local $Class::XSConstructor::SETUP_FOR = $klass;
	local $Class::XSConstructor::REDEFINE  = !!1;
	Class::XSConstructor->import(@optlist);
}

sub import {
	my $self = shift;
	my $caller = caller;
	after_runtime {
		$self->setup_for($caller);
	};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooX::XSConstructor - glue between Moo and Class::XSConstructor

=head1 SYNOPSIS

  package Foo;
  use Moo;
  use MooX::XSConstructor;
  
  # do normal Moo stuff here

=head1 DESCRIPTION

MooX::XSConstructor will look at your class attributes, and see if it
could be built using the simple constructor that L<Class::XSConstructor> is
able to provide.

If your class is too complicated, it is a no-op.

If your class is simple enough, you will hopefully get a faster constructor.

Things that are deemed too complicated if they appear in I<any> attributes
(even an inherited one):

=over

=item *

Eager builders and defaults. (Lazy builders and defaults are fine.)

=item *

Type constraints. (Except Type::Tiny, which is fine.)

=item *

Type coercions.

=item *

Triggers.

=item *

Use of C<init_arg>.

=item *

Use of C<weak_ref>.

=back

Also if your class has a C<BUILDARGS> or C<FOREIGNBUIDARGS> method, it will
be too complicated. (The default C<BUILDARGS> inherited from L<Moo::Object>
is fine.)

B<< So what Moo features are okay? >>

Required versus optional attributes, L<Type::Tiny> type constraints (but not
coercions), reader/writer/predicate/clearer, lazy defaults/builders, and
delegation (C<handles>).

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-XSConstructor>.

=head1 SEE ALSO

L<Moo>, L<Class::XSConstructor>.

You may also be interested in L<Class::XSAccessor>. Moo already includes
all the glue to interface with that, so a MooX module like this one isn't
necessary.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

