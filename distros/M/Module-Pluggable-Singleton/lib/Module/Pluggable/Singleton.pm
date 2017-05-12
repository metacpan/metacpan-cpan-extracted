package Module::Pluggable::Singleton;
{
  $Module::Pluggable::Singleton::VERSION = '0.06';
}
{
  $Module::Pluggable::Singleton::DIST = 'Module-Pluggable-Singleton';
}

use strict;
use warnings;
use Module::Pluggable::Singleton::Object;
use Carp;
use Data::Dump qw/pp/;

=head1 NAME

Module::Pluggable::Singleton - call/return single plugins on demand using shortened names

=head1 VERSION

version 0.06

=cut

=head1 SYNOPSIS

    package MyPluggable;
    use Module::Pluggable::Singleton;

    my $plugins = MyPluggable->plugin;
    my @plugins = MyPluggable->plugin;

    my @plugins = MyPluggable->plugins;

    my $plugin_long = $logic->plugin($name);

    my $plugins = MyPluggable->plugin;
    my $nick = MyPluggable->call('Robert','nickname',$person->full_name);

=head1 DESCRIPTION

=head1 METHODS

=head2 find($name)

Return the instance of the plugin with given short name

    $plugin = $logic->find('Bar');

=head2 plugin($name)

Return an array of the shortened available plugins or the full name of the
module when a short name is given

    my @plugin_short = $logic->plugin
    my $plugin_long = $logic->plugin($name);

=head2 plugin($name)

Return an array of all the module names

=head2 call($plugin_name, $method, $params)

Using the plugin $plugin_name call $method with $params

    $rv = $logic->call($plugin_name, $method, $params)

=cut

sub import {
    my ($class, %opts) = @_;
    my $caller = (caller)[0];
    $opts{require} = 1; # you find out earlier if it has a syntax error
    $opts{package} = $caller;

    my $finder = Module::Pluggable::Singleton::Object->new(%opts);

    if (!$opts{search_path}) {
        $opts{search_path} = "${caller}::Plugin";
    }
    if ($opts{search_path}) {
        if (ref($opts{search_path}) eq '') {
            $opts{search_path} = [$opts{search_path}];
        }
    }

    my $namespace  = "${caller}::". ucfirst($opts{sub_name} || 'plugins');
    my $sub_name = $opts{sub_name} || 'plugins';
    my $plugin_for = { }; # maps shortname to module name
    my $instance_of = { }; # instances

    my $find_sub = sub {
        shift @_;
        return $finder->find(@_);
    };

    my $plugin_sub = sub {
        shift @_;
        return $finder->plugin(@_);
    };
    my $call_sub = sub {
        shift @_;
        return $finder->call(@_);
    };

    my $plugins_sub = sub {
        my($self) = @_;
        $finder->plugins(@_);
    };
    no strict 'refs';
    no warnings qw(redefine prototype);

    *{"$caller\::$sub_name"} = $plugins_sub;
    *{"$caller\::find"} = $find_sub;
    *{"$caller\::plugin"} = $plugin_sub;
    *{"$caller\::call"} = $call_sub;

    return;
}

=head1 AUTHOR

Jason Tang, C<< <tang.jason.ch at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-pluggable-singleton at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Pluggable-Singleton>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

Module::Pluggable::Object

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Pluggable::Singleton


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Pluggable-Singleton>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Pluggable-Singleton>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Pluggable-Singleton>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Pluggable-Singleton/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jason Tang.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Module::Pluggable::Singleton
