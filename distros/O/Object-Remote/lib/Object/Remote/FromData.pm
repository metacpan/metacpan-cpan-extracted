package Object::Remote::FromData;

use strictures 1;
use Object::Remote;
use Object::Remote::Logging qw ( :log );

our %Modules;
our %Not_Loaded_Yet;
our %Seen;

sub import {
  my $target = caller;
  log_trace { "import has been invoked by '$target' on " . __PACKAGE__ };
  return if $Seen{$target};
  log_debug { "'$target' has not yet loaded " . __PACKAGE__ };
  $Seen{$target} = $Not_Loaded_Yet{$target} = 1;
}

sub flush_loaded {
  log_debug { "flushing the loaded classes" };
  foreach my $key (keys %Not_Loaded_Yet) {
    log_trace { "flushing '$key'" };
    my $data_fh = do { no strict 'refs'; *{"${key}::DATA"} };
    my $data = do { local $/; <$data_fh> };
    my %modules = reverse(
      $data =~ m/(^package ([^;]+);\n.*?(?:(?=^package)|\Z))/msg
    );
    $_ .= "\n1;\n" for values %modules;
    @Modules{keys %modules} = values %modules;
    delete $Not_Loaded_Yet{$key};
  }
  log_trace { "done flushing loaded classes" };
}

sub find_module {
  flush_loaded;
  my ($module) = @_;
  $module =~ s/\//::/g;
  $module =~ s/\.pm$//;
  return $Modules{$module};
}

1;
