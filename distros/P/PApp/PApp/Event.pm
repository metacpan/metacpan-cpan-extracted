##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Event - catch/broadcast various events

=head1 SYNOPSIS

 use PApp::Event;

=head1 DESCRIPTION

This module allows you to broadcast asynchroneous events to all other papp
applications.

Why is this useful? A common scenario is this: Often you want to implement
some internal data caching. PApp itself caches it's translation files,
content management systems often cache frequently-used content objects.

Whenever these caches are invalidated, one papp application (or an
external program) needs to signal all running application instances (maybe
even on multiple machines) to delete all or some specific cache entry.

This is what this module is for.

=over 4

=cut

package PApp::Event;

require 5.006;

use PApp::SQL;
use PApp::Config qw(DBH $DBH); DBH;
use PApp::Exception ();
use Compress::LZF ':freeze';

$VERSION = 2.3;

our $event_count;

=item on "event_type" => \&coderef

Register a handler that is called on the named event. The handler will
receive the C<event_type> as first argument. The remaining arguments
consist of all the scalars that have been broadcasted (i.e. multiple
events of the same type get "bundled" into one call), sorted in the order
of submittal, i.e. the newest event data comes last.

When called in a scalar context (as opposed to void context), it returns
an a handler id. When this handler id is destroyed (e.g. by going out of
scope), the handler itself will be removed.

The current contents of $PApp::SQL::Database/DBH will be saved and
restored while the handler runs.

=cut

sub PApp::Event::handler::DESTROY {
   my $handlers = $handler{$_[0][0]};

   for (0 .. $#handlers) {
      if ($handlers[$_] == $_[0][1]) {
         splice @$handlers, $_, 1;
         return;
      }
   }

}

sub on($&) {
   my $handler = [$_[1], $PApp::SQL::Database];

   push @{$handler{$_[0]}}, $handler;
   no warnings;
   return bless [ $_[0], $handler ], PApp::Event::handler:: if defined wantarray;
}

=item broadcast "event_type" => $data[, $data...]

Broadcast an event of the named type, together with any number of scalars
(each representing a single event!). The event handlers registered in
the current process for the given type will be executed before this call
returns, other events might or might not be processed. If you want to
force processing of events, call C<PApp::Event::check>.

=cut

sub broadcast($;@) {
   my $event = shift;
   my $id;

   sql_exec $DBH, "lock tables event write, event_count write";

   for (@_) {
      #use PApp::Util; print STDERR "broadcast $event: ", PApp::Util::dumpval $_, "\n";#d#

      $id = sql_insertid sql_exec $DBH,
                  "insert into event (id, ctime, event, data) values (NULL,NULL,?,?)",
                  $event, sfreeze_cr $_;
   }

   sql_exec $DBH, "update event_count set count = ? where count < ?", $id, $id;

   sql_exec $DBH, "unlock table";

   if (@_) {
      $id > $event_count
         or die "FATAL: event table corrupted; new id $id <= current event_count $event_count";

      handle_events ($id) if @_;
   }
}

sub skip_all_events {
   $event_count = eval { sql_fetch $DBH, "select count from event_count" };
}

skip_all_events;

=item check

Check for any outstanding events and execute them, if any.

=cut

sub check() {
   handle_events (sql_fetch $DBH, "select count from event_count");
}

sub handle_event {
   for (@{$handler{$_[0]}}) {
      local $PApp::SQL::Database = $_->[1];
      local $PApp::SQL::DBH      = $_->[1] ? $_->[1]->checked_dbh : ();

      &{$_->[0]};
   }
}

sub handle_events {
   my $new_count = $_[0];

   return if $new_count == $event_count;

   my $st = sql_exec $DBH,
                     \my($event, $data),
                     "select event, data
                      from event
                      where id > ? and id <= ?
                      order by id, event",
                     $event_count, $new_count;
   $event_count = $new_count;

   my $levent;
   my @ldata;

   while ($st->fetch) {
      if ($levent ne $event) {
         handle_event $levent, @ldata if @ldata;
         $levent = $event;
         @ldata = ();
      }
      push @ldata, sthaw $data;
   }

   handle_event $levent, @ldata if @ldata;
}

1;

=back

=head1 Example

This example implements caching of a costly operation in a local hash:

  our %cache;

  sub fetch_element {
     my $id = shift;

     return
        $cache{$id}
           ||= costly_operation (sql_fetch "...", $id));
  }

C<costly_operation> will only be run when the C<%cache> doesn't yet
contain a cached version. Whenever the SQL database is updated, all other
clients must invalidate their caches. A simple version (that just removes
ALL entries) is this:

  PApp::Event::on demo_flush_cache => sub {
     %cache = ();
  };

  # after changes in the database:
  PApp::Event::broadcast demo_flush_cache => undef;

A more efficient version (when updates are frequent) only deletes the
entries that were updated. The C<$id> is given as the argument to
C<broadcast> (which only accepts a single scalar). The C<on>-handler,
however, receives all arguments in one run:

  PApp::Event::on demo_flush_cache => sub {
     shift; # get rid of event_type
     delete $cache{$_} for @_; # iterate over all arguments
  };

  # after changes in the database:
  PApp::Event::broadcast demo_flush_cache => $id;

=head1 SEE ALSO

L<PApp>.


=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

