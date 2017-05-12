package Module::Util;

use strict;
use warnings;

our $VERSION = '1.09';

=encoding UTF-8

=head1 NAME

Module::Util - Module name tools and transformations

=head1 SYNOPSIS

    use Module::Util qw( :all );

    $valid = is_valid_module_name $potential_module;

    $relative_path = module_path $module_name;

    $file_system_path = module_fs_path $module_name;

    # load module at runtime
    require module_path $module_name;

    # (see perldoc -f require for limitations of this approach.)

=head1 DESCRIPTION

This module provides a few useful functions for manipulating module names. Its
main aim is to centralise some of the functions commonly used by modules that
manipulate other modules in some way, like converting module names to relative
paths.

=cut

use Exporter;
use File::Spec::Functions qw( catfile rel2abs abs2rel splitpath splitdir );
use File::Find;

=head1 EXPORTS

Nothing by default.

Use the tag :all to import all functions.

=head1 FUNCTIONS

=cut

our @ISA = qw( Exporter );
our @EXPORT = ();
our @EXPORT_OK = qw(
    is_valid_module_name
    module_is_loaded
    find_installed
    all_installed
    find_in_namespace
    module_path
    module_fs_path
    module_path_parts
    path_to_module
    fs_path_to_module
    canonical_module_name
    module_name_parts
);

our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ]
);

my $SEPARATOR = qr/ :: | ' /x;

# leading underscores are technically valid as module names
# but no CPAN module has one.
our $module_re = qr/[[:alpha:]_] \w* (?: $SEPARATOR \w+ )*/xo;

=head2 is_valid_module_name

    $bool = is_valid_module_name($module)

Returns true if $module looks like a module name, false otherwise.

=cut

sub is_valid_module_name ($) {
    my $module = shift;

    return $module =~ /\A $module_re \z/xo;
}

=head2 module_is_loaded

    $abs_path_or_hook = module_is_loaded($module)

Returns the %INC entry for the given module. This is usually the absolute path
of the module, but sometimes it is the hook object that loaded it.

See perldoc -f require

Equivalent to:

    $INC{module_path($module)};

Except that invalid module names simply return false without generating
warnings.

=cut

sub module_is_loaded ($) {
    my $module = shift;

    my $path = module_path($module) or return;

    return $INC{$path};
}

=head2 find_installed

    $path = find_installed($module, [@inc])

Returns the first found installed location of the given module. This is always
an absolute filesystem path, even if it is derived from a relative path in the
include list.

By default, @INC is searched, but this can be overridden by providing extra
arguments.

    # look in @INC
    $path = find_installed("Module::Util")

    # look only in lib and blib/lib, not in @INC
    $path = find_installed("Module::Util", 'lib', 'blib/lib')

Note that this will ignore any references in the search path, so it doesn't
necessarily follow that the module cannot be successfully C<require>d if this
returns nothing.

=cut

sub find_installed ($;@) {
    my $module = shift;
    my @inc = @_ ? @_ : @INC;

    for my $path (_abs_paths($module, @inc)) {
        return $path if -e $path;
    }

    return;
}

=head2 all_installed

    @paths = all_installed($module, [@inc])

Like find_installed, but will return multiple results if the module is installed
in multiple locations.

=cut

sub all_installed ($;@) {
    my $module = shift;
    my @inc = @_ ? @_ : @INC;

    return grep { -e } _abs_paths($module, @inc);
}

=head2 find_in_namespace

    @modules = find_in_namespace($namespace, [ @inc ])

Searches for modules under a given namespace in the search path (@INC by
default).

    find_in_namespace("My::Namespace");

Returns unique installed module names under the namespace. Note that this does
not include the passed-in name, even if it is the name of an installed module.

Use of an empty string as the namespace returns all modules in @inc.

=cut

sub find_in_namespace ($;@) {
    my $ns = shift;
    my @inc = @_ ? @_ : @INC;
    my (@out, $ns_path);

    if ($ns ne '') {
        $ns_path = module_fs_path($ns) or return;
        $ns_path =~ s/\.pm\z//;
    }
    else {
        $ns_path = '';
    }

    for my $root (@inc) {
        my $ns_root = rel2abs($ns_path, $root);

        for my $path (_find_modules($ns_root)) {
            my $rel_path = abs2rel($path, rel2abs($root));
            push @out, fs_path_to_module($rel_path);
        }
    }

    my %seen;
    return grep { !$seen{$_}++ } @out;
}

sub _find_modules {
    my @roots = @_;

    # versions of File::Find from earlier perls don't have this feature
    BEGIN { unimport warnings qw( File::Find ) if $] >= 5.008 }

    my @out;
    File::Find::find({
        no_chdir => 1,
        wanted => sub { push @out, $_ if -f $_ && /\.pm\z/ }
    }, @roots);

    return @out;
}

# munge a module name into multiple possible installed locations
sub _abs_paths {
    my ($module, @inc) = @_;

    my $path = module_fs_path($module) or return;

    return
        map { rel2abs($path, $_) }
        grep { !ref }
        @inc;
}

=head2 module_path

    $path = module_path($module)

Returns a relative path in the form used in %INC. Which I am led to believe is
always a unix file path, regardless of the platform.

If the argument is not a valid module name, nothing is returned.

=cut

sub module_path ($) {
    my $module = shift;

    my @parts = module_path_parts($module) or return;

    return join('/', @parts);
}

=head2 module_fs_path

    $path = module_fs_path($module)

Like module_path, but returns the path in the native filesystem format.

On unix systems, this should be identical to module_path.

=cut

sub module_fs_path ($) {
    my $module = shift;

    my @parts = module_path_parts($module) or return;

    return catfile(@parts);
}

=head2 path_to_module

    $module = path_to_module($path)

Transforms a relative unix file path into a module name.

    # Print loaded modules as module names instead of paths:
    print join("\n", map { path_to_module($_) } keys %INC

Returns undef if the resulting module name is not valid.

=cut

sub path_to_module {
    my $path = shift;

    return _join_parts(split('/', $path));
}

=head2 fs_path_to_module

    $module = fs_path_to_module($fs_path)

Transforms relative filesystem paths into module names.

    # on windows:
    fs_path_to_module("Module\\Util.pm")
    # returns Module::Util

Returns undef if the resulting module is not valid.

=cut

sub fs_path_to_module {
    my $path = shift;

    my (undef, $dir, $file) = splitpath($path);
    my @dirs = grep { length } splitdir($dir);

    return _join_parts(@dirs, $file);
}

# opposite of module_path_parts, keep private
sub _join_parts {
    my @parts = @_;
    $parts[-1] =~ s/\.pm\z// or return;
    my $module = join('::', @parts);
    return unless is_valid_module_name($module);
    return $module;
}

=head2 module_path_parts

    @parts = module_path_parts($module_name)

Returns the module name split into parts suitable for feeding to
File::Spec->catfile.

    module_path_parts('Module::Util')
    # returns ('Module', 'Util.pm')

If the module name is invalid, nothing is returned.

=cut

sub module_path_parts ($) {
    my $module = shift;

    my @parts = module_name_parts($module) or return;
    $parts[-1] .= '.pm';

    return @parts;
}

=head2 canonical_module_name

    $module = canonical_module_name($module);

Returns the canonical module name for the given module. This basically consists
of eliminating any apostrophe symbols and replacing them with '::'.

    canonical_module_name("Acme::Don't"); # Acme::Don::t

Returns undef if the name is not valid.

=cut

sub canonical_module_name ($) {
    my $module = shift;

    return unless is_valid_module_name($module);

    # $module = _join_parts(module_path_parts($module));
    $module =~ s/'/::/g;

    return $module;
}

=head2 module_name_parts

    @parts = module_name_parts($module);

Returns a list of name parts for the given module.

    module_name_parts('Acme::Example); # ('Acme', 'Example')

=cut

sub module_name_parts ($) {
    my $module = shift;

    $module = canonical_module_name($module) or return;

    return split($SEPARATOR, $module);
}

1;

__END__

=head1 BUGS

None known. Please report any found.

=head1 SEE ALSO

L<pm_which>, a command-line utility for finding installed perl modules that is
bundled with this module.

Other, similar CPAN modules:

L<Class::Inspector>, L<Module::Info>,

L<Module::Require>, L<UNIVERSAL::require>, L<Module::Runtime>

perldoc -f require

=head1 AUTHOR

Matt Lawrence E<lt>mattlaw@cpan.orgE<gt>

=head1 THANKS

Alexander Kühne, Adrian Lai and Daniel Lukasiak for submitting patches.

=head1 COPYRIGHT

Copyright 2005 Matt Lawrence, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

vim: ts=8 sts=4 sw=4 sr et
