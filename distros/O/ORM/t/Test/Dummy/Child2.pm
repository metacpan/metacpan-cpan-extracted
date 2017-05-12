package Test::Dummy::Child2;

$VERSION=0.1;

use ORM::Base 'Test::Dummy';

sub new
{
    my $class = shift;
    my %arg   = @_;
    my $error = ORM::Error->new;
    my $ta    = Test::ORM->new_transaction( error=>$error );
    my $self;

    unless( $error->fatal )
    {
        $self = $class->SUPER::new( @_ );
    }

    if( $self && $self->a eq 'bad value' )
    {
        $error->add_fatal( "Bad 'a' value" );
        $self = undef;
    }

    $arg{error} && $arg{error}->add( error=>$error );
    return $self;
}
