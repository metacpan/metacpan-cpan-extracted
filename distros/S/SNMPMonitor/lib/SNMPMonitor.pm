package SNMPMonitor;
our $VERSION = '0.10';

use 5.008008;
use common::sense;

use Module::Pluggable require => 1;

use NetSNMP::OID     (':all');
use NetSNMP::agent     (':all');
use NetSNMP::ASN     (':all');

sub new {
    my $class = shift;
    my $self = {
        running     => '1',
        debugging   => '0',
        subagent    => '0',
        valid_plugins  => '',
        plugin      => '',
        agent       => new NetSNMP::agent('dont_init_agent' => 1,'dont_init_lib' => 1),
        oid         => {},
    };
    
    bless $self, $class;
    $self->set_accessors;

    $self->load_plugins;
    $self->check_oid;
    $self->register;
    return $self;
}

# Create accessor and mutator methods in the symbol table.
sub set_accessors {
    my $self = shift;

    # create accessor methods for defined parameters
    for my $datum (keys %{$self}) {
        no strict "refs";

        *$datum = sub {
            my $self = shift; # Don't ignore calling class/object
            $self->{$datum} = shift if @_;
            return $self->{$datum};
        };
    }
}

# finds and attempts to load and initialize plugins
sub load_plugins {
    my $self = shift;
    my $FH = shift;

    my @plugins = $self->plugins;
    my $valid_plugins = ();
    foreach (@plugins) {
        my ($initialized, $error) = $self->evaluate_plugin($_);
        push @{$valid_plugins}, $initialized if $initialized;
        print $FH "Error in Plugin: $_\n$@\n" unless $initialized;
    }
    $self->plugin($valid_plugins);    
}

# Evaluates plugins for validity,
# Returns initialized object if valid,
# Returns the error if invalid.
sub evaluate_plugin {
    my $self = shift;
    my $plugin = shift;

#    print STDERR "evaluating, " . $plugin . "\n";
    my $new_object = eval { $plugin->new; };    
    return $new_object, $@;
}

# Registers All Plugins with the SNMP Agent
sub register {
    my  $self = shift;
    my $FH = shift || 'STDERR';

    foreach (@{$self->plugin}) {
        print $FH "@ Registering: " . $_->name . "\n";
        $self->print_info($_);
        $self->register_plugin($_);
    }
}

# Actually Registers a Plugin with the SNMP Agtent.
sub register_plugin {
    my $self = shift;
    my $plugin = shift;

    $self->agent->register(
        $plugin->name, 
        $plugin->full_oid, 
        sub { 
            $plugin->set_monitor(@_)
        }, 
    );

}

sub dump_plugins {
    my $self = shift;    
    foreach (@{$self->plugin}) {
        $self->print_info($_);
    }
}


#print some info about the plugins
sub print_info {
    my $self = shift;
    my $plugin = shift;
    my $FH = shift || 'STDERR';

    print $FH "--> Name: "      . $plugin->name . "\n";
    print $FH "--> Full Name: " . $plugin->full_name . "\n";
    print $FH "--> Name: "      . $plugin->name . "\n";
    print $FH "--> OID: "       . $plugin->plugin_oid . "\n";
#    print $FH "Root OID: "     . $plugin->root_oid . "\n";
    print $FH "--> Full OID: "  . $plugin->full_oid . "\n\n";
}

sub check_oid {
    my $self = shift;
    
    INCREMENT: foreach my $plugin (@{$self->plugin}) {
                
        #print STDOUT $self->oid;
        if ($self->oid->{$plugin->plugin_oid}) {
            $self->increment_oid($plugin);
            redo INCREMENT;
        }
        else { 
            $self->oid->{$plugin->plugin_oid} = $plugin->name;
        }
    }
}

sub increment_oid {
    my $self = shift;
    my $plugin = shift;
    my $FH = shift || 'STDOUT' ;

    my @oid = split/\./, $plugin->plugin_oid;
    $oid[-1] += 1;
    my $new_oid = join '.', @oid;
    print $FH "! Created new OID: $new_oid for " . $plugin->name . "\n";

    $plugin->plugin_oid($new_oid);
    $plugin->reset_oid;
}

1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

SNMPMonitor - Perl extension for writing SNMP Monitors

=head1 SYNOPSIS

  use SNMPMonitor;
  my $monitor = SNMPMonitor->new ($root_oid);

=head1 DESCRIPTION

This module is designed to allow easy creation of custom SNMP monitors 
by using a pluggable architecture.  By far, the easiest way to implement
this module is to include the following lines in /etc/snmpd.conf

  perl use SNMPMonitor;
  perl my $monitor = SNMPMonitor->new;

This will include all plugins in $INSTALLDIR/SNMPMonitor/Plugin/

You may, however, use the above toinitialize the module from a script 
and simply include this script in /etc/snmpd.conf (obviously, omit the 'perl'):

  perl do '/path/to/script.pl'

=head2 EXPORT

None by default.  It's an object...

=head1 Writing Plugins

Plugins are self containd Perl scripts.  There are five basic requirements,
as long as these are met, anything is possible.

Requirements,

-Package Name that matches the file name
-isa relationship with SNMPMonitor::Plugin
-sub set_plugin_oid
-sub monitor
-module returns a true value and ends with '__END__'

=head2 Plugin Template

  listing: PluginTemplate.pm

  package SNMPMonitor::Plugin::PluginTemplate;
  use common::sense;

  use NetSNMP::ASN     (':all');
  use parent qw(SNMPMonitor::Plugin);

  sub set_plugin_oid { '0.0.0' };


  sub monitor {
      my $self = shift;
      my $request = shift;
      my $FH = shift || 'STDERR';

      # Print some debug output, optional
      print $FH "--> Request in: " . $self->name . "\n";
      print $FH "--> reporting 'Test Successful'\n";

      $request->setValue(ASN_OCTET_STR, "Test Successful");
  }

  1;
  __END__


=head1 SEE ALSO

Net-SNMP Documentation

=head1 Caveats 

Currently, there are some, but I don't remember right now.
Something about something...  Good, I know right?

=head1 AUTHOR

Jon, E<lt>Jon@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Jon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
