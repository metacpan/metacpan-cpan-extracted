use strict; use warnings;
{
    package MyApp::RoleB;
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

    required_matches(0);
    unique ('secret_identity');

}
{
    package MyApp::Role;
    use Moose::Role;
    use MooseX::Unique;

    has identity => (
        is  => 'ro',
        isa => 'Str',
        required => 1,
    );

    required_matches(1);
    unique ('identity');
}
{
    package MyApp;
    use Moose;
    use MooseX::Unique;

    with qw(MyApp::RoleB MyApp::Role);
}

require 't/multi.pl';



done_testing();
