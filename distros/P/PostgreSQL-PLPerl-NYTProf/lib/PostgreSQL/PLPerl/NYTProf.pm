package PostgreSQL::PLPerl::NYTProf;
BEGIN {
  $PostgreSQL::PLPerl::NYTProf::VERSION = '1.002';
}

# vim: ts=8 sw=4 expandtab:

=head1 NAME

PostgreSQL::PLPerl::NYTProf - Profile PostgreSQL PL/Perl functions with Devel::NYTProf

=head1 VERSION

version 1.002

=head1 SYNOPSIS

Load via the C<PERL5OPT> environment variable:

    $ PERL5OPT='-MPostgreSQL::PLPerl::NYTProf' pg_ctl restart

or load via your C<postgres.conf> file:

    custom_variable_classes = 'plperl'
    plperl.on_init = 'use PostgreSQL::PLPerl::NYTProf;'

and restart the server.

Then run some PL/Perl code:

    $ psql -c "do 'sub w { } w() for 1..100_000' language plperl" template1

which will create a nytprof.out.I<PID> file in the C<$PGDATA> directory,
where I<PID> is the process id of the postgres backend.

Finally, run C<nytprofhtml> to generate a report, for example:

    $ nytprofhtml --file $PGDATA/nytprof.out.54321 --open

=head1 DESCRIPTION

Profile PL/Perl functions inside PostgreSQL database with L<Devel::NYTProf>. 

PostgreSQL 9.0 or later is required.

=head1 ENABLING

In order to use this module you need to arrange for it to be loaded when
PostgreSQL initializes a Perl interpreter.

=head2 Quick Occasional Use

The C<PERL5OPT> environment variable can be used like this:

    $ PERL5OPT='-MPostgreSQL::PLPerl::NYTProf' pg_ctl restart

This will be effective for any pg_ctl command that restarts the postmaster
process, so C<restart> will work but C<reload> won't.

The profiler will remain enabled until the the postmaster process is restarted.

=head2 Via postgres.conf

You can simply add a C<use> statement to your F<postgres.conf> file:

    plperl.on_init='use PostgreSQL::PLPerl::NYTProf;'

though I'd recommend arranging for PostgreSQL to load a separate
F<plperloninit.pl> file from same directory as your F<postgres.conf> file:

    plperl.on_init='require "plperloninit.pl";'

then you can put whatever Perl statements you want in that file:

    use PostgreSQL::PLPerl::NYTProf;

When it's no longer needed just comment it out by prefixing with a C<#>.

=head1 USAGE

By default the NYTProf profile data files will be written into the database
directory, alongside your F<postgres.conf>, with the process id of the backend
appended to the name. For example F<nytprof.out.54321>.

You'll get one profile data file for each database connection. You can use the
L<nytprofmerge> utility to merge multiple data files if needed.

To generate a report from a data file, use a command like:

  nytprofhtml --file=$PGDATA/nytprof.out.54321 --open

=head1 INTERPRETING REPORTS

PL/Perl functions are given names in perl that include the OID of the PL/Perl
function. So a function created by C<CREATE FUNCTION foo () ...> would appear
in the reports as something like C<main::foo__3762>.

=head1 PROFILE ON DEMAND

The instructions above enable profiling for all database sessions that use PL/Perl.
Instead of profiling all sessions it can be useful to have the profiler loaded
into the server but only enable it for particular sessions.

You can do this by loading setting the C<NYTPROF> environment variable to
include the "C<start=no>" option. Then, to enable profiling for a particular
session you just need to call the C<DB::enable_profile> function. For example:

    do 'DB::enable_profile' language plperl;

See L<Devel::NYTProf/"RUN-TIME CONTROL OF PROFILING">.

The performance impact of loading but not enabling NYTProf should be I<very>
low (though I've not tried measuring it). So, while I wouldn't recommend doing
that on a production instance, it would be fine on a development instance.

=head1 LIMITATIONS

=head2 Can't use plperl and plperlu at the same time

Postgres uses separate Perl interpreters for the plperl and plperlu languages.
NYTProf is not multiplicity safe (as of version 4.05). It should just profile
whichever language was used first and ignore the other, but there may still be
problems in this situation. Let me know if you encounter any odd behaviour.

=head2 PL/Perl functions with unusual names are __ANON__

PL/Perl functions are created as anonymous subroutines in Perl.
PostgreSQL::PLPerl::NYTProf arranges for them to be given names.
The logic currently only works for names that match C</^\w+$/>.

=head1 SEE ALSO

L<Devel::NYTProf>

=head1 AUTHOR

B<Tim Bunce>, L<http://www.tim.bunce.name> and L<http://blog.timbunce.org>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2010 by Tim Bunce.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

use strict;

use Devel::NYTProf::Core;

# set some default options (can be overridden via NYTPROF env var)
DB::set_option("endatexit", 1); # for pg 8.4
DB::set_option("savesrc", 1);
DB::set_option("addpid", 1);
# file defaults to nytprof.out.$pid in $PGDATA directory

my $trace = $ENV{PLPERL_NYTPROF_TRACE} || 0;
my @on_init;
my $mkfuncsrc = "PostgreSQL::InServer::mkfuncsrc";

if (not -f 'postgres.conf') {
    # there's no easy way to tell that we're being loaded into the
    # postgres server when we're loaded via PERL5OPT. This'll do:
    warn __PACKAGE__." not running in postgres server";
}
elsif (defined &{$mkfuncsrc}) {
    # We were probably loaded via plperloninit.pl
    fix_mkfuncsrc();
}
else {
    # We were probably loaded via PERL5OPT='-M...' and so we're executing very
    # early, before mkfuncsrc has even been defined.
    # So we need to defer wrapping it until later.
    # We do that by wrapping  PostgreSQL::InServer::Util::bootstrap
    # But that doesn't exist yet either. Happily it will do a INIT time
    # so we arrange to wrap it then. Got that?
    push @on_init, sub {
        hook_after_sub("PostgreSQL::InServer::Util::bootstrap", \&fix_mkfuncsrc);
    };
}


sub fix_mkfuncsrc {

    # wrap mkfuncsrc with code that edits the returned code string
    # such that the code will give a name to the subroutine it defines.

    hook_after_sub("PostgreSQL::InServer::mkfuncsrc", sub {
        my ($argref, $code) = @_;
        my ($name, $imports, $prolog, $src) = @$argref;

        # $code = qq[ package main;  sub { $BEGIN $prolog $src } ];
        # XXX escape $name or extract from $code and use single quotes
        $code =~ s/\b sub \s* {(.*)} \s* $/sub $name { $1 }; \\&$name/sx
                or warn "Failed to edit sub name in $code"
            if $name =~ /^\w+$/; # XXX just sane names for now

        return $code;
    });
}


sub hook_after_sub {
    my ($sub, $code, $force) = @_;

    warn "Wrapping $sub\n" if $trace;
    my $orig_sub = (defined &{$sub}) && \&{$sub};
    if (not $orig_sub and not $force) {
        warn "hook_after_sub: $sub isn't defined\n";
        return;
    }

    my $wrapped = sub {
        warn "Wrapped $sub(@_) called\n" if $trace;
        my @ret;
        if ($orig_sub) {
            # XXX doesn't handle context
            # XXX the 'package main;' here is a hack to make
            # PostgreSQL::InServer::Util::bootstrap do the right thing
            @ret = do { package main;
BEGIN {
  $main::VERSION = '1.002';
} $orig_sub->(@_) };
        }
        return $code->( [ @_ ], @ret );
    };

    no warnings 'redefine';
    no strict;
    *{$sub} = $wrapped;
}


# --- final initialization ---

# give the 'application' a more user-friendly name
$0 = "PostgreSQL Session" if $0 eq '-e';

eval q{ INIT { $_->() for @on_init }; 1 } or die
    if @on_init;

require Devel::NYTProf; # init profiler - DO THIS LAST

__END__