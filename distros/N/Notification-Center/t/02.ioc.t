#!perl

use Test::More tests => 3;

{

    package Person;
    use Moose;

    has fname => ( is => 'rw', isa => 'Str' );
    has lname => ( is => 'rw', isa => 'Str' );
    has notification =>
      ( is => 'ro', isa => 'Notification::Center', required => 1 );

    sub print_name {
        my ($self) = @_;

        my $ns = $self->notification;
        $ns->notify( { event => 'print', args => $self } );
    }

    no Moose;

    package PrintName;
    use Moose;

    has notification =>
      ( is => 'ro', isa => 'Notification::Center', required => 1 );

    sub BUILD {
        my ( $self, $args ) = @_;
        my $ns = $self->notification;
        $ns->add(
            {
                observer => $self,
                event    => 'print',
                method   => 'display',
            }
        );
    }

    sub display {
        my ( $self, $person ) = @_;
        my $name = sprintf "%s, %s", $person->lname, $person->fname;
        Test::More::is( $name, 'Wall, Larry', 'Displaying the name' );
    }

    no Moose;

    package UCPrintName;
    use Moose;

    has notification =>
      ( is => 'ro', isa => 'Notification::Center', required => 1 );

    sub BUILD {
        my ( $self, $args ) = @_;
        my $ns = $self->notification;
        $ns->add(
            {
                observer => $self,
                method   => 'display',
            }
        );
    }

    sub display {
        my ( $self, $person ) = @_;
        my $name = sprintf "%s, %s", $person->lname, $person->fname;
        $name = uc $name;
        Test::More::is( $name, 'WALL, LARRY', 'Displaying the name' );
    }

    no Moose;
}

use Bread::Board;

my $c = container 'TestApp' => as {

    service 'fname' => 'Larry';
    service 'lname' => 'Wall';

    service 'notification_center' => (
        class     => 'Notification::Center',
        lifecycle => 'Singleton',
    );

    service 'person' => (
        class        => 'Person',
        dependencies => {
            notification => depends_on('notification_center'),
            fname        => depends_on('fname'),
            lname        => depends_on('lname'),
        },
    );

    service 'upn' => (
        class        => 'UCPrintName',
        dependencies => { notification => depends_on('notification_center') },
    );

    service 'pn' => (
        class        => 'PrintName',
        dependencies => { notification => depends_on('notification_center'), },
    );
};

my $pn     = $c->fetch('pn')->get;
my $upn    = $c->fetch('upn')->get;
my $person = $c->fetch('person')->get;
my $nc     = $c->fetch('notification_center')->get;

$person->print_name;
$nc->remove( { observer => $upn } );
$person->print_name;
