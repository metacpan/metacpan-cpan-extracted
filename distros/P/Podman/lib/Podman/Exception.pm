package Podman::Exception;

use Mojo::Base 'Mojo::Exception';

use constant MESSAGE => {
  900 => 'Connection failed.',
  304 => 'Action already processing.',
  400 => 'Bad parameter in request.',
  404 => 'No such item.',
  405 => 'Bad request.',
  409 => 'Conflict error in operation.',
  500 => 'Internal server error.',
};

has 'code' => -1;

sub new { $_[1] ? shift->SUPER::new(MESSAGE->{$_[0]} // 'Unknown error.')->code($_[0]) : shift->SUPER::new }

1;

__END__

=encoding utf8

=head1 NAME

Podman::Exception - Simple generic exceptions.

=head1 SYNOPSIS

    eval {
        Podman::Exception->throw(404);
    };
    say $@;

=head1 DESCRIPTION

=head2 Inheritance

    Podman::Exception
        isa Mojo::Exception

L<Podman::Exception> is a simple generic exception. Exceptions are thrown on any Podman service request failure.

    900 => 'Connection failed.',
    304 => 'Action already processing.',
    400 => 'Bad parameter in request.',
    404 => 'No such item.',
    405 => 'Bad request.',
    409 => 'Conflict error in operation.',
    500 => 'Internal server error.',

The message is determined by the provided C<code>.

=head1 ATTRIBUTES

=head2 code

    my $exception = Podman::Exception->new( code => 404 );

HTTP code received from Podman service.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=cut
