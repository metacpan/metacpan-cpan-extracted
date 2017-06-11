#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 37;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Human';
    use_ok 'DateTime';
}

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;
        $self->plugin('Human', phone_add => ',');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'flat_phone';
{
    $t->app->routes->get("/test/human/flat")->to( cb => sub {
        my ($self) = @_;

        is $self->flat_phone('1234567890'), '+71234567890',
            'wo country code';
        is $self->flat_phone('1234567890', 8), '+81234567890',
            'set country code';

        is $self->flat_phone('+79856395409'), '+79856395409',
            'with country code';
        is $self->flat_phone('+79856395409', 8), '+79856395409',
            'exists country code';

        is $self->flat_phone('1234567890w12345'), '+71234567890w12345',
            'waiting';
        is $self->flat_phone('+71234567890w12345'), '+71234567890w12345',
            'waiting and country code';
        is $self->flat_phone('+94953696027p00171'), '+94953696027p00171',
            'pause and country code';

        $self->render(text => 'OK.');
    });

    $t->get_ok("/test/human/flat")-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'human_phone';
{
    $t->app->routes->get("/test/human/phone")->to( cb => sub {
        my ($self) = @_;

        is $self->human_phone('1234567890'), '+7-123-456-7890',
            'wo country code';
        is $self->human_phone('1234567890', 8), '+8-123-456-7890',
            'set country code';
        is $self->human_phone('1234567890', 8, '&'), '+8-123-456-7890',
            'set country code and set separator';

        is $self->human_phone('+79856395409'), '+7-985-639-5409',
            'with country code';
        is $self->human_phone('1234567890', 8), '+8-123-456-7890',
            'exists country code';
        is $self->human_phone('1234567890', 8, '&'), '+8-123-456-7890',
            'exists country code and no separator';

        is $self->human_phone('1234567890w12345'), '+7-123-456-7890,12345',
            'waiting';
        is $self->human_phone('1234567890w12345', 8), '+8-123-456-7890,12345',
            'waiting and set country code';
        is $self->human_phone('1234567890w12345', 8, '&'),
            '+8-123-456-7890&12345',
            'waiting and set country code and set separator';

        is $self->human_phone('+71234567890w12345'), '+7-123-456-7890,12345',
            'waiting and country code';
        is $self->human_phone('+71234567890w12345', undef => '#'),
            '+7-123-456-7890#12345',
            'waiting and country code and set separator';

        is $self->human_phone('+94953696027p00171'), '+9-495-369-6027,00171',
            'pause and country code';

        $self->render(text => 'OK.');
    });

    $t->get_ok("/test/human/phone")-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'human_phones';
{
    $t->app->routes->get("/test/human/phones")->to( cb => sub {
        my ($self) = @_;

        is $self->human_phones('1234567890'), '+7-123-456-7890',
            'single wo country code';
        is $self->human_phones('1234567890,0987654321'),
            '+7-123-456-7890, +7-098-765-4321',
            'many wo country code';

        is $self->human_phones('+79856395409'), '+7-985-639-5409',
            'single with country code';
        is $self->human_phones('+79856395409,+80987654321'),
            '+7-985-639-5409, +8-098-765-4321',
            'many with country code';

        is $self->human_phones('1234567890w12345'), '+7-123-456-7890,12345',
            'single waiting';
        is $self->human_phones('1234567890w12345,1234567890w12345'),
            '+7-123-456-7890,12345, +7-123-456-7890,12345',
            'many waiting';

        is $self->human_phones('+71234567890w12345'), '+7-123-456-7890,12345',
            'single waiting with country code';
        is $self->human_phones('+71234567890w12345,    +91234567890w12345'),
            '+7-123-456-7890,12345, +9-123-456-7890,12345',
            'many waiting with country code';

        $self->render(text => 'OK.');
    });

    $t->get_ok("/test/human/phones")-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 AUTHORS

Dmitry E. Oboukhov <unera@debian.org>,
Roman V. Nikolaev <rshadow@rambler.ru>

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

