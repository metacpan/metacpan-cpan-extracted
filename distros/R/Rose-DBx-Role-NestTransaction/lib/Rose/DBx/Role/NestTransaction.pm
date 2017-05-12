package Rose::DBx::Role::NestTransaction;

use strict;
use warnings;

use Role::Tiny;

our $VERSION = '0.03';

sub nest_transaction {
    my $self = shift;
    my $cb = shift;

    if ( $self->in_transaction ) {
        $cb->(@_);
    } else {
        $self->do_transaction($cb, @_) or die $self->error;
    }

    return 1;
}

1;

=head1 NAME

Rose::DBx::Role::NestTransaction - Nested transactions support for Rose::DB

=head1 SYNOPSIS

    # Define yout DB class
    package MyDB;
    use base 'Rose::DB';

    use Role::Tiny::With;
    with 'Rose::DBx::Role::NestTransaction';

    # Somewhere in your code
    MyDB->new_or_cached->nest_transaction(sub {
        User->new( name => 'name' )->save();
    });

=head1 DESCRIPTION

This module provides a role for Rose::DB. Just consume the role in your Rose::DB subclass

=head1 METHODS

=head2 nest_transaction

These methods behaves like do_transaction but it repects existing transactions and do not start new one if the transaction already started. On error it revert transaction and rethrow error and on success it returns true

=head1 AUTHOR

Viktor Turskyi, C<< <koorchik at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/koorchik/Rose-DBx-Role-NestTransaction>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Viktor Turskyi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

