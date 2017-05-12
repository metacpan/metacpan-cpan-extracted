package QBit::Cron::Methods;
$QBit::Cron::Methods::VERSION = '0.004';
use qbit;

use base qw(QBit::Application::Part);

sub _register_method {
    my ($package, $sub, $time) = @_;

    my $pkg_stash = package_stash($package);
    $pkg_stash->{'__CRON__'} = [] unless exists($pkg_stash->{'__CRON__'});

    push(
        @{$pkg_stash->{'__CRON__'}},
        {
            sub     => $sub,
            package => $package,
            time    => $time,
        }
    );
}

sub _set_method_attr {
    my ($package, $sub, $name, $value) = @_;

    my $pkg_stash = package_stash($package);
    $pkg_stash->{'__CRON_ATTRS__'} = {} unless exists($pkg_stash->{'__CRON_ATTRS__'});

    $pkg_stash->{'__CRON_ATTRS__'}{$package, $sub}{$name} = $value;
}

sub MODIFY_CODE_ATTRIBUTES {
    my ($package, $sub, @attrs) = @_;

    my @unknown_attrs = ();

    foreach my $attr (@attrs) {
        if ($attr =~ /^CRON\s*\(\s*'\s*([\d \/*,-]+)\s*'\s*\)$/) {
            $package->_register_method($sub, $1);
        } elsif ($attr =~ /^LOCK(?:\s*\(\s*'\s*([\w\d_]+)\s*'\s*\))?$/) {
            $package->_set_method_attr($sub, lock => $1);
        } elsif ($attr =~ /^SILENT$/) {
            $package->_set_method_attr($sub, silent => TRUE);
        } else {
            push(@unknown_attrs, $attr);
        }
    }

    return @unknown_attrs;
}

sub import {
    my ($package, %opts) = @_;

    $package->SUPER::import(%opts);

    $opts{'path'} ||= '';

    my $app_pkg = caller();
    die gettext('Use only in QBit::Cron and QBit::Application descendant')
      unless $app_pkg->isa('QBit::Cron')
          && $app_pkg->isa('QBit::Application');

    my $pkg_stash = package_stash($package);

    my $app_pkg_stash = package_stash($app_pkg);
    $app_pkg_stash->{'__CRON__'} = {}
      unless exists($app_pkg_stash->{'__CRON__'});

    my $pkg_sym_table = package_sym_table($package);

    foreach my $method (@{$pkg_stash->{'__CRON__'} || []}) {
        my ($name) =
          grep {
                !ref($pkg_sym_table->{$_})
              && defined(&{$pkg_sym_table->{$_}})
              && $method->{'sub'} == \&{$pkg_sym_table->{$_}}
          } keys %$pkg_sym_table;

        $method->{'attrs'} = $pkg_stash->{'__CRON_ATTRS__'}{$method->{'package'}, $method->{'sub'}} || {};

        throw gettext("Cron method \"%s\" is exists in package \"%s\"",
            $name, $app_pkg_stash->{'__CRON__'}{$opts{'path'}}{$name}{'package'})
          if exists($app_pkg_stash->{'__CRON__'}{$opts{'path'}}{$name});
        $app_pkg_stash->{'__CRON__'}{$opts{'path'}}{$name} = $method;
    }

    {
        no strict 'refs';
        foreach my $method (qw(get_option)) {
            *{"${package}::${method}"} = sub {shift->app->$method(@_)};
        }
    }
}

TRUE;
