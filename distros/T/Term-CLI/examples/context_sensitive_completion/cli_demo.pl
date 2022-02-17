#!/usr/bin/env perl

use 5.014_001;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../../lib");

use open qw( :std :utf8 );
use File::Slurp;
use JSON::MaybeXS;

use Term::CLI;

sub Main {
    my $term = setup_term();

    while ( defined( my $cmd_line = $term->readline ) ) {
        $term->execute($cmd_line);
    }
    print "\n";
    execute_exit( 'exit', 0 );
}

sub load_json {
    my ($fname) = @_;
    my $text = read_file($fname);

    state $js_obj = JSON::MaybeXS->new( utf8 => 1 );
    return $js_obj->decode($text);
}

sub execute_exit {
    my ( $cmd, @args ) = @_;
    my $excode = $args[0] // 0;
    say "-- exit: $excode";
    exit $excode;
}

sub setup_term {
    my @commands;

    my $country_data = load_json('./data/data.json');

    my $term = Term::CLI->new(
        name          => 'csc',
        prompt        => 'csc> ',
        skip          => qr/^\s*(?:#.*)?$/,
        history_lines => 100,
    );

    push @commands, Term::CLI::Command->new(
        name        => 'show',
        usage       => 'B<show> I<continent> [I<country> [I<city>]]',
        summary     => 'show information about a location',
        description => 'Show information about a region, country, or city.',
        arguments   => [
            Term::CLI::Argument::Continent->new(
                name         => 'continent',
                country_data => $country_data,
            ),
            Term::CLI::Argument::Country->new(
                name         => 'country',
                country_data => $country_data,
                min_occur    => 0,
            ),
            Term::CLI::Argument::City->new(
                name         => 'city',
                country_data => $country_data,
                min_occur    => 0,
            ),
        ],
        callback => sub {
            my ( $cmd, %args ) = @_;
            return %args if $args{status} < 0;
            my ( $continent, $country, $city ) = @{ $args{arguments} };
            if ($city) {
                show_city( $city, $country_data );
                return %args;
            }
            if ($country) {
                show_country( $country, $country_data );
                return %args;
            }
            show_continent( $continent, $country_data );
            return %args;
        }
    );

    push @commands, Term::CLI::Command->new(
        name      => 'exit',
        arguments => [
            Term::CLI::Argument::Number::Int->new(
                name      => 'code',
                min_occur => 0,
                min       => 0,
                inclusive => 1
            ),
        ],
        callback => sub {
            my ( $cmd, %args ) = @_;
            return %args if $args{status} < 0;
            execute_exit( $cmd->name, @{ $args{arguments} } );
            return %args;
        }
    );

    push @commands, Term::CLI::Command::Help->new();

    $term->add_command(@commands);
    return $term;
}

sub show_city {
    my ( $city, $country_data ) = @_;
    my $city_record = $country_data->{cities}->{$city};
    print JSON::MaybeXS->new( pretty => 1, canonical => 1 )
        ->encode($city_record);
}

sub show_country {
    my ( $country, $country_data ) = @_;
    my $country_record = $country_data->{countries}->{$country};
    print JSON::MaybeXS->new( pretty => 1, canonical => 1 )
        ->encode($country_record);
}

sub show_continent {
    my ( $continent, $country_data ) = @_;
    my $continent_record = $country_data->{continents}->{$continent};
    print JSON::MaybeXS->new( pretty => 1, canonical => 1 )
        ->encode($continent_record);
}

package Term::CLI::Argument::Continent {
    use Moo;
    extends 'Term::CLI::Argument::Enum';
    has country_data => ( is => 'ro', required => 1 );
    around BUILDARGS => sub {
        my ( $orig, $class, @args ) = @_;
        return $class->$orig(@args) if @args % 2;
        my %args         = @args;
        my $country_data = $args{country_data} // {};
        return $class->$orig( @args,
            value_list => [ sort keys %{ $country_data->{continents} } ], );
    };
}

package Term::CLI::Argument::Country {
    use Moo;

    use namespace::clean;

    extends 'Term::CLI::Argument::Enum';

    has country_data => ( is => 'ro', required => 1 );

    around BUILDARGS => sub {
        my ( $orig, $class, @args ) = @_;
        return $class->$orig(@args) if @args % 2;
        my %args         = @args;
        my $country_data = $args{country_data} // {};
        return $class->$orig( @args,
            value_list => [ sort keys %{ $country_data->{countries} } ], );
    };

    sub complete {
        my ( $self, $text, $state ) = @_;
        my $continent = $state->{processed}->[-1];
        my $values = $self->country_data->{continents}{$continent}{countries};
        return ( sort @{$values} ) if !length $text;
        return ( sort grep { substr( $_, 0, length $text ) eq $text }
                @{$values} );
    }

    sub validate {
        my ( $self, $text, $state ) = @_;

        my $country_record = $self->country_data->{countries}->{$text};

        return $self->set_error("not a valid country name")
            if !$country_record;

        my $continent = $state->{arguments}->[-1];

        return $self->set_error("not a valid country name in $continent")
            if $country_record->{continent} ne $continent;

        return $text;
    }
}

package Term::CLI::Argument::City {
    use Moo;
    use List::Util qw( first );

    use namespace::clean;

    extends 'Term::CLI::Argument::Enum';

    has country_data => ( is => 'ro', required => 1 );

    around BUILDARGS => sub {
        my ( $orig, $class, @args ) = @_;
        return $class->$orig(@args) if @args % 2;
        my %args         = @args;
        my $country_data = $args{country_data} // {};
        return $class->$orig( @args,
            value_list => [ sort keys %{ $country_data->{cities} } ], );
    };

    sub complete {
        my ( $self, $text, $state ) = @_;
        my $country = $state->{processed}->[-1];
        my $values  = $self->country_data->{countries}{$country}{cities};
        return ( sort @{$values} ) if !length $text;
        return ( sort grep { substr( $_, 0, length $text ) eq $text }
                @{$values} );
    }

    sub validate {
        my ( $self, $text, $state ) = @_;

        my $city_record = $self->country_data->{cities}->{$text};

        return $self->set_error("not a valid city name")
            if !$city_record;

        my $country = $state->{arguments}->[-1];

        if ( !first { $_ eq $country } @{ $city_record->{countries} } ) {
            return $self->set_error("not a valid city name in $country");
        }

        return $text;
    }
}

Main;
