use strict;                     # redundant, but quiets perlcritic
use warnings;
package Method::Generate::Constructor::Role::StrictConstructor;

our $VERSION = '0.012';

use Moo::Role;
use B ();

#
# The gist of this code was copied directly from Dave Rolsky's (DROLSKY)
# MooseX::StrictConstructor, specifically from
# MooseX::StrictConstructor::Trait::Method::Constructor as a modifier around
# _generate_BUILDALL.  It has diverged only slightly to handle Moo-specific
# differences.
#
around _assign_new => sub {
    my $orig = shift;
    my $self = shift;
    my $spec = $_[0];

    my @attrs = map { B::perlstring($_) . ' => undef,' }
        grep {defined}
        map  { $_->{init_arg} }    ## no critic (ProhibitAccessOfPrivateData)
        values(%$spec);

    my $state = ($] >= 5.010) ? "use feature 'state'; state" : "my";

    my $body = <<"EOF";

    # MooX::StrictConstructor
    $state \$attrs = { @attrs };
    my \@bad = sort grep { ! exists \$attrs->{\$_} }  keys \%{ \$args };
    if (\@bad) {
       die("Found unknown attribute(s) passed to the constructor: " .
           join ", ", \@bad);
    }

EOF

    $body .= $self->$orig(@_);

    return $body;
};

1;

__END__

=pod

=encoding UTF-8

=for :stopwords George Hartzell

=head1 NAME

Method::Generate::Constructor::Role::StrictConstructor - a role to make Moo constructors strict

=head1 DESCRIPTION

This role wraps L<Method::Generate::Constructor/_assign_new> with a bit of code
that ensures that all arguments passed to the constructor are valid init_args
for the class.

=head2 STANDING ON THE SHOULDERS OF ...

This code would not exist without the examples in L<MooX::InsideOut> and
L<MooseX::StrictConstructor>.

=head1 SEE ALSO

=over 4

=item *

L<MooseX::StrictConstructor>

=item *

L<MooX::InsideOut>

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
