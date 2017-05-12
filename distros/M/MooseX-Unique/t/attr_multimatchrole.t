use strict; use warnings;
{
    package MyApp::Role;
    use Moose::Role;
    use MooseX::Unique;

    has secret_identity => (
        is  => 'ro',
        isa => 'Str',
        required => 1,
        unique => 1,
    );

    has number =>  ( 
        is => 'rw',
        isa => 'Int'
    );

    required_matches(1);

}
{
    package MyApp;
    use Moose;
    use MooseX::Unique;

    has identity => (
        is  => 'ro',
        isa => 'Str',
        required => 1,
        unique => 1,
    );



    required_matches(1);

    with 'MyApp::Role';
}


require 't/multi.pl';

done_testing();
