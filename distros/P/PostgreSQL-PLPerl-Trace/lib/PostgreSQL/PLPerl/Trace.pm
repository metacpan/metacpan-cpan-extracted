package PostgreSQL::PLPerl::Trace;
our $VERSION = '1.001';

=head1 NAME

PostgreSQL::PLPerl::Trace - Simple way to trace execution of Perl statements in PL/Perl

=head1 VERSION

version 1.001

=head1 SYNOPSIS

Load via a line in your F<plperlinit.pl> file:

    use PostgreSQL::PLPerl::Trace;

Load via the C<PERL5OPT> environment variable:

    $ PERL5OPT='-MPostgreSQL::PLPerl::Trace' pg_ctl ...

=head1 DESCRIPTION

Writes a line to the PostgreSQL log file for every PL/Perl statement executed.
This can generate truly I<massive> amounts of log data and also slows excution
of PL/Perl code by at least a couple of orders of magnitude.

Why would you want to do this? Well, there are times when it's a simple and
effective way to see what PL/Perl code is I<actually> being executed.

This module is based on L<Devel::Trace> but modified to work with PostgreSQL PL/Perl
for both the C<plperlu> language I<and>, more significantly, for the C<plperl>
language as well. It also shows the subroutine name whenever execution moves
from one subroutine to another.

=head1 ENABLING

In order to use this module you need to arrange for it to be loaded when
PostgreSQL initializes a Perl interpreter.

Create a F<plperlinit.pl> file in the same directory as your
F<postgres.conf> file, if it doesn't exist already.

In the F<plperlinit.pl> file write the code to load this module:

    use PostgreSQL::PLPerl::Trace;

When it's no longer needed just comment it out by prefixing with a C<#>.

=head2 PostgreSQL 8.x

Set the C<PERL5OPT> before starting postgres, to something like this:

    PERL5OPT='-e "require q{plperlinit.pl}"'

The code in the F<plperlinit.pl> should also include C<delete $ENV{PERL5OPT};>
to avoid any problems with nested invocations of perl, e.g., via a C<plperlu>
function.

=head2 PostgreSQL 9.0

For PostgreSQL 9.0 you can still use the C<PERL5OPT> method described above.
Alternatively, and preferably, you can use the C<plperl.on_init> configuration
variable in the F<postgres.conf> file.

    plperl.on_init='require q{plperlinit.pl};'

=head2 Alternative Method

It you're not already using the C<PERL5OPT> environment variable to load a
F<plperlinit.pl> file, as described above, then you can use it as a quick way
to load the module for ad-hoc use:

    $ PERL5OPT='-MPostgreSQL::PLPerl::Trace' pg_ctl ...

=head1 AUTHOR

Tim Bunce L<http://www.tim.bunce.name>

Copyright (c) Tim Bunce, Ireland, 2010. All rights reserved.
You may use and distribute on the same terms as Perl 5.10.1.

With thanks to L<http://www.TigerLead.com> for sponsoring development.

=cut

# these are currently undocumented but used by tests
our $TRACE;  $TRACE = 1     unless defined $TRACE;
our $fh;     $fh = \*STDERR unless defined $fh;

my $main_glob = *{"main::"};
my $main_stash = \%{$main_glob}; # get ref to true main glob outside of Safe
my $file_sub_prev = '';

# maybe move core of this to to a new Devel::TraceSafe module

sub DB::DB { # magic sub

    return unless $TRACE;

    my ($p, $f, $l) = caller();

    my $code = \@{"::_<$f"};
    if (!@$code) { # probably inside Safe
        my $glob = $main_stash->{"_<$f"};
        $code = \@{$glob};
    }

    my $sub = (caller(1))[3] || '???';
    my $linesrc = $code->[$l];
    if (!$linesrc) { # should never happen
        my $submsg = $sub ? " for sub $sub" : "";
        $linesrc = "\t(missing src$submsg in $p)";
    }
    chomp $linesrc;

    my $file_sub = "$f/$sub";
    if ($file_sub ne $file_sub_prev) {
        print $fh "-- in $sub:\n" if $sub;
        $file_sub_prev = $file_sub;
    }

    print $fh ">> $f:$l: $linesrc\n";
}


$^P |= 0
    |  0x002  # Line-by-line debugging & save src lines.
    |  0x004  # Switch off optimizations.
#   |  0x008  # Preserve more data for future interactive inspections.
#   |  0x010  # Keep info about source lines on which a subroutine is defined.
    |  0x020  # Start with single-step on.
    |  0x100  # Provide informative "file" names for evals
    |  0x200  # Provide informative names to anonymous subroutines
    |  0x400  # Save source code lines into "@{"_<$filename"}".
    ;

1;

# vim: ts=8:sw=4:et