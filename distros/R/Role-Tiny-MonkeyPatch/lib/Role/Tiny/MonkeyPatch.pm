use strict;
use warnings;

package Role::Tiny::MonkeyPatch;

# ABSTRACT: monkey patch roles into existing classes

use Role::Tiny;
use Sub::Util qw(set_subname);
use Carp;

sub monkey_patch {
    # -----------------------------------------
    # shameless copy paste from Mojo::Util
    # -----------------------------------------
    my ($class, %patch) = @_;
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::$_"} = set_subname("${class}::$_", $patch{$_}) for keys %patch;
}

sub monkey_patch_roles {
    my $package = shift;

    my $class = ref $package || $package || "";

    # print "$class\n";

    croak (sprintf "%s does not look like a correct class name", ($class))
	if ($class) !~ /^\w(?:[\w:']*\w)?$/;

    croak (sprintf "Could not load class %s", ($class))
	unless ($class->can('new') || eval "require $class; 1");

    if ($class->can('with_roles')) {
	warn (sprintf "Class %s already has roles", ($class));
	return;
    }
    monkey_patch $package, "with_roles", sub { with_roles(@_) };
}

sub with_roles {
    my $class = shift;

    my $p = ((ref $class) || $class) . "::Role::";

    my @roles = map { s/^\+/$p/r } @_;

    if (ref $class) {
	# print STDERR "object";
	Role::Tiny->apply_roles_to_object($class, @roles);
	return $class
    } else {
	# print STDERR "class";
	Role::Tiny->apply_roles_to_package($class, @roles);
	return $class
    }
}

sub import {
    my ($caller) = caller();
    no strict "refs";
    *{$caller . "::monkey_patch_roles"} = *monkey_patch_roles;
    # print STDERR "$caller\n";
    use strict "refs";
    my ($class, @packages) = @_;
    for my $package (@packages) {
	monkey_patch_roles($package)
    }
}

1;

=pod

=head1 Role::Tiny::MonkeyPatch

=head2 NAME

Role::Tiny::MonkeyPatch - monkeypatch roles into existing classes

=head2 SYNOPSIS

    use Role::Tiny::MonkeyPatch qw/Some::Existing::Class/;

    my $something = Some::Existing::Class->new->withroles('+Some::Role');

    $something->some_method_provided_by_role

or

    use Role::Tiny::MonkeyPatch;

    my $something = Some::Existing::Class->new;

    monkey_patch_roles($something);

    $something->some_method_provided_by_role

or

    use Role::Tiny::MonkeyPatch;

    monkey_patch_roles(Some::Existing::Class);

    my $something = Some::Existing::Class->new;

    $something->some_method_provided_by_role


=head2 DESCRIPTION

Role::Tiny::MonkeyPatch monkey patches Role::Tiny-based roles onto existing modules

=head2 FUNCTIONS

Role::Tiny::MonkeyPatch exports only one function

=head3 monkey_patch_roles

    monkey_patch_roles(Some::Class);

or 

    my $obj = Some::Class->new;
    monkey_patch_roles($obj);

monkey patch roles onto an existing class or object



=head2 CAVEATS AND NOTES

Be aware that Mojo::Base roles only work on hash-based classes

=head2 SEE ALSO

=over

=item Role::Tiny

=item Mojo::Util

=back

=head2 AUTHORS

Simone Cesano

=head2 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
