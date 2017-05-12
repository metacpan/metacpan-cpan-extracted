# NOTE: inc::Module::Install::PRIVATE::Padre needs Perl 5.8, so make sure
# that we force the Perl version check (and fail) early.
# Unicode is also considered to finally be "stable" at 5.8.5, so we will
# set our dependency on that.
use 5.008005;
use strict;

#use lib 'privinc';
use inc::Module::Install 1.06;

#use POSIX qw(locale_h);



# Workaround for the fact that Module::Install loads the modules
# into memory and when Test::NoWarnings is loaded it will hide
# the warnings generated from that point.
# Removed in r2208, added again in r9001
eval {
	require Test::NoWarnings;
	$SIG{__WARN__} = 'DEFAULT';
};

# Configure-time dependencies MUST be done first.
# This version ensures that we have a new MakeMaker that
# WON'T load modules to determine the version.
# This _SHOULD_ theoretically make the "require Test::NoWarnings".
# stuff above here no longer needed.
configure_requires 'ExtUtils::MakeMaker' => '6.52';

# NOTE: Core modules that aren't dual-life should always have a version of 0

name 'PPIx-EditorTools';
license 'perl';
author 'Steffen Mueller C<smueller@cpan.org>';
author 'Repackaged by Mark Grimes C<mgrimes@cpan.org>';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';
all_from 'lib/PPIx/EditorTools.pm';
requires 'perl' => '5.008005';

# General dependencies
requires 'Carp';
requires 'Class::XSAccessor' => '1.02';
requires 'File::Spec';
requires 'File::Basename';
requires 'PPI'                    => '1.215';
requires 'PPI::Find'              => '0';
requires 'Try::Tiny'              => '0.11';
test_requires 'File::Find'        => '0';
test_requires 'File::Temp'        => '0';
test_requires 'Test::More'        => '0.88';
test_requires 'Test::Most'        => '0';
test_requires 'Test::Differences' => '0';
test_requires 'Test::NoWarnings'  => '0.084';

no_index 'directory' => qw{ t xt eg share inc privinc };
homepage 'http://padre.perlide.org/';
bugtracker 'https://github.com/szabgab/PPIx-EditorTools/issues';
repository 'https://github.com/szabgab/PPIx-EditorTools';

WriteAll;

