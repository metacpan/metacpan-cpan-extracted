package Net::Groonga::HTTP;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.03";

use JSON::XS qw(encode_json);
use Furl;
use URI;
use Net::Groonga::HTTP::Response;

use Mouse;

has end_point => ( is => 'ro', required => 1 );

has ua => (
    is => 'ro',
    default => sub {
        Furl->new(
            agent => "Net::Groonga::HTTP/$VERSION",
            timeout => 3
        )
    }
);

no Mouse;

sub construct_api_url {
    my ($self, $name, %args) = @_;
    my $url = $self->end_point;
    $url =~ s!/$!!;
    my $uri = URI->new("$url/$name");
    $uri->query_form(%args);
    $uri;
}

sub call {
    my ($self, $function, %args) = @_;
    my $url = $self->construct_api_url($function, %args);
    my $res = $self->ua->get($url);
    return Net::Groonga::HTTP::Response->new(
        function      => $function,
        http_response => $res,
        args          => \%args,
    );
}

my @functions = qw(
    table_create
    column_create
    status
    select
    delete
    dump
);
for my $function (@functions) {
    no strict 'refs';
    *{__PACKAGE__ . "::${function}"} = sub {
        my ($self, %args) = @_;
        $self->call($function, %args);
    };
}

sub load {
    my ($self, %args) = @_;
    $args{values} = encode_json($args{values}) if ref $args{values};
    return $self->call('load', %args);
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::Groonga::HTTP - Client library for Groonga httpd.

=head1 SYNOPSIS

    use Net::Groonga::HTTP;

    my $groonga = Net::Groonga::HTTP->new(
        end_point => 'http://127.0.0.1:10041/d/',
    );
    my $res = $groonga->status();
    use Data::Dumper; warn Dumper($res);


=head1 DESCRIPTION

Net::Groonga::HTTP is a client library for Groonga http server.

Groonga is a fast full text search engine. Please look L<http://groonga.org/>.

=head1 CONSTRUCTOR

    Net::Groonga::HTT->new(%args);

You can create instance with following arguments:

=over 4

=item end_point :Str

API end point URL for Groonga httpd.

Example:

    Net::Groonga::HTTP->new(end_point => 'http://127.0.0.1:10041/d/');

=item ua : Furl

Instance of Furl to access Groonga httpd.

Example:

    Net::Groonga::HTTP->new(ua => Furl->new());

=back

=head1 METHODS

=over 4

=item C<< $groonga->call($function, %args) >>

Call a http server. Function name is C<< $function >>. Pass the C<< %args >>.

This method returns instance of L<Net::Groonga::HTTP::Response>.

=item $groonga->load(%args)

    $groonga->load(
        table => 'Entry',
        values => \@values,
    );

Load the data to database. This method encodes I<values> to JSON automatically, if it's arrayref.

=item $groonga->select(%args)

=item $groonga->status(%args)

=item $groonga->select(%args)

=item $groonga->delete(%args)

=item $groonga->column_create(%args)

=item $groonga->dump(%args)

You can use these methods if you are lazy.

=back

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

