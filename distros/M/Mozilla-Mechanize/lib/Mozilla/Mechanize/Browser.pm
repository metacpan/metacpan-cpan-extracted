package Mozilla::Mechanize::Browser;

use strict;
use warnings;

use Glib qw(FALSE G_PRIORITY_LOW);
use Gtk2 '-init';
use Mozilla::Mechanize::Browser::Gtk2MozEmbed;

## xxx: hack until I wrap nsIWebProgressListener or something in Mozilla::DOM
my %STATE = (
    START => 1,
    REDIRECTING => 2,
    TRANSFERRING => 4,
    NEGOTIATING => 8,
    STOP => 16,
    IS_REQUEST => 65536,
    IS_DOCUMENT => 131072,
    IS_NETWORK => 262144,
    IS_WINDOW => 524288,
    RESTORING => 16777216,
    IS_INSECURE => 4,
    IS_BROKEN => 1,
    IS_SECURE => 2,
    SECURE_HIGH => 262144,
    SECURE_MED => 65536,
    SECURE_LOW => 131072,
    IDENTITY_EV_TOPLEVEL => 1048576,
);

sub new {
    my $pkg = shift;
    my $opts = shift;
    my $debug = delete $opts->{debug};

    my $self = {
        netstopped => 0,
        debug => $debug,
    };
    bless($self, $pkg);

    $self->debug('Browser->new, opts: ' . join(', ', map("$_=$opts->{$_}", keys(%$opts))));

    my $window = Mozilla::Mechanize::Browser::Gtk2MozEmbed->new();
    $window->set_default_size($opts->{width}, $opts->{height});
    $window->iconify() unless $opts->{visible};
    $window->fullscreen() if $opts->{fullscreen};

    # XXX: maybe this isn't necessary (or even working)
    $window->signal_connect(delete_event => sub {
        $self->debug('delete_event signal');

        # XXX: how do you check to make sure that the main loop
        # is actually running before calling main_quit?
        # Something in Glib::MainLoop, maybe.
        Gtk2->main_quit;
        return FALSE;
    });

    my $embed = $window->{embed};
    $self->{embed} = $embed;
    $self->{window} = $window;

    $embed->signal_connect(net_start => sub { net_start_cb($self, @_) });

    # Any time a new page loads, this adds a "single-shot" idle callback
    # that stops the main loop. Thanks to muppet for the idea.
    $embed->signal_connect(net_stop => sub { net_stop_cb($self, @_) });

    $embed->signal_connect(net_state => sub { net_state_cb($self, @_) });
    $embed->signal_connect(net_state_all => sub { net_state_all_cb($self, @_) });
    $embed->signal_connect(progress => sub { progress_cb($self, @_) });
    $embed->signal_connect(progress_all => sub { progress_all_cb($self, @_) });

    # Start off with a blank page
    $embed->load_url('about:blank');
    $window->show_all();

    $self->debug('Browser->new, main');
    Gtk2->main;   # quits after net_stop event fires

    return $self;
}

=head2 $moz->embedded

Return a reference to the embedded (L<Gtk2::MozEmbed|Gtk2::MozEmbed>)
widget.

=cut

sub embedded { $_[0]->{embed} }


sub quit {
    my $self = shift;
    warn "Browser->quit\n" if $self->{debug};

    $self->{window}->destroy();
}


sub debug {
    my ($self, $msg) = @_;
    if ($self->{debug}) {
        my (undef, $file, $line) = caller();
        print STDERR "$msg at $file line $line\n";
    }
}

# When there is a change in the progress of loading a document.
# The cur value indicates how much of the document has been downloaded.
# The max value indicates the length of the document. If the value of
# max is less than one the full length of the document can not be determined.
sub progress_cb {
    my ($browser, $embed, $cur, $max) = @_;

    $browser->debug("progress signal: cur=$cur, max=$max");
}

sub progress_all_cb {
    my ($browser, $embed, $uri, $cur, $max) = @_;

    $browser->debug("progress_all signal: cur=$cur, max=$max, uri=$uri\n"
                      . "  ref uri=", ref($uri));
}

sub net_start_cb {
    my ($browser, $data) = @_;

    $browser->debug("net_start signal");
    $browser->{netstopped} = 0;
    FALSE;
}

sub net_stop_cb {
    my ($browser, $embed, $data) = @_;

    $browser->debug("net_stop signal");
    Glib::Idle->add(
        sub {
            $browser->debug("net_stop Idle, main_quit");
            $browser->{netstopped} = 1;

            Gtk2->main_quit;
            FALSE;  # uninstall
        }, undef, G_PRIORITY_LOW
    );
    FALSE;      # let any other handlers run
}

# I found it did something like this in
# http://code.google.com/p/google-gadgets-for-linux/source/browse/trunk/extensions/gtkmoz_browser_element/browser_child.cc
my $current_doc_loaded_mask = $STATE{STOP} | $STATE{IS_REQUEST};
sub net_state_cb {
    my ($browser, $embed, $state_flags, $data) = @_;
    $browser->debug("net_state_cb signal: flags=$state_flags, status=$data");

    if (($state_flags & $current_doc_loaded_mask) == $current_doc_loaded_mask) {
        $browser->debug("current_doc loaded!");

        net_stop_cb($browser, $embed, $data);
    }
}

sub net_state_all_cb {
    my ($browser, $embed, $uri, $state_flags, $data) = @_;

    $browser->debug("net_state_all: uri=$uri, flags=$state_flags, status=$data"
                . "ref uri=", ref($uri));
}



1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright 2005,2009 Scott Lanning <slanning@cpan.org>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
