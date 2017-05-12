#!/usr/bin/perl -w
use strict;
use warnings;
BEGIN { exit 0 if $] < 5.008008 }
require 5.8.1;
$|++;
if (!eval q[use Module::Build::Compat 0.02; use Module::Build 0.30; 1]) {
    print qq[This module requires Module::Build to install itself.\n];
    require ExtUtils::MakeMaker;
    my $yn =
        ExtUtils::MakeMaker::prompt(q[  Install Module::Build now from CPAN?],
                                    q[y]);
    if ($yn !~ m[^y]i) {
        warn qq[ *** Cannot install without Module::Build.  Exiting ...\n];
        exit 0;
    }
    require Cwd;
    require File::Spec;
    require CPAN;

    # Save this 'cause CPAN will chdir all over the place.
    my $cwd = Cwd::cwd();
    CPAN::Shell->install(q[Module::Build::Compat]);
    if (!CPAN::Shell->expand(q[Module], q[Module::Build::Compat])->uptodate) {
        warn qq[Couldn't install Module::Build, giving up.\n];
        exit 0;
    }
    if (!chdir $cwd) {
        warn qq[Cannot chdir() back to $cwd: $!];
        exit 0;
    }
}
if (!eval q[use Module::Build::Compat 0.02; use Module::Build 0.30; 1]) {
    warn $@;
    exit 0;
}
Module::Build::Compat->run_build_pl(args => \@ARGV);
require Module::Build;
Module::Build::Compat->write_makefile(build_class => q[Module::Build]);
__END__
Copyright (C) 2008-2009 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the terms of The Artistic License 2.0.  See the LICENSE file
included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by
the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

$Id: Makefile.PL 64e98b0 2009-09-12 05:23:14Z sanko@cpan.org $
