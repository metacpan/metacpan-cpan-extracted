# ABSTRACT: Exceptions for PONAPI::Server
package PONAPI::Exception;

use Moose;
use Moose::Util qw/find_meta/;

use JSON::MaybeXS;

sub throw {
  my $class_or_obj = shift;
  die ( blessed $class_or_obj ? $class_or_obj : $class_or_obj->new(@_) );
}

use overload
    q{""}    => 'as_string',
    fallback => 1;

has message => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has status => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { 400 },
);

has bad_request_data => (
    is  => 'ro',
    isa => 'Bool',
);

has sql_error => (
    is  => 'ro',
    isa => 'Bool',
);

has internal => (
    is  => 'ro',
    isa => 'Bool',
);

has json_api_version => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '1.0' },
    writer  => '_set_json_api_version'
);

# Picked from Throwable::Error
sub as_string {
    my $self = shift;
    return $self->message;
}

sub as_response {
    my $self = shift;

    my $status = $self->status;
    my $detail = $self->message;

    if ( $self->sql_error ) {
        $detail = "SQL error: $detail";
    }
    elsif ( $self->bad_request_data ) {
        $detail = "Bad request data: $detail";
    }
    else {
        $status = 500;
        warn $detail if $detail;
        $detail = "A fatal error has occured, please check server logs";
    }

    return $status, [], +{
        jsonapi => { version  => $self->json_api_version },
        errors  => [ { detail => $detail, status => $status } ],
    };
}

sub new_from_exception {
    my ( $class, $e ) = @_;

    return $e if blessed($e) && $e->isa($class);

    my %args_for_new = $class->_handle_exception_obj($e);

    unless ( $args_for_new{status} and $args_for_new{message} ) {
        %args_for_new = (
            status  => 500,
            message => '',
        );
        warn "$e";
    }

    return $class->new(%args_for_new);
}

sub _handle_exception_obj {
    my ( $self, $e ) = @_;
    return unless blessed($e) or $e->isa('Moose::Exception');

    if ( $e->isa('Moose::Exception::AttributeIsRequired') ) {
        my $attribute = $e->attribute_name;
        return _bad_req( "Parameter `$attribute` is required" );
    }
    elsif (
        $e->isa('Moose::Exception::ValidationFailedForTypeConstraint') or
        $e->isa('Moose::Exception::ValidationFailedForInlineTypeConstraint')
    ) {
        my $class      = find_meta( $e->class_name );
        my $attribute  = $class->get_attribute( $e->attribute_name );
        my $value_nice = JSON::MaybeXS->new->allow_nonref->utf8->canonical->encode( $e->value );

        if ( !$attribute ) {
            my $attr = $e->attribute_name;
            return _bad_req( "Parameter `$attr` got an expected data type: $value_nice" );
        }

        my $attribute_name = $attribute->name;
        my $type_name      = _moose_type_to_nice_description( $attribute->{isa} );

        return _bad_req( "Parameter `$attribute_name` expected $type_name, but got a $value_nice" );
    }

    return;
}

sub _bad_req {
    return (
        message          => shift,
        status           => 400,
        bad_request_data => 1,
    );
}

# THIS IS NOT COMPLETE, NOR IS IT MEANT TO BE
sub _moose_type_to_nice_description {
    my ($type_name) = @_;

    $type_name =~ s/ArrayRef/Collection/g;
    $type_name =~ s/HashRef/Resource/g;
    $type_name =~ s/Maybe\[(.+)]/null or $1/g;
    $type_name =~ s/\|/ or /g;

    return $type_name;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Exception - Exceptions for PONAPI::Server

=head1 VERSION

version 0.003001

=head1 SYNOPSIS

    use PONAPI::Exception;
    PONAPI::Exception->throw( message => "Generic exception" );
    PONAPI::Exception->throw(
        message => "Explanation for the sql error, maybe $DBI::errstr",
        sql     => 1,
    );
    PONAPI::Exception->throw(
        message          => "Data had type `foo` but we wanted `bar`",
        bad_request_data => 1,
    );

=head1 DESCRIPTION

I<PONAPI::Exception> can be used by repositories to signal errors;
exceptions thrown this way will be caught by L<the DAO|PONAPI::DAO> and
handled gracefully.

Different kinds of exceptions can be thrown by changing the arguments
to C<throw>; C<sql =E<gt> 1> will throw a SQL exception,
C<bad_request_data =E<gt> 1> will throw an exception due to the
input data being wrong, and not passing any of those will
throw a generic exception.

The human-readable C<message> for all of those will end up in the
error response returned to the user.

=head1 METHODS

=head2 message

This attribute contains the exception message.

=head2 as_string

Returns a stringified form of the exception.  The object is overloaded
to return this if used in string context.

=head2 as_response

Returns the exception as a 3-element list that may be fed directly
to plack as a {json:api} response.

    $e->as_response; # ( $status, [], { errors => [ { detail => $message } ] } )

=head2 json_api_version

Defaults to 1.0; only used in C<as_response>.

=head2 status

HTTP Status code for the exception; in most cases you don't need to
set this manually.

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
