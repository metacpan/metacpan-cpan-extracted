{
    package MyApp::Role;
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
    package MyApp;
    use Moose;
    with 'MyApp::Role';
    __PACKAGE__->meta->make_immutable();
}

require 't/main.pl';

done_testing();
