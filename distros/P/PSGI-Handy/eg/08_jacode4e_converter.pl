######################################################################
#
# 08_jacode4e_converter.pl - a Japanese character-code converter,
#                            served by the full four-layer Handy stack
#
# A dependency-free web front-end for Jacode4e::convert(). It wires the
# companion modules together:
#   model  = Jacode4e   (the actual character-code conversion engine)
#   view   = HP::Handy   (Jinja2-style templates, auto-escape)
#   server = HTTP::Handy (PSGI delivery layer)
# all glued by PSGI::Handy. As in eg/04 and eg/07, HP::Handy exposes
# render_string (not render), so it is injected through a CODE renderer;
# $c->render then works as in any PSGI::Handy app.
#
# It converts text between EVERY encoding Jacode4e supports: the PC
# encodings (CP932 family, Shift_JIS-2004, UTF-8 family) and the
# mainframe encodings (KEIS78/83/90, JEF, JIPS, CP00930, LetsJ).
#
# Two input modes are offered. "text" takes the UTF-8 octets typed into
# the form as-is (use this with a UTF-8 source). "hex" decodes a string
# of hex digits into raw bytes first, which is how you feed the raw
# bytes of a mainframe or Shift_JIS source that you cannot type. The
# result is always shown as a hex dump with byte and character counts;
# when the target is a UTF-8 family encoding the decoded text is shown
# as well. OUTPUT_SHIFTING (SO/SI around DBCS runs) and INPUT_LAYOUT
# (an 'S'/'D' sequence for shiftless mainframe input) are exposed so the
# round-trip subtleties of the mainframe encodings can be explored.
#
# Run: perl -Ilib eg/08_jacode4e_converter.pl
# Then open http://127.0.0.1:8080/ and convert, e.g., UTF-8 "kanji" to
# KEIS90 with output shift codes, then paste the hex back as a KEIS90
# source to confirm the round trip.
#
# Demonstrates:
#   PSGI::Handy new(renderer=>CODE)/get/post/to_app, Context render/param/
#   req->method, one handler shared by GET and POST, HP::Handy
#   render_string with for/if and the | safe filter, and Jacode4e::convert
#   across all supported encodings with OUTPUT_SHIFTING / INPUT_LAYOUT.
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use PSGI::Handy;
use HTTP::Handy;   # delivery layer (any PSGI server works)
use HP::Handy;
use Jacode4e;

######################################################################
# Encoding catalogue (display order preserved)
#   each entry: [ mnemonic, human-readable label, group ]
######################################################################
my @ENCODING = (
    [ 'utf8',     'UTF-8 (UTF-8.0)',                 'Unicode'   ],
    [ 'utf8.1',   'UTF-8.1',                         'Unicode'   ],
    [ 'utf8jp',   'UTF-8-SPUA-JP (JIS X 0213 pivot)','Unicode'   ],
    [ 'cp932',    'CP932 / Windows-31J',             'PC'        ],
    [ 'cp932ibm', 'CP932 (IBM)',                     'PC'        ],
    [ 'cp932nec', 'CP932 (NEC)',                     'PC'        ],
    [ 'cp932x',   'CP932X (extended, JIS X 0213)',   'PC'        ],
    [ 'sjis2004', 'Shift_JIS-2004',                  'PC'        ],
    [ 'cp00930',  'IBM CP00930 (CCSID 5026)',        'Mainframe' ],
    [ 'keis78',   'HITACHI KEIS78',                  'Mainframe' ],
    [ 'keis83',   'HITACHI KEIS83',                  'Mainframe' ],
    [ 'keis90',   'HITACHI KEIS90',                  'Mainframe' ],
    [ 'jef',      'FUJITSU JEF (12pt)',              'Mainframe' ],
    [ 'jef9p',    'FUJITSU JEF (9pt)',               'Mainframe' ],
    [ 'jipsj',    'NEC JIPS(J)',                     'Mainframe' ],
    [ 'jipse',    'NEC JIPS(E)',                     'Mainframe' ],
    [ 'letsj',    'UNISYS LetsJ',                    'Mainframe' ],
);

my %IS_ENCODING = map { $_->[0], 1 } @ENCODING;

# Encodings whose output is itself valid UTF-8, so it can be shown as text.
my %TEXTUAL_OUTPUT = ('utf8', 1, 'utf8.1', 1, 'utf8jp', 1);

######################################################################
# View: HP::Handy with an in-memory template registry
######################################################################
my $HP = HP::Handy->new(auto_escape => 1);

my %VIEW = (
    'page.html' => <<'TMPL',
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Jacode4e Web Converter</title>
<style>
 body   { font-family: sans-serif; margin: 1.5em; color: #222; }
 h1     { font-size: 1.4em; }
 .note  { color: #666; font-size: 0.85em; }
 form   { margin-top: 1em; }
 textarea { width: 100%; height: 7em; font-family: monospace; }
 .row   { margin: 0.6em 0; }
 label  { display: inline-block; min-width: 9em; vertical-align: top; }
 select, input[type=text] { font-family: monospace; }
 .err   { color: #b00; font-weight: bold; }
 .out   { background: #f4f4f4; border: 1px solid #ccc; padding: 0.6em;
          white-space: pre-wrap; word-break: break-all; font-family: monospace; }
 table.meta td { padding: 0 1em 0 0; }
</style>
</head>
<body>
<h1>Jacode4e Web Converter</h1>
<p class="note">PSGI::Handy + HTTP::Handy + HP::Handy + Jacode4e &mdash; pure Perl, no external dependencies.</p>

<form method="post" action="/" accept-charset="UTF-8">
  <div class="row">
    <label for="text">Input</label>
    <textarea id="text" name="text">{{ text }}</textarea>
  </div>

  <div class="row">
    <label for="mode">Input is</label>
    <select id="mode" name="mode">
      <option value="text" {{ mode_text_sel }}>text (UTF-8 typed above)</option>
      <option value="hex"  {{ mode_hex_sel }}>hex bytes (e.g. "0A42 B4C1")</option>
    </select>
    <span class="note">Use hex to feed raw bytes of a mainframe / Shift_JIS source.</span>
  </div>

  <div class="row">
    <label for="src">From encoding</label>
    <select id="src" name="src">{{ src_options | safe }}</select>
  </div>

  <div class="row">
    <label for="dst">To encoding</label>
    <select id="dst" name="dst">{{ dst_options | safe }}</select>
  </div>

  <div class="row">
    <label for="shifting">Output shift codes</label>
    <input type="checkbox" id="shifting" name="shifting" value="1" {{ shifting_chk }}>
    <span class="note">SO/SI around DBCS runs (needed for round-trippable KEIS/JEF/JIPS).</span>
  </div>

  <div class="row">
    <label for="layout">INPUT_LAYOUT</label>
    <input type="text" id="layout" name="layout" value="{{ layout }}" size="30">
    <span class="note">Optional. 'S'/'D' sequence, e.g. S4D2. Use when a shiftless mainframe source needs a record layout.</span>
  </div>

  <div class="row">
    <label>&nbsp;</label>
    <input type="submit" value="Convert">
  </div>
</form>

{% if has_result %}
<hr>
{% if error %}
<p class="err">Conversion error: {{ error }}</p>
{% else %}
<h2>Result</h2>
<table class="meta">
  <tr><td>Characters converted</td><td>{{ char_count }}</td></tr>
  <tr><td>Input bytes</td><td>{{ in_bytes }}</td></tr>
  <tr><td>Output bytes</td><td>{{ out_bytes }}</td></tr>
  <tr><td>From &rarr; To</td><td>{{ src }} &rarr; {{ dst }}</td></tr>
</table>

{% if show_text %}
<h3>Output as text</h3>
<div class="out">{{ out_text }}</div>
{% endif %}

<h3>Output (hex dump)</h3>
<div class="out">{{ out_hex }}</div>

<h3>Input (hex dump)</h3>
<div class="out">{{ in_hex }}</div>
{% endif %}
{% endif %}

</body>
</html>
TMPL
);

my $RENDERER = sub {
    my ($name, $vars) = @_;
    my $src = $VIEW{$name};
    die "no such template: $name\n" unless defined $src;
    return $HP->render_string($src, $vars);
};

######################################################################
# Helpers
######################################################################

# Build the <option> list for a <select>, marking $selected.
sub _options {
    my ($selected) = @_;
    my $html = '';
    my $last_group = '';
    my $e;
    for $e (@ENCODING) {
        my ($mnemonic, $label, $group) = @$e;
        if ($group ne $last_group) {
            $html .= '</optgroup>' if $last_group ne '';
            $html .= '<optgroup label="' . _esc($group) . '">';
            $last_group = $group;
        }
        my $sel = (defined $selected && $selected eq $mnemonic) ? ' selected' : '';
        $html .= '<option value="' . _esc($mnemonic) . '"' . $sel . '>'
               . _esc($mnemonic) . ' &mdash; ' . _esc($label) . '</option>';
    }
    $html .= '</optgroup>' if $last_group ne '';
    return $html;
}

sub _esc {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
}

# Format a byte string as an offset / hex / ascii dump (16 bytes a line).
sub _hexdump {
    my ($bytes) = @_;
    return '(empty)' if !defined($bytes) || length($bytes) == 0;
    my $out = '';
    my $len = length($bytes);
    my $offset = 0;
    while ($offset < $len) {
        my $chunk = substr($bytes, $offset, 16);
        my $hex   = '';
        my $ascii = '';
        my $i;
        for ($i = 0; $i < 16; $i++) {
            if ($i < length($chunk)) {
                my $c = ord(substr($chunk, $i, 1));
                $hex   .= sprintf('%02X ', $c);
                $ascii .= ($c >= 0x20 && $c <= 0x7E) ? chr($c) : '.';
            }
            else {
                $hex .= '   ';
            }
            $hex .= ' ' if $i == 7;
        }
        $out .= sprintf("%06X  %s |%s|\n", $offset, $hex, $ascii);
        $offset += 16;
    }
    return $out;
}

# Decode a user-supplied hex string into raw bytes. Ignores whitespace
# and an optional leading "0x". Dies on odd length or a bad nibble.
sub _hex_to_bytes {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/0x//gi;
    $s =~ s/\s+//g;
    return '' if $s eq '';
    if ($s =~ /[^0-9A-Fa-f]/) {
        die "input contains a non-hex character\n";
    }
    if (length($s) % 2 != 0) {
        die "hex input has an odd number of digits\n";
    }
    return pack('H*', $s);
}

######################################################################
# Application
######################################################################
my $app = PSGI::Handy->new(renderer => $RENDERER);

# One handler shared by GET (empty form) and POST (form plus result).
sub _handle {
    my ($c) = @_;

    my $text     = $c->param('text');
    my $mode     = $c->param('mode');
    my $src      = $c->param('src');
    my $dst      = $c->param('dst');
    my $shifting = $c->param('shifting');
    my $layout   = $c->param('layout');

    $text   = '' unless defined $text;
    $mode   = 'text' unless defined $mode && $mode eq 'hex';
    $src    = 'utf8'   unless defined $src && $IS_ENCODING{$src};
    $dst    = 'keis90' unless defined $dst && $IS_ENCODING{$dst};
    $layout = '' unless defined $layout;
    my $do_shift = (defined $shifting && $shifting eq '1') ? 1 : 0;

    my %vars = (
        text          => $text,
        layout        => $layout,
        mode_text_sel => ($mode eq 'text' ? 'selected' : ''),
        mode_hex_sel  => ($mode eq 'hex'  ? 'selected' : ''),
        shifting_chk  => ($do_shift ? 'checked' : ''),
        src_options   => _options($src),
        dst_options   => _options($dst),
        has_result    => 0,
        error         => '',
    );

    # Convert only on a POST that actually carries input.
    my $has_input = ($c->req->method() eq 'POST') && length($text) > 0;

    if ($has_input) {
        $vars{has_result} = 1;

        # Build the raw source byte string.
        my $in_bytes;
        eval {
            if ($mode eq 'hex') {
                $in_bytes = _hex_to_bytes($text);
            }
            else {
                $in_bytes = $text;   # raw UTF-8 octets from the form body
            }
        };
        if ($@) {
            my $msg = $@; $msg =~ s/\s+\z//;
            $vars{error} = $msg;
            return $c->render('page.html', { %vars });
        }

        # Convert in place. Jacode4e dies on an unknown encoding and on an
        # unmappable character, so guard the call with eval.
        my $work = $in_bytes;
        my $count;
        my %opt;
        $opt{OUTPUT_SHIFTING} = 1 if $do_shift;
        $opt{INPUT_LAYOUT}    = $layout if $layout ne '';

        eval {
            $count = Jacode4e::convert(\$work, $dst, $src, { %opt });
        };
        if ($@) {
            my $msg = $@; $msg =~ s/\s+\z//;
            $vars{error} = $msg;
            return $c->render('page.html', { %vars });
        }

        $vars{char_count} = defined $count ? $count : 0;
        $vars{in_bytes}   = length($in_bytes);
        $vars{out_bytes}  = length($work);
        $vars{src}        = $src;
        $vars{dst}        = $dst;
        $vars{in_hex}     = _hexdump($in_bytes);
        $vars{out_hex}    = _hexdump($work);

        if ($TEXTUAL_OUTPUT{$dst}) {
            $vars{show_text} = 1;
            $vars{out_text}  = $work;   # valid UTF-8; auto-escaped by HP::Handy
        }
        else {
            $vars{show_text} = 0;
            $vars{out_text}  = '';
        }
    }

    return $c->render('page.html', { %vars });
}

$app->get('/',  \&_handle);
$app->post('/', \&_handle);

$app->get('/health', sub {
    my $c = shift;
    return $c->text("ok\n");
});

my $psgi = $app->to_app;
HTTP::Handy->run(app => $psgi, host => '127.0.0.1', port => 8080);
