package Tak::ModuleSender;

use IO::All;
use List::Util qw(first);
use Config;
use Moo;

with 'Tak::Role::Service';

has dir_list => (is => 'lazy');

sub _build_dir_list {
  my %core = map +($_ => 1), @Config{qw(privlibexp archlibexp)};
  [ map io->dir($_), grep !/$Config{archname}$/, grep !$core{$_}, @INC ];
}

sub handle_source_for {
  my ($self, $module) = @_;
  my $io = first { $_->exists } map $_->catfile($module), @{$self->dir_list};
  unless ($io) {
    die [ 'failure' ];
  }
  my $code = $io->all;
  return $code;
}

1;
