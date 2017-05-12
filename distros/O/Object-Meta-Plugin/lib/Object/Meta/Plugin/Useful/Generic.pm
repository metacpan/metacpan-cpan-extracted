#!/usr/bin/perl
# $Id: Generic.pm,v 1.1 2003/11/29 14:35:24 nothingmuch Exp $

package Object::Meta::Plugin::Useful::Generic; # an extended base class with some logical features $$$ ## rename to Usefull::Generic;

use strict;
use warnings;
use warnings::register;

use base 'Object::Meta::Plugin::Useful';

our $VERSION = 0.01;

sub export { # utility method: export a list of method names
	my $self = shift;
	my @try_export = @_;
	
	my %tested = map { $_, undef } @{ $self->{exports} };
	
	push @{ $self->{exports} }, grep {
		(not exists $tested{$_}) and $tested{$_} = 1 # make sure we didn't pass this one already
		and $self->can($_) or (warnings::warnif($self,"Export of undefined method $_ attempted") and undef); # make sure we can use the method. UNIVERSAL::can should be replaced if magic is going on. To shut it up, 'no warnings Plugin::Class'.
	} @try_export;
	
	@{ $self->{exports} }; # number on scalar, list on list
}

sub exports {
	my $self = shift;
	@{ $self->{exports} };
}

1; # Keep your mother happy.

__END__

=pod

=head1 NAME

Object::Meta::Plugin::Useful::Generic - a generic useful plugin base class.

=head1 SYNOPSIS

	package MyFoo;
	use bas "Object::Meta::Plugin::Useful::Generic";

	sub new {
		my $pkg = shift;
		my $self = $pkg->SUPER::new(@_);
		$self->export(qw/foo bar/);
	}

	sub foo {
		# ...
	}

	sub bar {
		# ...
	}

=head1 DESCRIPTION

This provides a very simple base class for a plugin. It uses the method C<export> to explicitly mark a method name for exporting. When L<Object::Meta::Plugin::Useful>'s C<init> hits

=head1 METHODS

=over 4

=item export METHODS ...

This method takes a list of method names, and makes sure they are all implemented (C<$self->can($method)>) and so forth. It then makes notes of what remains, and will return these values when the exports method is called by the standard export list implementation.

=back

=head1 CAVEATS

=over 4

=item *

Will emit warnings if lexical warnings are asked for. It will bark when C<$self->can($method)> is not happy. You can suppress it with

	no warnings 'MyFoo';

Or

	no warnings 'Object::Meta::Plugin::Useful::Generic';

Depending on what level you'd like the warnings to be suppressed.

=back

=head1 BUGS

=over 4

=item *

Namespace is not well defined within the hash, nor is it guaranteed that it will never be extended.

=back

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<Object::Meta::Plugin>, L<Object::Meta::Plugin::Useful>, L<Object::Meta::Plugin::Useful::Meta>, L<Object::Meta::Plugin::Useful::Greedy>.

=cut
