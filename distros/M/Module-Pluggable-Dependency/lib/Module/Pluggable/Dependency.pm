package Module::Pluggable::Dependency;

use warnings;
use strict;
use Module::Pluggable ();
use Algorithm::Dependency::Ordered;
use Algorithm::Dependency::Source::HoA;

our $VERSION = '0.0.4';

sub import {
    my $package = shift;

    # let Module::Pluggable install it's normal subroutine
    my %args = @_;
    $args{package} ||= scalar caller;
    $args{require} = 1 if !$args{require} && !$args{instantiate};
    Module::Pluggable->import(%args);

    # wrap Module::Pluggable's sub to sort by dependencies
    my $sub_name = $args{sub_name} || 'plugins';
    my $installed_sub_name = "$args{package}::$sub_name";
    {
        no strict 'refs';
        no warnings 'redefine';
        my $original_sub = \&$installed_sub_name;
        *{$installed_sub_name} = sub {

            # build a dependency hash
            my %deps;
            my %objects;
            for my $plugin ( $original_sub->(@_) ) {
                my $plugin_name = ref($plugin) || $plugin;
                $deps{$plugin_name} = eval { [ $plugin->depends ] } || [];
                $objects{$plugin_name} = $plugin;
            }

            # calculate plugin order based on dependencies
            my $source = Algorithm::Dependency::Source::HoA->new( \%deps );
            my $deps
                = Algorithm::Dependency::Ordered->new( source => $source );
            return @objects{ @{ $deps->schedule_all } };
        };
    }
}

1;

__END__

=head1 NAME

Module::Pluggable::Dependency - order plugins based on inter-plugin dependencies

=head1 VERSION

This documentation refers to Module::Pluggable::Dependency version 0.0.3


=head1 SYNOPSIS

    package MyClass;
    use Module::Pluggable::Dependency;

and then later ...

    use MyClass;
    my $mc = MyClass->new();
    # returns the names of all plugins installed under MyClass::Plugin::*
    # sorted so that plugins are listed after all their dependencies
    my @plugins = $mc->plugins();


=head1 DESCRIPTION

L<Module::Pluggable::Dependency> provides a way to run plugins in situations
where one plugin depends on running after other plugins run.  This module is
similar to L<Module::Pluggable::Ordered> but it determines ordering via
dependencies instead of precedence levels.

Each plugin may implement an optional C<depends> method which returns a list
of the plugins upon which it depends.  L<Module::Pluggable::Dependency> makes
sure that plugins are returned in an order which meets the dependency
hierarchy.

Why would you use this?  Let's say you have a series of plugins for caching
complex calculations.  Some of the plugins base their complex calculations on
the calculations of other plugins.  You need to be sure that each plugin is
only run after it's dependencies have been run.  Because the ordering of
plugins is specified through dependencies, additional plugins may be added
without manually determining the needed precedence levels.

=head1 INTERFACE

L<Module::Pluggable::Dependency> should be a drop-in replacement for
L<Module::Pluggable>.  It accepts all the same options and just modifies the
behavior of the C<plugins> sub (or whatever you named it via C<sub_name>).

=head2 depends

Any plugin wanting to indicate it's dependence on another plugin should
implement a C<depends> method.  The method should return a list of class names
for the plugins upon which it depends.  For example:

    package My::Plugin::Foo;
    sub stuff { ... }
    
    package My::Plugin::Bar;
    sub stuff { ... }
    sub depends { qw( My::Plugin::Foo ) }

Because C<My::Plugin::Foo> doesn't have a C<depends> method, it's assumed that
the plugin has no dependencies.  C<My::Plugin::Bar> however, must be run after
the "Foo" plugin.

=head1 DIAGNOSTICS

Exceptions from L<Algorithm::Dependency::Ordered> are propagated.

=head1 CONFIGURATION AND ENVIRONMENT

Module::Pluggable::Dependency requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item *

Module::Pluggable 1.9

=item *

Algorithm::Dependency 1.04

=back

=head1 INCOMPATIBILITIES

None known.  You should even be able to use L<Module::Pluggable::Dependency>
at the same time as L<Module::Pluggable> and other derived classes.

=head1 BUGS AND LIMITATIONS

=over

=item *

Missing plugin dependencies aren't handled

=item *

Error reporting for circular plugin dependencies should be handled with a
module-specific error message.

=back

Please report any bugs or feature requests to
C<bug-module-pluggable-dependency at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Pluggable-Dependency>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Pluggable::Dependency

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Pluggable-Dependency>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Pluggable-Dependency>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Pluggable-Dependency>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Pluggable-Dependency>

=back

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
The MIT License

Copyright (c) 2006 Michael Hendricks (<michael@ndrix.org>).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
