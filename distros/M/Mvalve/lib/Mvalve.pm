# $Id$

package Mvalve;
use Mvalve::Const;
use Mvalve::Types;
use Mvalve::Message;
use Mvalve::Reader;
use Mvalve::Throttler;
use Mvalve::Writer;
use Time::HiRes();

our $VERSION   = '0.00014';
our $AUTHORITY = "cpan:DMAKI";

sub trace { print STDERR "MVALVE: @_\n" }

1;

__END__

=head1 NAME

Mvalve - Generic Q4M Powered Message Pipe

=head1 SYNOPSIS

  my $writer = Mvalve::Writer->new(
    queue => {
      args => {
        connect_info => [ 'dbi:mysql:dbname=...', ..., ... ]
      }
    }
  );

  my $reader = Mvalve::Reader->new(
    state => {
      args => {
      }
    },
    queue => {
      module => "...",
      args => {
        connect_info => [ ... ]
      }
    },
    throttler => {
      args => {
        max_items => $max,
        interval  => $interval,
        cache     => {
          data => [ ... ]
        }
      }
    }
  );

  $writer->insert( Mvalve::Message->new(...) );

  while ( 1 ) {
    my $message = $reader->next;
    if ($message) {
      # do whatever
    }
  }

=head1 DESCRIPTION

Mvalve stands for "Messave Valve". It is a frontend for Q4M powered set of
queues, acting as a single pipe.

Mvalve contains a reader and a writer. It's constructed like this because
typically Mvalve operations are done in separate, read-only or write-only
processes, so you don't need both to do the job.

All throttling is done at the reader side, so the only thing that the writer
needs is the information about the queue:

  Mvalve::Writer->new( queue => $queue_object );
  # or
  Mvalve::Writer->new(
    queue => {
      args => {
        connect_info => [ 'dbi:mysql:dbname=...', ..., ... ]
      }
    }
  );

The reader needs a bit more information:

  Mvalve::Reader->new(
    queue => $queue_object,
    throttler => $throttler_object, # optional - default will be provided
    state => $state_object,         # optional - default will be provided
  );
  # or
  Mvalve::Reader->new(
    queue => {
      module => "Q4M",
      args => {
        connect_info => [ 'dbi:mysql:dbname=...', ..., ... ]
      }
    },
    throttler => {
      module => "Data::Valve",
      args => {
        max_items => 1,
        interval  => 10,
        store     => {
          module => "Memcached",
          args => {
            servers => [ ... ]
          }
        }
      }
    },
    state => {
      module => "Memcached",
      args => {
       servers => [ ... ]
      }
    }
  );

=head1 SETUP

You need to have installed mysql 5.1 or later and q4m. You can grab
them at:

  http://dev.mysql.com/
  http://q4m.31tools.com/

Once you have a q4m-enabled mysql running, you need to create these q4m 
enabled tables in your mysql database.

  CREATE TABLE q_emerg (
     destination VARCHAR(40) NOT NULL,
     message     BLOB NOT NULL
  ) ENGINE=QUEUE DEFAULT CHARSET=utf8;
 
  CREATE TABLE q_timed (
     destination VARCHAR(40) NOT NULL,
     ready       BIGINT NOT NULL,
     message     BLOB NOT NULL
  ) ENGINE=QUEUE DEFAULT CHARSET=utf8;
 
  CREATE TABLE q_incoming (
     destination VARCHAR(40) NOT NULL,
     message     BLOB NOT NULL
  ) ENGINE=QUEUE DEFAULT CHARSET=utf8;

  CREATE TABLE q_statslog (
     action      VARCHAR(40) NOT NULL,
     destination VARCHAR(40) NOT NULL,
     logged_on   TIMESTAMP NOT NULL
  ) ENGINE=QUEUE DEFAULT CHARSET=utf8;

You also need to setup a memcached compatible distributed cache/storage.
This will be used to share certain key data across multiple instances
of Mvalve.

=head1 METHODS
 
=head2 trace

This is for debugging only

=head1 AUTHORS

Daisuke Maki C<< <daisuke@endeworks.jp> >>

Taro Funaki C<< <t@33rpm.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

