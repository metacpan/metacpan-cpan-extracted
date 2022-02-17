#!/usr/bin/perl

use 5.020;
use warnings;

use FindBin;
use File::Slurp;
use JSON::MaybeXS;

# Data sources: https://github.com/annexare/Countries/tree/master/data
# https://raw.githubusercontent.com/annexare/Countries/master/data/continents.json
# https://raw.githubusercontent.com/annexare/Countries/master/data/countries.json

my $continent_data = load_json('continents.json');
my $country_data   = load_json('countries.json');
my $description    = {
    generated_by => $FindBin::Script,
    sources      => {
        '_repository' => 'https://github.com/annexare/Countries',
        'continents.json' => 'master/data/continents.json',
        'countries.json' => 'master/data/countries.json',
    },
};

my %continent;
my %country;
my %currency;
my %city;

for my $country_record (values %$country_data) {
    my ($country_name, $continent_code, $capital_name, $currencies) =
        @{$country_record}{qw( name continent capital currency )};

    my $continent_name = $continent_data->{$continent_code};

    my $continent_record = $continent{$continent_name} //= {
        name => $continent_name,
        countries => [],
    };

    push @{$continent_record->{countries}}, $country_name;

    $capital_name ||= $country_name;

    $country{$country_name} = {
        name => $country_name,
        continent => $continent_name,
        cities => [ $capital_name ],
        currency => $currencies,
    };

    for my $currency ( @{$currencies} ) {
        my $curr_record = $currency{$currency} //= {
            name => $currency,
            country => [],
        };
        push @{$curr_record->{country}}, $country_name;
    }

    my $city_record = $city{$capital_name} //= {
        name => $capital_name,
        countries => [],
    };
    push @{$city_record->{countries}}, $country_name;
    
}

my $data = {
    _description => $description,
    continents   => \%continent,
    countries    => \%country,
    cities       => \%city,
    currencies   => \%currency,
};

print JSON::MaybeXS->new(utf8 => 1, pretty => 1, canonical => 1)->encode($data);

sub load_json {
    my ($fname) = @_;
    my $text = read_file($fname);

    state $js_obj = JSON::MaybeXS->new(utf8 => 1);
    return $js_obj->decode($text);
}
