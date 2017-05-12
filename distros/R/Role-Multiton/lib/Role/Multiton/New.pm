package Role::Multiton::New;

## no critic (RequireUseStrict) - Role::Tiny does strict
use Role::Tiny;

$Role::Multiton::New::VERSION = '0.2';

use Role::_Multiton ();

sub turn_new_into_multiton {
    my ( $self, @args ) = @_;
    my $class = ref($self);
    die "turn_new_into_multiton() must be called by an object" if !$class;

    no strict 'refs';    ## no critic

    die "turn_new_into_multiton() can not be called after turn_new_into_singleton()" if ${ $class . '::_singleton_orig_new' };

    my $arg_key     = Role::_Multiton::_get_arg_key( \@args );
    my $multiton_hr = Role::_Multiton::_get_multiton_lookup_hr($self);

    if ( ${ $class . '::_multiton_orig_new' } ) {
        $multiton_hr->{$arg_key} = $self;
    }
    else {
        ${ $class . '::_multiton_orig_new' } = \&{ $class . '::new' };
        $multiton_hr->{$arg_key} = $self;

        no warnings 'redefine';
        *{ $class . '::new' } = sub {
            my ( $self, @args ) = @_;
            my $arg_key     = Role::_Multiton::_get_arg_key( \@args );
            my $multiton_hr = Role::_Multiton::_get_multiton_lookup_hr($self);
            return $multiton_hr->{$arg_key} ||= ${ $class . '::_multiton_orig_new' }->( $self, @args );
          }
    }

    return $multiton_hr->{$arg_key};
}

# around 'new' => sub {
#     my ( $orig, $self, @args ) = @_;
#
#     my $arg_key = Role::_Multiton::_get_arg_key( \@args );
#
#     my $multiton_hr = Role::_Multiton::_get_multiton_lookup_hr($self);
#
#     return $multiton_hr->{$arg_key} ||= $orig->( $self, @args );
# };

1;

__END__

=encoding utf-8

=head1 NAME

Role::Multiton::New - Turn your new() into a multiton constructor

=head1 VERSION

This document describes Role::Multiton::New version 0.2

=head1 SYNOPSIS

Object:

    package ZeroCool

    ## no critic (RequireUseStrict) - Moo does strict
    use Moo;

    with 'Role::Multiton::New';

    …

Code:

    use ZeroCool;

    my $z3r0 = ZeroCool->new(…)->turn_new_into_multiton; # from now on new() returns a multiton (see Role::Multiton if you want to keep new() as-is and add multition support)

=head1 DESCRIPTION

See L<Role::Multiton> for more information on multitons. Then see INTERFACE for specifics of what this module does.

=head1 INTERFACE 

This role allows you to turn new() into a multiton constructor.

This is useful, for example, when a multiton makes sense but you can't change all the new() calls to singleton() or instance(). It might also be useful for testing so you can reliably operate on the same object.

Unfortunately one can not do this automatically via, say, C<around 'new'> because new() is built up along the way. See  L<rt 89239|https://rt.cpan.org/Ticket/Display.html?id=89239> for some specifics.

The seeming quantum state of new() is fixed however after it is called once. At that point it is possible to operate on it which is what turn_new_into_multiton() does.

You'll probably want to only call this on the final object as calling it on any supers will effect subsequent extenders.

=head2 turn_new_into_multiton()

This must be called with an object (to ensure new() has been called and is final). It returns the object so that it is safe to call in a chain the SYNOPSIS.

Subsequent calls will result in the multiton object being changed to the caller of turn_new_into_singleton(), probably a no-op most of the time.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Role::Multiton::New requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Role::Tiny>, L<Role::_Multiton>

=head1 SEE ALSO

L<Role::Singleton::New>, L<Role::Multiton>, L<Role::Singleton>

=head1 INCOMPATIBILITIES

None reported.

See L<Role::Multiton/INCOMPATIBILITIES> for info about object system specific compatibility.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-role-multiton@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
