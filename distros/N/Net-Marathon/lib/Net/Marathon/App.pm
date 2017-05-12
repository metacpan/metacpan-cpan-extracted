package Net::Marathon::App;

use strict;
use warnings;
use parent 'Net::Marathon::Remote';

our @rw_values = qw(
 id
 labels
 dependencies
 healthchecks
 requirePorts
 cpus
 backoffSeconds
 upgradeStrategy
 ports
 constraints
 cmd
 args
 env
 container
 executor
 mem
 maxLaunchDelaySeconds
 backoffFactor
 instances
);

sub new {
    my ($class, $conf, $parent) = @_;
    my $self = bless {};
    $conf = {} unless $conf && ref $conf eq 'HASH';
    $self->{data} = $conf;
    $self->{parent} = $parent;
    return $self;
}

sub create {
    my $self = shift;
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_post('/v2/apps', $self->get_updateable_values);
}

sub update {
    my ($self, $args) = @_;
    my $param = $args && $args->{force} && $args->{force} && $args->{force} !~ /false/i ? '?force=true' : ''; #default is false
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_put('/v2/apps/' . $self->id . $param, $self->get_updateable_values);
}

sub delete {
    my $self = shift;
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_delete('/v2/apps/' . $self->id);
}

sub restart {
    my $self = shift;
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_post('/v2/apps/' . $self->id . '/restart' );
}

sub versions {
    my ( $self, $extra ) = @_;
    if ( defined $extra ) {
        return $self->get_version( $extra );
    }
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_get_obj('/v2/apps/' . $self->id . '/versions' );
}

sub get_version {
    my ( $self, $version ) = @_;
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_get_obj('/v2/apps/' . $self->id . '/versions/' . $version );
}

sub kill_tasks {
    my ( $self, $args ) = @_;
    my %real_args = map {
        $_ =~ m,^host|scale$, ?
            ( $_ => $args->{$_} ) : print(STDERR "Extraoneous value `$_' to kill_tasks will be ignored\n") && ()
    } keys %{$args};
    return $self->{parent}->_delete('/v2/apps/' . $self->id . '/tasks', \%real_args);
}

sub kill_task {
    my ( $self, $task_id, $scale ) = @_;
    return $self->{parent}->_delete('/v2/apps/' . $self->id . '/tasks/' . $task_id, {scale => $scale});
}

sub get_updateable_values {
    my $self = shift;
    my %kv = map { $self->{data}->{$_} ? ( $_ => $self->{data}->{$_} ) : () } @Net::Marathon::App::rw_values;
    return \%kv;
}

sub labels {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{labels} = $val;
    }
    return $self->{data}->{labels};
}

sub healthChecks {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{healthChecks} = $val;
    }
    return $self->{data}->{healthChecks};
}

sub requirePorts {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{requirePorts} = $val;
    }
    return $self->{data}->{requirePorts};
}

sub cpus {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{cpus} = $val;
    }
    return $self->{data}->{cpus};
}

sub backoffSeconds {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{backoffSeconds} = $val;
    }
    return $self->{data}->{backoffSeconds};
}

sub upgradeStrategy {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{upgradeStrategy} = $val;
    }
    return $self->{data}->{upgradeStrategy};
}

sub ports {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{ports} = $val;
    }
    return $self->{data}->{ports};
}

sub constraints {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{constraints} = $val;
    }
    return $self->{data}->{constraints};
}

sub cmd {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{cmd} = $val;
    }
    return $self->{data}->{cmd};
}

sub args {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{args} = $val;
    }
    return $self->{data}->{args};
}

sub executor {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{executor} = $val;
    }
    return $self->{data}->{executor};
}

sub container {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{container} = $val;
    }
    return $self->{data}->{container};
}

sub env {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{env} = $val;
    }
    return $self->{data}->{env};
}

sub maxLaunchDelaySeconds {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{maxLaunchDelaySeconds} = $val;
    }
    return $self->{data}->{maxLaunchDelaySeconds};
}

sub backoffFactor {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{backoffFactor} = $val;
    }
    return $self->{data}->{backoffFactor};
}

sub mem {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{mem} = $val;
    }
    return $self->{data}->{mem};
}

sub instances {
    my ($self, $val) = @_;
    if ( $val ) {
        $self->{data}->{instances} = $val;
    }
    return $self->{data}->{instances};
}

sub tasksUnhealthy {
    my $self = shift;
    return $self->{data}->{tasksUnhealthy};
}

sub tasksStaged {
    my $self = shift;
    return $self->{data}->{tasksStaged};
}

sub deployments {
    my $self = shift;
    return $self->{data}->{deployments};
}

sub tasks {
    my $self = shift;
    return $self->{data}->{tasks};
}

sub uris {
    my $self = shift;
    return $self->{data}->{uris};
}

sub user {
    my $self = shift;
    return $self->{data}->{user};
}

sub storeUrls {
    my $self = shift;
    return $self->{data}->{storeUrls};
}

sub disk {
    my $self = shift;
    return $self->{data}->{disk};
}

sub tasksHealthy {
    my $self = shift;
    return $self->{data}->{tasksHealthy};
}

sub tasksRunning {
    my $self = shift;
    return $self->{data}->{tasksRunning};
}

sub acceptedResourceRoles {
    my $self = shift;
    return $self->{data}->{acceptedResourceRoles};
}

sub lastTaskFailure {
    my $self = shift;
    return $self->{data}->{lastTaskFailure};
}

return 1;
