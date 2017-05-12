package Module::CoreList::More;

our $DATE = '2016-02-17'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;

use Module::CoreList ();

sub _firstidx {
    my ($item, $ary) = @_;
    for (0..@$ary-1) {
       return $_ if $ary->[$_] eq $item;
    }
    -1;
}

# construct our own %delta from Module::CoreList's %delta. our version is a
# linear "linked list" (e.g. %delta{5.017} is a delta against %delta{5.016003}
# instead of %delta{5.016}. also, version numbers are cleaned (some versions in
# Module::CoreList has trailing whitespaces or alphas)

# the same for our own %released (version numbers in keys are canonicalized)

our @releases; # list of perl release versions, sorted by version
our @releases_by_date; # list of perl release versions, sorted by release date
our %delta;
our %released;
my %rel_orig_formats;
{
    # first let's only stored the canonical format of release versions
    # (Module::Core stores "5.01" as well as "5.010000"), for less headache
    # let's just store "5.010000"
    my %releases;
    for (sort keys %Module::CoreList::delta) {
        my $canonical = sprintf "%.6f", $_;
        next if $releases{$canonical};
        $releases{$canonical} = $Module::CoreList::delta{$_};
        $released{$canonical} = $Module::CoreList::released{$_};
        $rel_orig_formats{$canonical} = $_;
    }
    @releases = sort keys %releases;
    @releases_by_date = sort {$released{$a} cmp $released{$b}} keys %releases;

    for my $i (0..@releases-1) {
        my $reldelta = $releases{$releases[$i]};
        my $delta_from = $reldelta->{delta_from};
        my $changed = {};
        my $removed = {};
        # make sure that %delta will be linear "linked list" by release versions
        if ($delta_from && $delta_from != $releases[$i-1]) {
            $delta_from = sprintf "%.6f", $delta_from;
            my $i0 = _firstidx($delta_from, \@releases);
            #say "D: delta_from jumps from $delta_from (#$i0) -> $releases[$i] (#$i)";
            # accumulate changes between delta at releases #($i0+1) and #($i-1),
            # subtract them from delta at #($i)
            my $changed_between = {};
            my $removed_between = {};
            for my $j ($i0+1 .. $i-1) {
                my $reldelta_between = $releases{$releases[$j]};
                for (keys %{$reldelta_between->{changed}}) {
                    $changed_between->{$_} = $reldelta_between->{changed}{$_};
                    delete $removed_between->{$_};
                }
                for (keys %{$reldelta_between->{removed}}) {
                    $removed_between->{$_} = $reldelta_between->{removed}{$_};
                }
            }
            for (keys %{$reldelta->{changed}}) {
                next if exists($changed_between->{$_}) &&
                    !defined($changed_between->{$_}) && !defined($reldelta->{changed}{$_}) || # both undef
                    defined ($changed_between->{$_}) && defined ($reldelta->{changed}{$_}) && $changed_between->{$_} eq $reldelta->{changed}{$_}; # both defined & equal
                $changed->{$_} = $reldelta->{changed}{$_};
            }
            for (keys %{$reldelta->{removed}}) {
                next if $removed_between->{$_};
                $removed->{$_} = $reldelta->{removed}{$_};
            }
        } else {
            $changed = { %{$reldelta->{changed}} };
            $removed = { %{$reldelta->{removed} // {}} };
        }

        # clean version numbers
        for my $k (keys %$changed) {
            for ($changed->{$k}) {
                next unless defined;
                s/\s+$//; # eliminate trailing space
                # for "alpha" version, turn trailing junk such as letters to _
                # plus a number based on the first junk char
                s/([^.0-9_])[^.0-9_]*$/'_'.sprintf('%03d',ord $1)/e;
            }
        }
        $delta{$releases[$i]} = {
            changed => $changed,
            removed => $removed,
        };
    }
}

my $removed_from = sub {
    my ($order, $module) = splice @_,0,2;
    $module = shift if eval { $module->isa(__PACKAGE__) } && @_ > 0 && defined($_[0]) && $_[0] =~ /^\w/;

    for my $rel ($order eq 'date' ? @releases_by_date : @releases) {
        return $rel_orig_formats{$rel} if $delta{$rel}{removed}{$module};
    }

    return;
};

sub removed_from {
    $removed_from->('', @_);
}

sub removed_from_by_date {
    $removed_from->('date', @_);
}

my $first_release = sub {
    my ($order, $module) = splice @_,0,2;
    $module = shift if eval { $module->isa(__PACKAGE__) } && @_ > 0 && defined($_[0]) && $_[0] =~ /^\w/;

    for my $rel ($order eq 'date' ? @releases_by_date : @releases) {
        return $rel_orig_formats{$rel} if exists $delta{$rel}{changed}{$module};
    }

    return;
};

sub first_release {
    $first_release->('', @_);
}

sub first_release_by_date {
    $first_release->('date', @_);
}

my $is_core = sub {
    my $all = pop;
    my $module = shift;
    $module = shift if eval { $module->isa(__PACKAGE__) } && @_ > 0 && defined($_[0]) && $_[0] =~ /^\w/;
    my ($module_version, $perl_version);

    $module_version = shift if @_ > 0;
    $perl_version   = @_ > 0 ? shift : $];

    my $mod_exists = 0;
    my $mod_ver; # module version at each perl release, -1 means doesn't exist

  RELEASE:
    for my $rel (sort keys %delta) {
        last if $all && $rel > $perl_version; # this is the difference with is_still_core()

        my $reldelta = $delta{$rel};

        if ($rel > $perl_version) {
            if ($reldelta->{removed}{$module}) {
                $mod_exists = 0;
            } else {
                next;
            }
        }

        if (exists $reldelta->{changed}{$module}) {
            $mod_exists = 1;
            $mod_ver = $reldelta->{changed}{$module};
        } elsif ($reldelta->{removed}{$module}) {
            $mod_exists = 0;
        }
    }

    if ($mod_exists) {
        if (defined $module_version) {
            return 0 unless defined $mod_ver;
            return version->parse($mod_ver) >= version->parse($module_version) ? 1:0;
        }
        return 1;
    }
    return 0;
};

sub is_core { $is_core->(@_,1) }

sub is_still_core { $is_core->(@_,0) }

my $list_core_modules = sub {
    my $all = pop;
    my $class = shift if @_ && eval { $_[0]->isa(__PACKAGE__) };
    my $perl_version = @_ ? shift : $];

    my %added;
    my %removed;

  RELEASE:
    for my $rel (sort keys %delta) {
        last if $all && $rel > $perl_version; # this is the difference with list_still_core_modules()

        my $delta = $delta{$rel};

        next unless $delta->{changed};
        for my $mod (keys %{$delta->{changed}}) {
            # module has been removed between perl_version..latest, skip
            next if $removed{$mod};

            if (exists $added{$mod}) {
                # module has been added in a previous version, update first
                # version
                $added{$mod} = $delta->{changed}{$mod} if $rel <= $perl_version;
            } else {
                # module is first added after perl_version, skip
                next if $rel > $perl_version;

                $added{$mod} = $delta->{changed}{$mod};
            }
        }
        next unless $delta->{removed};
        for my $mod (keys %{$delta->{removed}}) {
            delete $added{$mod};
            # module has been removed between perl_version..latest, mark it
            $removed{$mod}++ if $rel >= $perl_version;
        }

    }
    %added;
};

sub list_core_modules { $list_core_modules->(@_,1) }

sub list_still_core_modules { $list_core_modules->(@_,0) }

1;

# ABSTRACT: More functions for Module::CoreList

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::CoreList::More - More functions for Module::CoreList

=head1 VERSION

This document describes version 0.08 of Module::CoreList::More (from Perl distribution Module-CoreList-More), released on 2016-02-17.

=head1 SYNOPSIS

 use Module::CoreList::More;

 # true, this module has always been in core since specified perl release
 Module::CoreList::More->is_still_core("Benchmark", 5.010001);

 # false, since CGI is removed in perl 5.021000
 Module::CoreList::More->is_still_core("CGI");

 # false, never been in core
 Module::CoreList::More->is_still_core("Foo");

 my %modules = list_still_core_modules(5.010001);

=head1 DESCRIPTION

This module is my experiment for providing more functionality to (or related to)
L<Module::CoreList>. Some ideas include: faster functions, more querying
functions, more convenience functions. When I've got something stable and useful
to show for, I'll most probably suggest the appropriate additions to
Module::CoreList.

Below are random notes:

=head1 FUNCTIONS

These functions are not exported. They can be called as function (e.g.
C<Module::CoreList::More::is_still_core($name)> or as class method (e.g. C<<
Module::CoreList::More->is_still_core($name) >>.

=head2 first_release( MODULE )

Like Module::CoreList's version, but faster (see L</"BENCHMARK">).

=head2 first_release_by_date( MODULE )

Like Module::CoreList's version, but faster (see L</"BENCHMARK">).

=head2 removed_from( MODULE )

Like Module::CoreList's version, but faster (see L</"BENCHMARK">).

=head2 removed_from_by_date( MODULE )

Like Module::CoreList's version, but faster (see L</"BENCHMARK">).

=head2 is_core( MODULE, [ MODULE_VERSION, [ PERL_VERSION ] ] )

Like Module::CoreList's version, but faster (see L</"BENCHMARK">).

=head2 is_still_core( MODULE, [ MODULE_VERSION, [ PERL_VERSION ] ] )

Like C<is_core>, but will also check that from PERL_VERSION up to the latest
known version, MODULE has never been removed from core.

Note/idea: could also be implemented by adding a fourth argument
MAX_PERL_VERSION to C<is_core>, defaulting to the latest known version.

=head2 list_core_modules([ PERL_VERSION ]) => %modules

List modules that are in core at specified perl release.

=head2 list_still_core_modules([ PERL_VERSION ]) => %modules

List modules that are (still) in core from specified perl release to the latest.
Keys are module names, while values are versions of said modules in specified
perl release.

=head1 BENCHMARK

                                  Rate MC->removed_from(Foo) MC->removed_from(CGI) MCM->removed_from(Foo) MCM->removed_from(CGI)
 MC->removed_from(Foo)  153.77+-0.42/s                    --                -88.3%                 -99.7%                 -99.8%
 MC->removed_from(CGI)     1314.4+-4/s           754.8+-3.5%                    --                 -97.7%                 -98.0%
 MCM->removed_from(Foo)   57760+-280/s           37460+-210%             4294+-25%                     --                 -11.7%
 MCM->removed_from(CGI) 65407.3+-1.2/s           42440+-120%             4876+-15%           13.25+-0.55%                     --
 
                                            Rate MC->removed_from_by_date(Foo) MC->removed_from_by_date(CGI) MCM->removed_from_by_date(Foo) MCM->removed_from_by_date(CGI)
 MC->removed_from_by_date(Foo)    151.41+-0.25/s                            --                        -87.9%                         -99.7%                         -99.8%
 MC->removed_from_by_date(CGI)     1252.7+-1.7/s                   727.4+-1.8%                            --                         -97.9%                         -98.2%
 MCM->removed_from_by_date(Foo) 59798.3+-0.074/s                    39395+-64%                  4673.5+-6.5%                             --                         -13.6%
 MCM->removed_from_by_date(CGI)     69210+-120/s                   45610+-110%                     5424+-12%                    15.73+-0.2%                             --
 
                                  Rate MC->first_release(Foo) MC->first_release(CGI) MCM->first_release(Foo) MCM->first_release(CGI)
 MC->first_release(Foo)   154.7+-0.2/s                     --                 -87.0%                  -99.7%                 -100.0%
 MC->first_release(CGI)  1186.2+-2.3/s            666.8+-1.8%                     --                  -97.6%                  -99.7%
 MCM->first_release(Foo)   48641+-62/s             31342+-57%           4000.5+-9.4%                      --                  -88.2%
 MCM->first_release(CGI) 411020+-550/s           265590+-490%             34550+-80%               745+-1.6%                      --
 
                                           Rate MC->first_release_by_date(Foo) MC->first_release_by_date(CGI) MCM->first_release_by_date(Foo) MCM->first_release_by_date(CGI)
 MC->first_release_by_date(Foo)  155.92+-0.13/s                             --                         -82.9%                          -99.7%                         -100.0%
 MC->first_release_by_date(CGI)  913.53+-0.71/s                   485.9+-0.68%                             --                          -98.2%                          -99.8%
 MCM->first_release_by_date(Foo)    50483+-16/s                       32277.9%                        5426.2%                              --                          -87.7%
 MCM->first_release_by_date(CGI)  410590+-400/s                   263230+-340%                     44845+-56%                   713.32+-0.83%                              --
 
                              Rate MC->is_core(Foo) is_still_core(Foo) MCM->is_core(Foo)
 MC->is_core(Foo)   155.99+-0.14/s               --             -98.7%            -99.3%
 is_still_core(Foo) 11568.8+-3.6/s          7316.4%                 --            -50.9%
 MCM->is_core(Foo)     23562+-96/s       15005+-63%      103.66+-0.83%                --
 
                                  Rate MC->is_core(Benchmark) is_still_core(Benchmark) MCM->is_core(Benchmark)
 MC->is_core(Benchmark)   575.3+-1.3/s                     --                   -94.8%                  -97.4%
 is_still_core(Benchmark)  11053+-13/s             1821.3+-5%                       --                  -49.6%
 MCM->is_core(Benchmark)  21930+-130/s              3713+-24%               98.4+-1.2%                      --
 
                            Rate MC->is_core(CGI) is_still_core(CGI) MCM->is_core(CGI)
 MC->is_core(CGI)   680.4+-3.2/s               --             -93.9%            -96.9%
 is_still_core(CGI)  11098+-13/s     1531.1+-7.9%                 --            -49.1%
 MCM->is_core(CGI)   21818+-32/s        3107+-16%       96.59+-0.37%                --
 
                                             Rate list_still_core_modules(5.020002) list_core_modules(5.020002) list_still_core_modules(5.010001) list_core_modules(5.010001)
 list_still_core_modules(5.020002) 267.21+-0.69/s                                --                      -13.0%                            -18.6%                      -66.4%
 list_core_modules(5.020002)       307.07+-0.57/s                      14.92+-0.37%                          --                             -6.5%                      -61.4%
 list_still_core_modules(5.010001)  328.3+-0.53/s                      22.86+-0.37%                 6.91+-0.26%                                --                      -58.7%
 list_core_modules(5.010001)       795.53+-0.98/s                     197.71+-0.85%               159.07+-0.58%                     142.32+-0.49%                          --

=head1 SEE ALSO

L<Module::CoreList>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-CoreList-More>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-CoreList-More>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-CoreList-More>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
