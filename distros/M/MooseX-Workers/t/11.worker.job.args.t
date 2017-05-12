use Test::More tests => 2;
use lib qw(lib);

# Testing command + args

{

    package Manager;
    use Moose;
    with qw(MooseX::Workers);

    sub worker_stdout {
        my ( $self, $output ) = @_;

        ::is( $output, 7, 'STDOUT' );
    }

    sub worker_started { ::pass('worker started') }
    
    sub run { 
        my $job = MooseX::Workers::Job->new(
           command => 'echo',
           args    => [ 7 ],
           name    => 'Foo',
        );
        $_[0]->spawn( $job );
        POE::Kernel->run();
    }
    __PACKAGE__->meta->make_immutable;
    no Moose;
}

Manager->new()->run();
