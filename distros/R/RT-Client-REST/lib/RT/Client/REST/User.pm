#!perl
# PODNAME: RT::Client::REST::User
# ABSTRACT: user object representation.

use strict;
use warnings;

package RT::Client::REST::User;
$RT::Client::REST::User::VERSION = '0.72';
use parent 'RT::Client::REST::Object';

use Params::Validate qw(:types);
use RT::Client::REST;
use RT::Client::REST::Object::Exception;
use RT::Client::REST::SearchResult;


sub _attributes {{
    id => {
        validation  => {
            type    => SCALAR,
        },
        form2value  => sub {
            shift =~ m~^user/(\d+)$~i;
            return $1;
        },
        value2form  => sub {
            return 'user/' . shift;
        },
    },


    privileged => {
        validation  => {
            type    => SCALAR,
        },
    },
    disabled => {
        validation  => {
            type    => SCALAR,
        },
    },
    name => {
        validation  => {
            type    => SCALAR,
        },
    },
    password => {
        validation  => {
            type    => SCALAR,
        },
    },
    email_address => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => 'EmailAddress',
    },
    real_name => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => 'RealName',
    },
    gecos => {
        validation  => {
            type    => SCALAR,
        },
    },
    comments => {
        validation  => {
            type    => SCALAR,
        },
    },
    nickname => {
        validation  => {
            type    => SCALAR,
        },
    },
    lang => {
        validation  => {
            type    => SCALAR,
        },
    },
    contactinfo => {
        validation  => {
            type    => SCALAR,
        },
    },
    signature => {
        validation  => {
            type    => SCALAR,
        },
    },


    organization => {
        validation  => {
            type    => SCALAR,
        },
    },
    address_one => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => 'Address1',
    },
    address_two => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => 'Address2',
    },
    city => {
        validation  => {
            type    => SCALAR,
        },
    },
    state => {
        validation  => {
            type    => SCALAR,
        },
    },
    zip => {
        validation  => {
            type    => SCALAR,
        },
    },
    country => {
        validation  => {
            type    => SCALAR,
        },
    },


    home_phone => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => 'HomePhone',
    },
    work_phone => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => 'WorkPhone',
    },
    cell_phone => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => 'MobilePhone',
    },
    pager => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => 'PagerPhone',
    },
}}


sub rt_type { 'user' }


__PACKAGE__->_generate_methods;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RT::Client::REST::User - user object representation.

=head1 VERSION

version 0.72

=head1 SYNOPSIS

  my $rt = RT::Client::REST->new(server => $ENV{RTSERVER});

  my $user = RT::Client::REST::User->new(
    rt  => $rt,
    id  => $id,
  )->retrieve;

=head1 DESCRIPTION

B<RT::Client::REST::User> is based on L<RT::Client::REST::Object>.
The representation allows one to retrieve, edit, comment on, and create
users in RT.

Note: RT currently does not allow REST client to search users.

=for stopwords EmailAddress gecos Gecos HomePhone MobilePhone PagerPhone RealName WorkPhone

=head1 ATTRIBUTES

=over 2

=item B<id>

For retrieval, you can specify either the numeric ID of the user or his
username.  After the retrieval, however, this attribute will be set
to the numeric id.

=item B<name>

This is the username of the user.

=item B<password>

User's password.  Reading it will only give you a bunch of stars (what
else would you expect?).

=item B<privileged>

Can the user have special rights?

=item B<disabled>

Can this user access RT?

=item B<email_address>

E-mail address of the user, EmailAddress.

=item B<real_name>

Real name of the user, RealName.

=item B<gecos>

Gecos.

=item B<comments>

Comments about this user.

=item B<nickname>

Nickname of this user.

=for stopwords lang

=item B<lang>

Language for this user.

=item B<organization>

=item B<address_one>

First line of the street address, Address1.

=item B<address_two>

Second line of the street address, Address2.

=item B<city>

City segment of user's address.

=item B<zip>

ZIP or Postal code segment of user's address.

=item B<country>

Country segment of user's address.

=item B<home_phone>

User's home phone number, HomePhone.

=item B<work_phone>

User's work phone number, WorkPhone.

=item B<cell_phone>

User's cell phone number, MobilePhone.

=item B<pager>

User's pager number, PagerPhone.

=for stopwords contactinfo

=item B<contactinfo>

Contact info (Extra Info field).

=item B<signature>

Signature for the user.

=back

=head1 DB METHODS

For full explanation of these, please see B<"DB METHODS"> in
L<RT::Client::REST::Object> documentation.

=over 2

=item B<retrieve>

Retrieve RT user from database.

=item B<store>

Create or update the user.

=item B<search>

Currently RT does not allow REST clients to search users.

=back

=head1 INTERNAL METHODS

=over 2

=item B<rt_type>

Returns 'user'.

=back

=head1 SEE ALSO

L<RT::Client::REST>, L<RT::Client::REST::Object>,
L<RT::Client::REST::SearchResult>.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2020 by Dmitri Tikhonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
