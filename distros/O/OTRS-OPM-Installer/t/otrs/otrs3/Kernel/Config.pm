package
   Kernel::Config;

sub new { return bless {}, shift };

package
    Kernel::System::Main;

sub new { my $cls = shift; return bless {@_}, $cls }

package
    Kernel::System::Encode;

sub new { my $cls = shift; return bless {@_}, $cls }

package
    Kernel::System::Log;

sub new { my $cls = shift; return bless {@_}, $cls }

package
    Kernel::System::Time;

sub new { my $cls = shift; return bless {@_}, $cls }

package
    Kernel::System::Package;

sub new { my $cls = shift; return bless {@_}, $cls }

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

package
    main;

use File::Basename;

my $dir = dirname __FILE__;

for my $class ( qw/Main Log Encode Time DB Package/ ) {
    $INC{'Kernel/System/'.$class.'.pm'} = __FILE__;
}

1;
