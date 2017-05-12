package Role::Singleton;

## no critic (RequireUseStrict) - Role::Tiny does strict
use Role::Tiny;

$Role::Singleton::VERSION = '0.2';

sub instance { goto &singleton; }

sub singleton {
    my ( $self, @args ) = @_;
    my $class = ref($self) || $self;

    no strict 'refs';    ## no critic
    return ${ $class . '::_singleton' } ||= $self->new(@args);
}

# need this or YAGNI ?
#
# sub clear_singleton {
#     my ($self) = @_;
#     my $class = ref($self) || $self;
#
#     no strict 'refs';
#     undef ${ $class . '::_singleton' };
#
#     return 1;
# }

1;

__END__

=encoding utf-8

=head1 NAME

Role::Singleton - Add a singleton constructor to your class

=head1 VERSION

This document describes Role::Singleton version 0.2

=head1 SYNOPSIS

Object:

    package ZeroCool

    ## no critic (RequireUseStrict) - Moo does strict
    use Moo;

    with 'Role::Singleton';

    …

Code:

    use ZeroCool;

    my $z3r0 = ZeroCool->new(…); # returns a new object every time, not a singlteon (see Role::Singleton::New if you want to do that)
    my $z3r1 = ZeroCool->singleton(…); # returns the object from the initial call to singleton() everytime, regardless of args in the subsequent calls
    my $z3r2 = ZeroCool->instance(…);  # alias to singleton()

=head1 DESCRIPTION

See L<http://en.wikipedia.org/wiki/Singleton_pattern> for info about singletons.

=head1 INTERFACE 

It adds these methods:

=head2 singleton()

Creates a new object initialized with the arguments provided and then returns it.

Subsequent calls to singleton() will return the singleton instance ignoring any arguments. I<NOTE: This is different from MooseX::Singleton which does not allow any arguments.>

If you’d rather have new() be a singleton use L<Role::Singleton::New> instead.

=head2 instance()

Alias to singleton(). This allows for compatibility with other constructor roles (e.g. L<MooseX::Singleton>, L<Moox::Singleton>).

It is nice because it allows you to switch between what type of instance you get without having to update your code.

For example, if your code does ZeroCool->instance() a million times and you see the need to change from using a singleton to a multiton (or some other instance() defining role), all you have to do is change your class and the consumers will not need to do anything besides update their ZeroCool install (i.e. not update their code in a million places).

Of course, there are also cases when being explicit is important so you’d use singleton().

You can also have both singleton and multiple support (the first one that is with()d will defined instance()):

This will give you multiton(), singleton(), and instance() is a singleton:

    with 'Role::Singleton';
    with 'Role::Multiton';

This will give you multiton(), singleton(), and instance() is a multiton:

    with 'Role::Multiton';
    with 'Role::Singleton';

If you’d rather have new() be a singleton use L<Role::Singleton::New> instead.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Role::Singleton requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Role::Tiny>

=head1 SEE ALSO

L<Role::Singleton::New>, L<Role::Multiton>, L<Role::Multiton::New>

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
