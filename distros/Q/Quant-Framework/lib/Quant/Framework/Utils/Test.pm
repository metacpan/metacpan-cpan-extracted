package Quant::Framework::Utils::Test;

=head1 NAME

Quant::Framework::Utils::Test

=head1 DESCRIPTION

This module is used when testing Quant::Framework modules to create new documents.
A set of pre-defined templates are provided which can be used to create test documents.
Also it is possible to change some/all of the test document by passing corresponding 
key/values to create_doc.

=head1 SYNOPSIS

  use Quant::Framework::Utils::Test;

  #using default values from test data file
  Quant::Framework::Utils::Test::create_doc("corporate_actions");

  #changing some of values in the test data file
  Quant::Framework::Utils::Test::create_doc("corporate_actions",
    {   symbol              => 'ABCD',
        chronicle_reader    => $reader,
        chronicle_writer    => $writer,
        actions             => {
            "62799500" => {
                "monitor_date" => "2014-02-07T06:00:07Z",
                "type" => "ACQUIS",
                "monitor" => 1,
                "description" =>  "Acquisition",
                "effective_date" =>  "15-Jul-14",
                "flag" => "N"
            },
        }
    });

=cut

use 5.010;
use strict;
use warnings;

use File::ShareDir ();
use YAML::XS qw(LoadFile);
use Quant::Framework::CorporateAction;
use Data::Chronicle::Writer;
use Data::Chronicle::Reader;
use Data::Chronicle::Mock;
use Quant::Framework::InterestRate;
use Quant::Framework::Currency;
use Quant::Framework::Asset;
use Quant::Framework::VolSurface::Delta;
use Quant::Framework::VolSurface::Moneyness;
use Quant::Framework::Utils::UnderlyingConfig;

=head2 create_doc

    Create a new document in the test database

    params:
    $yaml_db        => The name of the entity in the YAML file (eg. promo_code)
    $data_mod       => hasref of modifictions required to the data (optional)

=cut

sub create_doc {
    my ($yaml_db, $data_mod) = @_;

    my $save = 1;
    if (exists $data_mod->{save}) {
        $save = delete $data_mod->{save};
    }

    # get data to insert
    my $fixture = LoadFile(File::ShareDir::dist_file('Quant-Framework', 'test_data.yml'));

    my $data = $fixture->{$yaml_db}{data};

    die "Invalid yaml db name: $yaml_db" if not defined $data;

    # modify data?
    for (keys %$data_mod) {
        $data->{$_} = $data_mod->{$_};
    }

    # use class to create the document
    my $class_name = $fixture->{$yaml_db}{class_name};
    my $obj        = $class_name->new($data);

    if ($save) {
        $obj->save;
    }

    return $obj;
}

=head2 create_underlying_config

Creates an instance of UnderlyingConfig (for EURUSD or GDAXI) for tesing purposes.

=cut

sub create_underlying_config {
    my $symbol            = shift;
    my $custom_attributes = shift;

    my $fixture = LoadFile(File::ShareDir::dist_file('Quant-Framework', 'test_underlying_config.yml'));
    my $data = $fixture->{$symbol};

    if (defined $custom_attributes) {
        while (my ($key, $value) = each %$custom_attributes) {
            $data->{$key} = $value;
        }
    }

    if (not exists $data->{spot_db_args}) {
        $data->{spot_db_args} = +{
            underlying => $symbol,
            db_handle  => undef,
        };
    }

    return Quant::Framework::Utils::UnderlyingConfig->new($data);
}

1;
