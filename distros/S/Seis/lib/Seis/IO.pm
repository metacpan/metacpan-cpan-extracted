package Seis::IO;
use strict;
use warnings;
use utf8;
use 5.018_000;

sub _new {
    my ($class, $path) = @_;
    bless { path => $path }, $class;
}

# return Seis::IO->_new_with_fh($_[0], $fh);
sub _new_with_fh {
    my ($class, $path, $fh) = @_;
    bless { path => $path, fh => $fh }, $class;
}

sub lines {
    my $self = shift;
    my $fh = $self->{fh};
    my @lines = <$fh>;
    @lines;
}

sub eof:method {
    warn CORE::eof($_[0]->{fh});
    CORE::eof($_[0]->{fh});
}

sub get:method {
    my $self = shift;
    my $fh = $self->{fh};
    $self->{ins}++;
    my $line = scalar(<$fh>);
    chop($line);
    $line;
}

sub print:method {
    my $self = shift;
    print {$self->{fh}} shift;
}

sub close:method {
    my $self = shift;
    close $self->{fh};
}

sub getc:method {
    my $self = shift;
    getc $self->{fh};
}

sub ins {
    my $self = shift;
    $self->{ins};
}

sub say:method {
    my $self = shift;
    CORE::say {$self->{fh}} @_;
}

sub write:method {
    my $self = shift;
    CORE::print {$self->{fh}} @_;
}

sub read:method {
    my ($self, $len) = @_;
    CORE::read($self->{fh}, my $buf, $len);
    return $buf;
}

# Note. Following file testing cases are optimizable by XS.
sub e { -e $_[0]->{path} ? Bool::true() : Bool::false() }
sub d { -d $_[0]->{path} ? Bool::true() : Bool::false() }
sub s { -s $_[0]->{path} } # size.
sub f { -f $_[0]->{path} ? Bool::true() : Bool::false() }

sub copy {
    require File::Copy;
    File::Copy::copy($_[0]->{path}, $_[1])
        or Seis::Exception::IO->throw("$!");
}

1;

