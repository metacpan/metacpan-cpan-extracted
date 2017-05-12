#!/usr/bin/perl
# Starts an example application. Pass it the name of the class
# corresponding to the example. For example, the file Minilla.pm
# contains the Minilla class, so you would do
#
#   ./startapp.pl Minilla
#
# (You can also use Minilla.pm if you want.)

use strict;
use warnings;

BEGIN {
    print STDERR "\n**** NOTE ****\n\n",
      "If you can't load MozEmbed.so,\n",
      "search for LD_LIBRARY_PATH in README.\n\n",
      "If you get a blank window or 'Can't locate auto/Gtk2/MozEmbed/get_nsIWebB.al',\n",
      "try force installing Gtk2::MozEmbed manually as root.\n\n",
      "**************\n\n";
}

use Glib qw(FALSE);
use Gtk2 -init;

main();


sub main {
    my $class = get_class_from_cmdline();
    my $window = create_window($class);

    # Display the application window.
    $window->show_all();
    Gtk2->main();
}

sub get_class_from_cmdline {
    my $class = shift @ARGV;
    $class =~ s/\.pm$//;

    # Check that there is a corresponding $class.pm file
    # in the current directory.
    unless (grep {$_ eq $class} map {s/\.pm$//; $_} <*.pm>) {
        die "'$class' isn't a known example.\nUsage: $0 Minilla\n";
    }

    # Load that file.
    eval "require $class" or die "$@\n";

    return $class;
}

sub create_window {
    my $class = shift;

    my $window = $class->new();

    # This signal handler allows exiting the application
    # by clicking the window's close button. Otherwise, the window
    # will just hide and you have to Ctrl-c to kill the app.
    $window->signal_connect(delete_event => sub {
        Gtk2->main_quit;
        return FALSE;
    });

    # Set the window's default size. The window might be too small
    # if you don't do this.
    $window->set_default_size(600, 400);

    return $window;
}
