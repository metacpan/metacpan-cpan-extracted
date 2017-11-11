use strict;
use warnings;
use lib 't/lib';
use File::Spec;
use Cwd 'abs_path';
use Test::More;
use ConfigCascade::Test::Data;
use ConfigCascade::Test::RW_Widget;
use ConfigCascade::Test::RO_Widget;
BEGIN { use_ok('MooseX::ConfigCascade::Util') };

my $test_data = ConfigCascade::Test::Data->new;
my $expected = $test_data->expected;

my $modify = {
    str => sub{ $_[0].' MODIFIED BY PROGRAM value' },
    hash => sub { return { $_[0].' MODIFIED BY PROGRAM key' => $_[0].' MODIFIED BY PROGRAM value' }},
    array => sub {[ $_[0].' MODIFIED BY PROGRAM value' ]},
    bool => sub{ return 0 },
    num => sub{ 
        return 1.3 if $_[0] =~ /no_default/;
        return 2.5 if $_[0] =~ /has_default/;
        return 3.7 if $_[0] =~ /has_builder/;
        return 4.9 if $_[0] =~ /lazy/;
    },
    int => sub{
        return 12 if $_[0] =~ /no_default/;
        return 14 if $_[0] =~ /has_default/;
        return 16 if $_[0] =~ /has_builder/;
        return 18 if $_[0] =~ /lazy/;
    }
};

my %base_conf = %{$expected->{conf}->('program')};

foreach my $rwo ( $test_data->rwo ){

    my $package = "ConfigCascade::Test::".uc($rwo)."_Widget";

    foreach my $type ( $test_data->types ){
        foreach my $create_mode ( $test_data->modes ){

            my %conf = %{$expected->{conf}->('program')};
            my $accessor = $type."_".$create_mode;
            my $modified_val = $modify->{$type}->( $accessor );
            $conf{$package}{$accessor} = $modified_val;
            

            MooseX::ConfigCascade::Util->conf( \%conf );
            my $widget = $package->new;

            foreach my $att ($widget->meta->get_all_attributes){

                my $att_name = $att->name;
                next if $att_name eq 'cascade_util';

                if ( $att_name eq $accessor ){
                    is_deeply( $widget->$att_name, $modified_val, "($rwo, $accessor modified) ->$att_name correctly loaded with modified value" );
                } else {
                    is_deeply( $widget->$att_name, $base_conf{$package}{$att_name}, "($rwo, $accessor modified) ->$att_name correctly loaded without being modified" );
                }
            }
        }
    }
}


done_testing();


