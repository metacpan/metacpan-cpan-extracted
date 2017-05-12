# RT::Client::REST::Attachment -- attachment object representation.

package RT::Client::REST::Attachment;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = 0.03;

use Params::Validate qw(:types);
use RT::Client::REST::Object 0.01;
use RT::Client::REST::Object::Exception 0.03;
use base 'RT::Client::REST::Object';

sub _attributes {{
    id  => {
        validation  => {
            type    => SCALAR,
            regex   => qr/^\d+$/,
        },
    },

    creator_id => {
        validation  => {
            type    => SCALAR,
            regex   => qr/^\d+$/,
        },
        rest_name   => 'Creator',
    },

    parent_id => {
        validation  => {
            type    => SCALAR,
            regex   => qr/^\d+$/,
        },
    },

    subject => {
        validation  => {
            type    => SCALAR,
        },
    },

    content_type  => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => "ContentType",
    },

    file_name => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => 'Filename',
    },

    transaction_id => {
        validation  => {
            type    => SCALAR,
            regex   => qr/^\d+$/,
        },
        rest_name   => 'Transaction',
    },

    message_id => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => 'MessageId',
    },

    created => {
        validation  => {
            type    => SCALAR,
        },
        is_datetime => 1,
    },

    content => {
        validation  => {
            type    => SCALAR,
        },
    },

    headers => {
        validation  => {
            type    => SCALAR,
        },
    },

    parent => {
        validation  => {
            type    => SCALAR,
        },
    },

    content_encoding => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => 'ContentEncoding',
    },
}}

sub rt_type { 'attachment' }

sub retrieve {
    my $self = shift;

    $self->from_form(
        $self->rt->get_attachment(
            parent_id   => $self->parent_id,
            id          => $self->id,
        ),
    );

    $self->{__dirty} = {};

    return $self;
}

my @unsupported = qw(store search count);
# Override unsupported methods.
for my $method (@unsupported) {
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        RT::Client::REST::Object::IllegalMethodException->throw(
            ref($self) . " does not support '$method' method",
        );
    };
}

sub can {
    my ($self, $method) = @_;
    if (grep { $_ eq $method } @unsupported) {
        return;
    }
    return $self->SUPER::can($method);
}

__PACKAGE__->_generate_methods;

1;

__END__

=head1 NAME

RT::Client::REST::Attachment -- this object represents an attachment.

=head1 SYNOPSIS

  my $attachments = $ticket->attachments;

  my $count = $attachments->count;
  print "There are $count attachments.\n";

  my $iterator = $attachments->get_iterator;
  while (my $att = &$iterator) {
      print "Id: ", $att->id, "; Subject: ", $att->subject, "\n";
  }

=head1 DESCRIPTION

An attachment is a second-class citizen, as it does not exist (at least
from the current REST protocol implementation) by itself.  At the moment,
it is always associated with a ticket (see B<parent_id> attribute).
Thus, you will
rarely retrieve an attachment by itself; instead, you should use
C<attachments()> method of L<RT::Client::REST::Ticket> object to get
an iterator for all attachments for that ticket.

=head1 ATTRIBUTES

=over 2

=item B<id>

Numeric ID of the attachment.

=item B<creator_id>

Numeric ID of the user who created the attachment.

=item B<parent_id>

Numeric ID of the object the attachment is associated with.  This is not
a proper attribute of the attachment as specified by REST -- it is simply
to store the ID of the L<RT::Client::REST::Ticket> object this attachment
belongs to.

=item B<subject>

Subject of the attachment.

=item B<content_type>

Content type.

=item B<file_name>

File name (if any).

=item B<transaction_id>

Numeric ID of the L<RT::Client::REST::Transaction> object this attachment
is associated with.

=item B<message_id>

Message ID.

=item B<created>

Time when the attachment was created

=item B<content>

Actual content of the attachment.

=item B<headers>

Headers (not parsed), if any.

=item B<parent>

Parent (not sure what this is yet).

=item B<content_encoding>

Content encoding, if any.

=back

=head1 METHODS

B<RT::Client::REST::Attachment> is a read-only object, so you cannot
C<store()> it.  Also, because it is a second-class citizen, you cannot
C<search()> or C<count()> it -- use C<attachments()> method provided
by L<RT::Client::REST::Ticket>.

=over 2

=item retrieve

To retrieve an attachment, attributes B<id> and B<parent_id> must
be set.

=back

=head1 INTERNAL METHODS

=over 2

=item B<rt_type>

Returns 'attachment'.

=back

=head1 SEE ALSO

L<RT::Client::REST::Ticket>,
L<RT::Client::REST::SearchResult>.

=head1 AUTHOR

Dmitri Tikhonov <dtikhonov@yahoo.com>

=head1 LICENSE

Perl license.

=cut
