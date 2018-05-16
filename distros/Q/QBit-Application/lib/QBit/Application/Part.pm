package QBit::Application::Part;
$QBit::Application::Part::VERSION = '0.017';
use qbit;

use base qw(QBit::Class);

__PACKAGE__->mk_accessors(qw(app));

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    throw gettext('Required opt "app" must be QBit::Application descendant')
      unless $self->{'app'} && $self->{'app'}->isa('QBit::Application');

    weaken($self->{'app'});
}

sub model_accessors {
    my ($class, %accessors) = @_;

    my $pkg_stash = package_stash($class);

    no strict 'refs';
    while (my ($acc_name, $acc_class) = each(%accessors)) {
        my $accessor_from_app = $pkg_stash->{'__MODEL_ACCESSORS__'}{$acc_name} || $acc_name;

        *{"${class}::${acc_name}"} = sub {
            $_[0]->{'__ACCESSORS__'}{$acc_name} //= do {
                my $model = $_[0]->app->$accessor_from_app;

                throw gettext(
'Class "%s" expects application accessor "%s" used through model accessor "%s" to be "%s" descendant but got %s',
                    $class,
                    $accessor_from_app,
                    $acc_name,
                    $acc_class,
                    ref($model)
                  )
                  unless ref($model) && $model->isa($acc_class);

                weaken($model);

                return $model;
            };
        };
    }
}

sub register_rights {
    my ($class, $data) = @_;

    my $pkg_stash = package_stash($class);

    $pkg_stash->{'__RIGHT_GROUPS__'} = {} unless exists($pkg_stash->{'__RIGHT_GROUPS__'});
    $pkg_stash->{'__RIGHTS__'}       = {} unless exists($pkg_stash->{'__RIGHTS__'});

    foreach my $group (@$data) {
        $group->{'name'} = '__UNDEFINED__' unless exists($group->{'name'});
        $pkg_stash->{'__RIGHT_GROUPS__'}{$group->{'name'}} = $group->{'description'} if exists($group->{'description'});

        while (my ($right, $right_name) = each(%{$group->{'rights'}})) {
            $pkg_stash->{'__RIGHTS__'}{$right} = {name => $right_name, group => $group->{'name'}};
        }
    }
}

sub import {
    my ($package, %opts) = @_;

    my $pkg_stash = package_stash($package);

    $pkg_stash->{'__MODEL_ACCESSORS__'} = $opts{'models'} || {};

    my $app_pkg = $opts{'app_pkg'};
    unless ($app_pkg) {
        my $i = 1;
        while ($app_pkg = caller($i++)) {
            last if $app_pkg->isa('QBit::Application');
        }
    }

    throw gettext('Use only in QBit::Application descendant')
      unless $app_pkg && $app_pkg->isa('QBit::Application');

    my $app_pkg_stash = package_stash($app_pkg);

    my $rights = {};
    package_merge_isa_data(
        $package, $rights,
        sub {
            my ($ipackage, $res) = @_;

            my $ipkg_stash = package_stash($ipackage);
            $res->{'__RIGHTS__'} = {%{$res->{'__RIGHTS__'} || {}}, %{$ipkg_stash->{'__RIGHTS__'} || {}}};
            $res->{'__RIGHT_GROUPS__'} =
              {%{$res->{'__RIGHT_GROUPS__'} || {}}, %{$ipkg_stash->{'__RIGHT_GROUPS__'} || {}}};
        },
        __PACKAGE__
    );

    $app_pkg_stash->{'__RIGHT_GROUPS__'} =
      {%{$app_pkg_stash->{'__RIGHT_GROUPS__'} || {}}, %{$rights->{'__RIGHT_GROUPS__'} || {}}};

    $app_pkg_stash->{'__RIGHTS__'} = {%{$app_pkg_stash->{'__RIGHTS__'} || {}}, %{$rights->{'__RIGHTS__'} || {}}};

    {
        no strict 'refs';
        foreach my $method (qw(check_rights cur_user)) {
            *{"${package}::${method}"} = sub {shift->app->$method(@_)};
        }
    }
}

TRUE;
