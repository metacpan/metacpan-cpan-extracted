#!perl
# PODNAME: RT::Client::REST::Group
# ABSTRACT: group object representation.

use strict;
use warnings;

package RT::Client::REST::Group;
$RT::Client::REST::Group::VERSION = '0.57';
use base 'RT::Client::REST::Object';

use Params::Validate qw(:types);
use RT::Client::REST 0.14;
use RT::Client::REST::Object::Exception 0.01;
use RT::Client::REST::SearchResult 0.02;


sub _attributes {{
    id => {
        validation  => {
            type    => SCALAR,
        },
        form2value  => sub {
            shift =~ m~^group/(\d+)$~i;
            return $1;
        },
        value2form  => sub {
            return 'group/' . shift;
        },
    },

    name => {
        validation  => {
            type    => SCALAR,
        },
    },
    description => {
        validation  => {
            type    => SCALAR,
        },
    },
    members => {
        validation => {
            type   => ARRAYREF,
        },
        list       => 1,
    },
    disabled => {
        validation => {
            type   => SCALAR,
        },
    },
}}


sub rt_type { 'group' }


__PACKAGE__->_generate_methods;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RT::Client::REST::Group - group object representation.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

  my $rt = RT::Client::REST->new(server => $ENV{RTSERVER});

  my $group = RT::Client::REST::Group->new(
    rt  => $rt,
    id  => $id,
  )->retrieve;

=head1 DESCRIPTION

B<RT::Client::REST::Group> is based on L<RT::Client::REST::Object>.
The representation allows one to retrieve, edit, and create groups in RT.

Note: RT currently does not allow REST client to search groups.

=head1 ATTRIBUTES

=over 2

=item B<id>

For retrieval, you can specify either the numeric ID of the group or his
group name.  After the retrieval, however, this attribute will be set
to the numeric id.

=item B<name>

Name of the group

=item B<description>

Description

=item B<members>

List of the members of this group.

=back

=head1 DB METHODS

For full explanation of these, please see B<"DB METHODS"> in
L<RT::Client::REST::Object> documentation.

=over 2

=item B<retrieve>

Retrieve RT group from database.

=item B<store>

Create or update the group.

=item B<search>

Currently RT does not allow REST clients to search groups.

=back

=head1 INTERNAL METHODS

=over 2

=item B<rt_type>

Returns 'group'.

=back

=head1 SEE ALSO

L<RT::Client::REST>, L<RT::Client::REST::Object>,
L<RT::Client::REST::SearchResult>.

=head1 AUTHORS

=over 4

=item *

Abhijit Menon-Sen <ams@wiw.org>

=item *

Dmitri Tikhonov <dtikhonov@yahoo.com>

=item *

Damien "dams" Krotkine <dams@cpan.org>

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Miquel Ruiz <mruiz@cpan.org>

=item *

JLMARTIN

=item *

SRVSH

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dmitri Tikhonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
