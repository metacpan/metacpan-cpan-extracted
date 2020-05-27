package Role::Declare::StrictWith;
use strict;
use warnings;
use Devel::StrictMode;
use Exporter 'import';
use Role::Tiny::With 'with';

our @EXPORT = ('with_strict');

BEGIN { *with_strict = STRICT ? \&with : sub { } }

1;
=pod

=encoding utf8

=head1 NAME

Role::Declare::StrictWith - conditional role composition

=head1 SYNOPSIS

    package My::New::Role;
    use Role::Declare::StrictWith;

    with_strict 'My::New::Interface';

Which is equivalent to:

    package My::New::Role;
    use Role::Tiny::With;;
    use Devel::StrictMode;

    with 'My::New::Interface' if STRICT;

=head1 DESCRIPTION

This module provides B<with_strict> - a version of L<Role::Tiny::With>'s
L<with> which only works when L<Devel::StrictMode> is on.
If B<STRICT> is not enabled, B<with_strict> is a no-op.

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
