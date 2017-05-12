{
    package MyApp::Role;
    use Moose::Role;
    use MooseX::Unique;


    requires 'identity';
    unique 'identity';

    no Moose::Role;
    1;

}

{
    package MyApp;
    use Moose;

    has identity => (
        is  => 'ro',
        isa => 'Str',
        required => 1,
    );

    has number =>  ( 
        is => 'rw',
        isa => 'Int'
    );

    with 'MyApp::Role';

    __PACKAGE__->meta->make_immutable();
}

require 't/main.pl';

done_testing();
