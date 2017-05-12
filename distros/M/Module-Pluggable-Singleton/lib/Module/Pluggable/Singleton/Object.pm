package Module::Pluggable::Singleton::Object;
{
  $Module::Pluggable::Singleton::Object::VERSION = '0.06';
}
{
  $Module::Pluggable::Singleton::Object::DIST = 'Module-Pluggable-Singleton';
}

use parent 'Module::Pluggable::Object';
use Carp qw/croak confess/;
use Data::Dump q/pp/;

=head1 NAME

Module::Pluggable::Singleton::Object

=head1 VERSION

version 0.06

=head1 METHODS

=head2 new

=cut
 
sub new {
    my $class = shift;
    my %opts  = @_;
 
    $opts{require} = 1;
    my $obj = Module::Pluggable::Object->new(%opts);

    my $self = bless $obj, $class;
    $self->_parse_plugins($opts{package} || $class);

    return $self;
}


sub _parse_plugins {
    my($self,$caller) = @_;

    if (!$self->{search_path}) {
        $self->{search_path} = "${caller}::Plugin";
    }
    if ($self->{search_path}) {
        if (ref($self->{search_path}) eq '') {
            $self->{search_path} = [$self->{search_path}];
        }
    }

    warn "SEARCH_PATH: ". pp($self->{search_path})
        if ($self->{debug});


    my $namespace  = "${caller}::". ucfirst($self->{sub_name} || 'plugins');
    my $sub_name = $self->{sub_name} || 'plugins';
    my $plugin_for = { }; # maps shortname to module name
    my $instance_of = { }; # instances


    foreach my $plugin ($self->plugins) {
        my $shortname = $plugin;

        foreach my $path (@{$self->{search_path}}) {
            $shortname =~ s/^${path}:://;
        }

# FIXME:
#        if (not $plugin->isa($base_class)) {
#            confess __PACKAGE__ .": plugin '$shortname' needs to implement "
#                ."'". $base_class ."'";
#        }

        if (exists $plugin_for->{$shortname}) {
            confess "$caller: Plugin already exists for '$shortname'";
        }

        $plugin_for->{$shortname} = $plugin;
    }

    $self->{plugin_for} = $plugin_for;
}

=head2 find

=cut

sub find {
    my($self,$shortname) = @_;

    if (!defined $shortname) {
        die "Not provided name of plugin";
        return;
    }

    my $name = $self->{plugin_for}->{$shortname} || undef;
    if (!defined $name) {
        die "Not possible to load module '$shortname'";
    }


    # use an existing instance or create a new one.. and keep ref to it
    my $instance_of = $self->{instance_of} // { };
    my $instance = $instance_of->{$shortname}
        || (defined $name ? $name->new() : undef);

    if ($instance && not defined $instance_of->{$shortname}) {
        $instance_of->{$shortname} = $instance;
    }

    # if we didn't already the hash ref created
    $self->{instance_of} = $instance_of if (!defined $self->{instance_of});

    return $instance;
}

=head2 plugin

=cut

sub plugin {
    my($self,$shortname) = @_;
    my $plugin_for = $self->{plugin_for};

    return keys %{$plugin_for} if (!defined $shortname);

    return defined $plugin_for->{$shortname}
        ? $plugin_for->{$shortname} : undef;

}

=head2 call

=cut

sub call {
    my($self,$shortname,$method) = @_;

    if (!defined $shortname) {
        die "$caller: Plugin name not provided";
        return;
    }

    if (!defined $method) {
        die "Method name not provided";
        return;
    }


    my $instance = $self->find($shortname);
    if (!$instance->can($method)) {
        die "Cannot call '$method' on '$shortname' plugin";
    }

    return $instance->$method(@_);

}

1;
