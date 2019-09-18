package Eventer;

use Test::More;

use Fcntl;
use File::Temp ();

sub new {
    my ($class) = @_;

    my $tempdir = File::Temp::tempdir( CLEANUP => 1 );

    my $self = bless { _tempdir => $tempdir }, $class;
}

sub wait_until {
    my ($self, $evt) = @_;

    Time::HiRes::sleep(0.01) while !$self->has_happened($evt);

    return;
}

sub has_happened {
    my ($self, $evt) = @_;

    return -e "$self->{'_tempdir'}/event_$evt";
}

sub happen {
    my ($self, $evt) = @_;

    # diag "EVENT HAPPENING: $evt";

    sysopen my $fh, "$self->{'_tempdir'}/event_$evt", Fcntl::O_WRONLY | Fcntl::O_CREAT | Fcntl::O_EXCL;

    return;
}

1;
