#  Copyright 2014 - present MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use warnings;
package MongoDB::CommandResult;

# ABSTRACT: MongoDB generic command result document

use version;
our $VERSION = 'v2.2.2';

use Moo;
use MongoDB::Error;
use MongoDB::_Constants;
use MongoDB::_Types qw(
    HostAddress
    ClientSession
);
use Types::Standard qw(
    HashRef
    Maybe
);
use namespace::clean;

with $_ for qw(
  MongoDB::Role::_PrivateConstructor
  MongoDB::Role::_DatabaseErrorThrower
  MongoDB::Role::_DeprecationWarner
);

#pod =attr output
#pod
#pod Hash reference with the output document of a database command
#pod
#pod =cut

has output => (
    is       => 'ro',
    required => 1,
    isa => HashRef,
);

#pod =attr address
#pod
#pod Address ("host:port") of server that ran the command
#pod
#pod =cut

has address => (
    is       => 'ro',
    required => 1,
    isa => HostAddress,
);

#pod =attr session
#pod
#pod ClientSession which the command was ran with, if any
#pod
#pod =cut

has session => (
    is       => 'ro',
    required => 0,
    isa => Maybe[ClientSession],
);

#pod =method last_code
#pod
#pod Error code (if any) or 0 if there was no error.
#pod
#pod =cut

sub last_code {
    my ($self) = @_;
    my $output = $self->output;
    if ( $output->{code} ) {
        return $output->{code};
    }
    elsif ( $output->{lastErrorObject} ) {
        return $output->{lastErrorObject}{code} || 0;
    }
    elsif ( $output->{writeConcernError} ) {
        return $output->{writeConcernError}{code} || 0;
    }
    else {
        return 0;
    }
}

#pod =method last_errmsg
#pod
#pod Error string (if any) or the empty string if there was no error.
#pod
#pod =cut

sub last_errmsg {
    my ($self) = @_;
    my $output = $self->output;
    for my $err_key (qw/$err err errmsg/) {
        return $output->{$err_key} if exists $output->{$err_key};
    }
    if ( exists $output->{writeConcernError} ) {
        return $output->{writeConcernError}{errmsg}
    }
    return "";
}

#pod =method last_wtimeout
#pod
#pod True if a write concern error or timeout occurred or false otherwise.
#pod
#pod =cut

sub last_wtimeout {
    my ($self) = @_;
    return !!( exists $self->output->{wtimeout}
        || exists $self->output->{writeConcernError} );
}

#pod =method last_error_labels
#pod
#pod Returns an array of error labels from the command, or an empty array if there
#pod are none
#pod
#pod =cut

sub last_error_labels {
    my ( $self ) = @_;
    return $self->output->{errorLabels} || [];
}

#pod =method assert
#pod
#pod Throws an exception if the command failed.
#pod
#pod =cut

sub assert {
    my ($self, $default_class) = @_;

    if ( ! $self->output->{ok} ) {
        $self->session->_maybe_unpin_address( $self->last_error_labels )
            if defined $self->session;
        $self->_throw_database_error( $default_class );
    }

    return 1;
}

#pod =method assert_no_write_concern_error
#pod
#pod Throws an exception if a write concern error occurred
#pod
#pod =cut

sub assert_no_write_concern_error {
    my ($self) = @_;

    $self->_throw_database_error( "MongoDB::WriteConcernError" )
        if $self->last_wtimeout;

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::CommandResult - MongoDB generic command result document

=head1 VERSION

version v2.2.2

=head1 DESCRIPTION

This class encapsulates the results from a database command.  Currently, it is
only available from the C<result> attribute of C<MongoDB::DatabaseError>.

=head1 ATTRIBUTES

=head2 output

Hash reference with the output document of a database command

=head2 address

Address ("host:port") of server that ran the command

=head2 session

ClientSession which the command was ran with, if any

=head1 METHODS

=head2 last_code

Error code (if any) or 0 if there was no error.

=head2 last_errmsg

Error string (if any) or the empty string if there was no error.

=head2 last_wtimeout

True if a write concern error or timeout occurred or false otherwise.

=head2 last_error_labels

Returns an array of error labels from the command, or an empty array if there
are none

=head2 assert

Throws an exception if the command failed.

=head2 assert_no_write_concern_error

Throws an exception if a write concern error occurred

=for Pod::Coverage result

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Rassi <rassi@mongodb.com>

=item *

Mike Friedman <friedo@friedo.com>

=item *

Kristina Chodorow <k.chodorow@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
