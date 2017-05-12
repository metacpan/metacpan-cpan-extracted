BLOCK:
{
  # paste BELOW this line BETWEEN braces for sample program docs.

  # this script is included in the distribution as eg/snmp_sample.pl
  use POE qw/Component::SNMP/;

  my %system = ( sysUptime   => '.1.3.6.1.2.1.1.3.0',
                 sysName     => '.1.3.6.1.2.1.1.5.0',
                 sysLocation => '.1.3.6.1.2.1.1.6.0',
               );
  my @oids = values %system;
  my $base_oid = '.1.3.6.1.2.1.1'; # system.*

  POE::Session->create( inline_states =>
                        { _start       => \&_start,
                          snmp_handler => \&snmp_handler,
                        }
                      );

  sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    POE::Component::SNMP->create( alias     => 'snmp', # same as default
                                  hostname  => 'localhost',
                                  community => 'public',
                                  version   => 'snmpv2c',
                                  # debug => 0x0A,
                                );

    my @callback_args = (1, 2, 3);

    $kernel->post( snmp => get     => snmp_handler =>
                   -varbindlist    => \@oids );
    # ... or maybe ...
    $kernel->post( snmp => walk    => snmp_handler =>
                   -baseoid        => $base_oid );
    # ... or possibly even ...
    $kernel->post( snmp => getbulk => snmp_handler =>
                   -varbindlist    => [ $base_oid ],
                   -maxrepetitions => 6,
		   -callback_args  => \@callback_args
                 );

    $heap->{pending} = 3;
  }

  sub snmp_handler {
    my ($kernel, $heap, $request, $response) = @_[KERNEL, HEAP, ARG0, ARG1];
    my ($alias, $host, $cmd, @args) = @$request;
    my ($results, @callback_args)   = @$response;

    if (ref $results) {
      print "$host SNMP config ($cmd):\n";
      print "sysName:     $results->{$system{sysName}}\n";
      print "sysUptime:   $results->{$system{sysUptime}}\n";
      print "sysLocation: $results->{$system{sysLocation}}\n";
    } else {
      print "$host SNMP error ($cmd => @args):\n$results\n";
    }

    print "Additional args: @callback_args\n";

    if (--$heap->{pending} == 0) {
      $kernel->post( $alias => 'finish' );
    }
  }

  $poe_kernel->run();

  # see the eg/ folder in the distribution archive for more samples

}

# Local Variables:
# cperl-indent-level: 2
# End:

