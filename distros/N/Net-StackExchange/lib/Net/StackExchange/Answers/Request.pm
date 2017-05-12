package Net::StackExchange::Answers::Request;
BEGIN {
  $Net::StackExchange::Answers::Request::VERSION = '0.102740';
}

# ABSTRACT: Request methods for answers

use Moose;
use Moose::Util::TypeConstraints;

use JSON qw{ decode_json };

with 'Net::StackExchange::Role::Request';

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [
    qw{
        body
        comments
      }
    ] => (
    is     => 'rw',
    isa    => 'Boolean',
    coerce => 1,
);

has [
    qw{
        fromdate
        max
        min
        page
        todate
      }
    ] => (
    is  => 'rw',
    isa => 'Int',
);

has 'pagesize' => (
    is      => 'rw',
    isa     => 'Int',
    trigger => sub {
        my ( $self, $pagesize ) = @_;

        if ( $pagesize < 1 || $pagesize > 100 ) {
            confess 'value should be between 1 and 100 inclusive';
        }
    },
);

has 'order' => (
    is      => 'rw',
    isa     => enum( [ qw{ asc desc } ] ),
    default => 'desc',
);

has 'sort' => (
    is      => 'rw',
    isa     => enum( [ qw{ activity views creation votes } ] ),
    default => 'activity',
);

has '_NSE' => (
    is       => 'rw',
    isa      => 'Net::StackExchange',
    required => 1,
);

sub execute {
    my $self         = shift;
    my $json         = Net::StackExchange::Core::_execute($self);
    my $se           = $self->_NSE();
    my $json_decoded = decode_json($json);

    my $response = Net::StackExchange::Answers::Response->new( {
        '_NSE'          => $se,
        '_json_decoded' => $json_decoded,
        'json'          => $json,
        'total'         => $json_decoded->{'total'   },
        'page'          => $json_decoded->{'page'    },
        'pagesize'      => $json_decoded->{'pagesize'},
    } );
    return $response;
}

sub _get_request_attributes {
    return qw{
               body
               comments
               fromdate
               max
               min
               order
               page
               pagesize
               sort
               todate
             };
}

__PACKAGE__->meta()->make_immutable();

no Moose;
no Moose::Util::TypeConstraints;

1;



=pod

=head1 NAME

Net::StackExchange::Answers::Request - Request methods for answers

=head1 VERSION

version 0.102740

=head1 SYNOPSIS

    use Net::StackExchange;

    my $se = Net::StackExchange->new( {
        'network' => 'stackoverflow.com',
        'version' => '1.0',
    } );

    my $answers_route   = $se->route('answers');
    my $answers_request = $answers_route->prepare_request( { 'id' => 1036353 } );

    $answers_request->body(1);

    my $answers_response = $answers_request->execute();

=head1 ATTRIBUTES

=head2 C<id>

A single primary key identifier or a vectorised, semicolon-delimited list of
identifiers.

=head2 C<body>

When true, a post's body will be included in the response.

=head2 C<comments>

When true, any comments on a post will be included in the response.

=head2 C<fromdate>

Unix timestamp of the minimum creation date on a returned item. Accepted range
is 0 to 253_402_300_799.

=head2 C<max>

Maximum of the range to include in the response according to the current C<sort>.

=head2 C<min>

Minimum of the range to include in the response according to the current C<sort>.

=head2 C<order>

How the current C<sort> should be ordered. Accepted values are C<desc> (default)
or C<asc>.

=head2 C<page>

The pagination offset for the current collection. Affected by the specified
C<pagesize>.

=head2 C<pagesize>

The number of collection results to display during pagination. Should be between
1 and 100 inclusive.

=head2 C<sort>

How a collection should be sorted. Valid values are one of C<activity> (default),
C<views>, C<creation>, or C<votes>.

=head2 C<todate>

Unix timestamp of the maximum creation date on a returned item. Accepted range
is 0 to 253_402_300_799.

=head1 METHODS

=head2 C<execute>

Executes the request and returns a L<Net::StackExchange::Answers::Response>
object.

=head1 CONSUMES ROLES

L<Net::StackExchange::Roles::Request>

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

