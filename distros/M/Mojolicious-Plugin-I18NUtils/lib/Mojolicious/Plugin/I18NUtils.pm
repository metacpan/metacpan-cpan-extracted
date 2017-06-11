package Mojolicious::Plugin::I18NUtils;

# ABSTRACT: provide some helper functions for I18N
use Mojo::Base 'Mojolicious::Plugin';
use Time::Piece;
use CLDR::Number;
use HTTP::AcceptLanguage;

use Mojolicious::Plugin::I18NUtils::Locale;

our $VERSION = '0.20';

sub register {
    my ($self, $app, $config) = @_;

    $config //= {};
    my $parse_format = $config->{format} // '%Y-%m-%d %H:%M:%S';

    my %objects;

    $app->helper( browser_languages => sub {
        my $c = shift;

        my $lang = HTTP::AcceptLanguage->new( $c->req->headers->accept_language );
        return $lang->languages;
    });

    $app->helper( datetime_loc => sub {
        my $c = shift;
        my ($date, $lang) = @_;

        $lang //= ($c->browser_languages)[0];

        return '' if !defined $date;

        my $output_format  = $self->_date_long( $lang );
        my $formatted_date = $self->_translate( $date, $parse_format, $output_format );

        return $formatted_date;
    } );

    $app->helper( date_loc => sub {
        my $c = shift;
        my ($date, $lang) = @_;

        $lang //= ($c->browser_languages)[0];

        return '' if !defined $date;

        my $output_format  = $self->_date_short( $lang );
        my $formatted_date = $self->_translate( $date, $parse_format, $output_format );

        return $formatted_date;
    } );

    $app->helper( date_from_to => sub {
        my $c = shift;
        my ($date, $from, $to) = @_;

        my $in_format  = $self->_date_short( $from );
        my $out_format = $self->_date_short( $to );

        $out_format = '%Y-%m-%d' if lc $to eq 'iso';

        my $formatted_date = $self->_translate( $date, $in_format, $out_format );

        return $formatted_date;
    } );

    $app->helper( currency => sub {
        my ($c, $number, $locale, $currency, $opts) = @_;

        $locale //= ($c->browser_languages)[0];

        $objects{cldr}->{$locale} ||= CLDR::Number->new( locale => $locale );
        $objects{cur}->{$locale}  ||= $objects{cldr}->{$locale}->currency_formatter( currency_code => $currency );

        my $cur_object = $objects{cur}->{$locale};

        if ( $opts && $opts->{cash} ) {
            $cur_object->cash(1);
        }

        my $formatted = $cur_object->format( $number );
        $cur_object->cash(0);

        return $formatted;
    } );

    $app->helper( decimal => sub {
        my ($c, $number, $locale) = @_;

        $locale //= ($c->browser_languages)[0];

        $objects{cldr}->{$locale} ||= CLDR::Number->new( locale => $locale );
        $objects{dec}->{$locale}  ||= $objects{cldr}->{$locale}->decimal_formatter;

        my $formatted = $objects{dec}->{$locale}->format( $number );
        return $formatted;
    } );

    $app->helper( range => sub {
        my ($c, $lower, $upper, $locale) = @_;

        $locale //= ($c->browser_languages)[0];

        $objects{cldr}->{$locale} ||= CLDR::Number->new( locale => $locale );
        $objects{dec}->{$locale}  ||= $objects{cldr}->{$locale}->decimal_formatter;

        my $formatted = $objects{dec}->{$locale}->range( $lower, $upper );
        return $formatted;
    } );

    $app->helper( at_least => sub {
        my ($c, $number, $locale) = @_;

        $locale //= ($c->browser_languages)[0];

        $objects{cldr}->{$locale} ||= CLDR::Number->new( locale => $locale );
        $objects{dec}->{$locale}  ||= $objects{cldr}->{$locale}->decimal_formatter;

        my $formatted = $objects{dec}->{$locale}->at_least( $number );
        return $formatted;
    } );

    $app->helper( locale_obj => sub {
        my ( $c, $locale) = @_;

        $locale //= ($c->browser_languages)[0];

        return Mojolicious::Plugin::I18NUtils::Locale->new( locale => $locale );
    });
}

sub _translate {
    my ($self, $date, $in, $out) = @_;

    if ( length $date < 11 ) {
        $date .= ' 00:00:00';
    }

    my $out_date;

    {
        local $SIG{__WARN__} = sub {};

        eval {
            my $date_obj = Time::Piece->strptime( $date, $in );
            $out_date    = $date_obj->strftime( $out );
            1;
        } or $out_date = '';
    }

    return $out_date;
}

sub _date_long {
    my ($self, $lang) = @_;

    return "%d/%m/%Y %H:%M:%S" if !$lang;

    $lang = lc $lang;
    $lang =~ s/-/_/g;

    state $formats = {
        ar_sa   => '%d.%m.%Y %H:%M:%S',
        bg      => '%d.%m.%Y %H:%M:%S',
        ca      => '%d.%m.%Y %H:%M:%S',
        cs      => '%d/%m/%Y %H:%M:%S',
        da      => '%d.%m.%Y %H:%M:%S',
        de      => '%d.%m.%Y %H:%M:%S',
        el      => '%d.%m.%Y %H:%M:%S',
        en_ca   => '%Y-%m-%d %H:%M:%S',
        en_gb   => '%d/%m/%Y %H:%M:%S',
        en      => '%m/%d/%Y %H:%M:%S',
        es_co   => '%d/%m/%Y - %H:%M:%S',
        es_mx   => '%d/%m/%Y - %H:%M:%S',
        es      => '%d/%m/%Y - %H:%M:%S',
        et      => '%d.%m.%Y %H:%M:%S',
        fa      => '%d.%m.%Y %H:%M:%S',
        fi      => '%d.%m.%Y %H:%M:%S',
        fr_ca   => '%d.%m.%Y %H:%M:%S',
        fr      => '%d.%m.%Y %H:%M:%S',
        he      => '%d/%m/%Y %H:%M:%S',
        hi      => '%d/%m/%Y - %H:%M:%S',
        hr      => '%d.%m.%Y %H:%M:%S',
        hu      => '%Y.%m.%d %H:%M:%S',
        it      => '%d/%m/%Y %H:%M:%S',
        ja      => '%Y/%m/%d %H:%M:%S',
        lt      => '%Y-%m-%d %H:%M:%S',
        lv      => '%d.%m.%Y %H:%M:%S',
        ms      => '%d.%m.%Y %H:%M:%S',
        nb_no   => '%d/%m %Y %H:%M:%S',
        nl      => '%d-%m-%Y %H:%M:%S',
        pl      => '%Y-%m-%d %H:%M:%S',
        pt_br   => '%d/%m/%Y %H:%M:%S',
        pt      => '%Y-%m-%d %H:%M:%S',
        ru      => '%d.%m.%Y %H:%M:%S',
        sk_sk   => '%d.%m.%Y %H:%M:%S',
        sl      => '%d.%m.%Y %H:%M:%S',
        sr_cyrl => '%d.%m.%Y %H:%M:%S',
        sr_latn => '%d.%m.%Y %H:%M:%S',
        sv      => '%d/%m %Y %H:%M:%S',
        sw      => '%m/%d/%Y %H:%M:%S',
        tr      => '%d.%m.%Y %H:%M:%S',
        uk      => '%m/%d/%Y %H:%M:%S',
        vi_vn   => '%d.%m.%Y %H:%M:%S',
        zh_cn   => '%Y.%m.%d %H:%M:%S',
        zh_tw   => '%Y.%m.%d %H:%M:%S',
    };

    return $formats->{$lang} // '%d/%m/%Y %H:%M:%S';
}

sub _date_short {
    my ($self, $lang) = @_;

    return "%d/%m/%Y" if !$lang;

    $lang = lc $lang;
    $lang =~ s/-/_/g;

    state $formats = {
        ar_sa   => '%d.%m.%Y',
        bg      => '%d.%m.%Y',
        ca      => '%d.%m.%Y',
        cs      => '%d/%m/%Y',
        da      => '%d.%m.%Y',
        de      => '%d.%m.%Y',
        el      => '%d.%m.%Y',
        en_ca   => '%Y-%m-%d',
        en_gb   => '%d/%m/%Y',
        en      => '%m/%d/%Y',
        es_co   => '%d/%m/%Y',
        es_mx   => '%d/%m/%Y',
        es      => '%d/%m/%Y',
        et      => '%d.%m.%Y',
        fa      => '%d.%m.%Y',
        fi      => '%d.%m.%Y',
        fr_ca   => '%d.%m.%Y',
        fr      => '%d.%m.%Y',
        he      => '%d/%m/%Y',
        hi      => '%d/%m/%Y',
        hr      => '%d.%m.%Y',
        hu      => '%Y.%m.%d',
        it      => '%d/%m/%Y',
        ja      => '%Y/%m/%d',
        lt      => '%Y-%m-%d',
        lv      => '%d.%m.%Y',
        ms      => '%d.%m.%Y',
        nb_no   => '%d.%m.%Y',
        nl      => '%d-%m-%Y',
        pl      => '%Y-%m-%d',
        pt_br   => '%d/%m/%Y',
        pt      => '%Y-%m-%d',
        ru      => '%d.%m.%Y',
        sk_sk   => '%d.%m.%Y',
        sl      => '%d.%m.%Y',
        sr_cyrl => '%d.%m.%Y',
        sr_latn => '%d.%m.%Y',
        sv      => '%Y.%m.%d',
        sw      => '%m/%d/%Y',
        tr      => '%d.%m.%Y',
        uk      => '%m/%d/%Y',
        vi_vn   => '%d.%m.%Y',
        zh_cn   => '%Y.%m.%d',
        zh_tw   => '%Y.%m.%d',
    };

    return $formats->{$lang} // '%d/%m/%Y';
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::I18NUtils - provide some helper functions for I18N

=head1 VERSION

version 0.20

=head1 SYNOPSIS

In your C<startup>:

    sub startup {
        my $self = shift;
  
        # do some Mojolicious stuff
        $self->plugin( 'I18NUtils' );

        # more Mojolicious stuff
    }

In your template:

    <%= datetime_loc('2014-12-10', 'de') %>

=head1 CONFIGURE

If you use a default format other than I<%Y-%m-%d %H:%M:%S> for dates in your
application, you can set a format for the parser. E.g. if your dates look like

  10.12.2014 12:34:56

You can add the plugin this way

  $self->plugin( I18NUtils => { format => '%d.%m.%Y %H:%M:%S' } );

=head1 HELPERS

This plugin adds those helper methods to your web application:

=head2 browser_languages

Return a list of languages defined in the I<Accept-Language> header.

  my @languages = $c->browser_languages;

or

  your browser accepts those languages: <%= join ', ', browser_languages() %>

Samples:

  Accept-Language: en-ca,en;q=0.8,en-us;q=0.6,de-de;q=0.4,de;q=0.2

returns

  your browser accepts those languages: en-ca, en, en-us, de-de, de

=head2 datetime_loc

This helper returns the givent date and time in the localized format.

 <%= datetime_loc('2014-12-10 11:12:13', 'de') %>

will return

 10.12.2014 11:12:13

If you omit the language it will be retrieved from Accept-Language header

 <%= datetime_loc('2014-12-10 11:12:13') %>
 # Accept-Language: de, en;q=0.8

will return

 10.12.2014 11:12:13

=head2 date_loc

Same as C<datetime_loc>, but omits the time

 <%= date_loc('2014-12-10 11:12:13', 'de') %>

will return

 10.12.2014

If you omit the language it will be retrieved from Accept-Language header

 <%= date_loc('2014-12-10 11:12:13') %>
 # Accept-Language: de, en;q=0.8

will return

 10.12.2014

=head2 currency

If you need to handle prices, the helper C<currency> might help you

  <%= currency(1111.99, 'ar', 'EUR') %>
  <%= currency(1111.99, 'de', 'EUR') %>
  <%= currency(1111.99, 'en', 'EUR') %>

will return

  € ١٬١١١٫٩٩
  1.111,99 €
  €1,111.99 

If you omit the language it will be retrieved from Accept-Language header

 <%= currency(1111.99, 'EUR') %>
 # Accept-Language: de, en;q=0.8

will return

 1.111,99 €

=head2 decimal

  <%= decimal( 2000, 'ar' ) %>
  <%= decimal( 2000, 'de' ) %>
  <%= decimal( 2000, 'en' ) %>

will return

  ٢٬٠٠٠
  2.000
  2,000

If you omit the language it will be retrieved from Accept-Language header

 <%= decimal( 2000 ) %>
 # Accept-Language: de, en;q=0.8

will return

 2.000

=head2 range

  <%= range(1, 2000, 'ar' ) %>
  <%= range(1, 2000, 'de' ) %>
  <%= range(1, 2000, 'en' ) %>

will return

  ١–٢٬٠٠٠
  1–2.000
  1–2,000

If you omit the language it will be retrieved from Accept-Language header

 <%= range( 1, 2000 ) %>
 # Accept-Language: de, en;q=0.8

will return

  1–2.000

=head2 at_least

  <%= at_least( 2000, 'ar' ) %>
  <%= at_least( 2000, 'de' ) %>
  <%= at_least( 2000, 'en' ) %>

will return

  +٢٬٠٠٠
  2.000+
  2,000+

If you omit the language it will be retrieved from Accept-Language header

 <%= at_least( 2000 ) %>
 # Accept-Language: de, en;q=0.8

will return

  2.000+

=head1 METHODS

=head2 register

Called when registering the plugin.

    # load plugin, alerts are dismissable by default
    $self->plugin( 'I18NUtils' );

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
