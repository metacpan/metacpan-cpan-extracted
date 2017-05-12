{
    package MyApp::RoleA;
    use Moose::Role;
    use MooseX::Unique;

    has identity => (
        is  => 'ro',
        isa => 'Str',
        required => 1,
    );

    has number =>  ( 
        is => 'rw',
        isa => 'Int'
    );

    unique 'identity';
    no Moose::Role;
    1;

}

{
    package MyApp::RoleB;
    use Moose::Role;
    with 'MyApp::RoleA';
    no Moose::Role;
    1;
}

{
    package MyApp;
    use Moose;
    with 'MyApp::RoleB';
    __PACKAGE__->meta->make_immutable();
}

require 't/main.pl';


done_testing();
