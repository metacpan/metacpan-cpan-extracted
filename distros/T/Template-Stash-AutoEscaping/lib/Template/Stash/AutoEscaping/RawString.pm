package Template::Stash::AutoEscaping::RawString;
use strict;
use warnings;
use overload '""' => \&as_string;

sub new {
    my ( $klass, $str ) = @_;
    bless \$str, $klass;
}

sub as_string {
    my $self = shift;
    return $$self;
}

1;

=encoding utf8

=head1 NAME

Template::Stash::AutoEscaping::RawString - raw string support for
L<Template::Stash::AutoEscaping>. Internal use.

=head1 SYNOPSIS

See L<Template::Stash::AutoEscaping> .

=head1 DESCRIPTION

For internal use.

=head2 Methods

=head2 new

Constructor.

=head2 as_string

Return the string.

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
