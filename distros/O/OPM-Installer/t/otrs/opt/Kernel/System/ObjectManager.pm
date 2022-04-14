package
   Kernel::System::ObjectManager;

sub new { return bless {}, shift };

sub Get {
    my ($self, $class) = @_;

    $self->{$class} //= $class->new;

    return $self->{$class};
}

package
    Kernel::System::Package;

sub new { return bless {}, shift }

sub PackageInstall { return 1 }


package
    Kernel::System::DB;

sub new { return bless {}, shift }

sub Prepare {
    my ($self, %param) = @_;
    my $name           = ${ $param{Bind}->[0] };

    $self->{requested} = $name;
    $self->{done}      = 0;

    return 1;
}

sub FetchrowArray {
    my ($self) = @_;

    my %returns = (
        TicketOverviewHooked => [ 'TicketOverviewHooked', '5.0.8' ],
    );

    return if $self->{done};

    my @return = @{ $returns{ $self->{requested} } || [] };
    $self->{done}++;

    return @return;
}

1;
