#line 1
package Test2::Hub::Interceptor;
use strict;
use warnings;

our $VERSION = '1.302073';


use Test2::Hub::Interceptor::Terminator();

BEGIN { require Test2::Hub; our @ISA = qw(Test2::Hub) }
use Test2::Util::HashBase;

sub inherit {
    my $self = shift;
    my ($from, %params) = @_;

    if ($from->{+IPC} && !$self->{+IPC} && !exists($params{ipc})) {
        my $ipc = $from->{+IPC};
        $self->{+IPC} = $ipc;
        $ipc->add_hub($self->{+HID});
    }
}

sub terminate {
    my $self = shift;
    my ($code) = @_;

    eval {
        no warnings 'exiting';
        last T2_SUBTEST_WRAPPER;
    };
    my $err = $@;

    # Fallback
    die bless(\$err, 'Test2::Hub::Interceptor::Terminator');
}

1;

__END__

#line 80
