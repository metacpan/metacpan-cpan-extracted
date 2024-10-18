use strict;                     # redundant, but quiets perlcritic
use warnings;
package MooX::StrictConstructor::Role::Constructor;

our $VERSION = '0.013';

use Moo::Role;

with 'MooX::StrictConstructor::Role::Constructor::Base';

around _check_required => sub {
    my ($orig, $self, $spec, @rest) = @_;
    my $code = $self->$orig($spec, @rest);
    $code .= $self->_cap_call($self->_check_strict($spec, '$args'));
    return $code;
};

1;

__END__

=pod

=encoding UTF-8

=for :stopwords George Hartzell

=head1 NAME

MooX::StrictConstructor::Role::Constructor - a role to make Moo constructors strict

=head1 DESCRIPTION

This role wraps L<Method::Generate::Constructor> with a bit of code
that ensures that all arguments passed to the constructor are valid init_args
for the class.

=head2 STANDING ON THE SHOULDERS OF ...

This code would not exist without the examples in L<MooX::InsideOut> and
L<MooseX::StrictConstructor>.

=head1 SEE ALSO

=over 4

=item *

L<MooseX::StrictConstructor>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-StrictConstructor>
or by email to
L<bug-MooX-StrictConstructor@rt.cpan.org|mailto:bug-MooX-StrictConstructor@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

George Hartzell <hartzell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by George Hartzell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
