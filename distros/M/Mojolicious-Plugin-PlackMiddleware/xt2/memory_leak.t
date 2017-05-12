use strict;
use warnings;
use Test::Memory::Cycle;
use Test::More;
use Test::Mojo;
use Data::Dumper;
use Test::More tests => 4;

{
    package SomeApp;
    use strict;
    use warnings;
    use base 'Mojolicious';
    
    sub startup {
        my $self = shift;
        $self->plugin(plack_middleware => []);
        my $r = $self->routes;
        $r->route('/test')->to(cb => sub{
            my $c = shift;
            $c->render(text => 'Hello world');
        });
    }
}

my $app = SomeApp->new;
memory_cycle_ok( $app );

my $t = Test::Mojo->new($app);
$t->get_ok('/test');
is $t->tx->res->body, 'Hello world', 'right body';
memory_cycle_ok( $app );

__END__
