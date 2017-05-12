use strict; use warnings;
{
    package MyApp::RoleA;
    use Moose::Role;
    use MooseX::Unique;

    has secret_identity => (
        is  => 'ro',
        isa => 'Str',
        required => 1,
    );

    has number =>  ( 
        is => 'rw',
        isa => 'Int'
    );

    required_matches(1);
    unique ('secret_identity');

}
{
    package MyApp::RoleB;
    use Moose::Role;
    use MooseX::Unique;

    has identity => (
        is  => 'ro',
        isa => 'Str',
        required => 1,
        unique => 1,
    );

    required_matches(1);
}
{
    package MyApp::RoleC;
    use Moose::Role;
    with 'MyApp::RoleA', 'MyApp::RoleB';

    no Moose::Role;
}
{
    package MyApp;
    use Moose;
    with 'MyApp::RoleC';
    
    __PACKAGE__->meta->make_immutable();
    no Moose;
}


require 't/multi.pl';

done_testing();
