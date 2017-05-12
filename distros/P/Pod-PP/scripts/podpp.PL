# -*- perl -*-

use strict;
use Config;
use File::Basename qw(basename dirname);
use Cwd;

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
my $origdir = cwd;
chdir dirname($0);
my $script = basename($0, '.PL');
$script .= '.com' if $^O eq 'VMS';

unlink($script);
open OUT, ">$script" or die "open for writing $script: $!";

print OUT <<"!GROK!THIS!";
$Config{startperl}
    eval 'exec $Config{perlpath} -S \$0 \${1+"\$@"}'
	if \$running_under_some_shell;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
	
#
# $Id: podpp.PL,v 0.1 2001/04/25 10:41:49 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: podpp.PL,v $
# Revision 0.1  2001/04/25 10:41:49  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

use FindBin qw($Bin);
use lib "$Bin/wild_lib";

use Log::Agent;
logconfig(-prefix => $0);

use Getopt::Long;
Getopt::Long::config(qw(no_ignore_case));

my @include;
my %defs;
my $output;

fix_DUI();
&usage unless GetOptions(
	'h|help'		=> \&usage,
	'o|output=s'	=> \$output,
	'I=s'			=> \&arg_I,
	'D=s'			=> \&arg_D,
	'U=s'			=> \&arg_U,
);

#
# Argument processing
#
# Fills in @include and %defs, for -I and -D args.
# -U args are processed by making sure the item is not listed in %defs
# Arguments are parsed left to right

sub arg_I {
	my ($option, $value) = @_;
	unless (-d $value) {
		logwarn "ignoring -I $value";
		return;
	}
	push(@include, $value);
}

sub arg_D {
	my ($option, $value) = @_;
	if ($value =~ /^\w+$/) {
		$defs{$value} = '';
		return;
	} elsif ($value =~ /^(\w+)=(.*)/) {
		$defs{$1} = $2;
		return;
	}
	logwarn "ignoring -D $value";
}

sub arg_U {
	my ($option, $value) = @_;
	unless ($value =~ /^\w+$/) {
		logwarn "ignoring -U $value";
		return;
	}
	delete $defs{$value};
}

#
# fix_DUI
#
# Fix @ARGV in place
# Each -D, -U or -I followed by text is separated from the following
# text for Getopt::Long to properly parse them. Otherwise, it will
# complain that DFOO is not an option when faced with -DFOO=BAR
#
sub fix_DUI {
	for (my $i = 0; $i < @ARGV; $i++) {
		my $arg = $ARGV[$i];
		last if $arg eq '--';			# End of options
		if ($arg =~ /^(-[DUI])(.+)/) {
			my ($opt, $param) = ($1, $2);
			splice(@ARGV, $i, 1, $opt, $param);
			$i++;	# Skip inserted argument
		}
	}
}

sub usage {
	print STDERR <<EOM;
Usage: podpp [-h] [-I dir] [-D sym[=val]] [-U sym] [-o file] [files]
  -D : set symbol value
  -I : set include directory
  -U : undefine symbol
  -h/help   : show this help message
  -o/output : define output file (default is stdout)
EOM
	exit 1;
}

require Pod::PP;

my $parser = Pod::PP->make(
	-incpath	=> \@include,
	-symbols	=> \%defs,
);

if (defined $output) {
	open STDOUT, ">$output" or logdie "can't create $output: $!";
}

$parser->parse_from_filehandle(\*STDIN) unless @ARGV;
foreach my $file (@ARGV) {
	$parser->parse_from_file($file);
}

=head1 NAME

podpp - POD pre-processor

=head1 SYNOPSIS

B<podpp> S<[B<-h>]>
S<[B<-I> I<dir>]>
S<[B<-D> I<sym>[=I<val>]]>
S<[B<-U> I<sym>]>
S<[B<-o> I<file>]>
S<[I<file1>, I<file2>, ...]>

=head1 DESCRIPTION

B<podpp> is a pre-processor for POD, implemented on top of
the C<Pod::PP> module.  You should refer to L<Pod::PP> for the supported
POD directives, since this manpage only documents the pre-processor script.

B<podpp> either takes a list of files from the command line or reads
from STDIN.  The output is emitted to STDOUT or to a single file, as one
big happy stream.

=head1 OPTIONS

The following options are supported:

=over 4

=item B<-D> I<sym>[=I<val>]

Defines symbol I<sym>.  If I<val> is specified, the symbol I<sym> is set
to that value, otherwise it is marked defined but will not expand to anything.

You may choose to leave a space between C<-D> and I<sym> if you wish.
For instance:

	-DSYMBOL
	-DSYMBOL=simple_value
	-D SYMBOL
	-D SYMBOL='string with spaces'

You may give as many C<-D> switches as you want.

=item B<-I> I<dir>

Appends I<dir> to the include search path.  The space between C<-I> and
I<dir> is optional, as in:

	-I.. -I ../h

You may give as many C<-I> switches as necessary.  The include search path
is initially limited to C<".">, i.e. files to be included are located from the
place where the file making the inclusion lies.

=item B<-U> I<sym>

Undefines symbol I<sym>.

=item B<-h>

Prints a summary of the command line options.

=item B<-o> I<file>

Redirect output to named I<file>, instead of regular STDOUT.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Pod::PP(3).

=cut

!NO!SUBS!

close OUT or die "Can't close $script: $!";
chmod 0755, $script or die "Can't reset permissions for $script: $!\n";
exec("$Config{'eunicefix'} $script") if $Config{'eunicefix'} ne ':';
chdir $origdir;
