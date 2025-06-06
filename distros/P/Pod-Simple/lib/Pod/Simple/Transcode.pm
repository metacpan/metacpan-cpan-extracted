package Pod::Simple::Transcode;
use strict;
our $VERSION = '3.47';

BEGIN {
  if(defined &DEBUG) {;} # Okay
  elsif( defined &Pod::Simple::DEBUG ) { *DEBUG = \&Pod::Simple::DEBUG; }
  else { *DEBUG = sub () {0}; }
}

our @ISA;
foreach my $class (
  'Pod::Simple::TranscodeSmart',
  'Pod::Simple::TranscodeDumb',
  '',
) {
  $class or die "Couldn't load any encoding classes";
  DEBUG and print STDERR "About to try loading $class...\n";
  eval "require $class;";
  if($@) {
    DEBUG and print STDERR "Couldn't load $class: $@\n";
  } else {
    DEBUG and print STDERR "OK, loaded $class.\n";
    @ISA = ($class);
    last;
  }
}

sub _blorp { return; } # just to avoid any "empty class" warning

1;
__END__


