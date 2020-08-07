use inc::Module::Install;

RTx     'RT-Extension-AssetAutoName';
license 'gpl_2';
repository 'https://github.com/catalyst-cloud/rt-extension-assetautoname';

requires_rt '4.4.0';

# We need to modify the Name function RT::Asset, but don't want
# PAUSE to update the index for that namespace.
# Well, I would use this method, but it doesn't work with the
# inc/Moudule/Install files here... So instead we put
# "package RT::Assets" on two lines in:
#   lib/RT/Extension/AssetAutoName.pm
# no_index 'namespace' => 'RT::Asset';

sign;
WriteAll;
