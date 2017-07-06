#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 145;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::Human';
    use_ok 'DateTime';
    use_ok 'DateTime::Format::DateParse';
    use_ok 'Mojo::Util',    qw(url_escape);
    use_ok 'POSIX',         qw(strftime);
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

note 'basic';
{
    my $time = 60 * 60 * 24;
    my $dt   = DateTime->from_epoch( epoch => $time );
    $dt->set_time_zone( strftime '%z', localtime );

    my $str_tz      = $dt->strftime('%F %T %z');
    my $str_wo_tz   = $dt->strftime('%F %T');

    $t->app->routes->get("/test/human")->to( cb => sub {
        my ($self) = @_;

        is $self->str2time( $dt ),                  $dt->epoch,
            'str2time from DateTime';

        is $self->str2time( $str_tz ),              $dt->epoch,
            'str2time from ISO';
        is $self->str2time( $str_wo_tz ),           $dt->epoch,
            'str2time from ISO wo TZ';
        is $self->str2time( $time ),                $dt->epoch,
            'str2time from timestamp';

        is $self->strftime('%F %T %z', $str_tz),    $dt->strftime('%F %T %z'),
            'strftime from ISO';
        is $self->strftime('%F %T %z', $str_wo_tz), $dt->strftime('%F %T %z'),
            'strftime from ISO wo TZ';
        is $self->strftime('%F %T %z', $time),      $dt->strftime('%F %T %z'),
            'strftime from timestamp';

        is $self->human_datefull( $str_tz ),        $dt->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $str_wo_tz ),     $dt->strftime('%F %T'),
            'human_datefull from ISO wo TZ';
        is $self->human_datefull( $time ),          $dt->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str_tz ),        $dt->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $str_wo_tz ),     $dt->strftime('%F %H:%M'),
            'human_datetime from ISO wo TZ';
        is $self->human_datetime( $time ),          $dt->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str_tz ),            $dt->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $str_wo_tz ),         $dt->strftime('%H:%M:%S'),
            'human_time from ISO wo TZ';
        is $self->human_time( $time ),              $dt->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str_tz ),            $dt->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $str_wo_tz ),         $dt->strftime('%F'),
            'human_date from ISO wo TZ';
        is $self->human_date( $time ),              $dt->strftime('%F'),
            'human_date from timestamp';

        $self->render(text => 'OK.');
    });

    $t->get_ok("/test/human")-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'default timezone';
{
    my $time    = 60 * 60 * 24;

    my $tz_source   = DateTime::TimeZone->new(name => '-0200');
    my $tz_dest     = DateTime::TimeZone->new(name => '+0400');

    my $from    = DateTime->from_epoch(epoch => $time, time_zone => $tz_source);
    my $str     = $from->strftime('%F %T %z');

    my $to      = $from->clone;
    $to->set_time_zone( $tz_dest );

    $t->app->routes->get("/test/human/default")->to( cb => sub {
        my ($self) = @_;

        $self->app->plugin('Human', tz => $tz_dest->name);

        is $self->str2time( $to ),              $to->epoch, 'str2time';

        is $self->str2time( $str ),             $to->epoch, 'str2time';

        is $self->strftime('%F %T %z', $str),   $to->strftime('%F %T %z'),
            'strftime';

        is $self->human_datefull( $str ),       $to->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $time ),      $to->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str ),       $to->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $time ),      $to->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str ),           $to->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $time ),          $to->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str ),           $to->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $time ),          $to->strftime('%F'),
            'human_date from timestamp';

        $self->app->plugin('Human', tz => 'local');

        $self->render(text => 'OK.');
    });

    $t->get_ok("/test/human/default")-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}


note 'set timezone';
{
    my $time    = 60 * 60 * 24;

    my $tz_source   = DateTime::TimeZone->new(name => '-0300');
    my $tz_dest     = DateTime::TimeZone->new(name => '+0100');

    my $from    = DateTime->from_epoch(epoch => $time, time_zone => $tz_source);
    my $str     = $from->strftime('%F %T %z');

    my $to      = $from->clone;
    $to->set_time_zone( $tz_dest );

    $t->app->routes->get("/test/human/tz")->to( cb => sub {
        my ($self) = @_;

        $self->app->plugin('Human', tz => $tz_dest->name);

        is $self->str2time( $to ),              $to->epoch, 'str2time';

        is $self->str2time( $str ),             $to->epoch, 'str2time';

        is $self->strftime('%F %T %z', $str),   $to->strftime('%F %T %z'),
            'strftime';

        is $self->human_datefull( $str ),       $to->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $time ),      $to->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str ),       $to->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $time ),      $to->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str ),           $to->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $time ),          $to->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str ),           $to->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $time ),          $to->strftime('%F'),
            'human_date from timestamp';

        $self->app->plugin('Human', tz => 'local');

        $self->render(text => 'OK.');
    });

    $t->get_ok("/test/human/tz")-> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'cookie timezone numeric';
{
    my $time    = 60 * 60 * 24;

    my $tz_source   = DateTime::TimeZone->new(name => '-0200');
    my $tz_dest     = DateTime::TimeZone->new(name => '+0600');
    my $tz_default  = DateTime::TimeZone->new(name => '+0300');

    my $from    = DateTime->from_epoch(epoch => $time, time_zone => $tz_source);
    my $str     = $from->strftime('%F %T %z');

    my $to      = $from->clone;
    $to->set_time_zone( $tz_dest );

    $t->app->routes->get("/test/human/cookie/num")->to( cb => sub {
        my ($self) = @_;

       $self->app->plugin('Human', tz => $tz_default->name);

        is $self->str2time( $to ),              $to->epoch, 'str2time';

        is $self->str2time( $str ),             $to->epoch, 'str2time';

        is $self->strftime('%F %T %z', $str),   $to->strftime('%F %T %z'),
            'strftime';

        is $self->human_datefull( $str ),       $to->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $time ),      $to->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str ),       $to->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $time ),      $to->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str ),           $to->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $time ),          $to->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str ),           $to->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $time ),          $to->strftime('%F'),
            'human_date from timestamp';

        $self->app->plugin('Human', tz => 'local');

        $self->render(text => 'OK.');
    });

    my $cookie = Mojo::Cookie::Request->new(
        name    => 'tz',
        value   => $tz_dest->name,
    );

    $t  -> get_ok("/test/human/cookie/num" => {'Cookie' => $cookie->to_string} )
        -> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'cookie timezone numeric escaped';
{
    my $time    = 60 * 60 * 24;

    my $tz_source   = DateTime::TimeZone->new(name => '-0200');
    my $tz_dest     = DateTime::TimeZone->new(name => '+0300');
    my $tz_default  = DateTime::TimeZone->new(name => '+0700');

    my $from    = DateTime->from_epoch(epoch => $time, time_zone => $tz_source);
    my $str     = $from->strftime('%F %T %z');

    my $to      = $from->clone;
    $to->set_time_zone( $tz_dest );

    $t->app->routes->get("/test/human/cookie/esc")->to( cb => sub {
        my ($self) = @_;

       $self->app->plugin('Human', tz => $tz_default->name);

        is $self->str2time( $to ),              $to->epoch, 'str2time';

        is $self->str2time( $str ),             $to->epoch, 'str2time';

        is $self->strftime('%F %T %z', $str),   $to->strftime('%F %T %z'),
            'strftime';

        is $self->human_datefull( $str ),       $to->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $time ),      $to->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str ),       $to->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $time ),      $to->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str ),           $to->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $time ),          $to->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str ),           $to->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $time ),          $to->strftime('%F'),
            'human_date from timestamp';

        $self->app->plugin('Human', tz => 'local');

        $self->render(text => 'OK.');
    });

    my $cookie = Mojo::Cookie::Request->new(
        name    => 'tz',
        value   => url_escape $tz_dest->name,
    );

    $t  -> get_ok("/test/human/cookie/esc" => {'Cookie' => $cookie->to_string} )
        -> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'cookie timezone alpha';
{
    my $time    = 60 * 60 * 24;

    my $tz_source   = DateTime::TimeZone->new(name => '+0600');
    my $tz_dest     = DateTime::TimeZone->new(name => 'America/New_York');
    my $tz_default  = DateTime::TimeZone->new(name => 'Asia/Kolkata');

    my $from    = DateTime->from_epoch(epoch => $time, time_zone => $tz_source);
    my $str     = $from->strftime('%F %T %z');

    my $to      = $from->clone;
    $to->set_time_zone( $tz_dest );

    $t->app->routes->get("/test/human/cookie/alp")->to( cb => sub {
        my ($self) = @_;

        $self->app->plugin('Human', tz => $tz_default->name);

        is $self->str2time( $to ),              $to->epoch, 'str2time';

        is $self->str2time( $str ),             $to->epoch, 'str2time';

        is $self->strftime('%F %T %z', $str),   $to->strftime('%F %T %z'),
            'strftime';

        is $self->human_datefull( $str ),       $to->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $time ),      $to->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str ),       $to->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $time ),      $to->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str ),           $to->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $time ),          $to->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str ),           $to->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $time ),          $to->strftime('%F'),
            'human_date from timestamp';

        $self->app->plugin('Human', tz => 'local');

        $self->render(text => 'OK.');
    });

    my $cookie = Mojo::Cookie::Request->new(
        name    => 'tz',
        value   => $tz_dest->name,
    );

    $t  -> get_ok("/test/human/cookie/alp" => {'Cookie' => $cookie->to_string} )
        -> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'cookie timezone error';
{
    my $time    = 60 * 60 * 24;

    my $tz_source   = DateTime::TimeZone->new(name => '+0600');
    my $tz_default  = DateTime::TimeZone->new(name => 'Asia/Kolkata');

    my $from    = DateTime->from_epoch(epoch => $time, time_zone => $tz_source);
    my $str     = $from->strftime('%F %T %z');

    my $to      = $from->clone;
    $to->set_time_zone( $tz_default ); # default on error

    $t->app->routes->get("/test/human/cookie/err")->to( cb => sub {
        my ($self) = @_;

        $self->app->plugin('Human', tz => $tz_default->name);

        is $self->str2time( $to ),              $to->epoch, 'str2time';

        is $self->str2time( $str ),             $to->epoch, 'str2time';

        is $self->strftime('%F %T %z', $str),   $to->strftime('%F %T %z'),
            'strftime';

        is $self->human_datefull( $str ),       $to->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $time ),      $to->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str ),       $to->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $time ),      $to->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str ),           $to->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $time ),          $to->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str ),           $to->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $time ),          $to->strftime('%F'),
            'human_date from timestamp';

        $self->app->plugin('Human', tz => 'local');

        $self->render(text => 'OK.');
    });

    my $cookie = Mojo::Cookie::Request->new(
        name    => 'tz',
        value   => 'SomeStringNotTimeZone!',
    );

    $t  -> get_ok("/test/human/cookie/err" => {'Cookie' => $cookie->to_string} )
        -> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'cookie timezone like something right';
{
    my $time    = 60 * 60 * 24;

    my $tz_source   = DateTime::TimeZone->new(name => '+0600');
    my $tz_default  = DateTime::TimeZone->new(name => 'Asia/Kolkata');

    my $from    = DateTime->from_epoch(epoch => $time, time_zone => $tz_source);
    my $str     = $from->strftime('%F %T %z');

    my $to      = $from->clone;
    $to->set_time_zone( $tz_default ); # default on error

    $t->app->routes->get("/test/human/cookie/like")->to( cb => sub {
        my ($self) = @_;

        $self->app->plugin('Human', tz => $tz_default->name);

        is $self->str2time( $to ),              $to->epoch, 'str2time';

        is $self->str2time( $str ),             $to->epoch, 'str2time';

        is $self->strftime('%F %T %z', $str),   $to->strftime('%F %T %z'),
            'strftime';

        is $self->human_datefull( $str ),       $to->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $time ),      $to->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str ),       $to->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $time ),      $to->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str ),           $to->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $time ),          $to->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str ),           $to->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $time ),          $to->strftime('%F'),
            'human_date from timestamp';

        $self->app->plugin('Human', tz => 'local');

        $self->render(text => 'OK.');
    });

    my $cookie = Mojo::Cookie::Request->new(
        name    => 'tz',
        value   => 'SomeStringNotTimeZone/SomeStringNotTimeZone',
    );

    $t  -> get_ok("/test/human/cookie/like" => {'Cookie' => $cookie->to_string})
        -> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'local force timezone';
{
    my $time    = 60 * 60 * 24;

    my $tz_source   = DateTime::TimeZone->new(name => '-0200');
    my $tz_dest     = DateTime::TimeZone->new(name => '+0600');
    my $tz_default  = DateTime::TimeZone->new(name => '+0300');
    my $tz_force    = DateTime::TimeZone->new(name => '-0500');

    my $from    = DateTime->from_epoch(epoch => $time, time_zone => $tz_source);
    my $str     = $from->strftime('%F %T %z');

    my $to      = $from->clone;
    $to->set_time_zone( $tz_force );

    $t->app->routes->get("/test/human/cookie/num")->to( cb => sub {
        my ($self) = @_;

        $self->app->plugin('Human', tz => $tz_default->name);

        $self->stash('-human-force-tz' => $tz_force->name);

        is $self->str2time( $to ),              $to->epoch, 'str2time';

        is $self->str2time( $str ),             $to->epoch, 'str2time';

        is $self->strftime('%F %T %z', $str),   $to->strftime('%F %T %z'),
            'strftime';

        is $self->human_datefull( $str ),       $to->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $time ),      $to->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str ),       $to->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $time ),      $to->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str ),           $to->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $time ),          $to->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str ),           $to->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $time ),          $to->strftime('%F'),
            'human_date from timestamp';

        $self->app->plugin('Human', tz => 'local');

        $self->render(text => 'OK.');
    });

    my $cookie = Mojo::Cookie::Request->new(
        name    => 'tz',
        value   => $tz_dest->name,
    );

    $t  -> get_ok("/test/human/cookie/num" => {'Cookie' => $cookie->to_string} )
        -> status_is( 200 );

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'global force timezone';
{
    my $time    = 60 * 60 * 24;

    my $tz_source   = DateTime::TimeZone->new(name => '-0200');
    my $tz_dest     = DateTime::TimeZone->new(name => '+0600');
    my $tz_default  = DateTime::TimeZone->new(name => '+0300');
    my $tz_local    = DateTime::TimeZone->new(name => '-0700');
    my $tz_force    = DateTime::TimeZone->new(name => '-0500');

    my $from    = DateTime->from_epoch(epoch => $time, time_zone => $tz_source);
    my $str     = $from->strftime('%F %T %z');

    my $to      = $from->clone;
    $to->set_time_zone( $tz_force );

    $t->app->routes->get("/test/human/cookie/num")->to( cb => sub {
        my ($self) = @_;

        $self->app->plugin('Human',
            tz          => $tz_default->name,
            tz_force    => $tz_force->name,
        );

        $self->stash('-human-force-tz' => $tz_local->name);

        is $self->str2time( $to ),              $to->epoch, 'str2time';

        is $self->str2time( $str ),             $to->epoch, 'str2time';

        is $self->strftime('%F %T %z', $str),   $to->strftime('%F %T %z'),
            'strftime';

        is $self->human_datefull( $str ),       $to->strftime('%F %T'),
            'human_datefull from ISO';
        is $self->human_datefull( $time ),      $to->strftime('%F %T'),
            'human_datefull from timestamp';

        is $self->human_datetime( $str ),       $to->strftime('%F %H:%M'),
            'human_datetime from ISO';
        is $self->human_datetime( $time ),      $to->strftime('%F %H:%M'),
            'human_datetime from timestamp';

        is $self->human_time( $str ),           $to->strftime('%H:%M:%S'),
            'human_time from ISO';
        is $self->human_time( $time ),          $to->strftime('%H:%M:%S'),
            'human_time from timestamp';

        is $self->human_date( $str ),           $to->strftime('%F'),
            'human_date from ISO';
        is $self->human_date( $time ),          $to->strftime('%F'),
            'human_date from timestamp';

        $self->app->plugin('Human', tz => 'local');

        $self->render(text => 'OK.');
    });

    my $cookie = Mojo::Cookie::Request->new(
        name    => 'tz',
        value   => $tz_dest->name,
    );

    $t  -> get_ok("/test/human/cookie/num" => {'Cookie' => $cookie->to_string} )
        -> status_is( 200 );

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

