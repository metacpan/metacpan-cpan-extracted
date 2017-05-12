#!/usr/bin/perl

use strict;
use warnings;

use POE;
use POE::Component::LaDBI;

my $LADBI_ALIAS = 'ladbi';

my $DSN = 'dbi:Pg:dbname=test';
my $USER = 'dbuser';
my $PASSWD = 'secret';

my $SQL = "SELECT * FROM contacts";


POE::Component::LaDBI->create(Alias => $LADBI_ALIAS)
  or die "Failed to create a POE::Component::LaDBI session\n";

POE::Session->create
  (args => [$DSN, $USER, $PASSWD, $SQL],
   inline_states =>
    {
     _start          => sub {
       my ($dsn, $user, $passwd, $sql) = @_[ARG0..ARG3];
       print STDERR "_start: args=($dsn,$user,$passwd)\n";
       $_[HEAP]->{sql} = $sql;
       $_[KERNEL]->post($LADBI_ALIAS => 'connect',
			SuccessEvent => 'selectall',
			FailureEvent => 'dberror',
			Args => [ $dsn, $user, $passwd ]);
     },

     _stop           => sub {
       print STDERR "_stop: client session ended.\n";
     },

     shutdown        => sub {
       print STDERR "shutdown: sending shutodnw to $LADBI_ALIAS\n";
       $_[KERNEL]->post($LADBI_ALIAS => 'shutdown');
     },

     selectall       => sub {
       my ($dbh_id, $datatype, $data) = @_[ARG0..ARG2];
       $_[HEAP]->{dbh_id} = $dbh_id;
       print STDERR "selectall: dbh_id=$dbh_id\n";
       $_[KERNEL]->post($LADBI_ALIAS => 'selectall',
			SuccessEvent => 'display_results',
			FailureEvent => 'dberror',
			HandleId     => $dbh_id,
			Args         => [ $_[HEAP]->{sql} ] );
     },

     display_results => sub {
       my ($dbh_id, $datatype, $data) = @_[ARG0..ARG2];
       print STDERR "display_results: dbh_id=$dbh_id\n";
       for my $row ( @$data ) {
	 print join(',', @$row), "\n";
       }
       $_[KERNEL]->post($LADBI_ALIAS => 'disconnect',
			SuccessEvent => 'shutdown',
			FailureEvent => 'dberror',
			HandleId     => $dbh_id);
     },

     dberror         => sub {
       my ($dbh_id, $errtype, $errstr, $err) = @_[ARG0..ARG3];
       print STDERR "dberror: dbh_id  = $dbh_id\n";
       print STDERR "dberror: errtype = $errtype\n";
       print STDERR "dberror: errstr  = $errstr\n";
       print STDERR "dberror: err     = $err\n" if $errtype eq 'ERROR';
       $_[KERNEL]->yield('shutdown');
     }
    } #end: inline_states
  ) #end: POE::Session->create()
  or die "Failed to instantiate POE::Session\n";
			
$poe_kernel->run();

exit 0;
__END__
