package RackMan::Config;

use Config::IniFiles;
use File::Spec::Functions;
use Moose;
use RackMan;
use namespace::autoclean;


use constant {
    LOCAL_CONFIG_FILE   => "rack.local.conf",
};


my %defaults = (
    general => {
        default_scm => "none",
        ntp_servers => "0.0.0.0  0.0.0.0",
    },
);


has _config => (
    is => "ro",
    isa => "Config::IniFiles",
    handles => {
        exists  => "exists",
        setval  => "setval",
        newval  => "newval",
        delval  => "delval",
        ReadConfig      => "ReadConfig",
        WriteConfig     => "WriteConfig",
        RewriteConfig   => "RewriteConfig",
        GetFileName     => "GetFileName",
        SetFileName     => "SetFileName",
        Sections        => "Sections",
        SectionExists   => "SectionExists",
        AddSection      => "AddSection",
        DeleteSection   => "DeleteSection",
        Parameters      => "Parameters",
    },
);

has _local_config => (
    is => "rw",
    isa => "Config::IniFiles",
    clearer => "clear_local_config",
);

has _rackobject => (
    is => "rw",
    isa => "RackMan::Device",
    clearer => "clear_rackobject",
);


#
# BUILDARGS()
# ---------
sub BUILDARGS {
    my $class = shift;
    my %params;

    if (@_ % 2 == 0) {
        %params = @_;
    }
    elsif (ref $_[0] eq "HASH") {
        %params = %{$_[0]};
    }
    else {
        Rackman->error("invalid argument: ",
            lc ref $_[0], "ref instead of hashref");
    }

    RackMan->error("no such file '$params{'-file'}'")
        unless -f $params{"-file"};

    my $config = Config::IniFiles->new(%params)
        or RackMan->error("can't parse config file '$params{'-file'}': ",
        @Config::IniFiles::errors);

    RackMan->error("parameter [general]/path is missing")
        unless $config->val(general => "path");

    return { _config => $config }
}


#
# val()
# ---
sub val {
    my ($self, $section, $parameter, $default) = @_;
    my ($value, @values) = ("");

    # if no default is given, check if we have one
    $default = $defaults{$section}{$parameter}
        if not defined $default and exists $defaults{$section};

    # propagate context up to Config::IniFiles object
    if (wantarray) {
        @values = $self->_config->val($section, $parameter, $default);
    }
    else {
        $value  = $self->_config->val($section, $parameter, $default);
    }

    # check if there's a local config for this object to override
    # values from the global config
    if ($self->_local_config) {
        # propagate context up to Config::IniFiles object
        if (wantarray) {
            @values = $self->_local_config->val($section, $parameter, @values);
        }
        else {
            $value  = $self->_local_config->val($section, $parameter, $value);
        }
    }

    # post-process the values
    my $name = eval { $self->_rackobject->object_name } || "unknown";
    if (@values or defined $value) {
        s/%name%/$name/g for @values, $value;
    }

    return wantarray ? @values : $value
}


#
# set_current_rackobject()
# ----------------------
sub set_current_rackobject {
    my ($self, $rackobject) = @_;

    # associate the given RackObject to the config
    $self->_rackobject($rackobject);

    # see if there's a config specific to this device
    # (we assume that [general]/path contains a %name% paramter
    # that will now be correctly interpolated)
    my $path = $self->val(general => "path");
    my $local_cfg_path = catfile($path, LOCAL_CONFIG_FILE);
    return unless -f $local_cfg_path;

    # if that's the case, parse it and associate it to the config
    my $local_config = Config::IniFiles->new(-file => $local_cfg_path)
        or RackMan->error("can't parse config file '$local_cfg_path': ",
        @Config::IniFiles::errors);

    $self->_local_config($local_config);
}


#
# clear_current_rackobject()
# ------------------------
sub clear_current_rackobject {
    my ($self) = @_;
    $self->clear_rackobject;
    $self->clear_local_config;
}


__PACKAGE__->meta->make_immutable

__END__

=pod

=head1 NAME

RackMan::Config - Module to handle RackMan configuration

=head1 SYNOPSIS

    use RackMan::Config;


=head1 DESCRIPTION

This module mostly is a proxy to Config::IniFiles, with the added
feature that it can interpolate some parameters with values from
the current RackObject (as set with C<set_current_rackobject()>).
See L<"INTERPOLATED PARAMETERS"> for more details.


=head1 INTERPOLATED PARAMETERS

The configuration file can contain placeholders within the values,
interpolated upon C<val()> call with the corresponding values from
the current RackObject.

=over

=item %name%

name of the RackObject, or C<"unknown"> if it is undefined

=back


=head1 METHODS

Most of the methods from Config::IniFiles can be used on the object,
with the same arguments.

=head2 new

Create and return a new object. Accept the same parameters than
C<< Config::IniFile->new() >>


=head2 set_current_rackobject

Defines the current RackObject (a RackMan::Device instance), parses
and associates the corresponding F<rack.local.conf>, if any


=head2 clear_current_rackobject

Clear the current RackObject


=head1 SEE ALSO

L<Config::IniFiles>


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

