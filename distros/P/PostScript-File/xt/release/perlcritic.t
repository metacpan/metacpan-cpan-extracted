#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id: perlcritic.t 2035 2008-06-25 23:41:21Z cjm $
#---------------------------------------------------------------------

use Test::More;

plan skip_all => "Don't want automated Perl::Critic reports"
    if $ENV{AUTOMATED_TESTING};

# ProhibitAccessOfPrivateData is a badly implemented policy that bans
# all use of hashrefs
eval <<'';
use Test::Perl::Critic (qw(-verbose 10
                           -exclude) => ['ProhibitAccessOfPrivateData']);
use Perl::Critic::Utils 'all_perl_files';
use File::Spec ();

plan skip_all => "Test::Perl::Critic required for testing PBP compliance" if $@;

# I don't want to check the Metrics data files:

my $skipRE = File::Spec->catfile(qw(lib PostScript File Metrics x));
chop $skipRE;                   # Remove the x
$skipRE = qr/\Q$skipRE\E(?!Loader)/;

my @files = grep { not $_ =~ $skipRE } all_perl_files('lib');

plan tests => scalar @files;

critic_ok($_) for @files;
