##
# name:      inc::Module::Package
# abstract:  Module::Package Bootstrapper
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2011
# see:
# - Module::Package

package inc::Module::Package;

# Use BEGIN so unshift runs before use.
BEGIN {
    # This version is here in case of emergencies.
    $inc::Module::Package::VERSION = '0.30';

    # Borrowed from inc::Module::Install...
    my $author = $^O eq 'VMS' ? './inc/_author' : './inc/.author';

    # Do this because inc::Module::Install does it. We don't ever call that.
    $Module::Install::AUTHOR = 1
        if -d $author or not(-d 'inc');

    # Deleting the author's inc/ dir happens in Module::Install anyway,
    # but doing it here prevents a subtle Module::Package bug.
    if (-d $author) {
        require File::Path;
        File::Path::rmtree('inc');
    }

    # Make sure we pick up the local modules on user install.
    unshift @INC, 'inc' unless $INC[0] eq 'inc';
}

# Bare block contains the 'main' scope.
{
    # Pretend we are a Makefile.PL. Module::Install wants this.
    package main;

    # Load the real Module::Package.
    use Module::Package ();
}

# Tell Module::Package to begin the magic.
sub import {
    my $class = shift;
    Module::Package->import(@_);

    # Make sure we got the correct Module::Package.
# TODO: Need code review on this first. Might cause more harm than good.
#     die "Module::Package Bootstrapping Error"
#         unless $INC{'Module/Package.pm'} =~ /^inc/
#             or -e 'inc/.author';
}

# Be true to your perl.
1;

=head1 SYNOPSIS

In you C<Makefile.PL>:

    use inc::Module::Package <options>;

=head1 DESCRIPTION

This is the L<Module::Package> bootstrapping module.  It works something like
L<inc::Module::Install>.  This bootstrap module should only be loaded in an
author environment.
