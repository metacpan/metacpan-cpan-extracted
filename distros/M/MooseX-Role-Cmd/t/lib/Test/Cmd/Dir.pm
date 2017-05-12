package Test::Cmd::Dir;

use Moose;

with 'MooseX::Role::Cmd';

has 'b'         => ( isa => 'Bool', is => 'rw' );
has 'bool'      => ( isa => 'Bool', is => 'rw' );
has 'v'         => ( isa => 'Str',  is => 'rw' );
has 'value'     => ( isa => 'Str',  is => 'rw' );
has 's'         => ( isa => 'Str',  is => 'rw' );
has 'short'     => ( isa => 'Str',  is => 'rw' );
has 'r'         => ( isa => 'Bool', is => 'rw' );
has 'rename'    => ( isa => 'Bool', is => 'rw' );
has 'u'         => ( isa => 'Bool', is => 'rw' );
has 'undef'     => ( isa => 'Bool', is => 'rw' );
has 'undef_str' => ( isa => 'Str',  is => 'rw' );

has '_internal' => ( isa => 'Str', is => 'ro', lazy_build => 1 );

sub _build__internal {
    die "This builder should not be seen";
}

1;
