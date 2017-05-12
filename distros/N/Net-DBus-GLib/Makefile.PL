use 5.006;
use ExtUtils::MakeMaker;

my $DBUS_LIBS = `pkg-config --libs dbus-glib-1`;
my $DBUS_CFLAGS = `pkg-config --cflags dbus-glib-1`;

if (!defined $DBUS_LIBS || !defined DBUS_CFLAGS) {
    die "could not run 'pkg-config' to determine compiler/linker flags for dbus-glib-1 library: $!\n";
}
if (!$DBUS_LIBS || !$DBUS_CFLAGS) {
    die "'pkg-config' didn't report any compiler/linker flags for dbus-glib-1 library\n";
}

WriteMakefile(
	      'NAME' => 'Net::DBus::GLib',
	      'VERSION_FROM' => 'lib/Net/DBus/GLib.pm',
	      'PREREQ_PM' => {
		  'Test::More'  => 0,
		  'Net::DBus' => "0.33.2",
		  'Glib' => 0,
		  },
	      'AUTHOR' => 'Daniel Berrange <dan@berrange.com>',
	      'LIBS' => [$DBUS_LIBS],
	      'DEFINE' => "-DDBUS_API_SUBJECT_TO_CHANGE",
	      'INC' => "-Wall $DBUS_CFLAGS",
              'NO_META' => 1,
	      'depend' => {
		  Net-DBus-GLib.spec => '$(VERSION_FROM)',
		  Makefile => '$(VERSION_FROM)',
	      },
	      'realclean' => {
		  FILES => 'Net-DBus-GLib.spec',
	      },
);

package MY;

sub libscan
  {
    my ($self, $path) = @_;
    ($path =~ /\~$/ || $path =~ m,/CVS/,) ? undef : $path;
  }

__END__
