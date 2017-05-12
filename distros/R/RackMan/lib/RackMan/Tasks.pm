package RackMan::Tasks;

use Module::Runtime;
use Moose::Role;
use RackMan;
use RackMan::Types;
use Scalar::Util qw< looks_like_number >;
use Term::ANSIColor qw< BOLD RED >;
use namespace::autoclean;


#
# task_list()
# ---------
sub task_list {
    my ($class, $opts) = @_;

    print STDERR "usage: $::COMMAND list <pdu | server | switch | all>\n"
        and return if $opts->{stdout} and not defined $opts->{type};

    # the object connected to the RackTables database
    my $rackman = $opts->{rackman};
    my $racktables = $rackman->racktables;

    my $req_type = lc $opts->{type};
    my %conds;

    if ($req_type ne "all") {
        # determine the type of objects to look
        $req_type = RackMan::Types->to_racktables($req_type);

        # construct the additional WHERE conditions
        %conds = ( dict_value => $req_type );
    }

    # create the resultset
    my $list = $racktables->resultset("RackObject")->search(
        { chapter_id => 1, %conds },
        { join => "dictionary", order_by => { -asc => "name" } },
    );

    my $r = 1;
    my @objects;
    $opts->{as} ||= "simple";

    # fetch and print the corresponding objects
    while (my $rackobject = $list->next) {
        my $id   = $rackobject->id;
        my $name = $rackobject->name;
        my $type = $rackobject->dictionary->dict_value;
        not defined and $_ = "(null)" for $name, $type;

        # direct output on screen
        if ($opts->{stdout}) {
            my $rackdev = $rackman->device_by_id($id);

            if ($opts->{as} eq "ldif") {
                require RackMan::Format::LDAP;
                my $ldif = eval { RackMan::Format::LDAP::make_ldif($rackdev) };
                $r &&= print $ldif, $/ if $ldif;
            }
            else {
                $r &&= printf "%s (%d), %s, use:%s\n", $name, $id, $type,
                    eval { $rackdev->attributes->{Use} } || "(null)";
            }
        }
        # don't print, return the data
        else {
            push @objects, { id => $id, name => $name, type => $type };
        }
    }

    if ($opts->{stdout}) {
        return $r
    }
    else {
        return wantarray ? @objects : \@objects
    }
}


#
# task_info()
# ---------
sub task_info {
    my ($self, $opts) = @_;

    print "Name: ", $self->object_name, " (", $self->object_id, ")", $/,
          "Type: ", $self->object_type, $/;
    print "Asset tag: ", $self->object_asset_no, $/ if $self->object_asset_no;
    print $/;

    print "Attributes\n----------\n";
    my $attr = $self->attributes;
    print "  $_: $attr->{$_}\n" for sort keys %$attr;
    print $/;

    print "Tags\n----\n";
    print "  explicit tags: ", join(", ", @{ $self->explicit_tags }), $/;
    print "  implicit tags: ", join(", ", @{ $self->implicit_tags }), $/;
    print $/;

    print "Location\n--------\n";

    if (my ($parent_id) = @{ $self->parents }) {
        my $parent = $self->rackman->device_by_id($parent_id);
        print "  host: ", $parent->object_name, $/;
    }

    print "  rack: ", $self->rack->{name}, $/,
          "  site: ", $self->rack->{row_name}, $/;
    print $/;

    print "Comment\n-------\n", $self->object_comment, $/, $/
        if $self->object_comment;

    # choose the appropriate sort function for the ports
    if ($self->object_type eq "Switch") {
        *by_port_name = sub {
            my @a = ( (split "/", $a->{name}), 0, 0);
            my @b = ( (split "/", $b->{name}), 0, 0);
            lc $a[0] cmp lc $b[0] || $a[1] <=> $b[1] || $a[2] <=> $b[2]
        }
    } else {
        *by_port_name = sub {
            my @a = looks_like_number($a->{name})
                  ? ("", $a->{name}) : ($a->{name}, "");
            my @b = looks_like_number($b->{name})
                  ? ("", $b->{name}) : ($b->{name}, "");
            lc $a[0] cmp lc $b[0] || $a[1] <=> $b[1]
        }
    }

    if (@{ $self->ports }) {
        print "Ports\n-----\n";
        printf "  [%s] --(%s)--> %s [%s]\n",
            $_->{name}, $_->{oif_name},
            $_->{peer_object_name}||"", $_->{peer_port_name}||""
            for sort by_port_name @{ $self->ports };
        print $/;
    }

    if ($self->has_ipv4addrs) {
        print "IPv4 addresses\n--------------\n";

        for my $addr (@{ $self->ipv4addrs }) {
            print "  $addr->{type} | $addr->{iface} | $addr->{addr}\n"
        }

        my $gateway = $self->default_ipv4_gateway->{addr};
        print "  * default gateway: $gateway\n" if defined $gateway;
    }

    if ($self->has_ipv6addrs) {
        print "IPv6 addresses\n--------------\n";

        for my $addr (@{ $self->ipv6addrs }) {
            print "  $addr->{type} | $addr->{iface} | $addr->{addr}\n"
        }
    }

    print $/;
}


#
# task_dump()
# ---------
sub task_dump {
    my ($self, $opts) = @_;

    # extract the meaningful parts of the object
    my %struct;
    my @attrs = grep { !/^rack/ } map { $_->name }
        $self->meta->get_all_attributes;
    push @attrs, qw<
        object_id  object_name  object_asset_no
        object_comment  object_has_problem  rack
    >;

    # .. and copy over its attributes
    for my $attr (@attrs) {
        $struct{$attr} = $self->$attr;
    }

    $opts->{as} ||= "yaml";
    my $dump;

    if ($opts->{as} eq "ldif") {
        require RackMan::Format::LDAP;
        $dump = RackMan::Format::LDAP::make_ldif($self);
    }
    elsif ($opts->{as} eq "json") {
        require JSON;
        $dump = JSON::encode_json(\%struct);
    }
    elsif ($opts->{as} eq "perl") {
        $dump = \%struct
    }
    else {
        require YAML;
        $dump = YAML::Dump(\%struct);
    }

    if ($opts->{stdout}) {
        # stringify Perl structure
        if (ref $dump) {
            require Data::Dumper;
            my $dumper = Data::Dumper->new([$dump]);
            $dumper->Indent(1)->Sortkeys(1)->Terse(1);
            $dump = $dumper->Dump;
        }

        # add a newline if output is missing one (typically for JSON)
        $dump .= "\n" unless $dump =~ /\n$/;

        return print $dump
    }
    else {
        return $dump
    }
}


#
# task_write()
# ----------
sub task_write {
    my ($self, $opts) = @_;

    my $verbose = $opts->{rackman}->options->{verbose};

    if ($self->class and not $opts->{rackman}->options->{no_write_dev_cfg}) {
        # invoke the write_config() method, which should be provided by
        # the appropriate device role (RackMan::Device::*)
        my ($type) = $self->class =~ /::(\w+)$/;
        print "- ", BOLD($type), "\n" if $verbose;
        eval {
            $self->write_config({
                rackman => $opts->{rackman},
                verbose => $verbose,
            }); 1
        } or warn $@;
    }

    # invoke the write() method from each format that the device
    # role has declared to be relevent
    for my $format ($self->formats) {
        print "- ", BOLD($format) if $verbose;

        # load the module
        my $module = "RackMan::Format::$format";
        if (not eval { Module::Runtime::require_module($module) }) {
            print BOLD(RED(" -- failed")), "\n" if $verbose;
            (my $error = $@) =~ s/INC \(.+$/INC/sm;
            RackMan->warning("can't load $module: $error");
            next
        }

        print $/ if $verbose;

        # execute its write() method
        eval {
            $module->write({
                rackdev => $self,
                rackman => $opts->{rackman},
                verbose => $verbose,
            }); 1
        } or warn $@;
    }
}


#
# task_diff()
# ---------
sub task_diff {
    my ($self, $opts) = @_;

    my $verbose = $opts->{verbose} = $opts->{rackman}->options->{verbose};

    RackMan->error("object '", $self->object_name, "' has no hardware trait")
        unless $self->class;
    RackMan->error("hardware trait '", $self->class, "' has no support for ",
        "the 'diff' task") unless $self->class->can("diff_config");

    my ($type) = $self->class =~ /::(\w+)$/;
    print "- ", BOLD($type), "\n" if $verbose;
    eval { $self->diff_config($opts); 1 } or warn $@;
}


#
# task_push()
# ---------
sub task_push {
    my ($self, $opts) = @_;

    my $verbose = $opts->{verbose} = $opts->{rackman}->options->{verbose};

    RackMan->error("object '", $self->object_name, "' has no hardware trait")
        unless $self->class;
    RackMan->error("hardware trait '", $self->class, "' has no support for ",
        "the 'diff' task") unless $self->class->can("diff_config");

    my ($type) = $self->class =~ /::(\w+)$/;
    print "- ", BOLD($type), "\n" if $verbose;
    eval { $self->push_config($opts); 1 } or warn $@;
}


__PACKAGE__

__END__

=pod

=head1 NAME

RackMan::Tasks - High-level tasks

=head1 DESCRIPTION

This module provides high-level tasks for working on RackObjects.
It especially implements the actions documented in L<rack> under
the methods named C<task_$action>.


=head1 METHODS

All tasks expect arguments to be given as a hashref, the following ones
being common to all tasks:

=over

=item *

C<rackman> - C<RackMan> instance

=item *

C<stdout> - indicate that the task is executed from the C<rack> command,
and as such should send results to stdout

=back


=head2 task_diff

Print the difference between the actual and expected configuration
of the device corresponding to the given RackObject


=head2 task_dump

Print or return (an extract of) the internal structure of the RackObject.

The task prints on standard output when option C<stdout> is set,
otherwise returns the result.

B<Arguments>

=over

=item *

C<as> - specify the format: C<json>, C<perl>, C<yaml>

=back


=head2 task_info

Print information about the RackObject


=head2 task_list

Print the list the RackObject of the given type (C<server>, C<pdu>,
C<switch> or C<all>)


=head2 task_push

Push the configuration to the device corresponding to the given RackObject


=head2 task_write

Generate and write the configuration files for the given RackObject


=head1 AUTHOR

Sebastien Aperghis-Tramoni (sebastien@aperghis.net)

=cut

