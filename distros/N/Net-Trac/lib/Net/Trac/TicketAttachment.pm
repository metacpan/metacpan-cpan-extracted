use strict;
use warnings;

package Net::Trac::TicketAttachment;

use Any::Moose;
use URI::Escape qw(uri_escape);

=head1 NAME

Net::Trac::TicketAttachment - Represents a single attachment for a Trac ticket

=head1 DESCRIPTION

This class represents a single attachment for a Trac ticket.  You do not want
to deal with instantiating this class yourself.  Instead let L<Net::Trac::Ticket>
do the work.

=head1 ACCESSORS

=head2 connection

Returns the L<Net::Trac::Connection> used by this class.

=head2 ticket

Returns the ID of the ticket to which this attachment belongs.

=head2 filename

=head2 description

=head2 url

Relative to the remote Trac instance URL as set in the L<Net::Trac::Connection>.

=head2 content

returns the content of the attachment

=head2 content_type

returns the content_type of the attachment

=head2 size

In bytes.

=head2 author

=head2 date

Returns a L<DateTime> object.

=cut

has connection => ( isa => 'Net::Trac::Connection', is => 'ro' );
has ticket      => ( isa => 'Int',      is => 'ro' );
has date        => ( isa => 'DateTime', is => 'rw' );
has filename    => ( isa => 'Str',      is => 'rw' );
has description => ( isa => 'Str',      is => 'rw' );
has url         => ( isa => 'Str',      is => 'rw' );
has author      => ( isa => 'Str',      is => 'rw' );
has size        => ( isa => 'Int',      is => 'rw' );
has content => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub { ($_[0]->_load)[0] },
);

has content_type => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub { ($_[0]->_load)[1] },
);


=head1 PRIVATE METHODS

=head2 _parse_html_chunk STRING

Parses a specific chunk of HTML (as extracted by L<Net::Trac::Ticket>) into
the various fields.

=cut

sub _parse_html_chunk {
    my $self = shift;
    my $html = shift;

#      <a href="/trac/attachment/ticket/1/xl0A1UDD4i" title="View attachment">xl0A1UDD4i</a>
#      (<span title="27 bytes">27 bytes</span>) - added by <em>hiro</em>
#      <a class="timeline" href="/trac/timeline?from=2008-12-30T15%3A45%3A24Z-0500&amp;precision=second" title="2008-12-30T15:45:24Z-0500 in Timeline">0 seconds</a> ago.
#    </dt>
#                <dd>
#                  Test description
#                </dd>

# for individual attachment page, the html is like:
#
#    <div id="content" class="attachment">
#        <h1><a href="/xx/ticket/2">Ticket #2</a>: test.2.txt</h1>
#        <table id="info" summary="Description">
#          <tbody>
#            <tr>
#              <th scope="col">
#                File test.2.txt, <span title="5 bytes">5 bytes</span>
#                (added by sunnavy,  <a class="timeline" href="/xx/timeline?from=2009-05-27T14%3A31%3A02Z%2B0800&amp;precision=second" title="2009-05-27T14:31:02Z+0800 in Timeline">13 seconds</a> ago)
#              </th>
#            </tr>
#            <tr>
#              <td class="message searchable">
#                <p>
#blalba
#</p>
#
#              </td>
#            </tr>
#          </tbody>
#        </table>
#    </div>
    

    $self->filename($1) if $html =~ qr{<a (?:.+?) title="View attachment">(.+?)</a>};
    $self->url( "/raw-attachment/ticket/"
          . $self->ticket . "/"
          . uri_escape( $self->filename ) )
      if defined $self->filename;

    $self->size($1)   if $html =~ qr{<span title="(\d+) bytes">};
    $self->author($1) if $html =~ qr{added by (?:<em>)?\s*(\w+)};
    if ( $html =~ qr{<a (?:.+?) title="(.+?) in Timeline">} ) {
        my $scalar_date = $1;
        $self->date( Net::Trac::Ticket->timestamp_to_datetime($scalar_date) );
    }
    $self->description($1) if $html =~ qr{(?:<dd>|<p>)\s*(.*?)\s*(?:</dd>|</p>)}s;

    return 1;
}

sub _load {
    my $self = shift;
    my $content = $self->connection->_fetch( $self->url );
    my $content_type;
    my $type_header = $self->connection->mech->response->header('Content-Type');
    if ( $type_header =~ /(\S+?);/ ) {
        $content_type = $1;
    }
    $self->content( $content );
    $self->content_type( $content_type );
    return $content, $content_type;
}

=head1 LICENSE

Copyright 2008-2009 Best Practical Solutions.

This package is licensed under the same terms as Perl 5.8.8.

=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
