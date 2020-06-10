#line 1
package Test2::EventFacet::Trace;
use strict;
use warnings;

our $VERSION = '1.302175';

BEGIN { require Test2::EventFacet; our @ISA = qw(Test2::EventFacet) }

use Test2::Util qw/get_tid pkg_to_file gen_uid/;
use Carp qw/confess/;

use Test2::Util::HashBase qw{^frame ^pid ^tid ^cid -hid -nested details -buffered -uuid -huuid};

{
    no warnings 'once';
    *DETAIL = \&DETAILS;
    *detail = \&details;
    *set_detail = \&set_details;
}

sub init {
    confess "The 'frame' attribute is required"
        unless $_[0]->{+FRAME};

    $_[0]->{+DETAILS} = delete $_[0]->{detail} if $_[0]->{detail};

    unless (defined($_[0]->{+PID}) || defined($_[0]->{+TID}) || defined($_[0]->{+CID})) {
        $_[0]->{+PID} = $$        unless defined $_[0]->{+PID};
        $_[0]->{+TID} = get_tid() unless defined $_[0]->{+TID};
    }
}

sub snapshot {
    my ($orig, @override) = @_;
    bless {%$orig, @override}, __PACKAGE__;
}

sub signature {
    my $self = shift;

    # Signature is only valid if all of these fields are defined, there is no
    # signature if any is missing. '0' is ok, but '' is not.
    return join ':' => map { (defined($_) && length($_)) ? $_ : return undef } (
        $self->{+CID},
        $self->{+PID},
        $self->{+TID},
        $self->{+FRAME}->[1],
        $self->{+FRAME}->[2],
    );
}

sub debug {
    my $self = shift;
    return $self->{+DETAILS} if $self->{+DETAILS};
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

1;

__END__

#line 279
