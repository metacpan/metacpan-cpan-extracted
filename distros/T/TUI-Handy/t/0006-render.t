use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/0006-render.t - _render_frame() is a pure function returning the whole
# screen as one byte string, so the layout is testable without a terminal.

use lib 'lib', 't/lib';
use INA_CPAN_Check;

require TUI::Handy;
$TUI::Handy::ENCODING = 'utf8';
$TUI::Handy::ENCODING = $TUI::Handy::ENCODING;  # silence 'used only once' under -w

my $ESC = "\e";

my $dsl = <<'FORM';
Registration
Company: [______]
[X] Ship
(*) Cash
[OK]
FORM

my $t = TUI::Handy->new(dsl => $dsl);
$t->set('Company', 'ACME');
my $frame = $t->_render_frame;

my @tests = (
    sub { ok(defined $frame && $frame ne '', 'render returns a non-empty string') },
    sub { ok(index($frame, $ESC . '[H') == 0, 'frame starts with cursor-home') },
    sub { ok(index($frame, 'Registration') >= 0, 'heading text is rendered') },
    sub { ok(index($frame, 'Company') >= 0, 'text label is rendered') },
    sub { ok(index($frame, 'ACME') >= 0, 'text value is rendered') },
    sub { ok(index($frame, '[X]') >= 0, 'checked box shows X') },
    sub { ok(index($frame, '(*)') >= 0, 'selected radio shows star') },
    sub { ok(index($frame, 'OK') >= 0, 'button label is rendered') },
    sub { ok(index($frame, $ESC . '[7m') >= 0, 'focused widget is reverse-video') },
    sub {
        # The field body is padded to the interior width (6 columns).
        my ($w) = grep { $_->{kind} eq 'text' } @{$t->{widgets}};
        my $body = $t->_field_body($w);
        ok(TUI::Handy::_width($body, 'utf8') == $w->{iw}, 'field body padded to interior width');
    },
);

plan_tests(scalar(@tests));
for my $x (@tests) {
    $x->();
}
