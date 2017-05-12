package ORTestGlobs;
use Moo;

has handle => (is => 'rw');
has valueref => (is => 'ro', default => sub {
  my $body = '';
  return \$body;
});

sub write { my $self = shift; print { $self->handle } @_ }

sub getvalue { ${ $_[0]->valueref } }

sub gethandle {
  open my $fh, '>', $_[0]->valueref
    or die "Unable to open in-memory file: $!\n";
  return $fh;
}

sub getreadhandle {
  open my $fh, '<', $_[1]
    or die "Unable to open in-memory file: $!\n";
  return $fh;
}

1;
