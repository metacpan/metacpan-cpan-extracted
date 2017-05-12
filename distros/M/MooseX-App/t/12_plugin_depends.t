# -*- perl -*-

# t/12_plugin_depends.t - Test Depends

use Test::Most tests => 1+1;
use Test::NoWarnings;

use lib 't/testlib';
use Test08;

subtest 'Depends' => sub {
    plan tests => 8;

    {
        my $test01 = Test08->new_with_options( WriteToFile => 1 );
        isa_ok( $test01, 'MooseX::App::Message::Envelope' );

        my @errors = grep { $_->type eq 'error' } @{ $test01->blocks };
        is( scalar @errors, 1, 'only returned a single error' );
        is( $errors[0]->header,
            'Option \'WriteToFile\' requires \'FileFormat\' to be defined',
            'generated an error when an option dependency was not present'
        );
    }

    {
        my $test02 = Test08->new_with_options( ReadFromFile => 1 );
        isa_ok( $test02, 'MooseX::App::Message::Envelope' );

        my @errors = grep { $_->type eq 'error' } @{ $test02->blocks };
        is( scalar @errors, 1, 'only returned a single error' );
        is( $errors[0]->header,
            'Option \'ReadFromFile\' requires \'FileFormat\' to be defined',
            'generated an error when an option dependency was not present'
        );
    }

    {
        my $test03 = Test08->new_with_options( WriteToFile => 1, FileFormat => 'tsv' );
        ok( ! $test03->can('blocks'),
            'generated no errors when both an option and its dependencies are defined'
        );
    }

    {
        my $test04 = Test08->new_with_options( ReadFromFile => 1, FileFormat => 'tsv' );
        ok( ! $test04->can('blocks'),
            'generated no errors when both an option and its dependencies are defined'
        );
    }
};
