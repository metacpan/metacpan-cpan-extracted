package Podman::Exception;

##! Simple generic exception class.
##!
##!     Podman::Exception->new( Code => 404 );
##!
##! Exception is thrown on API request failure.

use strict;
use warnings;
use utf8;

use Moose;
with qw(Throwable);

use overload '""' => 'AsString';

### API error description.
has 'Message' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

### API (HTTP) code.
has 'Code' => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

### #[ignore(item)]
sub BUILD {
    my $Self = shift;

    my %Messages = (
        0   => 'Connection failed.',
        304 => 'Action already processing.',
        400 => 'Bad parameter in request.',
        404 => 'No such item.',
        409 => 'Conflict error in operation.',
        500 => 'Internal server error.',
    );

    $Self->Message($Messages{$Self->Code} || 'Unknown error.');

    return;
}

### #[ignore(item)]
sub AsString {
    my $Self = shift;

    return sprintf "%s (%d)", $Self->Message, $Self->Code;
}

__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Podman::Exception - Simple generic exceptions.

=head1 SYNOPSIS

    eval {
        Podman::Exception->new( Code => 404 )->throw();
    };
    print $@;

=head1 DESCRIPTION

L<Podman::Exception> is a simple generic exception class. Exception is thrown
on any API request failure.

    0   => 'Connection failed.',
    304 => 'Action already processing.',
    400 => 'Bad parameter in request.',
    404 => 'No such item.',
    409 => 'Conflict error in operation.',
    500 => 'Internal server error.',

=head1 ATTRIBUTES

=head2 Code

    my $Exception = Podman::Exception->new( Code => 404 );

HTTP code received from API.

=head2 Message

    print $Exception->Message();

Readonly human readable exception message. The message is related to the
C<Code>.

=head1 METHODS

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
