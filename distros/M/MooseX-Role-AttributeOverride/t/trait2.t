use strict;
use warnings;

{

    package MyApp::Meta::Attribute;
    use Moose::Role;

    around _process_options => sub {
        my ( $orig, $class, $name, $options ) = @_;
        $options->{default} = sub { return 'yep' };
        return $orig->( $class, $name, $options );
    };

    around clone => sub {
        my $orig  = shift;
        my $clone = $orig->(@_);
        $clone->{default} = sub { return 'yep' };    # Blah
    };

}
{

    package MyApp::RoleA;
    use Moose::Role;
    use MooseX::Role::AttributeOverride;

    has_plus 'fun' => ( traits => ['MyApp::Meta::Attribute'] );

    no Moose::Role;

}
{

    package MyApp::RoleB;
    use Moose::Role;
    with qw(MyApp::RoleA);
    no Moose::Role;

}
{

    package MyApp;
    use Moose;

    has 'fun' => (
        is  => 'rw',
        isa => 'Str'
    );

    with qw(MyApp::RoleB);

    __PACKAGE__->meta->make_immutable;
    no Moose;

}
{

    package main;
    use Test::More tests => 3;    # last test to print

    my $test = MyApp->new();
    my $attr = $test->meta->find_attribute_by_name('fun');
    ok( $attr->has_applied_traits, 'Traits get applied' );
    my @good =
        grep { $_ eq 'MyApp::Meta::Attribute' } @{ $attr->applied_traits };
    ok( scalar @good, 'My traits get applied to ' . ref($test) );
    is( $test->fun, 'yep', "Default was set by role" );

}
