# RT::Client::REST::Queue -- queue object representation.

package RT::Client::REST::Queue;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.02';

use Params::Validate qw(:types);
use RT::Client::REST 0.20;
use RT::Client::REST::Object 0.01;
use RT::Client::REST::Object::Exception 0.01;
use RT::Client::REST::SearchResult 0.02;
use RT::Client::REST::Ticket;
use base 'RT::Client::REST::Object';

=head1 NAME

RT::Client::REST::Queue -- queue object representation.

=head1 SYNOPSIS

  my $rt = RT::Client::REST->new(server => $ENV{RTSERVER});

  my $queue = RT::Client::REST::Queue->new(
    rt  => $rt,
    id  => 'General',
  )->retrieve;

=head1 DESCRIPTION

B<RT::Client::REST::Queue> is based on L<RT::Client::REST::Object>.
The representation allows one to retrieve, edit, comment on, and create
queue in RT.

Note: RT currently does not allow REST client to search queues.

=cut

sub _attributes {{
    id  => {
        validation  => {
            type    => SCALAR,
        },
        form2value  => sub {
            shift =~ m~^queue/(\d+)$~i;
            return $1;
        },
        value2form  => sub {
            return 'queue/' . shift;
        },
    },

    name   => {
        validation  => {
            type    => SCALAR,
        },
    },

    description => {
        validation  => {
            type    => SCALAR,
        },
    },

    correspond_address => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => 'CorrespondAddress',
    },

    comment_address => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => 'CommentAddress',
    },

    initial_priority => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => 'InitialPriority',
    },

    final_priority => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => 'FinalPriority',
    },

    default_due_in => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => 'DefaultDueIn',
    },

    disabled => {
        validation => {
            type   => SCALAR,
        },
    },
}}

=head1 ATTRIBUTES

=over 2

=item B<id>

For retrieval, you can specify either the numeric ID of the queue or its
name (case-sensitive).  After the retrieval, however, this attribute will
be set to the numeric id.

=item B<name>

This is the name of the queue.

=item B<description>

Queue description.

=item B<correspond_address>

Correspond address.

=item B<comment_address>

Comment address.

=item B<initial_priority>

Initial priority.

=item B<final_priority>

Final priority.

=item B<default_due_in>

Default due in.

=back

=head1 DB METHODS

For full explanation of these, please see B<"DB METHODS"> in
L<RT::Client::REST::Object> documentation.

=over 2

=item B<retrieve>

Retrieve queue from database.

=item B<store>

Create or update the queue.

=item B<search>

Currently RT does not allow REST clients to search queues.

=back

=head1 QUEUE-SPECIFIC METHODS

=over 2

=item B<tickets>

Get tickets that are in this queue (note: this may be a lot of tickets).
Note: tickets with status "deleted" will not be shown.
Object of type L<RT::Client::REST::SearchResult> is returned which then
can be used to get to objects of type L<RT::Client::REST::Ticket>.

=cut

sub tickets {
    my $self = shift;

    $self->_assert_rt_and_id;

    return RT::Client::REST::Ticket
        ->new(rt => $self->rt)
        ->search(limits => [
            {attribute => 'queue', operator => '=', value => $self->id},
        ]);
}

=back

=head1 INTERNAL METHODS

=over 2

=item B<rt_type>

Returns 'queue'.

=cut

sub rt_type { 'queue' }

=back

=head1 SEE ALSO

L<RT::Client::REST>, L<RT::Client::REST::Object>,
L<RT::Client::REST::SearchResult>,
L<RT::Client::REST::Ticket>.

=head1 AUTHOR

Dmitri Tikhonov <dtikhonov@yahoo.com>

=head1 LICENSE

Perl license.

=cut

__PACKAGE__->_generate_methods;

1;
