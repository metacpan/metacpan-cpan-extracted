use strict;
use warnings;
package MooX::StrictConstructor;

our $VERSION = '0.013';

use Moo ();
use Moo::Role ();
use Moo::_Utils qw(_install_modifier);
use Carp ();

sub import {
    my $class  = shift;
    my $target = caller;
    my $late;
    for my $arg (@_) {
        if ($arg eq '-late') {
            $late = 1;
        }
        else {
            Carp::croak("Unknown option $arg");
        }
    }
    unless ( Moo->is_class($target) ) {
        Carp::croak("MooX::StrictConstructor can only be used on Moo classes.");
    }

    _apply_role($target, $late);

    _install_modifier($target, 'after', 'extends', sub {
        _apply_role($target, $late);
    });
}

sub _apply_role {
    my ($target, $late) = @_;
    my $con = Moo->_constructor_maker_for($target); ## no critic (Subroutines::ProtectPrivateSubs)
    my $role = $late ? 'MooX::StrictConstructor::Role::Constructor::Late'
                     : 'MooX::StrictConstructor::Role::Constructor';
    Moo::Role->apply_roles_to_object($con, $role)
        unless Moo::Role::does_role($con, $role);
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords George Hartzell

=head1 NAME

MooX::StrictConstructor - Make your Moo-based object constructors blow up on unknown attributes

=head1 SYNOPSIS

    package My::Class;

    use Moo;
    use MooX::StrictConstructor;

    has 'size' => ( is => 'rw' );

    # then somewhere else, when constructing a new instance
    # of My::Class ...

    # this blows up because color is not a known attribute
    My::Class->new( size => 5, color => 'blue' );

=head1 DESCRIPTION

Simply loading this module makes your constructors "strict". If your
constructor is called with an attribute init argument that your class does not
declare, then it dies. This is a great way to catch small typos.

=head2 STANDING ON THE SHOULDERS OF ...

This module was inspired by L<MooseX::StrictConstructor>, and includes some
implementation details taken from it.

=head2 SUBVERTING STRICTNESS

There are two options for subverting the strictness to handle problematic
arguments. They can be handled in C<BUILDARGS> or in C<BUILD>.

You can use a C<BUILDARGS> function to handle them, e.g. this will allow you
to pass in a parameter called "spy" without raising an exception.  Useful?
Only you can tell.

   sub BUILDARGS {
       my ($self, %params) = @_;
       my $spy = delete $params{spy};
       # do something useful with the spy param
       return \%params;
   }

It is also possible to handle extra parameters in C<BUILD>. This requires
the strictness check to be performed at the end of object construction rather
than at the beginning.

    use MooX::StrictConstuctor -late;

    sub BUILD {
        my ($self, $params) = @_;
        if ( my $spy = delete $params->{spy} ) {
            # do something useful
        }
    }

When using this option, the object will be fully constructed before checking
the parameters, and a failure will cause the destructor to be run.

=head1 BUGS/ODDITIES

=head2 Inheritance

A class that uses L<MooX::StrictConstructor> but extends a non-Moo class will
not be handled properly.  This code hooks into the constructor as it is being
strung up (literally) and that happens in the parent class, not the one using
strict.

A class that inherits from a L<Moose> based class will discover that the
L<Moose> class's attributes are disallowed.  Given sufficient L<Moose> meta
knowledge it might be possible to work around this.  I'd appreciate pull
requests and or an outline of a solution.

=head2 Interactions with namespace::clean

L<MooX::StrictConstructor> creates a C<new> method that L<namespace::clean>
will over-zealously clean.  Workarounds include using L<namespace::autoclean>,
using L<MooX::StrictConstructor> B<after> L<namespace::clean> or telling
L<namespace::clean> to ignore C<new> with something like:

  use namespace::clean -except => ['new'];

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

=head1 CONTRIBUTORS

=for stopwords George Hartzell Graham Knop JJ Merelo jrubinator mohawk2 Samuel Kaufman Tim Bunce

=over 4

=item *

George Hartzell <hartzell@alerce.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

JJ Merelo <jjmerelo@gmail.com>

=item *

jrubinator <jjrs.pam+github@gmail.com>

=item *

mohawk2 <mohawk2@users.noreply.github.com>

=item *

Samuel Kaufman <samuel.c.kaufman@gmail.com>

=item *

Tim Bunce <Tim.Bunce@pobox.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by George Hartzell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
