package P4::Server::Test::Server::Helper::FailedSystem;

use base qw( P4::Server );

use Class::Std;

{

my %retval_of : ATTR( init_arg => 'retval' );

sub _system {
    my $self = shift;

    return $retval_of{ident $self};
}

}

1;
