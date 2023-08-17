package Pipe::Tube::Print;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.06';

sub init {
    my ($self, $file) = @_;
    # file can be either undef -> STDOUT or a filehandle, or a filename -> print into that file,
    if ($file) {
      if (not ref $file) {      # string, assume filename
        open my $fh, ">", $file or die $!;
        $self->{fh} = $fh;
        $self->logger("Print: received filename");
      } elsif ('GLOB' eq ref $file) { # filehandle
        $self->{fh} = $file;
        $self->logger("Print: received filehandle");
      } else {
        die "Unkown type of paramter for print: '" . ref($file) . "'\n";
      }
    }
    return $self;
}

sub run {
    my ($self, @input) = @_;
    $self->logger("Print: @input");
    if (my $fh = $self->{fh}) {
      print $fh @input;
    } else {
      print @input;
    }
    return;
}


1;

