# -*- perl -*-

# t/10_plugin_mutexgroup.t - Test MutexGroup

use Test::Most tests => 1+1;
use Test::NoWarnings;

use lib 't/testlib';
use Test07;

subtest 'MutexGroup' => sub {
    plan tests => 7;

    {
       my $test01 = Test07->new_with_options( UseAmmonia => 1, UseChlorine => 1 );
       isa_ok( $test01, 'MooseX::App::Message::Envelope' );

       my @errors = grep { $_->type eq 'error' } @{ $test01->blocks };
       is( scalar @errors, 1, 'only returned a single error' );
       is( $errors[0]->header,
           'Options UseAmmonia and UseChlorine are mutally exclusive',
           'generated an error when more than one option in the same mutexgroup is initialized'
       );
    }

    {
       my $test02 = Test07->new_with_options();
       isa_ok( $test02, 'MooseX::App::Message::Envelope' );

       my @errors = grep { $_->type eq 'error' } @{ $test02->blocks };
       is( scalar @errors, 1, 'only returned a single error' );
       is( $errors[0]->header,
           'Either UseAmmonia or UseChlorine must be specified',
           'generated an error when no options in the same mutexgroup are initialized'
       );
    }

    {
       my $test03 = Test07->new_with_options( UseAmmonia => 1 );
       ok( $test03->isa('Test07'),
           'generated no errors when only a single option from the same mutexgroup is initialized'
       );
    }
};
