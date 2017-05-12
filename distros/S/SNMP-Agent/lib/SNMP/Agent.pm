package SNMP::Agent;

=pod

=head1 NAME

SNMP::Agent - A simple SNMP AgentX subagent

=cut

use warnings;
use strict;

use Carp qw(croak);
use NetSNMP::agent (':all');
use NetSNMP::ASN qw(ASN_OCTET_STR ASN_BIT_STR ASN_NULL ASN_GAUGE ASN_UNSIGNED ASN_COUNTER ASN_COUNTER64 ASN_TIMETICKS);

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

Eliminates most of the hassle in developing simple SNMP subagents in perl.
A list of SNMP OIDs are registered to callbacks that return the data.

=cut

=head1 FUNCTIONS

=cut

sub _generic_handler
{

  # $oid, $suboid_handler and $asn_type are provided by the anonymous callback
  # registered by us, and remaining args come from the NetSNMP::agent module
  my ($self, $root_oid, $suboid_handler, $asn_type, $handler,
    $registration_info, $request_info, $requests)
    = @_;
  my $request;

  for ($request = $requests ; $request ; $request = $request->next())
  {
    my $oid  = $request->getOID();
    my $mode = $request_info->getMode();

    if ($mode == MODE_GET || $mode == MODE_GETNEXT)
    {
      if ($mode == MODE_GETNEXT)
      {
        my $next_oid =
          ($oid < new NetSNMP::OID($root_oid))
          ? $root_oid
          : $self->_get_next_oid($oid);

        # next_oid is undefined if handler was given last oid in subtree
        if (defined($next_oid))
        {
          $oid = new NetSNMP::OID($next_oid);
          $request->setOID($next_oid);
        }
        else
        {
          $oid = undef;
        }
      }

      if (defined($oid))
      {

        # Were not asked to GETNEXT beyond last OID in subtree -
        # process the request with the registered handler.
        my $value = $suboid_handler->($oid, $mode);

        my $new_asn_type = $self->_get_asn_type($oid);
        $new_asn_type ||= $asn_type;

        if($new_asn_type == ASN_UNSIGNED ||
           $new_asn_type == ASN_COUNTER ||
           $new_asn_type == ASN_COUNTER64 ||
           $new_asn_type == ASN_TIMETICKS )
        {
          $value = sprintf("%u", $value);
        }

        if($new_asn_type == ASN_OCTET_STR ||
           $new_asn_type == ASN_BIT_STR )
        {
          $value = sprintf("%s", $value);
        }

        # Possible that a GET request came for an unhandled OID
        # (undef value from handler) - don't set a value.
        $request->setValue($new_asn_type, $value) if (defined($value));
      }
    }
    elsif ($mode == MODE_SET_RESERVE1)
    {
      if ($oid != new NetSNMP::OID($root_oid))
      {
        $request->setError($request_info, SNMP_ERR_NOSUCHNAME);
      }
    }
    elsif ($mode == MODE_SET_ACTION)
    {
      $suboid_handler->($oid, $mode, $request->getValue());
    }
  }
}

=head2 new

Get an SNMP::Agent object. See EXAMPLES for use.

=cut

sub new
{
  my $class = shift;
  my ($name, $root_oid, $suboid_handler_map) = @_;

  my $self = {
    name         => 'example_agent',
    root_oid     => '1.3.6.1.4.1.8072.9999.9999.1',
    suboid_map   => {},
    get_next_oid => sub { return },
    get_asn_type => sub { return },
    shutdown     => 0,
  };

  croak "Invalid agent name" unless ($name =~ /^\w+$/);
  croak "Need hash reference to suboid handlers"
    unless (ref $suboid_handler_map eq "HASH");

  foreach my $suboid (keys %$suboid_handler_map)
  {
    my $handler  = $suboid_handler_map->{$suboid}->{handler};
    my $asn_type = $suboid_handler_map->{$suboid}->{type};
    $asn_type ||= ASN_OCTET_STR;

    my $ref_type = ref $handler;
    croak "Invalid suboid: $suboid" unless ($suboid =~ /^[\d\.]*/);
    croak "Not function reference or scalar for suboid $suboid"
      unless ($ref_type eq 'CODE' || $ref_type eq 'SCALAR');

    $suboid =~ s/^\.//;
    $self->{suboid_map}->{$suboid} = {handler => $handler, type => $asn_type};
  }

  $self->{name}     = $name;
  $self->{root_oid} = $root_oid;

  bless $self, $class;
  return $self;
}

=head2 register_get_next_oid

If your agent needs to support an OID subtree, the provided handler will
be called to find out what the next OID is from the previous one.

Must return undef if there is not a next OID below the registered root OID.

=cut

sub register_get_next_oid
{
  my $self    = shift;
  my $handler = shift;

  croak "Must be a CODE reference" unless (ref $handler eq 'CODE');

  $self->{get_next_oid} = $handler;
}

sub _get_next_oid
{
  my $self = shift;
  return $self->{get_next_oid}->(@_);
}

=head2 register_get_asn_type

If your agent needs to support an OID subtree, the provided handler will
be called to find out what the ASN type is for an OID. Required if the
ASN type differs from the default provided for an OID subtree.

Can return undef to use the default assigned ASN for the registered root OID.

=cut

sub register_get_asn_type
{
  my $self    = shift;
  my $handler = shift;

  croak "Must be a CODE reference" unless (ref $handler eq 'CODE');

  $self->{get_asn_type} = $handler;
}

sub _get_asn_type
{
  my $self = shift;
  return $self->{get_asn_type}->(@_);
}

=head2 run

Called on an SNMP::Agent object with no arguments to start the agent.
Does not return until shutdown called.

=cut

sub run
{
  my $self = shift;

  my $agent = new NetSNMP::agent(

    # makes the agent read a my_agent_name.conf file
    'Name'   => $self->{name},
    'AgentX' => 1
  );

  # register each oid handler individually to the same callback function
  my $root_oid = $self->{root_oid};
  foreach my $suboid (keys %{$self->{suboid_map}})
  {
    my $oid            = join('.', ($root_oid, $suboid));
    my $suboid_handler = $self->{suboid_map}->{$suboid}->{handler};
    my $asn_type       = $self->{suboid_map}->{$suboid}->{type};

    # All suboid handlers are a sub ref.
    if (ref $suboid_handler ne 'CODE')
    {
      $suboid_handler =
        ($asn_type == ASN_OCTET_STR)
        ? sub { return "$suboid_handler" }
        : sub { return $suboid_handler };
    }

    $agent->register($self->{name}, $oid,
      sub { $self->_generic_handler($oid, $suboid_handler, $asn_type, @_) });
  }

  while (!$self->{shutdown})
  {
    $agent->agent_check_and_process(1);
  }

  $agent->shutdown();
}

=head2 shutdown

Stop the agent.

=cut

sub shutdown
{
  my $self = shift;
  $self->{shutdown} = 1;
}

=head1 EXAMPLES

=head2 Simple handler

 use SNMP::Agent;
 use NetSNMP::ASN qw/ASN_GAUGE/;

 sub do_one { return int(rand(10)) }
 sub do_two { return "two" }

 my $root_oid = '1.3.6.1.4.1.8072.9999.9999.123';
 my %handlers = (
   '1' => { handler => \&do_one, type => ASN_GAUGE },
   '2' => { handler => \&do_two },     # default type ASN_OCTET_STR
 );

 my $agent = new SNMP::Agent('my_agent', $root_oid, \%handlers);
 $agent->run();

=head3 Output

 $ snmpwalk -v 2c -c public localhost 1.3.6.1.4.1.8072.9999.9999.123
 iso.3.6.1.4.1.8072.9999.9999.123.1 = Gauge32: 2
 iso.3.6.1.4.1.8072.9999.9999.123.2 = STRING: "two"

=head2 OID Tree

 use SNMP::Agent;

 my $root_oid = 'netSnmpPlaypen.7375.1';

 my @wasting_time = qw/Sittin' on the dock of the bay/;

 sub stats_handler {
   my $oid = shift;     # a NetSNMP::OID object

   return "root oid" if($oid =~ /$root_oid$/);

   my $idx = ($oid->to_array())[$oid->length - 1];
   return $wasting_time[$idx - 1];
 }

 sub next_oid_handler {
   my $oid = shift;

   if($oid eq $root_oid) {
     return join('.', ($root_oid, '.1'));
   }

   if($oid =~ /$root_oid\.(\d+)$/) {
     my $idx = $1;
     if ($idx <= $#wasting_time)
     {
       my $next_oid = join('.', ($root_oid, $idx + 1));
       return $next_oid;
     }
   }

   return;     # no next OID
 }

 my %handlers = (
   $root_oid => { handler => \&stats_handler },
 );

 my $agent = new SNMP::Agent('my_agent', '', \%handlers);
 $agent->register_get_next_oid(\&next_oid_handler);
 $agent->run();

=head3 Output

 snmpwalk -v 2c -c public localhost netSnmpPlaypen.7375
 NET-SNMP-MIB::netSnmpPlaypen.7375.1 = STRING: "root oid"
 NET-SNMP-MIB::netSnmpPlaypen.7375.1.1 = STRING: "Sittin'"
 NET-SNMP-MIB::netSnmpPlaypen.7375.1.2 = STRING: "on"
 NET-SNMP-MIB::netSnmpPlaypen.7375.1.3 = STRING: "the"
 NET-SNMP-MIB::netSnmpPlaypen.7375.1.4 = STRING: "dock"
 NET-SNMP-MIB::netSnmpPlaypen.7375.1.5 = STRING: "of"
 NET-SNMP-MIB::netSnmpPlaypen.7375.1.6 = STRING: "the"
 NET-SNMP-MIB::netSnmpPlaypen.7375.1.7 = STRING: "bay"

=head1 NOTES

=head2 Callbacks

The callback functions specified to handle OID requests are called
for SNMP sets as well as get requests. The requested OID and the
request type are passed as arguments to the callback. If the mode
is MODE_SET_ACTION there is a third argument, the value to be set.

 use NetSNMP::agent qw(MODE_SET_ACTION);
 my $persistent_val = 0;

 sub do_one
 {
   my ($oid, $mode, $value) = @_;
   if ($mode == MODE_SET_ACTION)
   {
     $persistent_val = $value;
   }
   else
   {
     return $persistent_val;
   }
 }

If asked to provide a value for an OID out of range, the handler
should return an undefined value.

=head2 OIDs

The OID passed to each callback function is a NetSNMP::OID object.
This may be a symbolic or numeric OID, and will be dependent on
your system configuration. If in doubt, convert it to a numeric
representation before using it:

 use NetSNMP::OID;
 my $oid = new NetSNMP::OID('netSnmpPlaypen');
 my $numeric = join '.', $oid->to_array();

 print "symbolic: $oid\n";
 print "numeric: $numeric\n";

 symbolic: netSnmpPlaypen
 numeric: 1.3.6.1.4.1.8072.9999.9999

=head2 Caching

No caching of responses is done by SNMP::Agent.  Any results from
expensive operations should probably be cached for some time in case
of duplicate requests for the same information.

=head1 AUTHOR

Alexander Else, C<< <aelse at else.id.au> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-snmp-agent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP-Agent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head2 COUNTER64

Strange values are returned for non-zero 64 bit counters. I suspect something in either NetSNMP::agent or communication
between it and the snmp daemon. From cursory investigation it does not appear to be a simple endian problem. I may be wrong.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNMP::Agent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNMP-Agent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP-Agent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP-Agent>

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP-Agent/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alexander Else.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of SNMP::Agent
