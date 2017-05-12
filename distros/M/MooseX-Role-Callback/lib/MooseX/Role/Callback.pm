package MooseX::Role::Callback;

our $VERSION = '0.01';

# ABSTRACT: Execute a callback function when a role is applied

use strict;
use warnings;

use Moose qw//;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => ['included'],
    role_metaroles => {
        role => ['MooseX::Role::Callback::Meta::Trait'],
    }
);

sub included {
    my ($meta, $callback) = @_;
    push @{$meta->include_callbacks}, $callback;
    return;
}

1;

__END__

=pod

=head1 NAME

MooseX::Role::Callback

=head1 SYNOPSIS

    package Foo;

    use Moose::Role;
    use MooseX::Role::Callback;

    included(sub {
        my ($meta, $user) = @_;
        print "Foo applied to " . $user->name . "\n";
    });

    package Bar;

    use Moose;
    with 'Foo'; # Prints "Foo applied to Bar"

=head1 DESCRIPTION

Execute a callback function when a role is applied.

=head1 FUNCTIONS

=head2 C<included>

Registers a function to be called when the role is applied. Takes a single
coderef as an argument.

The function will be passed the role's metaclass and the C<$thing>'s metaclass,
where C<$thing> can be either class or instance.

Call multiple times to register multiple callbacks.

=head1 GITHUB

Find this project on github:

https://github.com/pboyd/MooseX-Role-Callback

=head1 AUTHOR

Paul Boyd <pboyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Paul Boyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
