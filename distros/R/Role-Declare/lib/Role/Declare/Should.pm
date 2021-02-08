package Role::Declare::Should;
use strict;
use warnings;
use Devel::StrictMode;
use Import::Into;

sub import {
    shift;    # remove self
    my $pkg = caller;
    unless (STRICT) {
        push @_, -lax, -no_type_check;
    }
    Role::Declare->import::into($pkg, @_);
    return;
}

1;
=pod

=encoding utf8

=head1 NAME

Role::Declare::Should - skip some checks when not testing

=head1 SYNOPSIS

    package My::New::Role;
    use Role::Declare::Should;

=head1 DESCRIPTION

This module is a drop-in replacement for L<Role::Declare> which will
additionally disable argument count and type checks when not running
in a test environment, as determined by L<Devel::StrictMode>.

If B<STRICT> is enabled, using L<Role::Declare::Should> is functionally
identical to L<Role::Declare> (any import arguments are passed on).

If B<STRICT> is not enabled, it's equivalent to:

  use Role::Declare -lax, -no_type_check;

=head1 AUTHOR

Szymon Nieznański <snieznanski@perceptyx.com>

=head1 LICENSE

'Role::Declare' is Copyright (C) 2020, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.

=cut
