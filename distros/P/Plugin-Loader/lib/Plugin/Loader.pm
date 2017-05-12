package Plugin::Loader;
$Plugin::Loader::VERSION = '0.05';
use 5.006;
use Moo;
use Path::Iterator::Rule;
use File::Spec::Functions   qw/ catfile splitdir /;
use Carp                    qw/ croak /;

has 'max_depth' => (is => 'rw');

sub find_modules
{
    my ($self, $base) = @_;
    my @baseparts     = split(/::/, $base);
    my %modules;

    foreach my $directory (@INC) {
        my $path = catfile($directory, @baseparts);
        next unless -d $path;

        my $rule = Path::Iterator::Rule->new->perl_module;
        $rule->max_depth($self->max_depth) if $self->max_depth;

        foreach my $file ($rule->all($path)) {
            (my $modpath = $file) =~ s!^\Q$directory\E.|\.pm$!!g;

            my $module = join('::', splitdir($modpath));

            # Using a hash means that even if a module is installed
            # in more than one place, it will only be reported once
            $modules{ $module }++;
        }
    }

    return keys(%modules);
}

sub load
{
    my ($self, @modules) = @_;

    require Module::Runtime;
    foreach my $module (@modules) {
        Module::Runtime::require_module($module);
    }
}

1;

=encoding utf8

=head1 NAME

Plugin::Loader - finding and loading modules in a given namespace

=head1 SYNOPSIS

 use Plugin::Loader;

 my $loader  = Plugin::Loader->new;
 my @plugins = $loader->find_modules('MyApp::Plugin');

 foreach my $plugin (@plugins) {
    $loader->load($plugin);
 }

=head1 DESCRIPTION

B<Note>: this module has now been renamed to L<Module::Loader>.
In the slim chance that you'd started using C<Plugin::Loader>,
my apologies, and please switch to using L<Module::Loader>.
C<Plugin::Loader> will eventually be removed from CPAN.

This module provides methods for finding modules in a given namespace,
and then loading them. It is intended for use in situations where
you're looking for plugins, and then loading one or more of them.

This module was inspired by L<Mojo::Loader>, which I have used in
a number of projects. But some people were wary of requiring L<Mojolicious>
just to get a module loader, which prompted me to create C<Plugin::Loader>.

=head2 max_depth

C<Plugin::Loader> has an optional C<max_depth> attribute.
If you set this to 1, then C<find_modules> will only report modules
that are immediately within the namespace specified.

Let's say you have all of the CPAN plugins for the template toolkit
installed locally. If you don't specify C<max_depth>, then C<find_modules('Template::Plugin')>
would return L<Template::Plugin::Filter::Minify::JavaScript>
as well as L<Template::Plugin::File>. If you set C<max_depth> to 1,
then you'd get the latter but not the former.

Why might you want to do that?

You might have a convention where plugins are the modules immediately
within the specified namespace, but that each plugin can have additional
modules within its own namespace.

So typically you'll either not set C<max_depth>, or you'll set it to 1.

=head1 METHODS

=head2 find_modules

Takes a namespace, and returns all installed modules in that namespace,
that were found in C<@INC>. For example:

 @plugins = $loader->find_modules('Template::Plugin');

By default this will find all modules in the given namespace,
unless you've specified a maximum search depth, as described above.

=head2 load

Takes a module name and tries to load the module.
If loading fails, then we C<croak>.

=head1 SEE ALSO

L<Module::Loader> the new name for Plugin::Loader.

L<Mojo::Loader> was the inspiration for this module, but has
a slightly different interface. In particular, it has C<max_depth>
hard-coded to 1.

L<Module::Pluggable> is effectively a role which gives a class the ability
to find plugins within its namespace.

L<Module::Pluggable::Ordered> is similar to L<Module::Pluggable>,
but lets you control the order in which modules are loaded.

L<all> will load all modules in a given namespace, eg with C<use all 'IO::*';>

L<lib::require::all> will load all modules found in a given I<directory>
(as opposed to a namespace).

L<MAD::Loader> provides functions for loading modules,
but not for finding them.

L<Module::Find> provides a number of functions for finding and loading
modules. It provides different functions depending on whether you want
to limit the search depth to 1 or not: C<findallmod> vs C<findsubmod>.

L<Module::Recursive::Require> will load all modules in a given namespace,
and return a list of the modules found / loaded.
It lets you provide regexps for filtering out certain namespaces.

L<Module::Require> provides two functions, C<require_regex>
and C<require_glob> which will load all locally installed modules
whose name matches a pattern (specified as a regular expression
or glob-style pattern).

=head1 REPOSITORY

L<https://github.com/neilbowers/Plugin-Loader>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

