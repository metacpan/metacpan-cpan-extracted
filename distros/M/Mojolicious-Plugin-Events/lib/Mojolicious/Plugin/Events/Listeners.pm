package Mojolicious::Plugin::Events::Listeners;
use Mojo::Base -base;

use Mojo::Loader qw(find_modules load_class);
use Mojo::Server;

has app => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') };
has namespaces => sub { [] };

=head2 startup

Start listeners

=cut

sub startup {
    my ($self, $dispatcher) = @_;

    my @namespaces = @{ $self->namespaces };
    push(@namespaces, 'Mojolicious::Plugin::Events::Listeners');

    for my $namespace (@namespaces) {
        for my $module (find_modules($namespace)) {
            my $loaded = _listener($module, 1);

            if (!$loaded) {
                warn "Could not load $module";
                
                next;
            }

            # Initialize listener
            my $listener = $loaded->new(app => $self->app);
            Scalar::Util::weaken $listener->{ app };
            
            $dispatcher->on($listener->event => sub {
                my $self = shift;
                
                return $listener->handle(@_);
            });
        }
    }
}

=head2 _listener

Load listener

=cut

sub _listener {
    my ($module, $fatal) = @_;

    return $module->isa('Mojolicious::Plugin::Events::Listener') ? $module : undef
        unless my $e = load_class $module;
    $fatal && ref $e ? die $e : return undef;
}

1;
