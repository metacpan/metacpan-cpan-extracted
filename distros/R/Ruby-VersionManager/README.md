# NAME

rvm.pl

# WARNING!

This is an unstable development release not ready for production!

# VERSION

Version 0.004004

# SYNOPSIS

rvm.pl will provide a subset of the bash rvm.

# INSTALL RUBY

It is recommended to use Ruby::VersionManager with local::lib to avoid interference with possibly installed system ruby.
Ruby::VersionManager comes with a script rvm.pl with following options.

## version

Show the version of Ruby::VersionManager.

        rvm.pl version

## list

List available ruby versions.

        rvm.pl list

## updatedb

Update database of available ruby versions.

        rvm.pl updatedb

## install

Install a ruby version. If no version is given the latest stable release will be installed.
The program tries to guess the correct version from the provided string. It should at least match the major release.
If you need to install a preview or rc version you will have to provide the full exact version.

Latest ruby

        rvm.pl install

Latest ruby-1.8

        rvm.pl install 1.8

Install preview

        rvm.pl install ruby-1.9.3-preview1

To use the Ruby::VersionManager source ruby\_vmanager.rc.

        source ~/.ruby_vmanager/var/ruby_vmanager.rc

After installation a subshell will be launched with the new settings.

## uninstall

Remove a ruby version and the source dir including the downloaded archive.
You have to provide the full exact version of the ruby you want to remove as shown with list.

        rvm.pl uninstall ruby-1.9.3-preview1

If you uninstall your currently active ruby version you have to install/activate another version manually.

## gem

Pass arguments to the gem command.

        rvm.pl gem install unicorn # installs unicorn

Additionally you can use reinstall to reinstall your complete gemset. With a file containing the output of 'gem list' you can reproduce gemsets.

        rvm.pl gem reinstall gem_list.txt # installs all gems in the list exactly as given

        rvm.pl gem reinstall # reinstalls all installed gems

## gemset

Switch to another set of gems and launch a subshell with the new settings.

        rvm.pl gemset my_set

## gemsets

List gemsets of the currently used rubyversion.

        rvm.pl gemsets

The current set is marked with an asterisk.

# LIMITATIONS

Currently Ruby::VersionManager is only running on Linux.

# AUTHOR

Matthias Krull, `<m.krull at uninets.eu>`

# BUGS

Report bugs at:

- Ruby::VersionManager issue tracker

    [https://github.com/uninets/p5-Ruby-VersionManager/issues](https://github.com/uninets/p5-Ruby-VersionManager/issues)

- support at uninets.eu

    `<m.krull at uninets.eu>`

# SUPPORT

- Technical support

    `<m.krull at uninets.eu>`
