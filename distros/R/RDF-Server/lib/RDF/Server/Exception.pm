package RDF::Server::Exception;

use Moose;

has status => (
    is => 'rw',
    isa => 'Int',
);

has content => (
    is => 'rw',
    isa => 'Str',
);

has headers => (
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    default => sub { +{ } }
);

no Moose;

sub throw {
    my $class = shift;
    my %headers = @_;
    my $status;
    my $content;
    $content = delete $headers{Content} || delete $headers{content};
    $status = delete $headers{Status} || delete $headers{status};
    my $self = $class -> new(headers => \%headers);
    $self -> content($content) if defined $content;
    $self -> status($status) if defined $status;
    die $self;
}

{
    my $build_class = sub {
        my( $status, $type, $content, $headers ) = @_;

        my $header_code = '';

        if( $headers ) {
            $header_code = <<1HERE1;
has '+headers' => (
    default => sub { \$headers }
);
1HERE1
        }

        eval <<1HERE1;
package RDF::Server::Exception::$type;

use Moose;

extends 'RDF::Server::Exception';

has '+status' => (
    default => sub { \$status }
);

has '+content' => (
    default => sub{ \$content }
);

$header_code

1;
1HERE1
    };

    $build_class->( 400, 'BadRequest', 'Bad Request!');
    $build_class->( 403, 'Forbidden', 'Forbidden!');
    $build_class->( 404, 'NotFound', 'Not Found!');
    $build_class->( 405, 'MethodNotAllowed', 'Method Not Allowed!');
    $build_class->( 409, 'Conflict', 'Conflict!');
    $build_class->( 500, 'InternalServerError', 'Internal Server Error!');
}

1;
__END__

=pod

=head1 NAME

RDF::Server::Exception - exception classes

=head1 SYNOPSIS

 use RDF::Server::Exception;

 throw RDF::Server::Exception::NotFound;

=head1 DESCRIPTION

=head1 EXCEPTIONS

=over 4

=item BadRequest (400)

=item Forbidden (403)

=item NotFound (404)

=item MethodNotAllowed (405)

=item Conflict (409)

=item InternalServerError (500)

=back

=head1 METHODS

=over 4

=item throw (%headers)

Use C<throw> to propagate an error up the call stack.  This will 
bypass any further processing of a request and immediately cause the 
framework to return the given error.

The C<Content> and C<Status> headers are special and will set the content and
status of the response.  All other key value pairs will be used to set the
response headers.

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

