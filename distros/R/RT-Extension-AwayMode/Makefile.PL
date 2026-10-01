use inc::Module::Install;

# Set before all_from, which would otherwise derive this from the `use v5.20;`
# in lib/RT/Extension/AwayMode.pm and normalize it to the string "5.020".
# Module::Install::Admin::ScanDeps -- reached in author mode via RTx's
# include_deps('YAML::Tiny') -- looks that string up in
# %Module::CoreList::version, whose keys come from numeric literals, so perl
# 5.20.0's key stringifies to "5.02" and a lookup of "5.020" dies with
# "Module::CoreList has no information on perl 5.020". "5.02" is the same
# version (version->parse("5.02") is v5.20.0) and is a key CoreList has.
# `use v5.36;` happened to normalize to "5.036", which is a CoreList key, which
# is why this only broke once the floor dropped to 5.20.
perl_version '5.02';

RTx 'RT-Extension-AwayMode';
all_from 'lib/RT/Extension/AwayMode.pm';
license 'gpl_3';

resources(
    repository => 'https://github.com/firefart/RT-Extension-AwayMode.git',
    bugtracker => 'https://github.com/firefart/RT-Extension-AwayMode/issues',
    license    => 'https://opensource.org/licenses/gpl-3.0.html',
);

requires_rt('6.0.0');

WriteAll;
