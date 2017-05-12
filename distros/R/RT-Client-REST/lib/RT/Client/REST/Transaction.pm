# RT::Client::REST::Transaction -- transaction object representation.

package RT::Client::REST::Transaction;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = 0.01;

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

    creator => {
        validation  => {
            type    => SCALAR,
        },
    },

    type => {
        validation  => {
            type    => SCALAR,
        },
    },

    old_value => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => "OldValue",
    },

    new_value  => {
        validation  => {
            type    => SCALAR,
        },
        rest_name => "NewValue",
    },

    parent_id => {
        validation  => {
            type    => SCALAR,
            regex   => qr/^\d+$/,
        },
        rest_name   => 'Ticket',
    },

    attachments => {
        validation  => {
            type    => SCALAR,
        },
    },

    time_taken => {
        validation  => {
            type    => SCALAR,
        },
        rest_name   => 'TimeTaken',
    },

    field => {
        validation  => {
            type    => SCALAR,
        },
    },

    content => {
        validation  => {
            type    => SCALAR,
        },
    },

    created => {
        validation  => {
            type    => SCALAR,
        },
        is_datetime => 1,
    },

    description => {
        validation  => {
            type    => SCALAR|UNDEF,
        },
    },

    data => {
        validation  => {
            type    => SCALAR,
        },
    },
}}

sub rt_type { 'transaction' }

sub retrieve {
    my $self = shift;

    $self->from_form(
        $self->rt->get_transaction(
            parent_id   => $self->parent_id,
            id          => $self->id,
        ),
    );

    $self->{__dirty} = {};

    return $self;
}

# Override unsupported methods.
for my $method (qw(store search count)) {
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        RT::Client::REST::Object::IllegalMethodException->throw(
            ref($self) . " does not support '$method' method",
        );
    };
}

__PACKAGE__->_generate_methods;

1;

__END__

=head1 NAME

RT::Client::REST::Transaction -- this object represents a transaction.

=head1 SYNOPSIS

  my $transactions = $ticket->transactions;

  my $count = $transactions->count;
  print "There are $count transactions.\n";

  my $iterator = $transactions->get_iterator;
  while (my $tr = &$iterator) {
      print "Id: ", $tr->id, "; Type: ", $tr->type, "\n";
  }

=head1 DESCRIPTION

A transaction is a second-class citizen, as it does not exist (at least
from the current REST protocol implementation) by itself.  At the moment,
it is always associated with a ticket (see B<parent_id> attribute).
Thus, you will
rarely retrieve a transaction by itself; instead, you should use
C<transactions()> method of L<RT::Client::REST::Ticket> object to get
an iterator for all (or some) transactions for that ticket.

=head1 ATTRIBUTES

=over 2

=item B<id>

Numeric ID of the transaction.

=item B<creator>

Username of the user who created the transaction.

=item B<parent_id>

Numeric ID of the object the transaction is associated with.

=item B<type>

Type of the transactions.  Please referer to L<RT::Client::REST>
documentation for the list of transaction types you can expect this
field to contain.  Note that there may be some transaction types not
(dis)covered yet.

=item B<old_value>

Old value.

=item B<new_value>

New value.

=item B<field>

Name of the field the transaction is describing (if any).

=item B<attachments>

I have never seen it set to anything yet.  (I will some day investigate this).

=item B<created>

Time when the transaction was created.

=item B<content>

Actual content of the transaction.

=item B<description>

Human-readable description of the transaction as provided by RT.

=item B<data>

Not sure what this is yet.

=back

=head1 METHODS

B<RT::Client::REST::Transaction> is a read-only object, so you cannot
C<store()> it.  Also, because it is a second-class citizen, you cannot
C<search()> or C<count()> it -- use C<transactions()> method provided
by L<RT::Client::REST::Ticket>.

=over 2

=item retrieve

To retrieve a transaction, attributes B<id> and B<parent_id> must be set.

=back

=head1 INTERNAL METHODS

=over 2

=item B<rt_type>

Returns 'transaction'.

=back

=head1 SEE ALSO

L<RT::Client::REST>,
L<RT::Client::REST::Ticket>,
L<RT::Client::REST::SearchResult>.

=head1 AUTHOR

Dmitri Tikhonov <dtikhonov@yahoo.com>

=head1 LICENSE

Perl license.

=cut
