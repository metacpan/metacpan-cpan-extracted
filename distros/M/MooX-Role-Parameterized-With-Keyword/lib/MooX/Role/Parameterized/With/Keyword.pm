## no critic: (Modules::ProhibitAutomaticExportation)

package MooX::Role::Parameterized::With::Keyword;

use Exporter        qw(import);
use Module::Runtime qw(use_module);
use Moo::Role       qw();
use Role::Tiny      qw();

our @EXPORT = qw(with);

sub with {
    my $target = caller;

    while (@_) {
        my $role = shift;
        use_module($role);
        if (@_ && ref $_[0] eq 'HASH') {
            my $params = shift;
            $role->apply( $params, target => $target );
        } else {
            if ($role->can("apply")) {
                $role->apply( {}, target => $target );
            } elsif (Moo::Role->is_role($role)) {
                Moo::Role->apply_roles_to_package( $target, $role );
                Moo::Role->_maybe_reset_handlemoose($target);
            } elsif (Role::Tiny->is_role($role)) {
                Role::Tiny->apply_roles_to_package( $target, $role );
            } else {
                die "Can't apply $role to $target: $role is neither a ".
                    "MooX::Role::Parameterized/Moo::Role/Role::Tiny role";
            }
        }
    }
}

1;
# ABSTRACT: DSL to apply roles with composition parameters

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Role::Parameterized::With::Keyword - DSL to apply roles with composition parameters

=head1 VERSION

This document describes version 0.001 of MooX::Role::Parameterized::With::Keyword (from Perl distribution MooX-Role-Parameterized-With-Keyword), released on 2018-10-11.

=head1 DESCRIPTION

This module is a temporary alternative to L<MooX::Role::Parameterized::With> and
provides C<with> keyword. In addition to that, this module can include
L<Role::Tiny> and regular non-parametric L<Moo::Role> roles.

=for Pod::Coverage ^(with)$

=head1 SYNOPSYS

In L<MyRole1.pm>:

    package Role1; # a Role::Tiny role
    use Role::Tiny;
    sub meth1 { ... }
    1;

In F<MyRole2.pm>:

    package Role2; # a Moo::Role role
    use Moo::Role;
    sub meth2 { ... }
    1;

In F<MyRole3.pm>:

    package MyRole3; # a parameterized Moo::Role role
    use MooX::Role::Parameterized;
    role {
        my ($params, $mop) = @_;
        $mop->method($params->{name} => sub {...});
    };
    1;

In F<MyClass.pm>, which uses the roles:

    package MyClass;
    use MooX::Role::Parameterized::With::Keyword;
    with 'MyRole1', 'MyRole2', 'MyRole3' => {name => 'meth3_blah'};

In F<script.pl>, which uses the class:

    use MyClass;
    my $obj = MyClass->new;
    $obj->meth1;
    $obj->meth2;
    $obj->meth3_blah;

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/MooX-Role-Parameterized-With-Keyword>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-MooX-Role-Parameterized-With-Keyword>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-Role-Parameterized-With-Keyword>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<MooX::Role::Parameterized>

L<https://github.com/peczenyj/MooX-Role-Parameterized/pull/6>

L<https://github.com/peczenyj/MooX-Role-Parameterized/pull/7>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
