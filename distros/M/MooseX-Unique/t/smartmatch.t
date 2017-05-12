{
    package MyApp::Thing;
    use Moose;
    use Scalar::Util qw(blessed);

    use overload qw{~~} => 'smartmatch';

    has 'x' => ( is => 'rw', isa => 'Int' );
    has 'y' => ( is => 'rw', isa => 'Str' );

    sub smartmatch {
        my ($self,$match) = @_;
        my $vars = {};
        if ((blessed $match) && ($match->isa(ref($self)))) {
            $vars->{x} = $match->x;
            $vars->{y} = $match->y;
        }
        elsif (ref($match) eq 'HASH') {
            $vars = $match;
        }
        elsif (ref($match) eq 'ARRAY') {
            $vars->{x} = $match->[0];
            $vars->{y} = $match->[1];
        }
        else {
            $vars = $self->from_str($match);
        }
        return (($self->x == $vars->{x}) && ($self->y eq $vars->{y}));
    }

    sub from_str {
        my ($class, $string) = @_;
        return {
             x => length($string), 
             y => $string,
        };
    }
       
    {
        use Moose::Util::TypeConstraints;

        my $class = __PACKAGE__;

        class_type 'Thing' => { class => $class };

        coerce 'Thing', 
            from 'Str',
            via  { $class->new($class->from_str($_)) }
    }
}
{
    package MyApp;
    use Moose;
    use MooseX::Unique;

    has identity => (
        is  => 'ro',
        isa => 'Thing',
        required => 1,
        unique => 1,
        coerce => 1,
    );

    has number =>  ( 
        is => 'rw',
        isa => 'Int'
    );

}

require 't/main.pl';

cmp_ok ($objecta, '~~', $objectc, "Smartmatch Test") ;
cmp_ok ($objectc, '~~', $objecta, "Smartmatch Test 2"); 



done_testing();
