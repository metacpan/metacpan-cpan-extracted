#line 1
package Test2::Util::Trace;
use strict;
use warnings;

our $VERSION = '1.302073';


use Test2::Util qw/get_tid pkg_to_file/;

use Carp qw/confess/;

use Test2::Util::HashBase qw{frame detail pid tid};

sub init {
    confess "The 'frame' attribute is required"
        unless $_[0]->{+FRAME};

    $_[0]->{+PID} = $$        unless defined $_[0]->{+PID};
    $_[0]->{+TID} = get_tid() unless defined $_[0]->{+TID};
}

sub snapshot { bless {%{$_[0]}}, __PACKAGE__ };

sub debug {
    my $self = shift;
    return $self->{+DETAIL} if $self->{+DETAIL};
    my ($pkg, $file, $line) = $self->call;
    return "at $file line $line";
}

sub alert {
    my $self = shift;
    my ($msg) = @_;
    warn $msg . ' ' . $self->debug . ".\n";
}

sub throw {
    my $self = shift;
    my ($msg) = @_;
    die $msg . ' ' . $self->debug . ".\n";
}

sub call { @{$_[0]->{+FRAME}} }

sub package { $_[0]->{+FRAME}->[0] }
sub file    { $_[0]->{+FRAME}->[1] }
sub line    { $_[0]->{+FRAME}->[2] }
sub subname { $_[0]->{+FRAME}->[3] }

sub from_json {
    my $class = shift;
	my %p     = @_;

    my $trace_pkg = delete $p{__PACKAGE__};
	require(pkg_to_file($trace_pkg));

    return $trace_pkg->new(%p);
}

sub TO_JSON {
    my $self = shift;
    return {%$self, __PACKAGE__ => ref $self};
}

1;

__END__

#line 186
