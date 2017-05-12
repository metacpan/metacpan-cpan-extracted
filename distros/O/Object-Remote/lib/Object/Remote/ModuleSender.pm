package Object::Remote::ModuleSender;

use Object::Remote::Logging qw( :log :dlog );
use Config;
use File::Spec;
use List::Util qw(first);
use Moo;

has dir_list => (is => 'lazy');

sub _build_dir_list {
  my %core = map +($_ => 1), grep $_, @Config{
    qw(privlibexp archlibexp vendorarchexp sitearchexp)
  };
  DlogS_trace { "dir list built in ModuleSender: $_" } [ grep !$core{$_}, @INC ];
}

sub source_for {
  my ($self, $module) = @_;
  log_debug { "locating source for module '$module'" };
  if (my $find = Object::Remote::FromData->can('find_module')) {
    if (my $source = $find->($module)) {
      Dlog_trace { "source of '$module' was found by Object::Remote::FromData" };
      return $source;
    }
  }
  log_trace { "Searching for module in library directories" };
  my ($found) = first {  -f $_ }
                  map File::Spec->catfile($_, $module),
                    @{$self->dir_list};
  die "Can't locate ${module} in \@INC. (on remote host) dir_list contains:\n"
      .join("\n", @{$self->dir_list})
    unless $found;
  log_debug { "found '$module' at '$found'" };
  open my $fh, '<', $found or die "Couldn't open ${found} for ${module}: $!";
  return do { local $/; <$fh> };
}

1;
