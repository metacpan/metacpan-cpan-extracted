# This script is automatically executed after 2008.xs has been compiled. It
# takes all symbol names from constants.txt and functions.txt that we would
# like to provide, checks which of them we actually provide, and makes these
# available through @_constants and @_functions in symbols.pl which is loaded
# by 2008.pm via "require" to populate @EXPORT_OK. This is to make sure that
# "use POSIX::2008 'non_existent_name';" croaks at compile time.

use File::Spec;

require XSLoader;
XSLoader::load('POSIX::2008', '0.27');

my %names;

foreach my $type (qw(constants functions)) {
  $names{$type} = do {
    local $/;
    my $file = "${type}.txt";
    open my $fh, '<', $file or die "Can't open $file: $!";
    [sort split ' ', <$fh>];
  };
}

my $file = File::Spec->catfile(
  File::Spec->curdir(), qw(blib lib POSIX 2008 symbols.pl)
);

open my $fh, '>', $file or die "Can't open $file: $!";

foreach my $type (sort keys %names) {
  print $fh "our \@_${type} = qw(\n";
  foreach my $name (@{$names{$type}}) {
    print $fh "$name\n" if defined &{"POSIX::2008::$name"};
  }
  print $fh ");\n\n";
}

print $fh "1;\n";
close $fh or die "Can't write $file: $!";
