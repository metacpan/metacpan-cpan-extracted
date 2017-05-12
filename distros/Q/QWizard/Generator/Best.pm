package QWizard::Generator::Best;

use strict;
use Config;
our $VERSION = '3.15';

sub new {
    my $type = shift;

    # first check if we're in a web server...
    # XXX: there is probably a better way to determine things than this.
    if (exists($ENV{'SERVER_NAME'})) {
	my $have_html = eval { require QWizard::Generator::HTML };
	if (!$have_html) {
	    die "We're in a web server and we can't load the QWizard::Generator::HTML module\n"; 
	}
	return new QWizard::Generator::HTML(@_);
    }

    # see if they have a preference and if we can use it
    if (exists($ENV{'QWIZARD_GENERATOR'})) {
	my $class = $ENV{'QWIZARD_GENERATOR'};
	if ($class !~ /::/) {
	    $class = "QWizard::Generator::" . $class;
	}
	my $haveit = 
	  eval "require $class;";
	if ($haveit) {
	    return eval "new " . $class . "();"
	} else {
	    print STDERR "requested QWizard Generator $class could not be loaded\n";
	}
    }

    # checks to see if we're running on win32, macos or have the X11 DISLAY var
    my $havedisplay = ($^O eq 'MSWin32' ||
		    $Config{'ccflags'} =~ /-D_?WIN32_?/ ||
		    $^O eq 'MacOS' ||
		    defined($ENV{'DISPLAY'}));

    # console like
    my $have_gtk2 =
      eval { 
	  if (!$havedisplay) {
	      return 0;
	  }
	  require QWizard::Generator::Gtk2;
      };
    # ideally, Gtk2 is the current nicest interface.  Try it.
    return new QWizard::Generator::Gtk2(@_) if ($have_gtk2);

    # console like
    my $have_tk =
      eval { 
	  if (!$havedisplay) {
	      return 0;
	  }
	  require QWizard::Generator::Tk;
      };
    # ideally, Tk is the second nicest interface.  Try it.
    return new QWizard::Generator::Tk(@_) if ($have_tk);

    my $have_curses = eval { require QWizard::Generator::Curses };
    # next try the curses interface, if available
    return new QWizard::Generator::Curses(@_) if ($have_curses);

    my $have_readline = eval { require QWizard::Generator::ReadLine };
    # next try the curses interface, if available
    return new QWizard::Generator::ReadLine(@_) if ($have_readline);

    # remote client: future
    my $have_wap = eval { require QWizard::Generator::WAP };

    die "Sorry, I couldn't find a suitable QWizard::Generator perl module to use.  XXX: describe solution alternatives to the user (eg, how to install a module).\n";
}

1;
