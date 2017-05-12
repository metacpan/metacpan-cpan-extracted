package Net::Amazon::HadoopEC2::Group;
use Moose;

has _ec2 => (
    is => 'ro',
    isa => 'Net::Amazon::EC2',
    required => 1,
);

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has _master_name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->name . '-master';
    }
);

has _groups => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1,
    lazy => 1,
    auto_deref => 1,
    default => sub {
        my $self = shift;
        return [ $self->name, $self->_master_name ]
    }
);

has aws_account_id => ( is => 'ro', isa => 'Str', required => 1 );
has web_ports => ( is => 'rw', isa => 'Int', required => 1, default => 1 );

no Moose;

sub ensure {
    my ($self) = @_;
    unless ($self->find) {
        return $self->create;
    }
    return 1;
}

sub find {
    my ($self) = @_;
    my $g = $self->_ec2->describe_security_groups(
        GroupName => [ $self->_groups ],
    );
    if (ref $g eq 'Net::Amazon::EC2::Errors') {
        $g->errors->[0]->code eq 'InvalidGroup.NotFound' or die $g->errors->[0]->message;
        return;
    } else {
        scalar @{$g} == 2 or die $self->name . " doesn't seem to be Hadoop cluster.";
        return 1;
    }
}

sub create {
    my ($self) = @_;
    for my $target ( $self->_groups ) {
        my $desc = 'Group for Hadoop ' . ($target =~ m{master} ? 'Master' : 'Slaves') . '.';
        $self->_ec2->create_security_group(
            GroupName => $target,
            GroupDescription => $desc,
        ) == 1 or return;
    }
    my $success = 0;
    my $result;
    for my $target ( $self->_groups ) {
        my ($peer_target) = grep {$_ ne $target} $self->_groups;
        $result = $self->_ec2->authorize_security_group_ingress(
            GroupName => $target,
            IpProtocol => 'tcp',
            FromPort => 22,
            ToPort => 22,
            CidrIp => '0.0.0.0/0',
        );
        $result == 1 or last;
        $result = $self->_ec2->authorize_security_group_ingress(
            GroupName => $target,
            SourceSecurityGroupName => $peer_target,
            SourceSecurityGroupOwnerId => $self->aws_account_id,
        );
        $result == 1 or last;
        $result = $self->_ec2->authorize_security_group_ingress(
            GroupName => $target,
            SourceSecurityGroupName => $target,
            SourceSecurityGroupOwnerId => $self->aws_account_id,
        );
        $result == 1 or last;
        if ( $self->web_ports ) {
            $result = $self->_ec2->authorize_security_group_ingress(
                GroupName => $target,
                IpProtocol => 'tcp',
                FromPort => 50030,
                ToPort => 50030,
                CidrIp => '0.0.0.0/0',
            );
            $result == 1 or last;
            $result = $self->_ec2->authorize_security_group_ingress(
                GroupName => $target,
                IpProtocol => 'tcp',
                FromPort => 50060,
                ToPort => 50060,
                CidrIp => '0.0.0.0/0',
            );
            $result == 1 or last;
        }
        $success++;
    }
    return $success == 2;
}

sub remove {
    my ($self) = @_;
    my $success = 0;
    my $result;
    for my $target ( $self->_groups ) {
        my ($peer_target) = grep {$_ ne $target} $self->_groups;
        $result = $self->_ec2->revoke_security_group_ingress(
            GroupName => $target,
            SourceSecurityGroupName => $peer_target,
            SourceSecurityGroupOwnerId => $self->aws_account_id,
        );
        $result == 1 or last;
        $success++;
    }
    $success == 2 or return;
    for my $target ( $self->_groups ) {
        $result = $self->_ec2->delete_security_group(
            GroupName => $target,
        );
        $result == 1 or last;
        $success++;
    }
    return $success == 4;
}

1;
__END__

=pod

=head1 NAME

Net::Amazon::HadoopEC2::Group - A class to manipulate EC2 security group for hadoop-ec2.

=head1 SYNOPSIS

  # instanciate
  my $group = Net::Amazon::HadoopEC2::Group->new(
    {
        aws_account_id => 'your id',
        name => 'hadoop-ec2-test',
    }
  );

  # creates the security group
  $group->create unless $group->find;
  # this is equivalent to below:
  $group->ensure;

  # removes the security group
  $group->remove;

=head1 DESCRIPTION

A class to manipulate EC2 security group for hadoop-ec2.

=head1 METHODS

=head2 new ($hashref)

Constructor. The Arguments are:

=over 4 

=item name (required)

Name of the hadoop-ec2 group name.

=item aws_account_id (required)

Your aws account id.

=item web_ports (optional)

Specify 1 to enable web_ports. The default is 1.

=back

=head2 ensure

Ensures there are suitable EC2 security groups to run the Hadoop-EC2 cluster. 
Returns true if it's ok.

=head2 find

Finds suitable EC2 security groups to run the Hadoop-EC2 cluster.
Returns true if it's ok.

=head2 create

Creates two EC2 security groups to run the Hadoop-EC2 cluster;
one is for slaves, the ather is for master.
Returns true if the creation succeeded.

=head2 remove

Removes EC2 security groups.
Returns true if the process succeeded.

=head1 AUTHOR

Nobuo Danjou <nobuo.danjou@gmail.com>

=head1 SEE ALSO

L<Net::Amazon::HadoopEC2>

L<Net::Amazon::EC2>

=cut
