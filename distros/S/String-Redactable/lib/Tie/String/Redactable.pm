use v5.20;

package Tie::String::Redactable;
use experimental qw(signatures);
use parent qw(String::Redactable);

our $VERSION = '1.087';

sub TIESCALAR ($class, $string) {
	local $SIG{__WARN__} = sub {};
	my $self = bless String::Redactable->new($string), __PACKAGE__;
	}

sub FETCH ($self) {
	$self->placeholder;
	}

sub STORE {
	return;
	}

=encoding utf8

=head1 NAME

Tie::String::Redactable - work even harder to redact a string

=head1 SYNOPSIS

	use Tie::String::Redactable;

	my $object = tie my $string, 'Tie::String::Redactable', $secret;

	$object->to_str_unsafe;
	(tied $string)->to_str_unsafe;

=head1 DESCRIPTION

This is a tied version of L<String::Redactable> that refuses to store
a new value, and you have to go through the tied object to get to the
object that allows you to call the method you need. It's unlikely that
you would inadvertently type out any of that.

=head1 TO DO

=head1 SEE ALSO

=head1 SOURCE AVAILABILITY

This source is on GitHub:

	http://github.com/briandfoy/string-redactable

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2025-2026, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

__PACKAGE__;
