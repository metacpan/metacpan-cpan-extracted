# It is dirty rework of original smsc.ru library. Now it has object interface.
package SMS::API::SMSC;

use strict;
use warnings;
use 5.008_001;

our $VERSION = 0.001;

use LWP::UserAgent;
use URI::Escape;
require Carp;

use constant SMSC_DEBUG => $ENV{SMSC_DEBUG};

sub new {
    my ($class, %args) = @_;

    bless {
        login    => $args{login}    || Carp::croak('login required'),
        password => $args{password} || Carp::croak('password requried'),
        post     => $args{post}     || 0,
        https    => $args{https}    || 0,
        charset  => $args{charset}  || 'utf-8',
    }, $class;
}

my @FORMATS = ("flash=1", "push=1", "hlr=1", "bin=1", "bin=2", "ping=1");

sub send {
    my ($self, $phones, $message, %args) = @_;

    my $cmd_arg = "cost=3&phones=" . uri_escape($phones);
    $cmd_arg .= "&mes=" . uri_escape($message);
    $cmd_arg .= "&charset=" . $self->{charset};

    $cmd_arg .= "&translit=$args{translit}"        if $args{translit};
    $cmd_arg .= "&id=$args{id}"                    if $args{id};
    $cmd_arg .= $FORMATS[$args{format} - 1]        if $args{format};
    $cmd_arg .= "&time=" . uri_escape($args{time}) if $args{time};
    $cmd_arg .= "&$args{query}"                    if $args{query};
    $cmd_arg .= "&sender=" . uri_escape($args{sender})
      if defined $args{sender};

    my @m = $self->_smsc_send_cmd("send", $cmd_arg);

    # (id, cnt, cost, balance) или (id, -error)

    if (SMSC_DEBUG) {
        if ($m[1] > 0) {
            print
              "Сообщение отправлено успешно. ID: $m[0], всего SMS: $m[1], стоимость: $m[2] руб., баланс: $m[3] руб.\n";
        }
        else {
            print "Ошибка №", -$m[1],
              $m[0] ? ", ID: " . $m[0] : "", "\n";
        }
    }

    return @m;
}

sub get_cost {
    my ($self, $phones, $message, %args) = @_;

    my @formats = ("flash=1", "push=1", "hlr=1", "bin=1", "bin=2", "ping=1");

    my @m = $self->_smsc_send_cmd(
        "send",
        "cost=1&phones="
          . uri_escape($phones) . "&mes="
          . uri_escape($message)
          . (
            defined $args{sender} ? "&sender=" . uri_escape($args{sender})
            : ""
          )
          . "&charset="
          . $self->{charset}
          . ($args{translit} ? "&translit=$args{translit}"       : "")
          . ($args{format}   ? "&" . $FORMATS[$args{format} - 1] : "")
          . (
            $args{query} ? "&$args{query}"
            : ""
          )
    );

    # (cost, cnt) или (0, -error)

    if (SMSC_DEBUG) {
        if ($m[1] > 0) {
            print
              "Стоимость рассылки: $m[0] руб. Всего SMS: $m[1]\n";
        }
        else {
            print "Ошибка №", -$m[1], "\n";
        }
    }

    return @m;
}

sub get_status {
    my ($self, $id, $phone) = @_;

    my @m =
      $self->_smsc_send_cmd("status",
        "phone=" . uri_escape($phone) . "&id=" . $id);

    # (status, time, err) или (0, -error)

    if (SMSC_DEBUG) {
        if (exists $m[2]) {
            print "Статус SMS = $m[0]",
              $m[1]
              ? ", время изменения статуса - "
              . localtime($m[1])
              : "", "\n";
        }
        else {
            print "Ошибка №", -$m[1], "\n";
        }
    }

    return @m;
}

sub get_balance {
    my $self = shift;

    my @m = $self->_smsc_send_cmd("balance");   # (balance) или (0, -error)

    if (SMSC_DEBUG) {
        if (!exists $m[1]) {
            print "Сумма на счете: ", $m[0], " руб.\n";
        }
        else {
            print "Ошибка №", -$m[1], "\n";
        }
    }

    return exists $m[1] ? undef : $m[0];
}


# ВНУТРЕННИЕ ФУНКЦИИ

# Функция вызова запроса. Формирует URL и делает 3 попытки чтения

sub _smsc_send_cmd {
    my ($self, $cmd, $arg) = @_;

    my $url = ($self->{https} ? "https" : "http") . "://smsc.ru/sys/$cmd.php";
    $arg =
        "login="
      . uri_escape($self->{login}) . "&psw="
      . uri_escape($self->{password})
      . "&fmt=1&"
      . ($arg ? $arg : "");

    my $ret;
    my $i = 0;

    do {
        sleep(2) if ($i);
        $ret = $self->_smsc_read_url($url, $arg);
    } while ($ret eq "" && ++$i < 3);

    if ($ret eq "") {
        print "Ошибка чтения адреса: $url\n"
          if (SMSC_DEBUG);
        $ret = ",0";    # фиктивный ответ
    }

    return split(/,/, $ret);
}

# Функция чтения URL

sub _smsc_read_url {
    my ($self, $url, $arg) = @_;

    my $ret = "";
    my $post = $self->{post} || length($arg) > 2000;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(60);

    my $response =
        $post
      ? $ua->post($url, Content => $arg)
      : $ua->get($url . "?" . $arg);

    $ret = $response->content if $response->is_success;

    return $ret;
}

1;

__END__

=encoding utf8

=head1 NAME

SMS::API::SMSC - send SMS with smsc.ru

=head1 SYNOPSIS

    use SMS::API::SMSC;

    my $sms = SMS::API::SMSC->new(login => '<login>', password => '<password>');

    my ($sms_id, $sms_cnt, $cost, $balance) =
      $sms->send("79999999999", "Ваш пароль: 123", translit => 1);

    my ($sms_id, $sms_cnt, $cost, $balance) =
      $sms->send("79999999999", "http://smsc.ru\nSMSC.RU",
        query => "maxsms=3");

    my ($sms_id, $sms_cnt, $cost, $balance) = $sms->send(
        "79999999999",
        "0605040B8423F0DC0601AE02056A0045C60C037761702E736D73632E72752F0001037761702E736D73632E7275000101",
        format => 5
    );

    my ($sms_id, $sms_cnt, $cost, $balance) =
      $sms->send("79999999999", "", format => 3);

    my ($cost, $sms_cnt) = $sms->get_cost("79999999999",
        "Вы успешно зарегистрированы!");

    my ($status, $args{time}) = $sms->get_status($sms_id, "79999999999");

    my $balance = $sms->get_balance();

=head1 METHODS

The following method are available

=over

=item $sms->send($phones, $message, %args);

Функция отправки SMS.

Обязательные параметры:

=over 2

=item $phones

список телефонов через запятую или точку с запятой

=item $message

отправляемое сообщение

=back

необязательные параметры:

=over 4

=item $args{translit}

переводить или нет в транслит (1,2 или 0)

=item $args{time}

необходимое время доставки в виде строки (DDMMYYhhmm, h1-h2, 0ts, +m)

=item $args{id}

идентификатор сообщения. Представляет собой 32-битное число в диапазоне от 1 до 2147483647.

=item $args{format}

формат сообщения (0 - обычное sms, 1 - flash-sms, 2 - wap-push, 3 - hlr, 4 - bin, 5 - bin-hex, 6 - ping-sms)

=item $args{sender}

имя отправителя (Sender ID). Для отключения Sender ID по умолчанию необходимо в
качестве имени передать пустую строку или точку.

=item $args{query}

строка дополнительных параметров, добавляемая в URL-запрос ("valid=01:00&maxsms=3")

=back

возвращает массив (<id>, <количество sms>, <стоимость>, <баланс>) в случае
успешной отправки, либо массив (<id>, -<код ошибки>) в случае ошибки

=item $sms->get_cost($phones, $message, %args);


Функция получения стоимости SMS

обязательные параметры:

=over 4

=item $phones

список телефонов через запятую или точку с запятой

=item $message

отправляемое сообщение

=back

необязательные параметры:

=over 4

=item $args{translit}

переводить или нет в транслит (1,2 или 0)

=item $args{format}

формат сообщения (0 - обычное sms, 1 - flash-sms, 2 - wap-push, 3 - hlr, 4 - bin, 5 - bin-hex, 6 - ping-sms)

=item $args{sender}

имя отправителя (Sender ID)

=item $args{query}

строка дополнительных параметров, добавляемая в URL-запрос ("list=79999999999:Ваш пароль: 123\n78888888888:Ваш пароль: 456")

=back

возвращает массив (<стоимость>, <количество sms>) либо массив (0, -<код ошибки>) в случае ошибки

=item $sms->get_status($id, $phone);

Функция проверки статуса отправленного SMS или HLR-запроса

=over 2

=item $id

ID cообщения

=item $phone

номер телефона

=back

возвращает массив:
для отправленного SMS (<статус>, <время изменения>, <код ошибки sms>)
для HLR-запроса (<статус>, <время изменения>, <код ошибки sms>, <код страны регистрации>, <код оператора абонента>,
<название страны регистрации>, <название оператора абонента>, <название роуминговой страны>, <название роумингового оператора>,
<код IMSI SIM-карты>, <номер сервис-центра>)
либо массив (0, -<код ошибки>) в случае ошибки

=item $sms->get_balance;

Функция получения баланса

без параметров

возвращает баланс в виде строки или undef в случае ошибки

=back

=head1 SEE ALSO

Original library L<http://smsc.ru/api/perl/>

=head1 COPYRIGHT

Copyright 2012 Sergey Zasenko.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Based on original smsc.ru library smsc.ru/api/perl
