use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/0005-event.t - _handle_event drives focus movement, editing and button
# presses with no real terminal, so the interaction logic of the full-screen
# ANSI driver is testable in isolation.
#
# The button tests are the ANSI half of the handler contract that
# t/0007-line-driver.t checks for the line-oriented driver: a handler
# returning true closes the form, one returning false leaves it open with
# everything already entered still in place, and pressed() is set only by a
# press that actually closed the form -- so a form abandoned with ESC after a
# refused press reports no button at all.

use lib 'lib', 't/lib';
use INA_CPAN_Check;

require TUI::Handy;
$TUI::Handy::ENCODING = 'utf8';
$TUI::Handy::ENCODING = $TUI::Handy::ENCODING;  # silence 'used only once' under -w

my $dsl = <<'FORM';
Name: [______]
[ ] Ship

Payment:
(*) Cash
( ) Card
[OK]
FORM

sub cur {
    my $t = shift;
    return $t->{widgets}[ $t->{focus}[ $t->{fi} ] ];
}

my @tests = (
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        ok(cur($t)->{kind} eq 'text', 'focus starts on the first field');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->_handle_event(['key', 'TAB']);
        ok(cur($t)->{kind} eq 'check', 'TAB moves focus forward');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->_handle_event(['key', 'TAB']);
        $t->_handle_event(['key', 'STAB']);
        ok(cur($t)->{kind} eq 'text', 'Shift-TAB moves focus back');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->_handle_event(['char', 'H']);
        $t->_handle_event(['char', 'i']);
        ok($t->form->{'Name'} eq 'Hi', 'typing into a text field');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->_handle_event(['char', 'A']);
        $t->_handle_event(['key', 'BS']);
        ok($t->form->{'Name'} eq '', 'Backspace key deletes a character');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->_handle_event(['key', 'TAB']);        # to checkbox
        $t->_handle_event(['char', ' ']);         # space toggles
        ok($t->form->{'Ship'} == 1, 'Space toggles a checkbox');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->_handle_event(['key', 'TAB']);        # checkbox
        $t->_handle_event(['key', 'TAB']);        # radio Cash
        $t->_handle_event(['key', 'TAB']);        # radio Card
        $t->_handle_event(['char', ' ']);         # select
        ok($t->form->{'Payment'} eq 'Card', 'Space selects a radio button');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->_handle_event(['key', 'ESC']);
        ok($t->{aborted} == 1 && $t->{done} == 1, 'ESC aborts the form');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('OK', sub { 1 });                 # returning true closes
        $t->{fi} = $#{$t->{focus}};               # jump to the last widget (OK)
        $t->_handle_event(['char', ' ']);
        ok($t->{done} == 1 && $t->pressed eq 'OK', 'pressing OK closes the form');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('OK', sub { 1 });
        $t->{fi} = $#{$t->{focus}};
        $t->_handle_event(['key', 'ENTER']);
        ok($t->{done} == 1 && $t->pressed eq 'OK', 'Enter presses a button too');
    },
    sub {
        # No handler registered: the press submits and closes.
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->{fi} = $#{$t->{focus}};
        $t->_handle_event(['key', 'ENTER']);
        ok($t->{done} == 1 && $t->pressed eq 'OK',
           'a button with no handler submits and closes');
    },
    sub {
        # A handler returning false asks for the form to stay open.  The
        # line-oriented driver honours this as well; see t/0007-line-driver.t.
        my $t = TUI::Handy->new(dsl => $dsl);
        my $fired = 0;
        $t->set('OK', sub { $fired++; 0 });
        $t->{fi} = $#{$t->{focus}};
        $t->_handle_event(['char', ' ']);
        ok($fired == 1 && $t->{done} == 0 && !defined($t->pressed),
           'a refused press leaves the form open and pressed() unset');
    },
    sub {
        # The regression this test exists for: a press the handler refused,
        # followed by ESC.  pressed() must stay undefined, or a caller that
        # checks it would act on data the handler rejected.
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('OK', sub { 0 });
        $t->{fi} = $#{$t->{focus}};
        $t->_handle_event(['char', ' ']);
        $t->_handle_event(['key', 'ESC']);
        ok($t->{aborted} == 1 && !defined($t->pressed),
           'ESC after a refused press still reports no button');
    },
    sub {
        # Everything typed survives a refused press, so the user can correct
        # one field rather than start again.
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('OK', sub { 0 });
        $t->_handle_event(['char', 'H']);
        $t->_handle_event(['char', 'i']);
        $t->{fi} = $#{$t->{focus}};
        $t->_handle_event(['char', ' ']);
        ok($t->form->{'Name'} eq 'Hi', 'a refused press keeps the entered values');
    },
    sub {
        # close_form() closes even though the handler returns false, and the
        # press is recorded because it did close the form.
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->set('OK', sub { my ($form, $self) = @_; $self->close_form; 0 });
        $t->{fi} = $#{$t->{focus}};
        $t->_handle_event(['char', ' ']);
        ok($t->{done} == 1 && defined($t->pressed) && $t->pressed eq 'OK',
           'close_form() from a handler closes and records the press');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        my $n = scalar(@{$t->{focus}});
        for (my $i = 0; $i < $n; $i++) {
            $t->_handle_event(['key', 'TAB']);
        }
        ok($t->{fi} == 0, 'focus ring wraps around');
    },
    sub {
        my $t = TUI::Handy->new(dsl => $dsl);
        $t->_handle_event(['key', 'ESC']);
        ok($t->{done} == 1 && $t->{aborted} == 1, 'ESC aborts and closes the form');
    },

    # A form of nothing but headings has an empty focus ring.  ESC has to work
    # there too: _read_key() reports end of input as ESC as well, so if the
    # empty ring swallowed it the run loop would have no way to end at all and
    # would spin forever with the terminal still in cbreak mode.
    sub {
        my $t = TUI::Handy->new(dsl => "Notice\nNothing to fill in.\n");
        ok(scalar(@{$t->{focus}}) == 0, 'a form of headings has an empty focus ring');
    },
    sub {
        my $t = TUI::Handy->new(dsl => "Notice\nNothing to fill in.\n");
        $t->_handle_event(['key', 'ESC']);
        ok($t->{done} == 1 && $t->{aborted} == 1,
           'ESC closes a form with nothing to focus');
    },
    sub {
        my $t = TUI::Handy->new(dsl => "Notice\nNothing to fill in.\n");
        for my $ev (['key', 'TAB'], ['key', 'ENTER'], ['char', 'x'], ['char', ' ']) {
            $t->_handle_event($ev);
        }
        ok($t->{done} == 0, 'other events on an empty focus ring do nothing');
    },
    sub {
        # Rendering an empty focus ring must not compare against undef.
        my $t = TUI::Handy->new(dsl => "Notice\nNothing to fill in.\n");
        my $warn = '';
        local $SIG{__WARN__} = sub { $warn .= $_[0] };
        my $frame = $t->_render_frame;
        ok(($warn eq '' && $frame =~ /Notice/) ? 1 : 0,
           'an empty focus ring renders without warnings');
    },
);

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
