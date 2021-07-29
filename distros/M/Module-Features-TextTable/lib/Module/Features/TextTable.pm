package Module::Features::TextTable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-26'; # DATE
our $DIST = 'Module-Features-TextTable'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %FEATURES_DEF = (
    v => 1,
    summary => 'Features of modules that generate text tables',
    features => {
        can_align_cell_containing_wide_character => {tags=>['category:alignment']},
        can_align_cell_containing_color_code     => {tags=>['category:alignment','category:color']},
        can_align_cell_containing_newline        => {tags=>['category:alignment']},
        can_use_box_character                    => {summary => 'Can use terminal box-drawing character when drawing border', tags => ['category:border']},
        can_customize_border                     => {summary => 'Let user customize border character in some way, e.g. selecting from several available borders, disable border', tags => ['category:border']},
        can_halign                               => {summary => 'Provide a way for user to specify horizontal alignment (left/middle/right) of cells', tags=>['category:alignment']},
        can_halign_individual_row                => {summary => 'Provide a way for user to specify different horizontal alignment (left/middle/right) for individual rows', tags=>['category:alignment']},
        can_halign_individual_column             => {summary => 'Provide a way for user to specify different horizontal alignment (left/middle/right) for individual columns', tags=>['category:alignment']},
        can_halign_individual_cell               => {summary => 'Provide a way for user to specify different horizontal alignment (left/middle/right) for individual cells', tags=>['category:alignment']},
        can_valign                               => {summary => 'Provide a way for user to specify vertical alignment (top/middle/bottom) of cells', tags=>['category:alignment']},
        can_valign_individual_row                => {summary => 'Provide a way for user to specify different vertical alignment (top/middle/bottom) for individual rows', tags=>['category:alignment']},
        can_valign_individual_column             => {summary => 'Provide a way for user to specify different vertical alignment (top/middle/bottom) for individual columns', tags=>['category:alignment']},
        can_valign_individual_cell               => {summary => 'Provide a way for user to specify different vertical alignment (top/middle/bottom) for individual cells', tags=>['category:alignment']},
        can_rowspan                              => {tags=>['category:rowspan']},
        can_colspan                              => {tags=>['category:colspan']},
        can_color                                => {summary => 'Can produce colored table', tags=>['category:color']},
        can_color_theme                          => {summary => 'Allow choosing colors from a named set of palettes', tags=>['category:color']},
        can_set_cell_height                      => {summary => 'Allow setting height of rows'},
        can_set_cell_height_of_individual_row    => {summary => 'Allow setting height of individual rows'},
        can_set_cell_width                       => {summary => 'Allow setting height of rows'},
        can_set_cell_width_of_individual_column  => {summary => 'Allow setting height of individual rows'},
        speed                                    => {summary => 'Subjective speed rating, relative to other text table modules', schema=>['str', in=>[qw/slow medium fast/]], tags=>['category:speed']},
        can_hpad                                 => {summary => 'Provide a way for user to specify horizontal padding of cells'},
        can_hpad_individual_row                  => {summary => 'Provide a way for user to specify different horizontal padding of individual rows'},
        can_hpad_individual_column               => {summary => 'Provide a way for user to specify different horizontal padding of individual columns'},
        can_hpad_individual_cell                 => {summary => 'Provide a way for user to specify different horizontal padding of individual cells'},
        can_vpad                                 => {summary => 'Provide a way for user to specify vertical padding of cells'},
        can_vpad_individual_row                  => {summary => 'Provide a way for user to specify different vertical padding of individual rows'},
        can_vpad_individual_column               => {summary => 'Provide a way for user to specify different vertical padding of individual columns'},
        can_vpad_individual_cell                 => {summary => 'Provide a way for user to specify different vertical padding of individual cells'},
    },
);

1;
# ABSTRACT: Features of modules that generate text tables

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Features::TextTable - Features of modules that generate text tables

=head1 VERSION

This document describes version 0.003 of Module::Features::TextTable (from Perl distribution Module-Features-TextTable), released on 2021-02-26.

=head1 DESCRIPTION

=head1 DEFINED FEATURES

Features defined by this module:

=over

=item * can_align_cell_containing_color_code

Optional. Type: bool. 

=item * can_align_cell_containing_newline

Optional. Type: bool. 

=item * can_align_cell_containing_wide_character

Optional. Type: bool. 

=item * can_color

Optional. Type: bool. Can produce colored table. 

=item * can_color_theme

Optional. Type: bool. Allow choosing colors from a named set of palettes. 

=item * can_colspan

Optional. Type: bool. 

=item * can_customize_border

Optional. Type: bool. Let user customize border character in some way, e.g. selecting from several available borders, disable border. 

=item * can_halign

Optional. Type: bool. Provide a way for user to specify horizontal alignment (left/middle/right) of cells. 

=item * can_halign_individual_cell

Optional. Type: bool. Provide a way for user to specify different horizontal alignment (left/middle/right) for individual cells. 

=item * can_halign_individual_column

Optional. Type: bool. Provide a way for user to specify different horizontal alignment (left/middle/right) for individual columns. 

=item * can_halign_individual_row

Optional. Type: bool. Provide a way for user to specify different horizontal alignment (left/middle/right) for individual rows. 

=item * can_hpad

Optional. Type: bool. Provide a way for user to specify horizontal padding of cells. 

=item * can_hpad_individual_cell

Optional. Type: bool. Provide a way for user to specify different horizontal padding of individual cells. 

=item * can_hpad_individual_column

Optional. Type: bool. Provide a way for user to specify different horizontal padding of individual columns. 

=item * can_hpad_individual_row

Optional. Type: bool. Provide a way for user to specify different horizontal padding of individual rows. 

=item * can_rowspan

Optional. Type: bool. 

=item * can_set_cell_height

Optional. Type: bool. Allow setting height of rows. 

=item * can_set_cell_height_of_individual_row

Optional. Type: bool. Allow setting height of individual rows. 

=item * can_set_cell_width

Optional. Type: bool. Allow setting height of rows. 

=item * can_set_cell_width_of_individual_column

Optional. Type: bool. Allow setting height of individual rows. 

=item * can_use_box_character

Optional. Type: bool. Can use terminal box-drawing character when drawing border. 

=item * can_valign

Optional. Type: bool. Provide a way for user to specify vertical alignment (top/middle/bottom) of cells. 

=item * can_valign_individual_cell

Optional. Type: bool. Provide a way for user to specify different vertical alignment (top/middle/bottom) for individual cells. 

=item * can_valign_individual_column

Optional. Type: bool. Provide a way for user to specify different vertical alignment (top/middle/bottom) for individual columns. 

=item * can_valign_individual_row

Optional. Type: bool. Provide a way for user to specify different vertical alignment (top/middle/bottom) for individual rows. 

=item * can_vpad

Optional. Type: bool. Provide a way for user to specify vertical padding of cells. 

=item * can_vpad_individual_cell

Optional. Type: bool. Provide a way for user to specify different vertical padding of individual cells. 

=item * can_vpad_individual_column

Optional. Type: bool. Provide a way for user to specify different vertical padding of individual columns. 

=item * can_vpad_individual_row

Optional. Type: bool. Provide a way for user to specify different vertical padding of individual rows. 

=item * speed

Optional. Type: str. Subjective speed rating, relative to other text table modules. 

=back

For more details on module features, see L<Module::Features>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Features-TextTable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Features-TextTable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Module-Features-TextTable/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Features>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
