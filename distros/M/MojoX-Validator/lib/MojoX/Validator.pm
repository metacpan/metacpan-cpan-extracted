package MojoX::Validator;

use strict;
use warnings;

use base 'Input::Validator';

our $VERSION = '0.0016';

1;
__END__

=head1 NAME

MojoX::Validator - Validator for Mojolicious

=head1 SYNOPSIS

    my $validator = MojoX::Validator->new;

    # Fields
    $validator->field('phone')->required(1)->regexp(qr/^\d+$/);
    $validator->field([qw/firstname lastname/])
      ->each(sub { shift->required(1)->length(3, 20) });

    # Groups
    $validator->field([qw/password confirm_password/])
      ->each(sub { shift->required(1) });
    $validator->group('passwords' => [qw/password confirm_password/])->equal;

    # Conditions
    $validator->field('document');
    $validator->field('number');
    $validator->when('document')->regexp(qr/^1$/)
      ->then(sub { shift->field('number')->required(1) });

    $validator->validate($values_hashref);
    my $errors_hashref = $validator->errors;
    my $pass_error = $validator->group('passwords')->error;
    my $validated_values_hashref = $validator->values;

=head1 DESCRIPTION

A wrapper around L<Input::Validator>. See original documentation.

=head1 CREDITS

Yaroslav Korshak (yko)

forwardever

vaneska

Glen Hinkle

Alex Voronov

Bedivere

JEEN Lee

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2013, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
