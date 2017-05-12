package Module::Start::Flavor::Basic;
use base 'Module::Start::Flavor';

use constant flavor => 'basic';

1;

__DATA__

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See [http://www.perl.com/perl/misc/Artistic.html]

=cut

_____[ __config__ ]____________________________________________________________
# Configuration file for Module::Start::Flavor::Basic

installer: Module::Start::Flavor::Basic
module_template: ++module_lib_path++
_____[ Changes ]_______________________________________________________________
# Revision history for [% module_dist_name %]

version: 0.01
date:    [% date_time_human %]
changes:
- Initial release
_____[ Makefile.PL ]___________________________________________________________
use inc::Module::Install;

name        '[% module_dist_name %]';
all_from    '[% module_lib_path %]';

WriteAll;
_____[ ++module_lib_path++ ]___________________________________________________
package [% module_name %];

use warnings;
use strict;

=head1 NAME

[% module_name %] - The great new [% module_name %]!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use [% module_name %];

    my $foo = [% module_name %]->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

[% author_full_name %], C<< <[% author_email_masked %]> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-[% module_dist_name_lower %] at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=[% module_dist_name %]>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc [% module_name %]

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/[% module_dist_name %]>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/[% module_dist_name %]>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% module_dist_name %]>

=item * Search CPAN

L<http://search.cpan.org/dist/[% module_dist_name %]>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright [% date_time_year %] [% author_full_name %], all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of [% module_name %]
_____[ t/00-load.t ]_________________________________________________________
#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( '[% module_name %]' );
}

diag( "Testing [% module_name %] $[% module_name %]::VERSION, Perl $], $^X" );
_____[ README ]________________________________________________________________
[% module_dist_name %]

The README is used to introduce the module and provide instructions on
how to install the module, any machine dependencies it may have (for
example C compilers and installed libraries) and any other information
that should be provided before the module is installed.

A README file is required for CPAN modules since CPAN extracts the README
file from a module distribution so that people browsing the archive
can use it get an idea of the modules uses. It is usually a good idea
to provide version information here so that people can decide whether
fixes for the module are worth downloading.

INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install


SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the perldoc command.

    perldoc [% module_name %]

You can also look for information at:

    Search CPAN
        http://search.cpan.org/dist/[% module_dist_name %]

    CPAN Request Tracker:
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% module_dist_name %]

    AnnoCPAN, annotated CPAN documentation:
        http://annocpan.org/dist/[% module_dist_name %]

    CPAN Ratings:
        http://cpanratings.perl.org/d/[% module_dist_name %]

COPYRIGHT AND LICENCE

Copyright (C) [% date_time_year %] [% author_full_name %]

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
_____[ MANIFEST ]______________________________________________________________
[%- self.manifest_files -%]
