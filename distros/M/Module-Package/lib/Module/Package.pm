##
# name:      Module::Package
# abstract:  Postmodern Perl Module Packaging
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - Module::Package::Plugin
# - Module::Install::Package
# - Module::Package::Tutorial

package Module::Package;
use 5.005;
use strict;

BEGIN {
    $Module::Package::VERSION = '0.30';
    $inc::Module::Package::VERSION ||= $Module::Package::VERSION;
    @inc::Module::Package::ISA = __PACKAGE__;
}

sub import {
    my $class = shift;
    $INC{'inc/Module/Install.pm'} = __FILE__;
    unshift @INC, 'inc' unless $INC[0] eq 'inc';
    eval "use Module::Install 1.01 (); 1" or $class->error($@);

    package main;
    Module::Install->import();
    eval {
        module_package_internals_version_check($Module::Package::VERSION);
        module_package_internals_init(@_);
    };
    if ($@) {
        $Module::Package::ERROR = $@;
        die $@;
    }
}

# XXX Remove this when things are stable.
sub error {
    my ($class, $error) = @_;
    if (-e 'inc' and not -e 'inc/.author') {
        require Data::Dumper;
        $Data::Dumper::Sortkeys = 1;
        my $dump1 = Data::Dumper::Dumper(\%INC);
        my $dump2 = Data::Dumper::Dumper(\@INC);
        die <<"...";
This should not have happened. Hopefully this dump will explain the problem:

inc::Module::Package: $inc::Module::Package::VERSION
Module::Package: $Module::Package::VERSION
inc::Module::Install: $inc::Module::Install::VERSION
Module::Install: $Module::Install::VERSION

Error: $error

%INC:
$dump1
\@INC:
$dump2
...
    }
    else {
        die $error;
    }
}

1;

=head1 SYNOPSIS

In your C<Makefile.PL>:

    use inc::Module::Package;

or one of these invocations:

    # These two are functionally the same as above:
    use inc::Module::Package ':basic';
    use inc::Module::Package 'Plugin:basic';

    # With Module::Package::Catalyst plugin options
    use inc::Module::Package 'Catalyst';

    # With Module::Package::Catalyst::common inline plugin class
    use inc::Module::Package 'Catalyst:common';

    # Pass options to the Module::Package::Ingy::modern constructor
    use inc::Module::Package 'Ingy:modern',
        option1 => 'value1',
        option2 => 'value2';

=head1 DESCRIPTION

This module is a dropin replacement for L<Module::Install>. It does everything
Module::Install does, but just a bit better.

Actually this module is simply a wrapper around Module::Install. It attempts
to drastically reduce what goes in a Makefile.PL, while at the same time,
fixing many of the problems that people have had with Module::Install (and
other module frameworks) over the years.

=head1 PROPAGANDA

Module::Install took Makefile.PL authoring from a black art to a small set of
powerful and reusable instructions. It allowed packaging gurus to take their
fancy tricks and make them into one liners for the rest of us.

As the number of plugins has grown over the years, using Module::Install has
itself become a bit of a black art. It's become hard to know all the latest
tricks, put them in the correct order, and make sure you always use the
correct sets for your various Perl modules.

Added to this is the fact that there are a few problems in Module::Install
design and general usage that are hard to fix and deploy with certainty that
it will work in all cases.

This is where Module::Package steps in. Module::Package is the next logical
step in Makefile.PL authoring. It allows gurus to create well tested sets of
Module::Install directives, and lets the rest of us use Makefile.PLs that are
one line long. For example:

    use inc::Module::Package 'Catalyst:widget';

could be the one line Makefile.PL for a Catalyst widget (whatever that is)
module distribution. Assuming someone creates a module called
Module::Package::Catalyst, with an inline class called
Module::Package::Catalyst::widget that inherited from
L<Module::Package::Plugin>.

Module::Package is pragmatic. Even though you can do everything in one line,
you are still able to make any Module::Install calls as usual. Also you can
pass parameters to the Module::Package plugin.

    use inc::Module::Package 'Catalyst:widget',
        deps_list => 0,
        some_cataylst_thing => '...';

    # All Module::Install plugins still work!
    requires 'Some::Module' => 3.14;

This allows Module::Package::Catalyst to be configurable, even on the
properties like C<deps_list> that are inherited from
L<Module::Package::Plugin>.

The point here is that with Module::Package, module packaging just got a whole
lot more powerful and simple. A rare combination!

=head1 FEATURES

Module::Package has many advantages over vanilla Module::Install.

=head2 Smaller Makefile.PL Files

In the majority of cases you can reduce your Makefile.PL to a single command.
The core Module::Package invokes the Module::Install plugins that it thinks
you want. You can also name the Module::Package plugin that does exactly the
plugins you want.

=head2 Reduces Module::Install Bloat

Somewhere Module::Install development went awry, and allowed modules that only
have useful code for an author, to be bundled into a distribution. Over time,
this has created a lot of wasted space on CPAN mirrors. Module::Package fixes
this.

=head2 Collaborator Plugin Discovery

An increasing problem with Module::Install is that when people check out your
module source from a repository, they don't know which Module::Install plugin
modules you have used. That's because the Makefile.PL only requires the
function names, not the module names that they come from.

Many people have realized this problem, and worked around it in various
suboptimal ways. Module::Package manages this problem for you.

=head2 Feature Grouping and Reuse

Module::Install has lots of plugins. Although it is possible with plain
Module::Install, nobody seems to make plugins that group other plugins. This
also might introduce subtle problems of using groups with other groups.

Module::Package has object oriented plugins whose main purpose is to create
these groups. They inherit base functionality, subclass it to their design
goals and can define options for the user to tweak how they will operate.

=head1 USAGE

The basic anatomy of a Makefile.PL call to Module::Package is:

    use inc::Module::Package 'PluginName:flavor <version>',
        $option1 => $value1;

The C<inc::Module::Package> part uses the Module::Install C<inc> bootstrapping
trick.

C<PluginName:flavor> (note the single ':') resolves to the inline class
C<Module::Package::PluginName::flavor>, within the module
C<Module::Package::PluginName>. Module::Package::PluginName::flavor must be a
subclass of L<Module::Package::Plugin>.

An optional version can be used after the plugin name.

Optional key/value pairs can follow the Plugin specification. They are used to
pass information to the plugin. See Plugin docs for more details.

If C<:flavor> is omitted, the class Module::Package::PluginName is
used. The idea is that you can create a single module with many different
plugin styles.

If C<PluginName> is omitted, then C<:flavor> is used against
L<Module::Package::Plugin>. These are a set of common plugin classes that you
can use.

If C<PluginName:flavor> is omitted altogether, it is the same as saying
'Plugin:basic'. Note that you need to specify the ':basic' plugin if you want
to also pass it options.

=head1 STATUS

This is still an early release. We are still shaking out the bugs. You might
want to hold off for a bit longer before using Module::Package for important
modules.
