package Osgood::Server;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use Catalyst qw/-Debug ConfigLoader Static::Simple Params::Nested/;

our $VERSION = '2.0.1';
our $AUTHORITY = 'cpan:GPHAT';

# Configure the application. 
#
# Note that settings in osgood_server.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'Osgood::Server' );

# Start the application
__PACKAGE__->setup;


=head1 NAME

Osgood::Server - Event Repository

=head1 SYNOPSIS

    create a database (mysql in our example)
    mysql -u root your_database < sql/schema.sql
    edit osgood_server.yml
    script/osgood_server_server.pl

=head1 DESCRIPTION

Osgood is a passive, persistent, stateless event repository.

* Passive: Osgood doesn't seek out events, it only waits for notification of
them.

* Persistent: Events are durable, they do not disappear if the server goes
offline.

* Stateless: Events in Osgood are read-only.  You cannot change them.

What's all that fancy talk mean?  Osgood is a system wherein you record the
fact that something happened.  A client library (L<Osgood::Client> that allows
you to send events to Osgood and to later retrieve them.

Effectively we are talking about an implementation of the Publisher /
Subscriber model.  This implementation is built using HTTP as the medium
and a relational database as the backing store.

An example may help to illustrate the usefulness.

Imagine a company that sells widgets.  Sometimes, customers are unhappy and
cancel the widgets.  When a customer calls to do so, the call center dutifully
cancels the order.  This works fine and the world is a happy place.

One day a new marketing employee decides to try and woo these customers back.
She asks you to build a system to send an email to a customer that cancels,
promising a $5 coupon to come back for more widgets!  This is a great idea,
and it is a great chance to use Osgood.

When the cancellation happens, you add a smidge of code that uses
Osgood::Client to send an event.  You might use descriptions like:

  my $event = Osgood::Event->new(
      object    => 'Order',
      action    => 'canceled',
      params    => {
          id    => 12345
      }
  );
  my $list = Osgood::EventList->new(events => [ $event ]);
  $client->send($list);

Meaning that Order #12345 was canceled.

Later, you whip up a job that runs every hour that queries Osgood for all
the orders that have been canceled.

  $client->query({
      object    => 'Order',
      action    => 'canceled',
  });

Now you have a list!  But every call returns ALL the Order canceled events that
happened, ever!  The query method provides a bunch of constraints to fix that.
The most useful of which is 'id'.  Providing query with an id limits the
returned events to all the events that have an ID GREATER THAN THE ONE
PROVIDED.

There are other constraints provided in L<Osgood::Server::Controller::Event>
such as date_before and date_after.

The advantage of this implementation is that you can create subscribers
to an event without adding any new code to your cancellation process.  State
is maintained by the jobs that do the querying, however you choose to
implement it.  We use ids, you might use dates.

IMPORTANT: 

=head1 PERFORMANCE

Note: See the accompanying section of Osgood::Client as well.

Osgood uses some DBIx::Class shortcuts to pull results faster.  Depending on
database hardware, small numbers of events (hundreds) should be really fast.
Tests have been conducted on lists of 10_000 events and the response time still
falls within ::Client's default 30 second timeout on modern hardware.

=head1 SEE ALSO

L<Osgood::Server::Controller::Root>, L<Catalyst>, L<Osgood::Client>

=head1 AUTHORS

Lauren O'Meara

Cory 'G' Watson <gphat@cpan.org>

=head1 CONTRIBUTORS

Guillermo Roditi (groditi)
Mike Eldridge (diz)

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Magazines.com, LLC

You can redistribute and/or modify this code under the same terms as Perl
itself.

=cut

sub add_from_list {
    my ($self, $list) = @_;

    my $iter = $list->iterator;
    # count events
    my $count = 0;
    my $error = undef;

	my $schema = $self->model('OsgoodDB')->schema;
	$schema->txn_begin;

    while (($iter->has_next) && (!defined($error))) {
        my $event = $iter->next;

        # find or create the action
        my $action = $self->model('OsgoodDB::Action')->find_or_create({
            name => $event->action
        });
        if (!defined($action)) {
            $error = "Error: bad action " . $event->action();
            last;
        }
        # find or create the object
        my $object = $self->model('OsgoodDB::Object')->find_or_create({
            name => $event->object
        });
        if (!defined($object)) {
            $error = "Error: bad object " . $event->object;
            last;
        }
        # create event - this has to be a new thing. no find here. 
        my $db_event = $self->model('OsgoodDB::Event')->create({
            action_id => $action->id,
            object_id => $object->id,
            date_occurred => $event->date_occurred
        });
        if (!defined($db_event)) {
            $error = 'Error: bad event ' . $event->object . ' '
                . $event->action . ' ' . $event->date_occurred;
            last;
        }
        # add all params
        my $params = $event->params;
        if (defined($params)) {
            foreach my $param_name (keys %{$params}) {
                my $event_param = $self->model('OsgoodDB::EventParameter')->create({
                    event_id => $db_event->id,
                    name => $param_name,
                    value => $params->{$param_name}
                });
                if (!defined($event_param)) {
                    $error = 'Error: bad event parameter' .  $param_name .
                             ' ' .  $params->{$param_name};
                }
            }
        }

        # increment count of inserted events
        $count++;
    }

    if (defined($error)) {      # if error, rollback
        $count = 0;             # if error, count is zero. nothing inserted.
        $schema->txn_rollback;
    } else {                    # otherwise, commit
        $schema->txn_commit;
    }

    return ($count, $error);
}

1;
