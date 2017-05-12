use strict;
use warnings FATAL => 'all';

package Mozilla::Mechanize::GUITester;

BEGIN {
	# capture possible Xlib messages on STDERR
	use IO::CaptureOutput qw(capture);
	capture(sub {
		eval "use base 'Mozilla::Mechanize'";
	});
	die "Unable to use Mozilla::Mechanize: $@" if $@;
};

use Mozilla::Mechanize::GUITester::Gesture;
use Mozilla::PromptService;
use Mozilla::ObserverService;
use Mozilla::SourceViewer;
use X11::GUITest qw(ClickMouseButton :CONST SendKeys ReleaseKey
		PressMouseButton ReleaseMouseButton PressKey
		ResizeWindow GetScreenRes QuoteStringForSendKeys);
use File::Temp qw(tempdir);
use Mozilla::ConsoleService;
use Mozilla::DOM::ComputedStyle;
use Carp;
use Test::More;

our $VERSION = '0.23';

sub _N {
	my ($self, $msg) = @_;
	diag($msg . " $self->{_reqs_count}") if $ENV{MMG_NET};
}

=head1 NAME

Mozilla::Mechanize::GUITester - enhances Mozilla::Mechanize with GUI testing.

=head1 SYNOPSIS

  use Mozilla::Mechanize::GUITester;

  # regular Mozilla::Mechanize initialization
  my $mech = Mozilla::Mechanize::GUITester->new(%mechanize_args);
  $mech->get_url($url);

  # convenience wrapper over GetElementById and QueryInterface
  my $elem = $mech->get_html_element_by_id("some_id");

  # click mouse at the element position + (1, 1)
  $mech->x_click($elem, 1, 1);

  # play with the mouse relative to the element position
  $mech->x_mouse_down($elem, 2, 2);
  $mech->x_mouse_move($elem, 4, 4);
  $mech->x_mouse_up($elem, 4, 4);

  # send keystrokes to the application
  $mech->x_send_keys('{DEL}');

  # press and release left CTRL button. You can click in the middle.
  $mech->x_press_key('LCT');
  $mech->x_release_key('LCT');

  # run some javascript code and print its result
  print $mech->run_js('return "js: " + 2');

  # find out element style using its id
  print $mech->get_element_style_by_id('the_elem_id', 'background-color');

  # are there any javascript errors?
  print Dumper($mech->console_messages);

  # find out HTTP response status (works only for HTTP protocol)
  print $mech->status;

  # change some text box by sending keypresses - fires all JS events
  my $input = $mech->get_html_element_by_id("tbox", "Input");
  $mech->x_change_text($input, "Hi");

=head1 DESCRIPTION

This module enhances Mozilla::Mechanize with convenience functions allowing
testing of DHTML/JavaScript rich pages.

It uses X11::GUITest to emulate mouse clicking, dragging and moving over
elements in DOM tree.

It also allows running of arbitrary javascript code in the page context and
getting back the results.

C<MMG_TIMEOUT> environment variable can be used to adjust timeout of X events
(given in milliseconds).

=head1 CONSTRUCTION

=head2 Mozilla::Mechanize::GUITester->new(%options);

This constructor delegates to Mozilla::Mechanize::new function. See
Mozilla::Mechanize manual for its description.

=cut
sub new {
	my $home = $ENV{HOME};
	my $td = tempdir("/tmp/mozilla_guitester_XXXXXX", CLEANUP => 1);
	local $ENV{HOME} = $td;
	local $ENV{MOZ_NO_REMOTE} = 1;
	my $self = shift()->SUPER::new(@_);
	$self->{_home} = $td;
	$self->{_popups} = {};
	$self->{_alerts} = '';
	$self->{_console_messages} = [];

	$self->{_window_id} = $self->agent->{window}->window->XWINDOW;
	confess("# Unable to find window id") unless $self->window_id;

	Mozilla::PromptService::Register({ DEFAULT => sub {
		my $name = shift;
		$self->{_popups}->{$name} = [ @_ ];
		$self->{_alerts} .= $_[2] . "\n";
	} , Confirm => sub { return $self->{_confirm_result} }
	, Prompt => sub { return $self->{_prompt_result}; } });
	$self->{_reqs_count} = 0;
	Mozilla::ObserverService::Register({
		'http-on-examine-response' => sub {
			$self->_N('http-on-examine-response');
			my $channel = shift;
			$self->{_response_status} = $channel->responseStatus;
			$self->{_reqs_count}-- if $self->{_reqs_count} > 0;
		}, "http-on-modify-request" => sub {
			$self->_N('http-on-modify-request');
			$self->{_reqs_count}++;
		}, "http-on-examine-cached-response" => sub {
			$self->_N('http-on-examine-cached-response');
			$self->{_reqs_count}-- if $self->{_reqs_count} > 0;
 		}
	});
	$self->{_console_handle} = Mozilla::ConsoleService::Register(sub {
		my $msg = shift;
		push @{ $self->console_messages }, $msg if $msg;
	});
	return $self;
}

sub _countdown_requests {
	my ($self) = @_;
	$self->_N(join("", Carp::longmess()) . "_countdown_requests");
	$self->_wait_for_gtk;
	my $n = 1;
	while ($self->{_reqs_count} > 0) {
		$self->_N("iteration $n");
		my $rq = $self->{_reqs_count};
		$self->_wait_for_gtk;

		next if $rq != $self->{_reqs_count};
		if (($n++ % 50) == 0) {
			$self->_N("forcing reqs count");
			$self->{_reqs_count}--;
		}
	}
	$self->_N("_countdown_requests finish");
}

sub _wait_while_busy {
	my $self = shift;
	$self->_countdown_requests; 
	$self->{$_} = undef for qw(forms cur_form links images);
	return 1;
}
 
=head1 ACCESSORS

=head2 $mech->status

Returns last response status using Mozilla::ObserverService and
nsIHTTPChannel:responseStatus function.

Note that it works only for HTTP requests.

=cut
sub status { return shift()->{_response_status}; }

=head2 $mech->last_alert

Returns last alert contents intercepted through Mozilla::PromptService.

It is useful for communication from javascript.

=cut
sub last_alert { return shift()->{_popups}->{Alert}->[2]; }

=head2 $mech->console_messages

Returns arrayref of all console messages (e.g. javascript errors) aggregated
so far.

See Mozilla nsIConsoleService documentation for more details.

=cut
sub console_messages { return shift()->{_console_messages}; }

=head2 $mech->window_id

Returns window id of guitester window.

=cut
sub window_id { return shift()->{_window_id}; }

=head1 METHODS

=head2 $mech->x_resize_window($width, $height)

Resizes window to $width, $height. Dies if the screen is too small for it.

=cut
sub x_resize_window {
	my ($self, $width, $height) = @_;
	my ($x, $y) = GetScreenRes();
	die "Screen width is too small: $x < $width" if ($x < $width);
	die "Screen height is too small: $y < $height" if ($y < $height);
	ResizeWindow($self->window_id, $width, $height);
}

=head2 $mech->pull_alerts

Pulls all alerts aggregated so far and resets alerts stash. Useful for JS
debugging.

=cut
sub pull_alerts {
	my $self = shift;
	my $res = $self->{_alerts};
	$self->{_alerts} = '';
	return $res;
}

=head2 $mech->set_confirm_result($res)

Future C<confirm> JavaScript calls will return C<$res> as a result.

=cut
sub set_confirm_result {
	my ($self, $res) = @_;
	$self->{_confirm_result} = $res;
}

=head2 $mech->set_prompt_result($res)

Future prompt JavaScript calls will return C<$res> as a result.

=cut
sub set_prompt_result {
	my ($self, $res) = @_;
	$self->{_prompt_result} = $res;
}

=head2 $mech->run_js($js_code)

Wraps $js_code with JavaScript function and invokes it. Its result is
returned as string and intercepted through C<alert()>.

See C<last_alert> accessor above.

=cut
sub run_js {
	my ($self, $js) = @_;
	my $code = <<ENDS;
function __guitester_run_js() {
	$js;
}
alert(__guitester_run_js());
ENDS
	$self->get("javascript:$code");
	return $self->last_alert;
}

=head2 $mech->get_element_style($element, $style_attribute)

Uses Mozilla::DOM::ComputedStyle to get property value of C<$style_attribute>
for the C<$element> retrieved by GetElementById previously.

=cut
sub get_element_style {
	my ($self, $el, $attr) = @_;
	confess "No element given!" unless $el;
	confess "No attribute given!" unless $attr;
	return Get_Computed_Style_Property($self->get_window, $el, $attr);
}

=head2 $mech->get_element_style_by_id($element_id, $style_attribute)

Convenience function to retrieve style property by C<$element_id>. See
C<$mech->get_element_style>.

=cut
sub get_element_style_by_id {
	my ($self, $id, $attr) = @_;
	return $self->get_element_style(
			$self->get_document->GetElementById($id), $attr);
}

=head2 $mech->get_full_zoom

Returns current full zoom value

=cut
sub get_full_zoom {
	return Get_Full_Zoom(shift()->{agent}->{embed}->get_nsIWebBrowser);
}

=head2 $mech->set_full_zoom($zoom)

Sets full zoom to C<$zoom>.

=cut
sub set_full_zoom {
	return Set_Full_Zoom(shift()->{agent}->{embed}->get_nsIWebBrowser
			, shift);
}

=head2 $mech->calculated_content

This is basically body.innerHTML content as provided by Mozilla::Mechanize.
See its documentation for more info.

=cut
sub calculated_content {
	return shift()->SUPER::content(@_);
}

=head2 $mech->content

This is more like "View Source" page content. It leaves html tags intact and
also doesn't evaluate javascript's document.write calls.

=cut
sub content {
	my $self = shift;
	return Get_Page_Source($self->agent->{embed});
}

sub gesture {
	my ($self, $e) = @_;
	return Mozilla::Mechanize::GUITester::Gesture->new({
			element => $e, dom_window => $self->get_window
			, zoom => $self->get_full_zoom
			, window_id => $self->window_id });
}

=head2 $mech->get_html_element_by_id($html_id, $elem_type)

Uses GetElementById and QueryInterface to get Mozilla::DOM::HTMLElement.
If $elem_type is given queries Mozilla::DOM::HTML<$elem_type>Element.

See Mozilla::DOM documentation for more details.

=cut
sub get_html_element_by_id {
	my ($self, $id, $type) = @_;
	my $e = $self->get_document->GetElementById($id) or return;
	my $dom_class = "Mozilla::DOM::HTML" . ($type || '') . "Element";
	return $e->QueryInterface($dom_class->GetIID);
}

sub _wait_for_gtk {
	my $self = shift;
	my $t = $ENV{MMG_TIMEOUT} || 200;
	no warnings 'uninitialized';
	do {
		$self->_N("_wait_for_gtk");
		my $run = 1;
		Glib::Timeout->add($t, sub {
			$self->_N("TIMEOUT");
			$run = 0;
			Gtk2->main_quit;
		}, undef, -100);
		Mozilla::DOM::ComputedStyle::Set_Poll_Timeout();
		capture(sub { Gtk2->main while $run });
		Mozilla::DOM::ComputedStyle::Unset_Poll_Timeout();
	} while (Gtk2->events_pending);
}

sub _with_gesture_do {
	my ($self, $elem, $func) = @_;
	$self->_wait_for_gtk;
	my $g = $self->gesture($elem);
	$func->($g);
	$self->_wait_for_gtk;
}

=head2 $mech->x_click($element, $x, $y, $times)

Emulates mouse click at ($element.left + $x, $element.top + $y) coordinates.

Optional C<$times> parameter can be used to specify the number of clicks sent.

=cut
sub x_click {
	my ($self, $entry, $by_left, $by_top, $num) = @_;
	$num ||= 1;
	$self->_with_gesture_do($entry, sub {
		my $g = shift;
		$g->element_mouse_move($by_left, $by_top);
		ClickMouseButton(M_LEFT) for (1 .. $num);
	});
}

=head2 $mech->x_mouse_down($element, $x, $y)

Presses left mouse button at ($element.left + $x, $element.top + $y).

=cut
sub x_mouse_down {
	my ($self, $entry, $by_left, $by_top) = @_;
	$self->_with_gesture_do($entry, sub {
		my $g = shift;
		$g->element_mouse_move($by_left, $by_top);
		PressMouseButton(M_LEFT);
	});
}

=head2 $mech->x_mouse_up($element, $x, $y)

Releases left mouse button at ($element.left + $x, $element.top + $y).

=cut
sub x_mouse_up {
	my ($self, $entry, $by_left, $by_top) = @_;
	$self->_with_gesture_do($entry, sub {
		my $g = shift;
		$g->element_mouse_move($by_left, $by_top);
		ReleaseMouseButton(M_LEFT);
	});
}

=head2 $mech->x_mouse_move($element, $x, $y)

Moves mouse to ($element.left + $x, $element.top + $y).

=cut
sub x_mouse_move {
	my ($self, $entry, $by_left, $by_top) = @_;
	$self->_with_gesture_do($entry, sub {
		my $g = shift;
		$g->element_mouse_move($by_left, $by_top);
	});
}

=head2 $mech->x_send_keys($keystroke)

Sends $keystroke to mozilla window. It uses X11::GUITest SendKeys function.
Please see its documentation for possible C<$keystroke> values.

=cut
sub x_send_keys {
	my ($self, $keys) = @_;
	confess "Undefined keys" unless defined $keys;
	SendKeys($keys) or confess "Unable to send $keys";
	$self->_wait_for_gtk;
}

=head2 $mech->x_press_key($key)

Uses X11::GUITest PressKey function.  Please see its documentation for
possible C<$key> values.

=cut
sub x_press_key {
	my ($self, $key) = @_;
	PressKey($key);
	$self->_wait_for_gtk;
}

=head2 $mech->x_release_key($keystroke)

Uses X11::GUITest ReleaseKey function to release previously pressed key.
Please see its X11::GUITest documentation for possible C<$key> values.

=cut
sub x_release_key {
	my ($self, $key) = @_;
	ReleaseKey($key);
	$self->_wait_for_gtk;
}

=head2 $mech->x_change_text($input, $value)

Changes value of C<$input> edit box to C<$value>. All JavaScript events are
fired. It also works on textarea element.

=cut
sub x_change_text {
	my ($self, $input, $val) = @_;
	$input->SetValue("");
	$self->x_click($input, 4, 4);
	$self->x_send_keys($val ? QuoteStringForSendKeys($val) : $val);
	$self->x_send_keys('{TAB}');
}

=head2 $mech->x_change_select($input, $option_no)

Chooses option C<$option_no> of C<$input> select. All JavaScript events are
fired.

=cut
sub x_change_select {
	my ($self, $input, $opno, $x, $y) = @_;
	my $times = $opno - $input->GetSelectedIndex;
	my $key = "{DOW}";
	if ($times < 0) {
		$key = "{UP}";
		$times *= -1;
	}
	$self->x_click($input, $x // 7, $y // 7);
	$self->x_send_keys($key) for (1 .. $times);
	$self->x_send_keys('{ENT}');
}

sub close {
	my $self = shift;
	Mozilla::ConsoleService::Unregister($self->{_console_handle});
	$self->SUPER::close(@_);
}

sub set_fields {
	my ($self, %fields) = @_;
	for my $n (keys %fields) {
		my $el;
		eval { $el = $self->get_html_element_by_id($n, "Input") };
		next unless $el;
		$el->GetType eq 'checkbox' or next;
		$el->SetChecked(delete $fields{$n});
	}
	$self->SUPER::set_fields(%fields);
}

=head2 $mech->qi($elem, $interface)

Queries interface Mozilla::DOM::HTML$interfaceElement of C<$elem>.

=cut
sub qi {
	confess "# No element" unless $_[1];
	my $cl = 'Mozilla::DOM::HTML' . ($_[2] || '') . "Element";
	return $_[1]->QueryInterface($cl->GetIID);
}

=head2 $mech->qi_ns($elem, $interface)

Queries interface Mozilla::DOM::NSHTML$interfaceElement of C<$elem>.

=cut
sub qi_ns {
	confess "# No element" unless $_[1];
	my $c = "Mozilla::DOM::NSHTML" . ($_[2] || "") . "Element";
	return $_[1]->QueryInterface($c->GetIID);
}

1;

=head1 AUTHOR

Boris Sukholitko <boriss@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Mozilla::Mechanize|Mozilla::Mechanize>

=cut

