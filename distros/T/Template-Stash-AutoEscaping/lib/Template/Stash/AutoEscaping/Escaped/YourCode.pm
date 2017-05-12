package Template::Stash::AutoEscaping::Escaped::YourCode;
use strict;
use warnings;
use base qw(Template::Stash::AutoEscaping::Escaped::Base Class::Data::Inheritable);
__PACKAGE__->mk_classdata('escape_method');

sub escape {
    my $class = shift;
    my $text = shift;
    $class->escape_method->($text);
}

1;

=encoding utf8

=head1 NAME

Template::Stash::AutoEscaping::Escaped::YourCode - custom escaping base class
L<Template::Stash::AutoEscaping>. Internal use.

=head1 SYNOPSIS

See L<Template::Stash::AutoEscaping> .

=head1 DESCRIPTION

For internal use.

=head2 Methods

=head2 new

Constructor.

=head2 new_as_escaped

Constructor.

=head2 as_string

Return the string.

=head2 flag

Flags

=head2 escape

Abstract method.

=head2 stop_callback

Clear the callback.

=head2 escape_manually

Internal use.

=head2 concat

Stuff.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mala E<lt>cpan@ma.laE<gt> (original author of L<Template::Stash::AutoEscape>)

Shlomi Fish (L<http://www.shlomifish.org/>) added some enhancements and
fixes, while disclaiming all rights, as part of his work for
L<http://reask.com/> and released the result as
C<Template::Stash::AutoEscaping> .

=head1 SEE ALSO

L<Template::Stash::AutoEscaping>

=cut
