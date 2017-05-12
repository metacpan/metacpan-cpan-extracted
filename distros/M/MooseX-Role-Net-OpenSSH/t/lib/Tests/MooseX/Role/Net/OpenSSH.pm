{

    package Tests::MooseX::Role::Net::OpenSSH::DummyThing;
    use Moose;
    use Data::Dumper;
    with 'MooseX::Role::Net::OpenSSH';

    sub _build_ssh_hostname { "localhost" }
    sub _build_ssh_username { "tcampbell" }

    sub _build_ssh_options {
        my $self = shift;
        return {
            user        => $self->ssh_username,
            timeout     => 10,
            batch_mode  => 1,
            master_opts => [
                # -o => 'ControlMaster no',
                # -o => 'ControlPersist no',
                -o => 'CheckHostIP no',
                -o => 'StrictHostKeyChecking no',
                -o => 'UserKnownHostsFile=/dev/null',
                -o => 'LogLevel=quiet',
            ],
        };
    }

    sub get_uptime {
        my $self    = shift;
        my @command = qw/ id /;
        my @output  = $self->ssh->capture( { stderr_to_stdout => 1, }, @command );
        chomp @output;
        warn Data::Dumper->Dump( [ \@output ], [ 'output' ] );
        return \@output;
    }
}

package Tests::MooseX::Role::Net::OpenSSH;
use Test::Class::Most parent => 'Tests::MooseX::Role::Net::OpenSSH::Base';
use strict;
use warnings;
use Test::MockObject::Extends;
use Data::Dumper;

sub setup : Tests(setup) {
    my $self = shift;
    $self->SUPER::setup;
}

sub basic_test : Tests {
    my $self = shift;

    my $thing = Tests::MooseX::Role::Net::OpenSSH::DummyThing->new;

    ok $thing->can( '_build_ssh' ), 'can _build_ssh';
    ok $thing->can( 'ssh' ), 'can ssh';

    #warn Dumper $thing;
    #$thing->get_uptime;

}

1;
