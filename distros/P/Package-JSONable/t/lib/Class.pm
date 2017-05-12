package Class;

use Package::JSONable (
    string    => 'Str',
    integer   => 'Int',
    number    => 'Num',
    bool      => 'Bool',
    array     => 'ArrayRef',
    array_ref => 'ArrayRef',
    hash      => 'HashRef',
    hash_ref  => 'HashRef',
    null      => 'Str',
    custom    => sub {
        my ( $self, $val ) = @_;
        
        return $val . ' world';
    },
);

sub new {
    return bless {}, 'Class';
}

sub string {
    return 'hello';
}

sub custom {
    return 'hello';
}

sub integer {
    return 3;
}

sub number {
    return 3.1415;
}

sub bool {
    return;
}

sub array {
    return (1,2,3);
}

sub array_ref {
    return [1,2,3];
}

sub hash {
    return (
        one   => 1,
        two   => 2,
        three => 3,
    );
}

sub hash_ref {
    return {
        one   => 1,
        two   => 2,
        three => 3,
    };
}

sub null {
    return;
}

1;
