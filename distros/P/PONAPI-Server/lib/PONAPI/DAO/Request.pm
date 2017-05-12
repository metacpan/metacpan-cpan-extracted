# ABSTRACT: DAO request class
package PONAPI::DAO::Request;

use Moose;
use JSON::MaybeXS;

use PONAPI::Document;

has repository => (
    is       => 'ro',
    does     => 'PONAPI::Repository',
    required => 1,
);

has document => (
    is       => 'ro',
    isa      => 'PONAPI::Document',
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has send_doc_self_link => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

has is_valid => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 1 },
    writer  => '_set_is_valid',
);

has json => (
    is      => 'ro',
    isa     => JSON::MaybeXS::JSON(),
    default => sub { JSON::MaybeXS->new->allow_nonref->utf8->canonical },
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;

    die "[__PACKAGE__] missing arg `version`"
        unless defined $args{version};

    $args{document} = PONAPI::Document->new(
        version  => $args{version},
        req_path => $args{req_path} // '/',
        req_base => $args{req_base} // '/',
    );

    return \%args;
}

# These validation methods will be overwritten in the appropriate roles.
# They cover the case where an attribute is NOT expected.
sub _validate_id {
    my ( $self, $args ) = @_;
    return unless defined $args->{id};
    $self->_bad_request( "`id` is not allowed for this request" )
}

sub _validate_rel_type {
    my ( $self, $args ) = @_;
    return unless defined $args->{rel_type};
    $self->_bad_request( "`relationship type` is not allowed for this request" );
}

sub _validate_include {
    my ( $self, $args ) = @_;
    return unless defined $args->{include};
    $self->_bad_request( "`include` is not allowed for this request" );
}

sub _validate_fields {
    my ( $self, $args ) = @_;
    return unless defined $args->{fields};
    $self->_bad_request( "`fields` is not allowed for this request" );
}

sub _validate_filter {
    my ( $self, $args ) = @_;
    return unless defined $args->{filter};
    $self->_bad_request( "`filter` is not allowed for this request" );
}

sub _validate_sort {
    my ( $self, $args ) = @_;
    return unless defined $args->{sort};
    $self->_bad_request( "`sort` is not allowed for this request" );
}

sub _validate_page {
    my ( $self, $args ) = @_;
    return unless defined $args->{page};
    $self->_bad_request( "`page` is not allowed for this request" );
}

sub BUILD {
    my ( $self, $args ) = @_;

    # `type` exists
    my $type = $self->type;
    return $self->_bad_request( "Type `$type` doesn't exist.", 404 )
        unless $self->repository->has_type( $type );

    $self->_validate_id($args);
    $self->_validate_rel_type($args);
    $self->_validate_include($args);
    $self->_validate_fields($args);
    $self->_validate_filter($args);
    $self->_validate_sort($args);
    $self->_validate_page($args);

    # validate `data`
    if ( exists $args->{data} ) {
        if ( $self->can('data') ) {
            $self->_validate_data;
        }
        else {
            $self->_bad_request( "request body is not allowed" );
        }
    }
    elsif ( $self->can('has_data') ) {
        $self->_bad_request( "request body is missing `data`" );
    }
}

sub response {
    my ( $self, @headers ) = @_;
    my $doc = $self->document;

    $doc->add_self_link
        if $self->send_doc_self_link && !$doc->has_link('self');

    return (
        $doc->status,
        \@headers,
        (
            $doc->status != 204
                ? $doc->build
                : ()
        ),
    );
}

sub _bad_request {
    my ( $self, $detail, $status ) = @_;
    $self->document->raise_error( $status||400, { detail => $detail } );
    $self->_set_is_valid(0);
    return;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request - DAO request class

=head1 VERSION

version 0.003001

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
