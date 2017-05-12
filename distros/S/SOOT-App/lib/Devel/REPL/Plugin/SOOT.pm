package Devel::REPL::Plugin::SOOT;
use strict;
use warnings;
use Devel::REPL::Plugin;
use namespace::clean -except => [ 'meta' ];
use Fcntl qw(:flock :seek);

has 'history_file_handle' => (
  isa => 'FileHandle', is => 'rw', required => 1, lazy => 1,
  default => sub { $_[0]->open_history_file() }
);

# HISTLEN should probably be in a config file to stop people accidentally
# truncating their history if they start the program and forget to set
# PERLREPL_HISTLEN
our $HistLen = $ENV{SOOT_HISTLEN} || 1000;

our $REPL;

around 'run' => sub {
  my $orig=shift;
  my ($self, @args)=@_;
  my $hist_file = $self->get_history_file;
  $self->term->stifle_history($HistLen);
  -f($hist_file) && $self->term->ReadHistory($hist_file);
  $self->term->Attribs->{do_expand}=1;
  $REPL = $self if not defined $REPL;
  $self->$orig(@args);
  $REPL = undef;
  $self->term->WriteHistory($hist_file) ||
    $self->print("warning: failed to write history file $hist_file");
};

use vars '%SIG';
SCOPE: {
  my %sig = %SIG;
  $SIG{INT} = sub {
    if (defined $REPL) {
      $REPL->term->WriteHistory($REPL->get_history_file);
    }
    return $sig{INT}->(@_) if ref($sig{INT});
  };
  $SIG{TERM} = sub {
    if (defined $REPL) {
      $REPL->term->WriteHistory($REPL->get_history_file);
    }
    return $sig{TERM}->(@_) if ref($sig{INT});
  };
}

sub get_history_file {
  my $self = shift;
  my $filename = '.soot_hist';
  my $histfile;
  if (-f $filename) {
    $histfile = $filename;
  }
  else {
    foreach my $path ((map {$ENV{$_}} qw(HOME HOMEDIR USERDIR)), '~') {
      if (defined $path and -f File::Spec->catfile($path, $filename)) {
        $histfile = File::Spec->catfile($path, $filename);
        last;
      }
    }
  }
  if (defined $histfile) {
    return $histfile;
  } else {
    return $filename;
  }
}


1;
