package Mojolicious::Plugin::Human;

use strict;
use warnings;
use utf8;
use 5.10.0;

use Mojo::Base 'Mojolicious::Plugin';
use Carp;
use POSIX       qw(strftime);
use DateTime;
use DateTime::Format::DateParse;
use DateTime::TimeZone;

use Mojo::Util  qw(url_unescape);
use Mojo::ByteStream;

our $VERSION = '1.01';

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Human - Helpers to print values as human readable form.

=head1 SYNOPSIS

    $self->plugin('Human', {

        # Set money parameters if you need
        money_delim => ",",
        money_digit => " ",

        # Local format for date and time strings
        datetime    => '%d.%m.%Y %H:%M',
        time        => '%H:%M:%S',
        date        => '%d.%m.%Y',

        phone_country   => 1,
    });

    # Controllers

    $self->human_datetime( time );

    # Templates

    # return '2015-05-23 13:63'
    %= human_datetime '2015-05-23 13:63:67 +0400'

=head1 DESCRIPTION

You can use this module in Mojo template engine to make you users happy.

=head1 CONFIGURATION

=over

=item money_format

Set printf like money format. Default B<%.2f>

=item money_delim

Set format for human readable delimiter of money. Default: B<.>

=item money_digit

Set format for human readable digits of money. Default: B<,>

=item datefull

Set full format for human readable date and time. Default: %F %T

=item datetime

Set format for human readable date and time. Default: %F %H:%M

=item time

Set format for human readable time. Default: %H:%M:%S

=item date

Set format for human readable date. Default: %F

=item tz

Set default time zone for DateTime. Default: local

=item tz_force

Force use time zone

=item tz_cookie

Set default cookie name for extract time zone from client. Default: tz

=item interval_format

Set default time format for intervals. Default : %0.2d:%0.2d:%0.2d

=item phone_country

Set country code for phones functions. Default: 7

=item suffix_one

Set default suffix for 1 value. DEPRICATED!

=item suffix_two

Set default suffix for value between 2 and 5. DEPRICATED!

=item suffix_many

Set default suffix for other values. DEPRICATED!

=item cut_length

Set default max length for I<human_cut>. Default: 8

=back

=head1 DATE AND TIME HELPERS

=head2 str2datetime $str, $tz

Get string or number, return DateTime object.
Optional get $tz timezone.

=head2 str2time $str, $tz

Get string, return timestamp.
Optional get $tz timezone.

=head2 strftime $str, $tz

Get string, return formatted string.
Optional get $tz timezone.

=head2 human_datetime $str, $tz

Get string, return date and time string in human readable form.
Optional get $tz timezone.

=head2 human_time $str, $tz

Get string, return time string in human readable form.
Optional get $tz timezone.

=head2 human_date $str, $tz

Get $str string, return date string in human readable form.
Optional get $tz timezone.

=head2 human_interval $sec

Get count of seconds and return interval human readable form.

=head1 MONEY HELPERS

=head2 human_money $str

=head2 human_money $format, $str

Get number, return money string in human readable form with levels.

=head2 human_money_short $str

=head2 human_money_short $format, $str

Like I<human_money> but discard zeros.

=head1 PHONE HELPERS

=head2 flat_phone $str, $country

Get srtring, return flat phone string.

=head2 human_phone $str, $country, $add

Get srtring, return phone string in human readable form.

=head2 human_phones $str, $country, $add

Get srtring, return phones (if many) string in human readable form.

=head1 TEXT HELPERS

=head2 human_suffix $str, $count, $one, $two, $many

Get word base form and add some of suffix ($one, $two, $many) depends of $count
DEPRICATED!

=head2 human_suffix_ru $count, $one, $two, $many

Get word form for ($one, $two, $many) depends of $count

=head2 human_cut $str, $length

Return string cut off $length and ellipsis in the end.

=head1 DISTANCE HELPERS

=head2 human_distance $dist

Return distance, without fractional part if possible.

=cut

# Placement level in the money functions
our $REGEXP_DIGIT = qr{^(-?\d+)(\d{3})};

# Timestamp
our $REGEXP_TIMESTAMP = qr{^\d+$};

# Fractional part of numbers
our $REGEXP_FRACTIONAL = qr{\.?0+$};
# Fractional delimeter of numbers
our $REGEXP_FRACTIONAL_DELIMITER = qr{\.};

# Phones symbols
our $REGEXP_PHONE_SYMBOL = qr{[^0-9wp\+]+};
# Phones command
our $REGEXP_PHONE_COMMAND = qr{[wp]};
# Get parts of phone number to make it awesome
our $REGEXP_PHONE_AWESOME = qr{^(\+.)(...)(...)(.*)$};

# Some values separators
our $REGEXP_SEPARATOR = qr{[\s,;:]+};

sub register {
    my ($self, $app, $conf) = @_;

    # Configuration
    $conf                       ||= {};

    $conf->{money_format}       //= '%.2f';
    $conf->{money_delim}        //= '.';
    $conf->{money_digit}        //= ',';

    $conf->{datefull}           //= '%F %T';
    $conf->{datetime}           //= '%F %H:%M';
    $conf->{time}               //= '%H:%M:%S';
    $conf->{date}               //= '%F';
    $conf->{tz}                 //= strftime '%z', localtime;
    $conf->{tz_force}           //= undef;
    $conf->{tz_cookie}          //= 'tz';
    $conf->{interval_format}    //= '%0.2d:%0.2d:%0.2d';

    $conf->{phone_country}      //= 7;
    $conf->{phone_add}          //= '.';

    $conf->{suffix_one}         //= '';
    $conf->{suffix_two}         //= 'a';
    $conf->{suffix_many}        //= 'ов';

    $conf->{cut_length}         //= 8;

    # Get timezone from cookies
    $app->hook(before_dispatch => sub {
        my ($self) = @_;

        my $tz = $self->cookie( $conf->{tz_cookie} );
        return unless defined $tz;
        return unless length  $tz;

        $tz = url_unescape $tz;
        return unless DateTime::TimeZone->is_valid_name( $tz );

        $self->stash('-human-cookie-tz' => $tz);
    });

    # Datetime

    $app->helper(str2datetime => sub {
        my ($self, $str, $tz) = @_;
        return unless $str;

        my $dt = eval {
            if( ref $str ) {
                $str->clone;
            } elsif( $str =~ m{$REGEXP_TIMESTAMP} ) {
                DateTime->from_epoch( epoch => $str );
            } else {
                DateTime::Format::DateParse->parse_datetime( $str );
            }
        };
        return if ( !$dt or $@ );

        # time zone: set or force or cookie or default
        $tz ||= $conf->{tz_force}                   ||
                $self->stash('-human-force-tz')     ||
                $self->stash('-human-cookie-tz')    ||
                $conf->{tz};
        # make time zone
        $dt->set_time_zone( $tz );

        return $dt;
    });

    $app->helper(str2time => sub {
        my ($self, $str, $tz) = @_;
        my $datetime = $self->str2datetime($str => $tz);
        return $str unless $datetime;
        return Mojo::ByteStream->new( $datetime->epoch );
    });

    $app->helper(strftime => sub {
        my ($self, $format, $str, $tz) = @_;
        return unless defined $str;
        my $datetime = $self->str2datetime($str => $tz);
        return $str unless $datetime;
        return Mojo::ByteStream->new( $datetime->strftime( $format ) );
    });

    $app->helper(human_datefull => sub {
        my ($self, $str, $tz) = @_;
        my $datetime = $self->str2datetime($str => $tz);
        return $str unless $datetime;
        return Mojo::ByteStream->new( $datetime->strftime($conf->{datefull}) );
    });

    $app->helper(human_datetime => sub {
        my ($self, $str, $tz) = @_;
        my $datetime = $self->str2datetime($str => $tz);
        return $str unless $datetime;
        return Mojo::ByteStream->new( $datetime->strftime($conf->{datetime}) );
    });

    $app->helper(human_time => sub {
        my ($self, $str, $tz) = @_;
        my $datetime = $self->str2datetime($str => $tz);
        return $str unless $datetime;
        return Mojo::ByteStream->new( $datetime->strftime($conf->{time}) );
    });

    $app->helper(human_date => sub {
        my ($self, $str, $tz) = @_;
        my $datetime = $self->str2datetime($str => $tz);
        return $str unless $datetime;
        return Mojo::ByteStream->new( $datetime->strftime($conf->{date}) );
    });

    $app->helper(human_interval => sub {
        my ($self, $sec) = @_;

        return undef unless defined $sec;

        my $epoch = abs $sec;

        my $seconds = $epoch               % 60;
        my $minutes = int($epoch / 60)     % 60;
        my $hours   = int($epoch / 3600)   % 24;
        my $days    = int($epoch / 86400);

        my $time = '';
        $time .= sprintf $conf->{interval_format}, $hours, $minutes, $seconds;
        $time  = sprintf '%d %s', $days, $time if $days;
        $time  = ($sec < 0 ? '-' : '') . $time;

        return $time;
    });

    # Money

    $app->helper(human_money => sub {
        my $self    = shift;
        my $str     = pop;
        my $format  = shift // $conf->{money_format};

        return undef unless defined $str;
        return undef unless length  $str;

        my $delim = $conf->{money_delim};
        my $digit = $conf->{money_digit};
        $str = sprintf $format, $str;
        $str =~ s{$REGEXP_FRACTIONAL_DELIMITER}{$delim};
        1 while $str =~ s{$REGEXP_DIGIT}{$1$digit$2};

        return Mojo::ByteStream->new($str);
    });

    $app->helper(human_money_short => sub {
        my $self = shift;

        my $stream = $self->human_money(@_);
        return undef unless defined $stream;

        my $str = "$stream";
        s{\D00$}{} for $str;
        return Mojo::ByteStream->new($str);
    });

    # Phones

    $app->helper(flat_phone => sub {
        my ($self, $phone, $country) = @_;
        return undef unless $phone;

        # clear
        s/$REGEXP_PHONE_SYMBOL//ig for $phone;
        return undef unless 10 <= length $phone;

        $country //= $conf->{phone_country};
        # make full
        $phone = '+' . $country . $phone unless $phone =~ m{^\+};

        return Mojo::ByteStream->new($phone);
    });

    $app->helper(human_phone => sub {
        my ($self, $phone, $country, $add) = @_;
        return unless $phone;

        # make clean
        $phone = $self->flat_phone( $phone, $country );
        return $phone unless $phone;

        # make awesome
        $add //= $conf->{phone_add};
        s{$REGEXP_PHONE_AWESOME}{$1-$2-$3-$4},
        s{$REGEXP_PHONE_COMMAND}{$add}ig
            for $phone;

        return Mojo::ByteStream->new($phone);
    });

    $app->helper(human_phones => sub {
        my ($self, $str, $country, $add) = @_;
        return '' unless $str;

        my @phones = split m{$REGEXP_SEPARATOR}, $str;
        my $phones = join ', ' => grep { $_ } map {
            $self->human_phone( $_, $country, $add )
        } @phones;

        return Mojo::ByteStream->new($phones);
    });

    # Text

    # DEPRICATED
    $app->helper(human_suffix => sub {
        my ($self, $str, $count, $one, $two, $many) = @_;

        warn 'human_suffix DEPRICATED!';

        return      unless defined $str;
        return $str unless defined $count;

        # Last digit
        my $tail = abs( $count ) % 10;

        # Default suffix
        $one  //= $str  . $conf->{suffix_one};
        $two  //= $str  . $conf->{suffix_two};
        $many //= $str  . $conf->{suffix_many};

        # Get right suffix
        my $result =
            ( $tail == 0 )                  ?$many  :
            ( $tail == 1 )                  ?$one   :
            ( $tail >= 2  and $tail < 5 )   ?$two   :$many;

        # For 10 - 20 get special suffix
        $tail = abs( $count ) % 100;
        $result =
            ( $tail >= 10 and $tail < 21 )  ?$many  :$result;

        return Mojo::ByteStream->new($result);
    });

    $app->helper(human_suffix_ru => sub {
        my ($self, $count, $one, $two, $many) = @_;

        return unless defined $count;

        # Last digit
        my $tail = abs( $count ) % 10;

        # Get right suffix
        my $result =
            ( $tail == 0 )                  ?$many  :
            ( $tail == 1 )                  ?$one   :
            ( $tail >= 2  and $tail < 5 )   ?$two   :$many;

        # For 10 - 20 get special suffix
        $tail = abs( $count ) % 100;
        $result =
            ( $tail >= 10 and $tail < 21 )  ?$many  :$result;

        return Mojo::ByteStream->new($result);
    });

    $app->helper(human_cut => sub {
        my ($self, $str, $length) = @_;

        return undef unless defined $str;
        return undef unless length $str;

        $length //= $conf->{cut_length};
        return Mojo::ByteStream->new(
            $length < length $str
                ? substr($str, 0 => $length) . '…'
                : $str
        );
    });

    # Distance

    $app->helper(human_distance => sub {
        my ($self, $dist) = @_;
        $dist = sprintf '%3.2f', $dist;
        $dist =~ s{$REGEXP_FRACTIONAL}{};
        return Mojo::ByteStream->new($dist);
    });
}

1;

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
