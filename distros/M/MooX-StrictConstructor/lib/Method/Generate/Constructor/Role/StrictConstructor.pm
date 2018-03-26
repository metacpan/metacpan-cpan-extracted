use strict;                     # redundant, but quiets perlcritic
package Method::Generate::Constructor::Role::StrictConstructor;
$Method::Generate::Constructor::Role::StrictConstructor::VERSION = '0.010';
# ABSTRACT: a role to make Moo constructors strict.


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

    my $body .= <<"EOF";

    # MooX::StrictConstructor
    $state \$attrs = { @attrs };
    my \@bad = sort grep { ! exists \$attrs->{\$_} }  keys \%{ \$args };
    if (\@bad) {
       Carp::confess("Found unknown attribute(s) passed to the constructor: " .
           join ", ", \@bad);
    }

EOF

    $body .= $self->$orig(@_);

    return $body;
};


1;

__END__

=pod

=head1 NAME

Method::Generate::Constructor::Role::StrictConstructor - a role to make Moo constructors strict.

=head1 VERSION

version 0.010

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

L<MooX::InsideOut>

=item *

L<MooseX::StrictConstructor>

=back

=head1 AUTHOR

George Hartzell <hartzell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George Hartzell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
