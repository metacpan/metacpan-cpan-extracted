package MooseX::Storage::Engine::Trait::OnlyWhenBuilt;
# ABSTRACT: An engine trait to bypass serialization

our $VERSION = '0.52';

use Moose::Role;
use namespace::autoclean;

# we should
# only serialize the attribute if it's already built. So, go ahead
# and check if the attribute has a predicate. If so, check if it's
# set  and then go ahead and look it up.
around 'collapse_attribute' => sub {
    my ($orig, $self, $attr, @args) = @_;

    my $pred = $attr->predicate if $attr->has_predicate;
    if ($pred) {
        return () unless $self->object->$pred();
    }

    return $self->$orig($attr, @args);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Engine::Trait::OnlyWhenBuilt - An engine trait to bypass serialization

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    {   package Point;
        use Moose;
        use MooseX::Storage;

        with Storage( traits => [qw|OnlyWhenBuilt|] );

        has 'x' => (is => 'rw', lazy_build => 1 );
        has 'y' => (is => 'rw', predicate => '_has_y' );
        has 'z' => (is => 'rw', builder => '_build_z' );

        sub _build_x { 3 }
        sub _build_y { expensive_computation() }
        sub _build_z { 3 }
    }

    my $p = Point->new( 'x' => 4 );

    # the result of ->pack will contain:
    # { x => 4, z => 3 }
    $p->pack;

=head1 DESCRIPTION

Sometimes you don't want a particular attribute to be part of the
serialization if it has not been built yet. If you invoke C<Storage()>
as outlined in the C<Synopsis>, only attributes that have been built
(i.e., where the predicate returns 'true') will be serialized.
This avoids any potentially expensive computations.

This trait is applied to an instance of L<MooseX::Storage::Engine>, for the
user-visible version shown in the SYNOPSIS, see L<MooseX::Storage::Traits::OnlyWhenBuilt>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Storage>
(or L<bug-MooseX-Storage@rt.cpan.org|mailto:bug-MooseX-Storage@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris.prather@iinteractive.com>

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
