package Salvation::TC::Type::SessionId;

# $Id: SessionId.pm 6868 2014-06-03 10:59:59Z trojn $

use strict;
use warnings;

use base 'Salvation::TC::Type';

use Salvation::TC::Exception::WrongType ();

my $re = qr/^[A-Za-z0-9]{32}$/;

sub Check {

    my ( $class, $session_id ) = @_;

    ( defined( $session_id ) && $session_id =~ $re ) ||
        Salvation::TC::Exception::WrongType -> throw( 'type' => 'SessionId', 'value' => $session_id, '-text' => 'Wrong type for "session_id".' );
}

1;
__END__
