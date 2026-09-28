package NoDoubleQuote;

#
# Refuse a double quote in any argument of a list "cmd" or "wrapper" before a
# test hands it to task() or parallel().
#
# On MSWin32 system(LIST) joins its arguments into one command line, wrapping
# any with a space in double quotes but not escaping the quotes inside, so a
# child perl given -e code with a double quote in it runs a different program
# (t/03.fixes.t's header has the first case). 0.19's t/05.features.t and
# t/07.coverage.t each passed such code, and failed only on a Strawberry Perl
# 5.42.0 smoker. Checking here makes the same mistake fail on every platform,
# where it can be seen before an upload. A string "cmd" is not checked: it is
# a command line already, and its quotes are meant for the shell.
#

use strict;
use warnings FATAL => 'all';
require 5.010;
use Exporter 'import';
our @EXPORT_OK = ('refuse_double_quotes');

# @args is what task() or parallel() is about to be given: a hash ref, or a
# flat key/value list, whose "tasks" (for parallel) are hash refs of their own.
sub refuse_double_quotes {
	my @args = @_;
	# an odd-length list is task()'s own argument error to report, not this
	return if (scalar @args % 2 == 1) && !((scalar @args == 1) && (ref $args[0] eq 'HASH'));
	my %args = ((scalar @args == 1) && (ref $args[0] eq 'HASH')) ? %{ $args[0] } : @args;
	foreach my $key ('cmd', 'wrapper') {
		next unless ref $args{$key} eq 'ARRAY';
		foreach my $i (0 .. $#{ $args{$key} }) {
			my $arg = $args{$key}[$i];
			die "\"$key\" index $i has a double quote, which MSWin32 would garble: $arg\n"
				if defined $arg && $arg =~ /"/;
		}
	}
	if (ref $args{tasks} eq 'ARRAY') {
		refuse_double_quotes($_) foreach grep { ref $_ eq 'HASH' } @{ $args{tasks} };
	}
	return;
}

1;
