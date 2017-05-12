package Socialtext::WikiFixture::Selenese;
use strict;
use warnings;
use base 'Socialtext::WikiFixture';
use Encode;
use Test::More;
use Carp qw(croak);

=head1 NAME

Socialtext::WikiFixture::Selenese - Executes wiki tables using Selenium RC

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

This class executes wiki tables using Selenium Remote Control.  Test tables
contain 3 columns:

  | *Command* | *Option1* | *Option2* |

This module will attempt to convert selenese into proper calls to
Test::WWW::Selenium, otherwise the calls will be passed straight to 
Test::WWW::Selenium.

=head1 FUNCTIONS

=head2 new( %opts )

Create a new fixture object.  Options:

=over 4

=item host

Mandatory - specifies the Selenium server to connect to

=item port 

Optional - specifies the port of the Selenium server (default: 4444)

=item browser_url

Mandatory - Passed to WWW::Selenium constructor, specifies where the
browser should connect to.

=back

=head2 init()

Called by the constructor.  Creates a Test::WWW::Selenium object which
asks the Selenium Server to launch a browser.

=cut

sub init {
    my ($self) = @_;

    unless ($self->{selenium}) {
        die "Selenium host is mandatory!" unless $self->{host};
        die "Selenium browser_url is mandatory!" unless $self->{browser_url};

        $self->{selenium} = Test::WWW::Selenium->new(
            host        => $self->{host},
            port        => $self->{port} || 4444,
            browser_url => $self->{browser_url},
            browser     => $self->{browser}  || $ENV{selenium_browser} || '*firefox',
            verbose     => $self->{verbose},
        );
        $self->{_started_selenium}++;
    }
    $self->{selenium_timeout} ||= 10000;

    $self->remove_selenium_frame if $self->{maximize};
}

=head2

This removes the selenium frame accross the top so you can see the whole window

=cut
sub remove_selenium_frame {
    my $self = shift;
    my $cnode = "document.body.childNodes[1].childNodes[1]";

    my $sel = $self->{selenium};

    $sel->open('about:blank');

    $sel->get_eval("window.frames[0].resizeTo(screen.width,screen.height)");

    $sel->{browser_start_command} ||= '';
    if ($sel->{browser_start_command} =~ /^\*(?:chrome|firefox)$/) {
        $sel->get_eval("$cnode.firstChild.setAttribute('style','display:none')");
        $sel->get_eval("$cnode.childNodes[2].style.width = screen.width + 'px'");
        $sel->get_eval("$cnode.childNodes[2].childNodes[1].style.width = screen.width + 'px'");
    }
    elsif ($sel->{browser_start_command} =~ /^\*ie/) {
        my $iframe = 'document.getElementById("myiframe")';
        $sel->get_eval("$iframe.contentWindow.moveTo(0,0)");
        $sel->get_eval("$iframe.outerHeight = screen.availHeight");
        $sel->get_eval("$iframe.outerWidth = screen.availWidth");
    }
}

=head2 end_hook()

Called by the test plan after testing has finished.  Kills the browser.

=cut

sub end_hook {
    my $self = shift;
    if ($self->{_started_selenium}) {
        $self->{selenium}->stop;
        $self->{selenium} = undef;
    }
}

=head3 handle_command()

Called by the test plan to execute each command.

=cut

sub handle_command {
    my $self = shift;
    my $sel = $self->{selenium};
    my $command = $self->_munge_command(shift);
    my ($opt1, $opt2, @other) = $self->_munge_options(@_);

    # Convenience method
    if ($command eq 'text_like' and !$opt2) {
        $opt2 = $opt1;
        $opt1 = '//body';
    }

    if ($command =~ /_(?:un)?like$/) {
        if ($opt2) {
            $opt2 = $self->quote_as_regex($opt2);
        }
        else {
            $opt1 = $self->quote_as_regex($opt1);
        }
    }

    Encode::_utf8_on($opt2) unless Encode::is_utf8($opt2);
    # Try to guess _ok methods
    $command .= '_ok' if { map { $_ => 1 } qw(open type) }->{$command};
    $self->$command($opt1, $opt2, @other);
}

sub _munge_command {
    my $self = shift;
    my $command = shift;
    
    $command =~ s/-/_/g;
    $command =~ s/^\*(.+)\*$/$1/;

    # Turn Camelcase into perl style (eg: clickAndWait -> click_and_wait)
    while ($command =~ /[A-Z]/) {
        $command =~ s/([a-z]*)([A-Z])/($1 ? $1 . '_' : '') . lc($2)/e;
    }

    # Map selenese (eg: verify_title => title_like)
    if ($command =~ /^verify_(\w+)$/) {
        $command = lc($1) . '_like';
    }

    return $command;
}

sub _try_condition {
    my ($self, $condition, $arg, $timeout) = @_;

    $timeout = $self->{selenium_timeout} unless defined $timeout;
    $arg =~ s/'/\\'/g;

    my $cmd = "try { $condition('$arg') ? true : false } catch(e) { false }";
    $self->{selenium}->wait_for_condition_ok($cmd, $timeout);
}

=head2 click_and_wait()

Clicks and waits.

=cut

sub click_and_wait { shift->_and_wait('click_ok', @_) }

=head2 select_and_wait()

Selects and waits.

=cut

sub select_and_wait { shift->_and_wait('select_ok', @_) }

sub _and_wait {
    my ($self, $method, $opt1, $opt2) = @_;
    my $sel = $self->{selenium};

    my @args;
    push @args, $opt2 if $opt2;
    $sel->$method($opt1, @args);
    $sel->wait_for_page_to_load_ok($self->{selenium_timeout});
}

=head2 text_present_like()


Search entire body for given text

=cut

sub text_present_like {
    my ($self, $opt1) = @_;
    $self->{selenium}->text_like('//body', $opt1);
}

=head2 store_value( $name, $locator )

Stores an element's value as a variable for later use.

=cut

sub store_value {
    my ($self, $name, $locator) = @_;
    unless (defined $name and defined $locator) {
        diag "Both name and locator must be defined for set!";
        return;
    }
    $self->{$name} = $self->{selenium}->get_value($locator);
    diag "Set '$name' to '$self->{$name}'";
}

=head2 store_text( $name, $locator )

Stores an element's text as a variable for later use.

=cut

sub store_text {
    my ($self, $name, $locator) = @_;
    unless (defined $name and defined $locator) {
        diag "Both name and locator must be defined for set!";
        return;
    }
    $self->{$name} = $self->{selenium}->get_text($locator);
    diag "Set '$name' to '$self->{$name}'";
}

=head2 print_page()

Prints the text of the current page loaded into the browser.

=cut

sub print_page {
    my ($self) = @_;

    print $self->get_text('//body');
}

=head2 pause($timeout)

Waits $timeout milliseconds (default: 1 second)

=cut

sub pause {
    my ($self,$timeout) = @_;
    $timeout = 1000  unless defined $timeout;
    $timeout /= 1000;
    sleep $timeout;
}

=head2 wait_for_text_present_ok($text, $timeout)

Waits until $text is present in the html source

=cut

sub wait_for_text_present_ok {
    my $self = shift;
    $self->_try_condition('selenium.isTextPresent',@_);
}

=head2 wait_for_element_present_ok($locator, $timeout)

Waits until $locator is present

=cut

sub wait_for_element_present_ok {
    my $self = shift;
    $self->_try_condition('selenium.isElementPresent',@_);
}

=head2 wait_for_element_visible_ok($locator, $timeout)

Waits until $locator is visible

=cut

sub wait_for_element_visible_ok {
    my $self = shift;
    $self->_try_condition('selenium.isVisible',@_);
}

=head2 wait_for_text_not_present_ok($text, $timeout)

Waits until $text is not present in the html source

=cut

sub wait_for_text_not_present_ok {
    my $self = shift;
    $self->_try_condition('!selenium.isTextPresent',@_);
}

=head2 wait_for_element_not_present_ok($locator, $timeout)

Waits until $locator is not present

=cut

sub wait_for_element_not_present_ok {
    my $self = shift;
    $self->_try_condition('!selenium.isElementPresent',@_);
}

=head2 wait_for_element_not_visible_ok($locator, $timeout)

Waits until $locator is not visible

=cut

sub wait_for_element_not_visible_ok {
    my $self = shift;
    $self->_try_condition('!selenium.isVisible',@_);
}

=head2 AUTOLOAD

Any functions not specified are passed to Test::WWW::Selenium

=cut
our $AUTOLOAD;
sub AUTOLOAD {
    my $name = $AUTOLOAD;
    $name =~ s/.+:://;
    return if $name eq 'DESTROY';

#    warn "No method $name found - passing to selenium\n";
    my $self = shift;
    $self->{selenium}->$name(@_);
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-socialtext-editpage at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Socialtext-WikiTest>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Socialtext::WikiFixture::Selenese

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Socialtext-WikiTest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Socialtext-WikiTest>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Socialtext-WikiTest>

=item * Search CPAN

L<http://search.cpan.org/dist/Socialtext-WikiTest>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
