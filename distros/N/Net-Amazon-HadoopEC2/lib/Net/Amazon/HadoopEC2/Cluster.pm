package Net::Amazon::HadoopEC2::Cluster;
use Moose;
use Net::Amazon::EC2;
use Net::Amazon::HadoopEC2::SSH;
use MIME::Base64;
use Carp;

has name     => ( is => 'ro', isa => 'Str', required => 1 );
has _ec2      => ( 
    is => 'ro', 
    isa => 'Net::Amazon::EC2', 
    required => 1,
);
has key_file => ( is => 'rw', isa => 'Str', required => 1 );
has master_instance => ( is => 'rw', isa => 'Maybe[Net::Amazon::EC2::RunningInstances]');
has slave_instances => (
    is => 'rw', 
    isa => 'ArrayRef[Net::Amazon::EC2::RunningInstances]', 
    default => sub { [] }, 
);

has _ssh => (
    is => 'ro',
    isa => 'Net::Amazon::HadoopEC2::SSH',
    lazy => 1,
    default => sub {
        Net::Amazon::HadoopEC2::SSH->new(
            {
                host => $_[0]->master_instance->dns_name,
                key_file => $_[0]->key_file,
            }
        );
    },
    handles => qr(execute|push_files|get_files),
);

has retry => ( is => 'rw', isa => 'Int', required => 1, default => 1 );
has map_tasks => (is => 'rw', isa => 'Int', required => 1, default => 2 );
has reduce_tasks => (is => 'rw', isa => 'Int', required => 1, default => 2 );
has compress => (is => 'rw', isa => 'Str', required => 1, default => 'false' );
has user_data => (is => 'rw', isa => 'HashRef', auto_deref => 1 );

__PACKAGE__->meta->make_immutable;

no Moose;

sub launch_cluster {
    my ($self, $args) = @_;
    $self->_launch_master($args) or return;
    $self->launch_slave($args) or return;
    return $self;
}

sub find_cluster {
    my ($self) = @_;
    my $master_group = sprintf("%s-master", $self->name);
    my @res = @{$self->_ec2->describe_instances};
    my @master = $self->_wait_for_instances({name => $master_group}) or return;
    scalar @master == 1 or return;
    $self->master_instance($master[0]);
    $self->_find_slaves;
    return $self;
}

sub _find_slaves {
    my ($self) = @_;
    my @slaves = $self->_wait_for_instances({name => $self->name});
    $self->slave_instances([ @slaves ]);
}

sub _launch_master {
    my ($self, $args) = @_;
    my $master_group = sprintf("%s-master", $self->name);
    my $user_data = {
        MASTER_HOST => 'master',
        MAX_MAP_TASKS => $self->map_tasks,
        MAX_REDUCE_TASKS => $self->reduce_tasks,
        COMPRESS => $self->compress,
        $self->user_data,
    };
    my $user_data_str = join(',', map {join('=', $_, $user_data->{$_})} keys %{$user_data});
    my $result;
    $result = $self->_ec2->run_instances(
        ImageId => $args->{image_id},
        MinCount => 1,
        MaxCount => 1,
        KeyName => $args->{key_name},
        SecurityGroup => $master_group,
        UserData => encode_base64($user_data_str),
    );
    if (ref $result eq 'Net::Amazon::EC2::Errors') {
        croak $result->errors->[0]->message;
    }
    ref $result eq 'Net::Amazon::EC2::ReservationInfo' or return;
    my $master_id = $result->instances_set->[0]->instance_id;
    my ($master) = $self->_wait_for_instances({name => $master_group, instance_id => $master_id}) or return;
    $self->master_instance($master);
    $self->push_files(
        {
            files => [ $self->key_file ],
            destination => '/root/.ssh/id_rsa',
        }
    ) or return;
    $self->execute( { command => 'chmod 600 /root/.ssh/id_rsa' } )->code and return;
    return $self;
}

sub launch_slave {
    my ($self, $args) = @_;
    $self->master_instance or return;
    my $user_data = {
        MASTER_HOST => $self->master_instance->private_dns_name,
        MAX_MAP_TASKS => $self->map_tasks,
        MAX_REDUCE_TASKS => $self->reduce_tasks,
        COMPRESS => $self->compress,
        $self->user_data,
    };
    my $user_data_str = join(',', map {join('=', $_, $user_data->{$_})} keys %{$user_data});
    my $result = $self->_ec2->run_instances(
        ImageId => $self->master_instance->image_id,
        MinCount => 1,
        MaxCount => $args->{slaves} || 1,
        KeyName => $self->master_instance->key_name,
        SecurityGroup => $self->name,
        UserData => encode_base64($user_data_str),
    );
    if (ref $result eq 'Net::Amazon::EC2::Errors') {
        croak $result->errors->[0]->message;
    }
    ref $result eq 'Net::Amazon::EC2::ReservationInfo' or return;
    my @instances = map { $_->instance_id} @{$result->instances_set};
    $self->_wait_for_instances({name => $self->name, instance_id => [ @instances ]});
    $self->_find_slaves;
    return $self;
}

sub _wait_for_instances {
    my ($self, $args) = @_;
    my $name = $args->{name} or croak "name not specified";
    my $instances = $args->{instance_id} || [];
    $instances = [ $instances ] unless ref $instances;
    while (1) {
        my $result = $self->_ec2->describe_instances(
            InstanceId => $instances,
        );
        if (ref $result eq 'Net::Amazon::EC2::Errors') {
            croak $result->errors->[0]->message;
        }
        ref $result->[0] eq 'Net::Amazon::EC2::ReservationInfo' or return;
        my @found = map {@{$_->instances_set}} grep { grep {$_->group_id eq $name} @{$_->group_set}} @{$result};
        if (grep {$_->instance_state->code == 0} @found) {
            $self->retry or last;
            sleep 1;
        }
        @found = grep {$_->instance_state->code == 16} @found; 
        if (my $count_expect = scalar @{$instances}) {
            scalar @found == $count_expect or next;
        }
        return @found;
    }
}

sub terminate_cluster {
    my ($self) = @_;
    my @instances = map { $_->instance_id } ($self->master_instance, @{$self->slave_instances});
    my $result = $self->_ec2->terminate_instances(
        InstanceId => [ @instances ],
    );
    if (ref $result eq 'Net::Amazon::EC2::Errors') {
        croak $result->errors->[0]->message;
    }
    $self->master_instance(undef);
    $self->slave_instances( [] );
    return $result;
}

sub terminate_slaves {
    my ($self, $args) = @_;
    my $existing = scalar @{$self->slave_instances};
    my $count = $args->{slaves} || $existing;
    $count = $existing if $count > $existing;
    my @instances = map { $_->instance_id } @{$self->slave_instances}[ 0 .. $count - 1 ];
    my $result = $self->_ec2->terminate_instances(
        InstanceId => [ @instances ],
    );
    if (ref $result eq 'Net::Amazon::EC2::Errors') {
        croak $result->errors->[0]->message;
    }
    $self->_find_slaves;
    return $result;
}

1;
__END__

=pod

=head1 NAME

Net::Amazon::HadoopEC2::Cluster - Representation of Hadoop-EC2 cluster

=head1 SYNOPSIS

    my $hadoop = Net::Amazon::HadoopEC2->new(
        {
            aws_account_id => 'my account',
            aws_access_key_id => 'my key',
            aws_secret_access_key => 'my secret',
        }
    );
    my $cluster = $hadoop->launch_cluster(
        {
            naem => 'hadoop-ec2-cluster',
            image_id => 'ami-b0fe1ad9' # hadoop-ec2 official image
            slaves => 2,
            key_name => 'gsg-keypair',
            key_file => "$ENV{HOME}/.ssh/id_rsa-gsg-keypair',
        }
    );
    $cluster->push_file(
        {
            files => ['map.pl', 'reduce.pl'],
            destination => '/root/',
        }
    );
    my $option = join(' ', qw(
            -mapper map.pl
            -reducer reduce.pl
            -file map.pl
            -file reduce.pl
        )
    );
    my $result = $cluster->execute(
        {
            command => "$hadoop jar $streaming $option",
        }
    );


=head1 DESCRIPTION

A class Representing Hadoop-EC2 cluster

=head1 METHODS

=head2 new

Constructor. Normally L<Net::Amazon::HadoopEC2> calls this 
so you won't need to think about this.

=head2 launch_cluster ($hashref)

Launches hadoop-ec2 cluster. Returns L<Net::Amazon::HadoopEC2::Cluster> instance itself
when succeeded.

=over 4

=item image_id (required)

The image id (ami) of the cluster.

=item key_name (optional)

The key name to use when launching cluster. the default is 'gsg-keypair'.

=item key_file (required)

Location of the private key file associated with key_name.

=item slaves (optional)

The number of slaves. The default is 2.

=back

=head2 find_cluster

Finds hadoop-ec2 cluster. Returns L<Net::Hadoop::EC2::Cluster> instance itself if found.

=head2 launch_slave ($hashref)

Launches hadoop-ec2 slave instance for this cluster. Returns L<Net::Hadoop::EC2::Cluster> instance itself
if succeeded. Arguments are:

=over 4

=item slaves (optional)

The number of slaves to launch. default is 1.

=back

=head2 terminate_cluster

Terminates all EC2 instances of this cluster. Returns L<Net::Amazon::EC2::TerminateInstancesResponse>
instance.

=head2 terminate_slaves ($hashref)

Terminates hadoop-ec2 slave instances of this cluster. 
Returns L<Net::Amazon::EC2::TerminateInstancesResponse> instance.
Arguments are:

=over 4

=item slaves (optional)

The number of slave instances to terminate. the default is the number of exisiting instances.

=back

=head2 execute ($hashref)

Runs command on the master instance via ssh. Returns L<Net::Amazon::HadoopEC2::SSH::Response> instance.
This method is implemented in L<Net::Amazon::HadoopEC2::SSH> and it's only wrapper of L<Net::SSH::Perl>.
Arguments are:

=over 4

=item command (required)

The command line to pass.

=item stdin (optional)

String to pass to STDIN of the command.

=back

=head2 push_files ($hashref)

Pushes local files to hadoop-ec2 master instance via ssh. This method is also implemented in
L<Net::Amazon::HadoopEC2::SSH>. Returns true if succeeded. Arguments are:

=over 4

=item files (required)

files to push. Accepts string or arrayref of strings.

=item destination (required)

Destination of the files.

=back

=head2 get_files ($hashref)

Gets files on the hadoop-ec2 master instance. This method is implemented in 
L<Net::Amazon::HadoopEC2::SSH>. Returns true if succeeded. Arguments are:

=over 4

=item files (required)

files to get. String and arrayref of strings is ok.

=item destination (required)

local path to place the files.

=back

=head1 ATTRIBUTES

=head2 name

Name of the cluster.

=head2 key_file

The key name to use when launching cluster. the default is 'gsg-keypair'.

=head2 retry

Boolean whether EC2 api request retry or not. 

=head2 map_tasks

MAX_MAP_TASKS to pass to the instances when boot.

=head2 reduce_tasks

MAX_REDUCE_TASKS to pass to the instances when boot.

=head2 compress

COMPRESS to pass to the instances when boot.

=head2 user_data

additional user data to pass to the instances when boot.

=head2 master_instance

L<Net::Amazon::EC2::RunningInstances> instance of master instance.

=head2 slave_instances

Arrayref of L<Net::Amazon::EC2::RunningInstances> instance of master instance.

=head1 AUTHOR

Nobuo Danjou L<nobuo.danjou@gmail.com>

=head1 SEE ALSO

L<Net::Amazon::HadoopEC2>

=cut
