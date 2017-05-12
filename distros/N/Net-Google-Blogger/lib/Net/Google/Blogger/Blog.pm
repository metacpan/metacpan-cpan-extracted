package Net::Google::Blogger::Blog;

use warnings;
use strict;

use Any::Moose;
use XML::Simple ();
use URI::Escape ();

use Net::Google::Blogger::Blog::Entry;


our $VERSION = '0.09';

has id              => ( is => 'ro', isa => 'Str', required => 1 );
has numeric_id      => ( is => 'ro', isa => 'Str', required => 1 );
has title           => ( is => 'rw', isa => 'Str', required => 1 );
has public_url      => ( is => 'ro', isa => 'Str', required => 1 );
has id_url          => ( is => 'ro', isa => 'Str', required => 1 );
has post_url        => ( is => 'ro', isa => 'Str', required => 1 );
has source_xml_tree => ( is => 'ro', isa => 'HashRef', required => 1 );
has blogger         => ( is => 'ro', isa => 'Net::Google::Blogger', required => 1 );

has entries => (
    is         => 'rw',
    isa        => 'ArrayRef[Net::Google::Blogger::Blog::Entry]',
    lazy_build => 1,
    auto_deref => 1,
);

__PACKAGE__->meta->make_immutable;


sub BUILDARGS {
    ## Parses source XML into initial attribute values.
    my $class = shift;
    my %params = @_;

    my $id = $params{source_xml_tree}{id}[0];
    my $links = $params{source_xml_tree}{link};

    return {
        id         => $id,
        numeric_id => $id =~ /(\d+)$/,
        title      => $params{source_xml_tree}{title}[0]{content},
        id_url     => (grep $_->{rel} eq 'self', @$links)[0]{href},
        public_url => (grep $_->{rel} eq 'alternate', @$links)[0]{href},
        post_url   => (grep $_->{rel} =~ /#post$/, @$links)[0]{href},
        %params,
    };
}


sub _build_entries {
    ## Populates the entries attribute, loading all entries for the blog.
    my $self = shift;

    # Search with no parameters.
    return $self->search_entries;
}


sub search_entries {
    ## Returns entries matching search criteria.
    my $self = shift;
    my %params = @_;

    # Construct request URL, incorporating category criteria into it, if given.
    my $url = 'http://www.blogger.com/feeds/' . $self->numeric_id . '/posts/default';
    $url .= '/-/' . join '/', map URI::Escape::uri_escape($_), @{ $params{categories} }
        if $params{categories};

    # Map our parameter names to Blogger's.
    my %params_to_req_args_map = (
        max_results   => 'max-results',
        published_min => 'published-min',
        published_max => 'published-max',
        updated_min   => 'updated-min',
        updated_max   => 'updated-max',
        order_by      => 'orderby',
        offset        => 'start-index',
    );

    # Map our sort mode parameter names to Blogger's.
    my %sort_mode_map = (
        last_modified => 'lastmodified',
        start_time    => 'starttime',
        updated       => 'updated',
    );

    # Populate request arguments hash WRT above mappings.
    my %req_args = (
        alt => 'atom',
    );
    foreach (keys %params_to_req_args_map) {
        $req_args{$params_to_req_args_map{$_}} = $params{$_} if exists $params{$_};
    }
    if (my $sort_mode = $params{sort_by}) {
        $req_args{orderby} = $sort_mode_map{$sort_mode};
    }

    # Execute request and parse the response.
    my $response = $self->blogger->http_get($url, %req_args);
    my $response_tree = XML::Simple::XMLin($response->content, ForceArray => 1);

    # Return list of entry objects constructed from list of hashes in parsed data.
    my @entries
        = map Net::Google::Blogger::Blog::Entry->new(
                  source_xml_tree => $_,
                  blog            => $self,
              ),
              @{ $response_tree->{entry} };
    return wantarray ? @entries : \@entries;
}


sub add_entry {
    ## Adds given entry to the blog.
    my $self = shift;
    my ($entry) = @_;

    my $response = $self->blogger->http_post(
        $self->post_url,
        'Content-Type' => 'application/atom+xml',
        Content        => $entry->as_xml,
    );

    die 'Unable to add entry to blog: ' . $response->status_line unless $response->is_success;
    $entry->update_from_http_response($response);

    push @{ $self->entries }, $entry;
    return $entry;
}


sub delete_entry {
    ## Deletes given entry from server as well as list of entries held in blog object.
    my $self = shift;
    my ($entry) = @_;

    my $response = $self->blogger->http_post(
        $entry->edit_url,
        'X-HTTP-Method-Override' => 'DELETE',
    );
    die 'Could not delete entry from server: ' . $response->status_line unless $response->is_success;

    $self->entries([ grep $_ ne $entry, $self->entries ]);
}


sub destroy {
    ## Removes references to the blog from child entries, so they're
    ## no longer circular. Blog object as well as entries can then be
    ## garbage-collected.
    my $self = shift;

    $_->blog(undef) foreach $self->entries;
}


1;

__END__

=head1 NAME

Net::Google::Blogger::Blog - (** DEPRECATED **) represents blog entity of Google Blogger service.

=head1 SYNOPSIS

This module is deprecated. Please use L<WebService::Blogger>.

=head1 DESCRIPTION

This class represents a blog in Net::Google::Blogger package. As of
present, you should never instantiate it directly. Only C<title>,
C<public_url> and C<entries> attributes are for public use, other are
subject to change in future versions.

=head1 METHODS

=head3 C<add_entry($entry)>

=over

Adds given entry to the blog. The argument must be an instance of Net::Google::Blogger::Blog::Entry

=back

=head3 C<delete_entry($entry)>

=over

Deletes given entry from server as well as list of entries held in blog object.

=back

=head3 C<search_entries(%criteria)>

=over

Returns entries matching specified conditions. The following example
contains all possible search criteria:

my @entries = $blog->search_entries(
     published_min => '2010-08-10T23:25:00+04:00'
     published_max => '2010-07-17T23:25:00+04:00',
     updated_min   => '2010-09-17T12:25:00+04:00',
     updated_max   => '2010-09-17T14:00:00+04:00',
     order_by      => 'start_time', # can also be: 'last_modified' or 'updated'
     max_results   => 20,
     offset        => 10,           # skip first 10 entries
 );

=back

=head3 C<destroy()>

=over

Removes references to the blog from child entries, so they're no
longer circular. Blog object as well as entries can then be
garbage-collected.

=back

=head1 ATTRIBUTES

=head3 C<title>

=over

Title of the blog.

=back

=head3 C<public_url>

=over

The human-readable, SEO-friendly URL of the blog.

=back

=head3 C<id_url>

=over

The never-changing URL of the blog, based on its numeric ID.

=back

=head3 C<entries>

=over

List of blog entries, lazily populated.

=back

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 BUGS

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


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Egor Shipovalov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
