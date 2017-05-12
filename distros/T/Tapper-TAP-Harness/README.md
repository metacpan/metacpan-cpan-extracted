Tapper-TAP-Harness
==================

The following documentation may include too much steps. But it gets the module installed and running

Pre-requirements manual installation
------------------------------------
* perl module Dist::Zilla::PluginBundle::Tapper
* cpan or cpanm

Manual installation
-------------------
This perl module can be manual installed by running the following commands

# install all required dependencies
dzil authordeps | cpanm
# install the package itself
dzil install
