=head1 NAME

SNMP::Persist - The SNMP pass_persist threaded backend

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

        use SNMP::Persist qw(&define_oid &start_persister &define_subtree);
        use strict;
        use warnings;


        #define base oid to host the subtree
        define_oid(".1.3.6.1.4.1.2021.248");

        #start the thread serving answers
        start_persister();

        #set first application number

        #loop forever to update the values
        while(1) {

          my %subtree;
          my $gameName;
          my $index=1;						#set first application number

          foreach $gameName ("game1", "game2") {                     #for each application
            $subtree{"1." . $index}=["INTEGER",$index];              #set game index data pair
            $subtree{"2." . $index}=["STRING",$gameName];            #set game name data pair
            $subtree{"3." . $index}=["Counter32", 344.2 ];           #set total memory data pair
            $index++;                                                #next application
          }

          #new values have arrived - notify the subtree controller
          define_subtree(\%subtree);

          #don't update for next 5 minutes
          sleep(300);
        }


The script can be used in the following way from snmpd.conf:

pass_persist .1.3.6.1.4.1.2021.248 <user script location>


=head1 DESCRIPTION

The SNMP-Persist module is a backend for pass_persist feature of net-snmp.

It simplifies the process of sharing user-specified data via SNMP and
development of persistent net-snmp applications controlling a chosen
MIB subtree.

It is particularly useful if data gathering process takes too long.
The responder is a separate thread, which is not influenced by updates
of MIB subtree data.
The answer to a snmp request is fast and doesn't rely on potentially
slow source of data.

=cut






package SNMP::Persist;

use 5.008;
use warnings;
use strict;
use threads;
use threads::shared;
use Exporter;

our @EXPORT_OK=qw(&define_subtree &start_persister &define_oid);
our @ISA=qw(Exporter);

my $mib : shared;
my $mutex	: shared;
my $base_oid : shared   = ".1.3.6.1.4.1.2021.240";
my $conversation_thread;

$|=1;

sub define_subtree {
  my $subtree=shift;
  my $value;
  my $item;

  #I expect a hash of two-elements arrays as an argument
  #will create a copy of it to allow sharing between threads
  #(sharing an array - empties an array :/ )

  #lets lock $mutex to hold queries till the update is finished
  #or wait till the query is finished
  lock($mutex);

  $mib=&share({});

  #the traverse & copy procedure
  foreach $value (keys %{$subtree}) {
	$mib->{$value}=&share([]);
	$mib->{$value}[0]=$subtree->{$value}[0];
	$mib->{$value}[1]=$subtree->{$value}[1];
  } #foreach

#do the sort here or after each getnext request
#  #now, lets decide the order
#  #sorted table of all oids
#  my @s = sort { _oid_cmp($a, $b) } keys %{ $mib };
#  #add a next_oid value to table of each oid
#  for (my $i = 0; $i < @s; $i++) {
#	$mib->{@s[$i]}[2]=@s[$i+1];
#  } #for
} #define_subtree-end



sub define_oid {
  #set new base_oid
  $base_oid=shift;
} #define_oid-end




sub start_persister {
  if (!$conversation_thread) {
  	$conversation_thread=threads->create("_conversation_update","");
  } else {
	warn "Will not start conversation thread more then once.";
  }
} #start-end




sub _conversation_update {

  #lets support PING, getnext and get queries in a loop
  while(<>) {
    if ( /PING\n/ ){
      print "PONG\n";
    } elsif ( /getnext\n/ ) {
      lock($mutex);
      #get next line with full oid
      my $req_oid=<STDIN>;
      if (! defined($mib)) {
        print "NONE\n";
        next; 
      }
      my $found=0;
      my $oid = _get_oid($req_oid); 
      #we don't need the sort really, what a waste it was!
      #sort all saved oids to a table
      #my @s = sort { _oid_cmp($a, $b) } keys %{ $mib };
      my ($oid_higher, $oid_hash);
      foreach $oid_hash (keys %{ $mib }) {
        #if higher then the requested one
	if (_oid_cmp($oid, $oid_hash) == -1 ) {
	  if (defined($oid_higher)) {
	    #if lower the the highest so far
	    if (_oid_cmp($oid_higher,$oid_hash) == 1) {
	      $oid_higher=$oid_hash;  
	    }	  
	  } else {
	    $oid_higher=$oid_hash;
	  }
	  $found=1;
	}
      } #for
      if (!$found) {
        print "NONE\n";
      } else {
        print "$base_oid.".$oid_higher."\n";   #print full oid
        print $mib->{$oid_higher}[0]."\n";             #print type
        print $mib->{$oid_higher}[1]."\n";             #print value
      }
    } elsif ( /get\n/ ) {
      lock($mutex);
      my $req_oid=<STDIN>; #get next line with full oid
      if (! defined($mib)) {
        print "NONE\n";
        next;
      }
      my $oid = _get_oid($req_oid);
      if (defined $oid && defined($mib->{$oid})) {
        print "$base_oid.$oid\n";	#print full oid
        print $mib->{$oid}[0]."\n";	#print type 
        print $mib->{$oid}[1]."\n";	#print value
      } else {
        print "NONE\n";
      }
    } #if
  } #while
#exit if snmpd has stopped
exit(0);
} #conversation_thread-end

sub _oid_cmp {
  my ($x, $y) = @_;
  return -1 unless $y;
  my @a = split /\./, $x;
  my @b = split /\./, $y;

  my $i = 0; #oid string index
  
  #traverse the oid strings to compare them and return the value (-1,0,1)
  while (1) {
    if ($i > $#a) {
      if ($i > $#b) {
        return 0;
      } else {
        return -1;
      }
    } elsif ($i > $#b) {
      return 1;
    }

    if ($a[$i] < $b[$i]) {
      return -1;
    } elsif ($a[$i] > $b[$i]) {
      return 1;
    }
    $i++;
  } #while_end
} #oid_cmp-end


#remove the base from the OID
#and a sort of lousy input validation
sub _get_oid {
  my $oid = shift;
  chomp $oid;

  my $base = $base_oid;
  $base =~ s/\./\\./g;

  if ($oid !~ /^$base(\.|$)/) {
    #requested oid doesn't match base oid
    return 0;
  }

  $oid =~ s/^$base\.?//;
  return $oid;
} #get_oid-end




1;







=head1 FUNCTIONS


=head2 B<define_subtree(\%hash)>

Start the thread responsible for handling snmp requests.
The function expects a reference to a predefined hash of arrays. 
Each array has to be built of two elements:

=over 5

=item * data type 

any SMI datatype supported by net-snmp (e.g. "INTEGER", "STRING", "Counter32") 

=item * value

a value set accordingly to the data type

=back


=head2 B<define_oid($string)>

Define the base oid for a mib subtree controlled by a script

=head2 B<start_persister( )>

Create or update the subtree data



=head1 AUTHOR

Anna Wiejak, C<< <anias at popoludnica.pl> >>



=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-persist at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP-Persist>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNMP::Persist

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP-Persist>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP-Persist>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNMP-Persist>

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP-Persist>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Anna Wiejak, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::Persist
