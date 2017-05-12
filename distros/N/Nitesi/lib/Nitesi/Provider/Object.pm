package Nitesi::Provider::Object;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(api_object);

use Nitesi::Class;

=head2 api_object

Creates an API object.

=cut

sub api_object {
    my (%args) = @_;
    my ($api_class, $api_object, $settings_class, $backend, $sname, $provider,
        $provider_settings, $o_settings, $backend_settings, @roles,
        $settings, @settings_args);

    $backend = $args{backend};
    $backend_settings = $args{backend_settings} || {};
    $api_class = $args{class};
    $settings = $args{settings};

    if (exists $args{name}) {
        $sname = ucfirst($args{name});

        # check whether base class for this object is overridden in the settings
        if (exists $settings->{$sname}->{class}) {
            $api_class = $settings->{$sname}->{class};
        }
    }

    # create API object
    my (%api_info, $o_key);

    $api_object = Nitesi::Class->instantiate($api_class,
					     api_class => $api_class,
					     api_name => $args{name},
                         );

    # add API attributes after instantiation
    $api_object->api_attributes($settings->{$sname}->{attributes});

    unless ($api_object) {
        die "Failed to create class $api_class: $@";
    }

    $api_info{$api_class} = $api_object->api_info;
    $o_key = $api_info{$api_class}->{key};

    # load roles for this API object
    for my $role_name (@{$args{roles} || []}) {
        Nitesi::Class->load($role_name);
        my $api_func = lc($role_name);
        $api_func =~ s/^(.*)::([^:]+)$/$2/;
        $api_func .= '_api_info';
        $api_info{$role_name} = $role_name->$api_func;
        push (@roles, $role_name);
    }

    my ($key, $value);

    # load backend class
    if ($backend) {
        my $backend_class = "Nitesi::Backend::$backend";
        Nitesi::Class->load($backend_class);

        # apply backend role to navigation object

        Moo::Role->apply_roles_to_object($api_object, @roles, $backend_class);

        while (($key, $value) = each %$backend_settings) {
            $api_object->$key($value);
        }
    }

    if ($settings->{$sname}->{field_map}) {
        $api_object->field_map($settings->{$sname}->{field_map});
    }

    $api_object->api_info(\%api_info);

    if ($args{$o_key}) {
        $api_object->$o_key($args{$o_key});
    }

    if ($args{record}) {
        while (($key, $value) = each %{$args{record}}) {
            $api_object->$key($value);
        }
    }

    return $api_object;
}

1;
