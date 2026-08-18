use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }

######################################################################
#
# eg/setup_wizard.pl - edit a key=value configuration file in a form
#
#     perl -Ilib eg/setup_wizard.pl [CONFIGFILE]
#
# This is the job TUI::Handy was written for.  A setup wizard has to run
# on the machine being set up, which is exactly the machine where nothing
# is installed yet: no CPAN, no compiler, no ncurses.  Here the whole
# wizard is one text block plus a read and a write.
#
# Note the two-argument open() and the bareword filehandles: this file,
# like the rest of the distribution, is written to run on Perl 5.005_03.
#
######################################################################

use lib 'lib';
use TUI::Handy;

my $file = defined($ARGV[0]) ? $ARGV[0] : 'tui_handy_demo.conf';

# The screen.  Field widths are set by the number of characters between
# the brackets, so the form is sized by drawing it.
my $dsl = <<'FORM';
Application setup
Host:     [______________________________]
Port:     [#####]
User:     [____________________]
Log dir:  [______________________________]
--------------------------------------------
[ ] Enable debug log

Startup:
(*) Manual
( ) Automatic
--------------------------------------------
[Save]
[Cancel]
FORM

# Which form key each configuration key maps to.  Keeping the map explicit
# means the configuration file format is not hostage to the wording on the
# screen.
my @KEYMAP = (
    ['host',    'Host'],
    ['port',    'Port'],
    ['user',    'User'],
    ['logdir',  'Log dir'],
    ['debug',   'Enable debug log'],
    ['startup', 'Startup'],
);

my %conf = read_conf($file);

my $tui = TUI::Handy->new(dsl => $dsl);

# Preset the form from the file.  set() understands all three widget
# kinds: a string for a text box, 0/1 for a checkbox, and the label of the
# wanted member for a radio group.
for my $pair (@KEYMAP) {
    my ($ckey, $fkey) = @{$pair};
    next unless defined $conf{$ckey};
    if ($ckey eq 'debug') {
        $tui->set($fkey, ($conf{$ckey} eq 'yes') ? 1 : 0);
    }
    else {
        $tui->set($fkey, $conf{$ckey});
    }
}

$tui->set('Save',   sub { 1 });
$tui->set('Cancel', sub { 1 });

my $form = $tui->run;

unless (defined($tui->pressed) && ($tui->pressed eq 'Save')) {
    print "cancelled; $file left unchanged\n";
    exit 0;
}

for my $pair (@KEYMAP) {
    my ($ckey, $fkey) = @{$pair};
    my $value = $form->{$fkey};
    $value = '' unless defined $value;
    if ($ckey eq 'debug') {
        $value = $value ? 'yes' : 'no';
    }
    $conf{$ckey} = $value;
}

write_conf($file, { %conf });
print "wrote $file\n";

######################################################################
# Configuration file I/O.  The format is one key=value per line, with #
# comments and blank lines ignored.
######################################################################

sub read_conf {
    my ($path) = @_;
    my %c = ();
    local *IN;
    open(IN, $path) or return %c;
    while (<IN>) {
        s/\r?\n\z//;
        next if /^\s*#/;
        next if /^\s*$/;
        next unless /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/;
        $c{$1} = $2;
    }
    close(IN);
    return %c;
}

sub write_conf {
    my ($path, $conf) = @_;
    local *OUT;
    open(OUT, ">$path") or die "Can't write $path: $!\n";
    print OUT "# written by eg/setup_wizard.pl\n";
    for my $pair (@KEYMAP) {
        my $ckey = $pair->[0];
        my $value = defined($conf->{$ckey}) ? $conf->{$ckey} : '';
        print OUT "$ckey=$value\n";
    }
    close(OUT);
    return;
}

__END__
