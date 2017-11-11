use strict;
use warnings;
use lib 't/lib';
use Test::More;
use ConfigCascade::Test::Data;
use ConfigCascade::Test::RW_Widget;
use ConfigCascade::Test::RO_Widget;
BEGIN { use_ok('MooseX::ConfigCascade::Util') };
use Try::Tiny;


my $test_data = ConfigCascade::Test::Data->new;


my %t = (
    string => "test string",
    object => ConfigCascade::Test::Data->new,
    hashref => { "test hashref key" => "test hashref value"},
    coderef => sub{ return "test coderef" },
    arrayref => [ 'test arrayref' ],
);
    

my $wrong = {
    str => [ $t{hashref}, $t{arrayref}, $t{object}, $t{coderef} ],
    hash => [ $t{string}, $t{object}, $t{coderef}, $t{arrayref} ],
    array => [ $t{string}, $t{object}, $t{coderef}, $t{hashref} ],
    bool => [ $t{string}, $t{object}, $t{coderef}, $t{hashref}, $t{arrayref} ],
    num => [ $t{string}, $t{object}, $t{coderef}, $t{hashref}, $t{arrayref} ],
    int => [ $t{string}, $t{object}, $t{coderef}, $t{hashref}, $t{arrayref} ]
};


my %conf = %{$test_data->expected->{conf}->('error test script')};


foreach my $rwo ( $test_data->rwo ){

    my $package = "ConfigCascade::Test::".uc($rwo)."_Widget";

    foreach my $type ( $test_data->types ){
        foreach my $create_mode ( $test_data->modes ){
            my $accessor = $type."_".$create_mode;

            foreach my $wrong_type (@{$wrong->{$type}}){
                my %conf = %{$test_data->expected->{conf}->('error test script')};
                $conf{$package}{$accessor} = $wrong_type;
                
                MooseX::ConfigCascade::Util->conf( \%conf );

                my $error;
                try {
                    my $widget = $package->new;
                } 
                catch {
                    $error = $_;
                };

                ok( defined $error, "($rwo) attempt to set ->$accessor to ($wrong_type) caused Moose error as expected");

                my ($msg_part) = $error =~ /^([^\n]+)/;

                my $error_correct = 0;
                if (    $msg_part =~ /validation failed/i
                    &&  $msg_part =~ /type constraint/i
                    &&  $msg_part =~ /$accessor/ ){
                    
                    $error_correct = 1;

                }

                ok( $error_correct, "($rwo) error caused by setting ->$accessor to ($wrong_type) looks correct" );

            }
        }
    }
}

done_testing();
