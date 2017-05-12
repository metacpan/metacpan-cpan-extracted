#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 33;
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
        $self->plugin('Human');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

$t->app->routes->get("/test/human")->to( cb => sub {
    my ($self) = @_;

    my $time = time;
    my $dt   = DateTime->from_epoch( epoch => $time, time_zone  => 'local');
    my $dstr = $dt->strftime('%F %T %z');

    is $self->str2time( $dstr ), $dt->epoch, 'str2time';
    is $self->strftime('%T', $dstr), $dt->strftime('%T'),   'strftime';

    is $self->human_datetime( $dstr ), $dt->strftime('%F %H:%M'),
        'human_datetime from ISO';
    is $self->human_datetime( $time ), $dt->strftime('%F %H:%M'),
        'human_datetime from timestamp';

    is $self->human_time( $dstr ), $dt->strftime('%H:%M:%S'),
        'human_time from ISO';
    is $self->human_time( $time ), $dt->strftime('%H:%M:%S'),
        'human_time from timestamp';

    is $self->human_date( $dstr ), $dt->strftime('%F'),
        'human_date from ISO';
    is $self->human_date( $time ), $dt->strftime('%F'),
        'human_date from timestamp';

    is $self->human_money,                  undef,      'human_money undefined';
    is $self->human_money(''),              '',         'human_money empty';
    is $self->human_money('12345678.00'),   '12,345,678.00',  'human_money';

    is $self->human_phones('1234567890'), '+7-123-456-7890',
        'human_phones';
    is $self->human_phones('1234567890,0987654321'),
        '+7-123-456-7890, +7-098-765-4321',
        'human_phones many';
    is $self->flat_phone('1234567890'), '+71234567890', 'flat_phone';


    ok $self->human_suffix('', 0, '1','2','100500') eq '100500',
        'human_suffix 0';
    ok $self->human_suffix('', 1, '1','2','100500') eq '1',
        'human_suffix 1';
    for my $count (2..4) {
        ok $self->human_suffix('', $count, '1','2','100500') eq '2',
            "human_suffix $count";
    }
    ok $self->human_suffix('', 6, '1','2','100500') eq '100500',
        'human_suffix 6';

    is $self->human_distance('1234.5678'),  '1234.57',  'human_distance1';
    is $self->human_distance('1234.5638'),  '1234.56',  'human_distance2';
    is $self->human_distance('1234.0010'),  '1234',     'human_distance3';
    is $self->human_distance('1234.0100'),  '1234.01',  'human_distance4';
    is $self->human_distance('1234.0000'),  '1234',     'human_distance5';
    is $self->human_distance('1234'),       '1234',     'human_distance6';
    is $self->human_distance('1234.'),      '1234',     'human_distance7';

    $self->render(text => 'OK.');
});

$t->get_ok("/test/human")-> status_is( 200 );

diag decode utf8 => $t->tx->res->body unless $t->tx->success;

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

