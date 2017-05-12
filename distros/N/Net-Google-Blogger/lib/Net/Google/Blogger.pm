package Net::Google::Blogger;

use warnings;
use strict;

use Any::Moose;
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;
use Data::Dumper;

use Net::Google::Blogger::Blog;


our $VERSION = '0.09';

has login_id   => ( is => 'ro', isa => 'Str', required => 1 );
has password   => ( is => 'ro', isa => 'Str', required => 1 );

has blogs => (
    is         => 'ro',
    isa        => 'ArrayRef[Net::Google::Blogger::Blog]',
    lazy_build => 1,
    auto_deref => 1,
);

has ua => (
    builder    => sub { LWP::UserAgent->new },
    lazy_build => 1,
    is         => 'ro',
);

__PACKAGE__->meta->make_immutable;


sub BUILD {
    ## Authenticates with Blogger.
    my $self = shift;

    my $response = $self->ua->post(
        'https://www.google.co.uk/accounts/ClientLogin',
        {
            Email       => $self->login_id,
            Passwd      => $self->password,
            service     => 'blogger',
        }
    );

    unless ($response->is_success) {
        my $error_msg = ($response->content =~ /\bError=(.+)/)[0] || 'Google error message unavailable';
        die 'HTTP error when trying to authenticate: ' . $response->status_line . " ($error_msg)";
    }

    my ($auth_token) = $response->content =~ /\bAuth=(.+)/
        or die 'Authentication token not found in the response: ' . $response->content;

    $self->ua->default_header(Authorization => "GoogleLogin auth=$auth_token");
    $self->ua->default_header(Content_Type => 'application/atom+xml');
}


sub _build_blogs {
    ## Populates 'blogs' property with list of instances of Net::Google::Blogger::Blog.
    my $self = shift;

    my $response = $self->http_get('http://www.blogger.com/feeds/default/blogs');
    my $response_tree = XML::Simple::XMLin($response->content, ForceArray => 1);

    return [
        map Net::Google::Blogger::Blog->new(
                source_xml_tree => $_,
                blogger         => $self,
            ),
            @{ $response_tree->{entry} }
   ];
}


sub http_put {
    ## Executes a PUT request using configured user agent instance.
    my $self = shift;
    my ($url, $content) = @_;

    my $request = HTTP::Request->new(PUT => $url, $self->ua->default_headers, $content);
    return $self->ua->request($request);
}


sub http_get {
    ## Executes a GET request.
    my $self = shift;
    my @req_args = @_;

    return $self->ua->get(@req_args);
}


sub http_post {
    ## Executes a POST request.
    my $self = shift;
    my @args = @_;

    return $self->ua->request(HTTP::Request::Common::POST(@args));
}


__END__

=head1 NAME

Net::Google::Blogger - (** DEPRECATED **) Interface to Google's Blogger service.

=head1 VERSION

Version 0.09

=cut

1;

=head1 SYNOPSIS

This module is deprecated. Please use L<WebService::Blogger>.

This module suite provides interface to the Blogger service now run by
Google. It's built in object-oriented fashion using Moose, which makes
it easy to use and extend. It also utilizes newer style GData API for
better compatibility. You can retrieve list of blogs for your account,
add, update or delete entries.

 use Net::Google::Blogger;

 my $blogger = Net::Google::Blogger->new(
     login_id   => 'myemail@gmail.com',
     password   => 'mypassword',
 );

 my @blogs = $blogger->blogs;
 foreach my $blog (@blogs) {
     print join ', ', $blog->id, $blog->title, $blog->public_url, "\n";
 }

 my $blog = $blogs[1];
 my @entries = $blog->entries;

 my ($entry) = @entries;
 print $entry->title, "\n", $entry->content;

 $entry->title('Updated Title');
 $entry->content('Updated content');
 $entry->categories([ qw/category1 category2/ ]);
 $entry->save;

 my $new_entry = Net::Google::Blogger::Blog::Entry->new(
     title   => 'New entry',
     content => 'New content',
     blog    => $blog,
 );
 $new_entry->save;
 $new_entry->delete;


=head1 SUBROUTINES/METHODS

=head2 new

Creates a new instance of Blogger account object. This method will
connect to the server and authenticate with the given credentials. 
Authentication token received will be stored privately and used in
all subsequent requests.

 my $blogger = Net::Google::Blogger->new(
     login_id   => 'myemail@gmail.com',
     password   => 'mypassword',
 );

=cut

=head2 blogs

Returns list of blogs for the account, as either array or array
reference, depending on the context. The array is composed of
instances of L<Net::Google::Blogger::Blog>.

=cut

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 BUGS

Deletion of entries is currently not supported.

Please report any bugs or feature requests to C<bug-net-google-api-blogger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Google-Blogger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Google::Blogger


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Google-Blogger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Google-Blogger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Google-Blogger>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Google-Blogger/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Egor Shipovalov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

