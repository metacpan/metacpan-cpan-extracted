package Package::Rename;

use strict;
use warnings;
use Carp;
use MRO::Compat;
use base 'Exporter';
our @EXPORT_OK = qw/copy_package remove_package rename_package link_package/;

our $VERSION = '0.02';

sub copy_package {
	my ($old_name, $new_name) = @_;
	no strict 'refs';
	%{"$new_name\::"} = %{"$old_name\::"};
	mro::method_changed_in($new_name);
	return;
}

sub remove_package {
	my $name = shift;
	my ($super, $sub) = $name =~ / ^ ( \w+ (?> ::\w+ )* ) :: (\w+) $/xs ? ($1, $2) : ('main', $name);
	no strict 'refs';
	undef ${"$super\::"}{"$sub\::"};
	mro::method_changed_in($name);
	return;
}

sub link_package {
	my ($old_name, $new_name) = @_;
	no strict 'refs';
	*{"$new_name\::"} = *{"$old_name\::"};
	mro::method_changed_in($new_name);
	return;
}

sub rename_package {
	my ($old_name, $new_name) = @_;
	link_package($old_name, $new_name);
	remove_package($old_name);
	return;
}

1;    # End of Package::Rename

__END__

=head1 NAME

Package::Rename - Rename or copy package

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This module allows you to rename, copy or even remove packages from the perl namespace.

=head1 FUNCTIONS

This module defines the following functions. They are all optionally exported.

=head2 rename_package($old_name, $new_name)

Give a package a different name. This is the equivalent of first linking a package, and then removing its original name.

=head2 link_package($old_name, $new_name)

Make a 'hard link' of a package, thus giving it a second name.

=head2 remove_package($name)

Remove a package from the namespace. You probably don't want to use this yourself unless you really know what you're doing.

=head2 copy_package($old_name, $new_name)

Copy the complete contents of a package.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

This code can cause serious mayham. Use it with care.

Please report any bugs or feature requests to C<bug-package-rename at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Package-Rename>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 PITFALLS

Perl looks up functions during compile time but methods run time. This fact can be useful (see namespace::clean for an example of that), but also to confusing.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Package::Rename


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Package-Rename>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Package-Rename>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Package-Rename>

=item * Search CPAN

L<http://search.cpan.org/dist/Package-Rename>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

