package Net::Journyx::Object::Loadable;

use MooseX::Role::Parameterized;
parameter 'drop_on' => (
    isa       => 'ArrayRef[Str]',
    default   => sub {[]},
);
parameter 'check_on' => (
    isa       => 'ArrayRef[Str]',
    default   => sub {[]},
);

has is_loaded => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    writer  => '_is_loaded',
);

requires 'load';
before load => sub { $_[0]->_is_loaded(0) };

role {
    my $p = shift;

    my %both;
    $both{$_}++ foreach @{ $p->drop_on };
    $both{$_}++ foreach @{ $p->check_on };
    delete $both{$_} foreach grep $both{$_} != 2, keys %both;

    foreach my $m ( grep !exists $both{$_}, @{ $p->drop_on } ) {
        before $m => sub { $_[0]->_is_loaded(0) }
    }
    foreach my $m ( grep !exists $both{$_}, @{ $p->check_on } ) {
        before $m => sub {
            die "$m is not allowed on not loaded objects"
                unless $_[0]->is_loaded;
        }
    }
    foreach my $m ( keys %both ) {
        before $m => sub {
            die "$m is not allowed on not loaded objects"
                unless $_[0]->is_loaded;
            $_[0]->_is_loaded(0);
        }
    }

};

no MooseX::Role::Parameterized;
1;
