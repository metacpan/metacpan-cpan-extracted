# -*- perl -*-
#	callback.t - Test script for Term::ReadLine:GNU callback function
#
#	$Id: callback.t 521 2016-05-19 06:39:31Z hayashi $
#
#	Copyright (c) 1999-2016 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

use strict;
use warnings;
use Test::More tests => 8;

# redefine Test::Mode::note due to it requires Perl 5.10.1.
no warnings 'redefine';
sub note {
    my $msg = join('', @_);
    $msg =~ s{\n(?!\z)}{\n# }sg;
    print "# $msg" . ($msg =~ /\n$/ ? '' : "\n");
}
use warnings 'redefine';

BEGIN {
    $ENV{PERL_RL} = 'Gnu';	# force to use Term::ReadLine::Gnu
}

# 'define @ARGV' is deprecated
my $verbose = scalar @ARGV && ($ARGV[0] eq 'verbose');

use Term::ReadLine;
ok(1, 'load done');

########################################################################
# test new method

my $term = new Term::ReadLine 'ReadLineTest';
isa_ok($term, 'Term::ReadLine');
my $attribs = $term->Attribs;
isa_ok($attribs, 'Term::ReadLine', 'Attribs');

my ($version) = $attribs->{library_version} =~ /(\d+\.\d+)/;

########################################################################
# check Tk is installed and X Window is available
{
    if (eval "use Tk; 1" && $ENV{DISPLAY} && $ENV{DISPLAY} ne '') {
	ok(1, 'use Tk');
    } else {
	diag 'skipped since Tk is not available.';
	ok(1, 'skipped since Tk is not available') for 1..5;
	exit 0;
    }
}

########################################################################
# setup IO stream
my ($IN, $OUT);
if ($verbose) {
    # wait for Perl Tk script from tty
    $IN = $attribs->{instream};
    $OUT = $attribs->{outstream};
} else {
    # non-interactive test
    # to surpress warning on GRL 4.2a (and above?).
    $attribs->{prep_term_function} = sub {} if ($version > 4.1);

    $attribs->{instream} = $IN = \*DATA;
    open(NULL, '>/dev/null') or die "cannot open \`/dev/null\': $!\n";
    $attribs->{outstream} = $OUT = \*NULL;
}

########################################################################
my $mw;
$mw = eval { new MainWindow; };
isa_ok($mw, 'MainWindow') or die "Cannot continue...\n";

# create file event handler
$mw->fileevent($IN, 'readable', $attribs->{callback_read_char});
ok(1, 'callback_read_char');

$term->callback_handler_install("> ", sub {
    my $line = shift;
    quit() unless defined $line;

    note $line unless $verbose;
    eval $line;
    print $OUT "$@\n" if $@;
});
# skip not to overwrite command prompt in the verbose mode
ok(1, 'callback_handler_install') unless $verbose;

# create Window Manager Delete Window ClientMessage event handler
$mw->protocol('WM_DELETE_WINDOW' => \&quit);

&MainLoop;

sub quit {
    note 'quitting...';

    # delayed.  See above.
    ok(1, 'callback_handler_install') if $verbose;

    # delete event handler
    $mw->fileevent($IN, 'readable', '');
    $term->callback_handler_remove();
    $mw->destroy;
    ok(1, 'callback_handler_remove and destroy');

    unless ($verbose) {
	# Be quiet during CPAN Testers testing.
	diag "Try \`$^X -Mblib t/callback.t verbose\', if you will.\n"
	    if (!$ENV{AUTOMATED_TESTING});
    }
    exit 0;
}

__END__
$b=$mw->Button(-text=>'hello',-command=>sub{print $OUT 'hello'})
$b->pack;
