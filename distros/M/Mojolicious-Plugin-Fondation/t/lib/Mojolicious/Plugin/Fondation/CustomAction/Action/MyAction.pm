package Mojolicious::Plugin::Fondation::CustomAction::Action::MyAction;
use Mojo::Base 'Mojolicious::Plugin::Fondation::Action::Base', -signatures;

sub after_load ($self, $long_name, $conf, $share_dir) {
    my $manager = $self->manager;
    $manager->{_my_action_calls} //= [];
    push @{$manager->{_my_action_calls}}, {
        long_name => $long_name,
        conf_keys => [ sort keys %$conf ],
    };
    $self->log->debug("MyAction executed for $long_name");
}

1;
