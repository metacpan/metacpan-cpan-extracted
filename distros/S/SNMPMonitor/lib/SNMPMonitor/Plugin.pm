package SNMPMonitor::Plugin;

use common::sense;
#use NetSNMP::ASN     (':all');
my $default_oid = '.1.3.6.1.4.1.9999.';
my $debugging = 1;

sub new {
    my $obj_class       = shift;
    my $root_oid        = shift;

    my $class = ref $obj_class || $obj_class;
    my ($name) = $class =~ /::Plugin::(.*)/;

    my $self = {
        name        => $name,
        full_name   => $class,
        root_oid    => $root_oid || $default_oid,
        plugin_oid  => '',
        full_oid    => '',
    };

    bless $self, $class;

    $self->set_accessors;        
    $self->set_oid;
    return $self;
}


sub set_accessors {
    my $self = shift;

    # create accessor methods for defined parameters
    for my $datum (keys %{$self}) {
        no strict "refs";

        *$datum = sub {
            my $self = shift; # XXX: Don't ignore calling class/object
            $self->{$datum} = shift if @_;
            return $self->{$datum};
        };
    }
}


# Set the OID using plugin defined OID.
sub set_oid {
    my $self = shift;
    $self->plugin_oid($self->set_plugin_oid);
    $self->full_oid($self->root_oid . $self->plugin_oid);
}

# reset the OID, 
sub reset_oid {
    my $self = shift;
    $self->full_oid($self->root_oid . $self->plugin_oid);
}

sub set_monitor {
    my $self = shift;
    my ($handler, $registration_info, $request_info, $requests) = @_;
    my $FH = shift || 'STDOUT';

#    do {
#        print $FH "refs: ",join(", ", ref($handler), ref($registration_info),
#                   ref($request_info), ref($requests)),"\n";
#        print $FH "processing a request of type " . $request_info->getMode() . "\n";
#    } if $debugging;

    for (my $request = $requests; $request; $request = $request->next()) {
        $self->monitor($request);
    }
}

1;
__END__
