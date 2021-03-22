
package Mojolicious::Plugin::DataTables::SSP::Column;

use Mojo::Base -base;

our $VERSION = '2.01';

has 'data';
has 'database';
has 'formatter';
has 'label';
has 'name';
has 'orderable';
has 'search';
has 'searchable';
has 'row';

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::DataTables::SSP::Column - DataTables SSP Column Helper

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('DataTables');

    # Mojolicious::Lite
    plugin 'DataTables';

=head1 DESCRIPTION

L<Mojolicious::Plugin::DataTables::SSP::Column> is a L<Mojolicious> plugin to add DataTables SSP (Server-Side Protocol) support in your Mojolicious application.


=head1 METHODS

L<Mojolicious::Plugin::DataTables::SSP::Column> implements the following methods.


=head2 data

=head2 database

=head2 formatter

=head2 label

=head2 name

=head2 orderable

=head2 search

=head2 searchable

=head2 row


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>, L<Mojolicious::Plugin::DataTables>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-DataTables/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-DataTables>

    git clone https://github.com/giterlizzi/perl-Mojolicious-Plugin-DataTables.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
