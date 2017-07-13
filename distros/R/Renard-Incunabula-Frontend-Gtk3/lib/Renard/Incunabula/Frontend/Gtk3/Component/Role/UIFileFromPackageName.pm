use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Frontend::Gtk3::Component::Role::UIFileFromPackageName;
# ABSTRACT: Role to obtain name of Glade UI file from the name of the package
$Renard::Incunabula::Frontend::Gtk3::Component::Role::UIFileFromPackageName::VERSION = '0.003';
use Moo::Role;

use Renard::Incunabula::Common::Types qw(File);
use File::Spec;
use File::Basename;
use Module::Util qw(:all);

has ui_file => (
	is => 'ro',
	isa => File,
	coerce => 1,
	default => method() {
		my $module_name = ref $self;
		my $package_last_component = (split(/::/, $module_name))[-1];
		my $module_file = find_installed($module_name);
		File::Spec->catfile(dirname($module_file), "@{[ $package_last_component ]}.glade")
	}
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Frontend::Gtk3::Component::Role::UIFileFromPackageName - Role to obtain name of Glade UI file from the name of the package

=head1 VERSION

version 0.003

=head1 DESCRIPTION

See the description of the attribute C<ui_file> for more information.

=head1 ATTRIBUTES

=head2 ui_file

A C<Str> that contains the path to a Glade UI file that resides in the same
directory as the C<.pm> file for the package that this role is used with.

For example, given a package C<Foo::Bar> from the file C<lib/Foo/Bar.pm>, the
contents of C<ui_file> will be C<lib/Foo/Bar.glade>.

See the C<ui_file> attribute in L<Renard::Incunabula::Frontend::Gtk3::Component::Role::FromBuilder>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
