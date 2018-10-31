package Org::To::Role;

our $DATE = '2018-10-30'; # DATE
our $VERSION = '0.231'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

use Moo::Role;
use String::Escape qw/elide printable/;

requires 'export_document';
requires 'export_block';
requires 'export_fixed_width_section';
requires 'export_comment';
requires 'export_drawer';
requires 'export_footnote';
requires 'export_headline';
requires 'export_list';
requires 'export_list_item';
requires 'export_radio_target';
requires 'export_setting';
requires 'export_table';
requires 'export_table_row';
requires 'export_table_cell';
requires 'export_table_vline';
requires 'export_target';
requires 'export_text';
requires 'export_time_range';
requires 'export_timestamp';
requires 'export_link';

1;
# ABSTRACT: Role for Org exporters

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::To::Role - Role for Org exporters

=head1 VERSION

This document describes version 0.231 of Org::To::Role (from Perl distribution Org-To-HTML), released on 2018-10-30.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-To-HTML>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-To-HTML>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-To-HTML>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
