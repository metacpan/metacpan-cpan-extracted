package Net::Marathon::Deployment;

sub new {
    my ($class, $args, $parent) = @_;
    my $self = bless {
        applications => {},
        id           => $args->{id},
        parent       => $parent,
        steps        => [],
        version      => $args->{version},
    };
    foreach my $application ( @{$args->{affectedApplications}} ) {
        $self->applications->{$application} = $parent->get_app($application);
    }
    foreach my $step ( @{$args->{steps}} ) {
        # documentation has an odd format, each step being wrapped inside an array.
        # defensive:
        if ( ref $step eq 'HASH' ) {
            $step = [ $step ];
        }
        foreach ( @{$step} ) {
            push @{$self->{steps}}, Net::Marathon::Deployment::Step->new($_->{action}, $self->{applications}->{$_->{application}});
        }
    }
    return $self;
}

package Net::Marathon::Deployment::Step;

sub new {
    my ($class, $action, $application) = @_;
    my $self = bless {
        action      => $action,
        application => $application,
    };
    return $self;
}

sub action {
    my $self = shift;
    return $self->{action};
}

sub app {
    my $self = shift;
    return $self->application;
}

sub application {
    my $self = shift;
    return $self->{application};
}

1;
