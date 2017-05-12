use Speech::Synthesis;
use Test::More tests => 2;
use strict;
use warnings;

my @engines = Speech::Synthesis->InstalledEngines();
plan skip_all => "No Speech Engines installed" unless @engines;

my @invalid_engines = ();
my @engines_not_valid_here = ();

@invalid_engines = grep {$_ !~ /^(MSAgent|SAPI4|SAPI5|MacSpeech|Festival)$/} @engines;
ok(scalar(@invalid_engines) == 0, 'Installed Engines are valid engines');

if ($^O eq 'MSWin32')
{
    @engines_not_valid_here = grep {$_ !~ /^(MSAgent|SAPI4|SAPI5|Festival)$/} @engines;
    ok(scalar(@engines_not_valid_here) == 0, 'Installed Engines are valid engines for MSWin32');
}
elsif ($^O eq 'darwin')
{
    @engines_not_valid_here = grep {$_ !~ /^(MacSpeech|Festival)$/} @engines;
    ok(scalar(@engines_not_valid_here) == 0, 'Installed Engines are valid engines for this platform');
}
else
{
    my @macspeech = grep {$_ =~ /^(MacSpeech)$/} @engines;
    ok(scalar(@macspeech) == 0, "You seem to have MacSpeech installed, but we're not running on darwin?!");
}
diag("The engines you installed are ".join(", ",@engines));
