package QBit::Application::Model;
$QBit::Application::Model::VERSION = '0.014';
use qbit;

use base qw(QBit::Application::Part);

sub get_option {
    my ($self, $name, $default) = @_;

    $self->{'__OPTIONS__'} = {%{$self->app->{'__OPTIONS__'}}, %{$self->app->get_option($self->{'accessor'}, {})}};

    my $res = QBit::Application::get_option($self, $name, $default);

    delete($self->{'__OPTIONS__'});

    return $res;
}

sub set_option {
    my ($self, $name, $value) = @_;

    $self->app->set_option($self->{'accessor'}, {%{$self->app->get_option($self->{'accessor'}, {})}, $name => $value});
}

sub timelog {
    shift->app->timelog;
}

sub import {
    my ($package, %opts) = @_;

    $package->SUPER::import(%opts);

    throw gettext('Required accessor') unless $opts{'accessor'};

    my $app_pkg;
    my $i = 0;
    while ($app_pkg = caller($i++)) {
        last if $app_pkg->isa('QBit::Application');
    }
    throw gettext('Use only in QBit::Application descendant')
      unless $app_pkg && $app_pkg->isa('QBit::Application');

    my $app_pkg_stash = package_stash($app_pkg);
    $app_pkg_stash->{'__MODELS__'} = {}
      unless exists($app_pkg_stash->{'__MODELS__'});

    throw gettext("Model with accessor \"%s\" is exists (class: \"%s\")", $opts{'accessor'}, $package)
      if exists($app_pkg_stash->{'__MODELS__'}{$opts{'accessor'}});

    throw gettext("Accessor cannot have name \"%s\", it is name of method", $opts{'accessor'})
      if $app_pkg->can($opts{'accessor'});

    $app_pkg_stash->{'__MODELS__'}{$opts{'accessor'}} = $package;

    {
        no strict 'refs';
        *{"${app_pkg}::$opts{'accessor'}"} = sub {
            my $self = shift;

            $self->{$opts{'accessor'}} = $package->new(app => $self, accessor => $opts{'accessor'})
              unless exists($self->{$opts{'accessor'}});
            return $self->{$opts{'accessor'}};
        };
    };
}

TRUE;
