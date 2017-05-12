#!perl

use lib '../lib';

use strict;
use warnings;

use Perl6::Say;

{
    package MyApp::Country;

    use Moose;
    use MooseX::Aliases;
    use MooseX::Types::Locale::Country qw(
        Alpha2Country
        Alpha3Country
        NumericCountry
        CountryName
    );

    use Data::Util qw(:check);
    use Locale::Country;

    use namespace::clean -except => 'meta';

    has 'alpha2' => (
        traits      => [qw(
            Aliased
        )],
        is          => 'rw',
        isa         => Alpha2Country,
        init_arg    => '_alpha2',
        alias       => 'code',
        coerce      => 1,
        lazy_build  => 1,
        writer      => '_set_alpha2',
        trigger     => sub {
            $_[0]->clear_alpha3;
            $_[0]->clear_numeric;
            $_[0]->clear_name;
        },
    );

    has 'alpha3' => (
        is          => 'rw',
        isa         => Alpha3Country,
        init_arg    => '_alpha3',
        coerce      => 1,
        lazy_build  => 1,
        writer      => '_set_alpha3',
        trigger     => sub {
            $_[0]->clear_alpha2;
            $_[0]->clear_numeric;
            $_[0]->clear_name;
        },
    );

    has 'numeric' => (
        is          => 'rw',
        isa         => NumericCountry,
        init_arg    => '_numeric',
        coerce      => 0,   # you cannot coerce numeric
        lazy_build  => 1,
        writer      => '_set_numeric',
        trigger     => sub {
            $_[0]->clear_alpha2;
            $_[0]->clear_alpha3;
            $_[0]->clear_name;
        },
    );

    has 'name' => (
        is          => 'rw',
        isa         => CountryName,
        init_arg    => '_name',
        coerce      => 1,
        lazy_build  => 1,
        writer      => '_set_name',
        trigger     => sub {
            $_[0]->clear_alpha2;
            $_[0]->clear_alpha3;
            $_[0]->clear_numeric;
        },
    );

    sub BUILDARGS {
        my $class = shift;

        if (@_ == 1 && ! ref $_[0]) {
            if (is_integer($_[0])) {
                return { _numeric => $_[0] };
            }
            else {
                my $length = length $_[0];
                return {
                    (     $length == 2 ? '_alpha2'
                        : $length == 3 ? '_alpha3'
                        :                '_name'   ) => $_[0]
                };
            }
        }
        else {
            return $class->SUPER::BUILDARGS(@_);
        }
    }

    sub _build_alpha2 {
          $_[0]->has_alpha3
            ? country_code2code
                ( $_[0]->alpha3,  LOCALE_CODE_ALPHA_3, LOCALE_CODE_ALPHA_2 )
        : $_[0]->has_numeric
            ? country_code2code
                ( $_[0]->numeric, LOCALE_CODE_NUMERIC, LOCALE_CODE_ALPHA_2 )
        :
              country2code
                ( $_[0]->name,    LOCALE_CODE_ALPHA_2);
    }

    sub _build_alpha3 {
          $_[0]->has_alpha2
            ? country_code2code
                ( $_[0]->alpha2,  LOCALE_CODE_ALPHA_2, LOCALE_CODE_ALPHA_3 )
        : $_[0]->has_numeric
            ? country_code2code
                ( $_[0]->numeric, LOCALE_CODE_NUMERIC, LOCALE_CODE_ALPHA_3 )
        :
              country2code
                ( $_[0]->name,    LOCALE_CODE_ALPHA_3 );
    }

    sub _build_numeric {
          $_[0]->has_alpha2
            ? country_code2code
                ( $_[0]->alpha2,  LOCALE_CODE_ALPHA_2, LOCALE_CODE_NUMERIC )
        : $_[0]->has_alpha3
            ? country_code2code
                ( $_[0]->alpha3,  LOCALE_CODE_ALPHA_3, LOCALE_CODE_NUMERIC )
        :
              country2code
                ( $_[0]->name,    LOCALE_CODE_NUMERIC );
    }

    sub _build_name {
          $_[0]->has_alpha2
            ? code2country
                ( $_[0]->alpha2,  LOCALE_CODE_ALPHA_2 )
        : $_[0]->has_alpha3
            ? code2country
                ( $_[0]->alpha3,  LOCALE_CODE_ALPHA_3 )
        :
              code2country
                ( $_[0]->numeric, LOCALE_CODE_NUMERIC );
    }

    sub set {
        my ($self, $argument) = @_;

        confess ('Cannot set country because: argument is not defined')
            unless defined $argument;
        confess ('Cannot set country because: argument is not string')
            unless is_string($argument);

        if (is_integer($argument)) {
            $self->_set_numeric($argument);
        }
        else {
            my $length = length $argument;
              $length == 2 ? $self->_set_alpha2($argument)
            : $length == 3 ? $self->_set_alpha3($argument)
            :                $self->_set_name($argument);
        }

        return $self;
    }

    alias has_code    => 'has_alpha2';
    alias clear_code  => 'clear_alpha2';
    alias _build_code => '_build_alpha2';
    alias _set_code   => '_set_alpha2';

    __PACKAGE__->meta->make_immutable;
}

my $country = MyApp::Country->new('japan'); # (lower case)
say $country->code;                         # 'JP'
say $country->alpha2;                       # 'JP'
say $country->alpha3;                       # 'JPN'
say $country->numeric;                      # 392
say $country->name;                         # 'Japan' (canonical case)

$country->set('de');                        # (lower case)
say $country->alpha2;                       # 'DE' (canonical case)
say $country->name;                         # 'Germany'

$country->set('United States of America');  # (alias name)
say $country->alpha2;                       # 'US'
say $country->name;                         # 'United States' (canonical name)

eval {
    $country->set('Programming Republic of Perl');
};
if ($@) {
    say 'Specified country name does not exist';    # Regrettably, true
}
