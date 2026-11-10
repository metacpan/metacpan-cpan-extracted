package Net::UPnP::AV::MediaServer;

#-----------------------------------------------------------------
# Net::UPnP::AV::MediaServer
#-----------------------------------------------------------------

use strict;
use warnings;
use Carp qw(croak);

use Net::UPnP::HTTP;
use Net::UPnP::Device;
use Net::UPnP::Service;
use Net::UPnP::AV::Container;
use Net::UPnP::AV::Item;

use vars qw($_DEVICE $DEVICE_TYPE $CONTENTDIRECTORY_SERVICE_TYPE);

$_DEVICE = 'device';

$DEVICE_TYPE = 'urn:schemas-upnp-org:device:MediaServer:1';
$CONTENTDIRECTORY_SERVICE_TYPE = 'urn:schemas-upnp-org:service:ContentDirectory:1';

#------------------------------
# new
#------------------------------

sub new {
	my($class) = shift;
	my($this) = {
		$Net::UPnP::AV::MediaServer::_DEVICE => undef,
	};
	bless $this, $class;
}

#------------------------------
# device
#------------------------------

sub setdevice() {
	my($this) = shift;
	if (@_) {
		$this->{$Net::UPnP::AV::MediaServer::_DEVICE} = $_[0];
	}
}

sub getdevice() {
	my($this) = shift;
	$this->{$Net::UPnP::AV::MediaServer::_DEVICE};
}

#------------------------------
# browse
#------------------------------

sub browse {
	my($this) = shift;
	my %args = (
		ObjectID => 0,	
		BrowseFlag => 'BrowseDirectChildren',
		Filter => '*',
		StartingIndex => 0,
		RequestedCount => 0,
		SortCriteria => '',
		@_,
	);
	
	my ($objid, $browseFlag, $filter, $startIdx, $reqCount, $sortCriteria) = @_;
	my (
		$dev,
		$condir_service,
		%req_arg,
		$action_res,
	);
	
	$dev = $this->getdevice();
	$condir_service = $dev->getservicebyname($Net::UPnP::AV::MediaServer::CONTENTDIRECTORY_SERVICE_TYPE);
	
	%req_arg = (
			'ObjectID' => $args{ObjectID},
			'BrowseFlag' => $args{BrowseFlag},
			'Filter' => $args{Filter},
			'StartingIndex' => $args{StartingIndex},
			'RequestedCount' => $args{RequestedCount},
			'SortCriteria' => $args{SortCriteria},
		);
	
	$condir_service->postaction("Browse", \%req_arg, $args{http_options});
}

sub browsedirectchildren {
	my($this) = shift;
	my %args = (
		ObjectID => 0,	
		Filter => '*',
		StartingIndex => 0,
		RequestedCount => 0,
		SortCriteria => '',
		@_,
	);
	$this->browse (
			ObjectID => $args{ObjectID},
			BrowseFlag => 'BrowseDirectChildren',
			Filter => $args{Filter},
			StartingIndex => $args{StartingIndex},
			RequestedCount => $args{RequestedCount},
			SortCriteria => $args{SortCriteria},
			http_options => $args{http_options}
			);
}

sub browsemetadata {
	my($this) = shift;
	my %args = (
		ObjectID => 0,	
		Filter => '*',
		StartingIndex => 0,
		RequestedCount => 0,
		SortCriteria => '',
		@_,
	);
	$this->browse (
			ObjectID => $args{ObjectID},
			BrowseFlag => 'BrowseMetadata',
			Filter => $args{Filter},
			StartingIndex => $args{StartingIndex},
			RequestedCount => $args{RequestedCount},
			SortCriteria => $args{SortCriteria},
			http_options => $args{http_options}
			);
}

#------------------------------
# getdirectchildren
#------------------------------

sub getcontentlist {
	my($this) = shift;
	$this->{content_error} = '';
	my %args = (
		ObjectID => 0,	
		Filter => '*',
		StartingIndex => 0,
		RequestedCount => 0,
		SortCriteria => '',
		@_,
	);
	if (defined $args{max_items}) {
		croak 'Invalid content item limit' unless $args{max_items} =~ /\A\d+\z/
			&& POSIX::isfinite(0 + $args{max_items}) && $args{max_items} > 0;
	}
	my (
		@content_list,
		$action_res,
		$arg_list,
		$result,
		$content,
		$container,
		$item,
		$numberReturned,
		$requestedCount,
		$totalMatches
	);
	
	@content_list = ();
	$action_res = $this->browsedirectchildren(
			ObjectID => $args{ObjectID},
			Filter => $args{Filter},
			StartingIndex => $args{StartingIndex},
			RequestedCount => $args{RequestedCount},
			SortCriteria => $args{SortCriteria},
			http_options => $args{http_options}
			);
	$numberReturned = 0;
	if ($action_res->getstatuscode() == 200) {
		$arg_list = $action_res->getargumentlist();
		$numberReturned = int($arg_list->{'NumberReturned'});
	}
	if ($numberReturned <= 0) {
		$action_res = $this-> browsemetadata(
				ObjectID => $args{ObjectID},
				Filter => $args{Filter},
				StartingIndex => $args{StartingIndex},
				RequestedCount => $args{RequestedCount},
				SortCriteria => $args{SortCriteria},
			http_options => $args{http_options}
			);
		$requestedCount = 999;
		if ($action_res->getstatuscode() == 200) {
			$arg_list = $action_res->getargumentlist();
			$totalMatches = int($arg_list->{'TotalMatches'});
			if (1 < $totalMatches) {
				$requestedCount = $totalMatches;
			}
		}
		$action_res = $this->browsedirectchildren(
				ObjectID => $args{ObjectID},
				Filter => $args{Filter},
				StartingIndex => $args{StartingIndex},
				RequestedCount => $requestedCount,
				SortCriteria => $args{SortCriteria},
			http_options => $args{http_options}
			);
		if ($action_res->getstatuscode() != 200) {
			$this->{content_error} = 'Content browse failed (HTTP ' . $action_res->getstatuscode() . ')';
			return @content_list;
		}
	}
	$arg_list = $action_res->getargumentlist();
	unless ($arg_list->{'Result'}) {
		return @content_list;
	}
	$result = $arg_list->{'Result'};

	while ($result =~ m/<container(.*?)<\/container>/sgi) {
		$content = $1;
		$container = Net::UPnP::AV::Container->new();
		if ($content =~ m/id=\"(.*?)\"/si) {
			$container->setid($1);
		}
		if ($content =~ m/<dc:title>(.*)<\/dc:title>/si) {
			$container->settitle($1);
		}
		if ($content =~ m/<dc:date>(.*)<\/dc:date>/si) {
			$container->setdate($1);
		}
		die "Content item limit exceeded\n"
			if defined($args{max_items}) && @content_list >= $args{max_items};
		push (@content_list, $container);
		#print "container(" . $container->getid() . ") = " . $container->gettitle() . "\n";
		#print $1;
	}

	while ($result =~ m/<item(.*?)<\/item>/sgi) {
		$content = $1;
		$item= Net::UPnP::AV::Item->new();
		if ($content =~ m/id=\"(.*?)\"/si) {
			$item->setid($1);
		}
		if ($content =~ m/<dc:title>(.*)<\/dc:title>/si) {
			$item->settitle($1);
		}
		if ($content =~ m/<dc:date>(.*)<\/dc:date>/si) {
			$item->setdate($1);
		}
		if ($content =~ m/<res[^>]*>(.*?)<\/res>/si) {
			$item->seturl(Net::UPnP::HTTP::xmldecode($1));
		}
		if ($content =~ m/protocolInfo=\"http-get:[^:]*:([^:]*):.*\"/si) {
			$item->setcontenttype($1);
		}
		elsif ($content =~ m/protocolInfo=\"[^:]*:[^:]:([^:]*):.*\"/si) {
			$item->setcontenttype($1);
		}
		die "Content item limit exceeded\n"
			if defined($args{max_items}) && @content_list >= $args{max_items};
		push (@content_list, $item);
	}

	@content_list;
}


# Depth-first traversal without recursive Perl calls. getcontentlist remains
# repeatable and one-level; state and budgets belong to this walk only.
sub walkcontent {
    my ($this, %args) = @_;
    my %options = (ObjectID => '0', max_depth => 32, max_nodes => 4096,
        timeout => 30, %args);
    croak 'A content callback is required' unless ref($options{callback}) eq 'CODE';
    foreach my $key (qw(max_depth max_nodes timeout)) {
        my $pattern = $key eq 'timeout' ? qr/\A\d+(?:\.\d+)?\z/ : qr/\A\d+\z/;
        croak "Invalid walk $key" unless defined($options{$key})
            && $options{$key} =~ $pattern && POSIX::isfinite(0 + $options{$key})
            && $options{$key} > 0;
    }
    $this->{walk_error} = '';
    my $deadline = Net::UPnP::HTTP::_now() + $options{timeout};
    my ($parsed, $visited) = (0, 0);
    my %seen = ($options{ObjectID} => 1);
    my $fetch = sub {
        my ($id) = @_;
        if (Net::UPnP::HTTP::_now() >= $deadline) {
            $this->{walk_error} = 'Content walk deadline exceeded';
            return undef;
        }
        if ($parsed >= $options{max_nodes}) {
            $this->{walk_error} = 'Content walk node limit reached';
            return undef;
        }
        my @list;
        my $ok = eval {
            @list = $this->getcontentlist(ObjectID => $id,
                max_items => $options{max_nodes} - $parsed,
                http_options => {deadline => $deadline});
            1;
        };
        unless ($ok) {
            $this->{walk_error} = $@ || 'Content browse failed';
            return undef;
        }
        if ($this->{content_error}) {
            $this->{walk_error} = $this->{content_error};
            return undef;
        }
        if (Net::UPnP::HTTP::_now() >= $deadline) {
            $this->{walk_error} = 'Content walk deadline exceeded';
            return undef;
        }
        $parsed += @list;
        return \@list;
    };
    my $root = $fetch->($options{ObjectID});
    return 0 unless defined $root;
    my @stack = ({list => $root, index => 0, depth => 1});
    while (@stack) {
        my $frame = $stack[-1];
        if ($frame->{index} >= @{$frame->{list}}) { pop @stack; next; }
        if (Net::UPnP::HTTP::_now() >= $deadline) {
            $this->{walk_error} = 'Content walk deadline exceeded'; last;
        }
        my $content = $frame->{list}[$frame->{index}++];
        my $id = $content->getid();
        next if $content->iscontainer() && $seen{$id}++;
        ++$visited;
        my $start = Net::UPnP::HTTP::_now();
        $options{callback}->($content, $frame->{depth});
        # Account for browsing, not caller-owned media conversion/processing.
        $deadline += Net::UPnP::HTTP::_now() - $start;
        next unless $content->iscontainer();
        if ($frame->{depth} >= $options{max_depth}) {
            $this->{walk_error} = 'Content walk depth limit reached'; last;
        }
        my $children = $fetch->($id);
        last unless defined $children;
        push @stack, {list => $children, index => 0, depth => $frame->{depth} + 1};
    }
    return $visited;
}

sub getwalkerror { $_[0]->{walk_error} || '' }

#------------------------------
# getsystemupdateid
#------------------------------

sub getsystemupdateid {
	my($this) = shift;

	my (
		$dev,
		$condir_service,
		$query_res,
	);
	
	$dev = $this->getdevice();
	$condir_service = $dev->getservicebyname($Net::UPnP::AV::MediaServer::CONTENTDIRECTORY_SERVICE_TYPE);
	
	$query_res = $condir_service->postquery("SystemUpdateID");

	if ($query_res->getstatuscode() != 200) {
		return "";
	}
	
	return $query_res->getvalue();
}

1;

__END__

=head1 NAME

Net::UPnP::AV::MediaServer - Perl extension for UPnP.

=head1 SYNOPSIS

    use Net::UPnP::ControlPoint;
    use Net::UPnP::AV::MediaServer;

    my $obj = Net::UPnP::ControlPoint->new();

    @dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);

    $devNum= 0;
    foreach $dev (@dev_list) {
        $device_type = $dev->getdevicetype();
        if  ($device_type ne 'urn:schemas-upnp-org:device:MediaServer:1') {
            next;
        }
        print "[$devNum] : " . $dev->getfriendlyname() . "\n";
        unless ($dev->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1')) {
            next;
        }
        $mediaServer = Net::UPnP::AV::MediaServer->new();
        $mediaServer->setdevice($dev);
        $mediaServer->walkcontent(callback => sub { print_content($mediaServer, @_); });
        die $mediaServer->getwalkerror() if $mediaServer->getwalkerror();
        $devNum++;
    }

    sub print_content {
        my ($mediaServer, $content, $indent) = @_;
        my $id = $content->getid();
        my $title = $content->gettitle();
        for ($n=0; $n<$indent; $n++) {
            print "\t";
        }
        print "$id = $title";
        if ($content->isitem()) {
            print " (" . $content->geturl();
            if (length($content->getdate())) {
                print " - " . $content->getdate();
            }
            print " - " . $content->getcontenttype() . ")";
        }
        print "\n";

    }

=head1 DESCRIPTION

The package is an extension UPnP/AV media server.

=head1 METHODS

=over 4

=item B<new> - create new Net::UPnP::AV::MediaServer.

    $mservier = Net::UPnP::AV::MediaServer();

Creates a new object. Read `perldoc perlboot` if you don't understand that.

The new object is not associated with any UPnP devices. Please use setdevice() to set the device.

=item B<setdevice> - set a UPnP devices

    $mservier->setdevice($dev);

Set a device to the object.

=item B<browse> - browse the content directory.
	
    @action_response = $mservier->browse(
                                        ObjectID => $objid, # 0	
                                        BrowseFlag => $browseFlag, # 'BrowseDirectChildren'
                                        Filter => $filter, # "*'
                                        StartingIndex => $startIndex, # 0
                                        RequestedCount => $reqCount, # 0
                                        SortCriteria => $sortCrit # ''
                                        );

Browse the content directory and return the action response, L<Net::UPnP::ActionResponse>.

=item B<getcontentlist> - get the content list.
	
    @content_list = $mservier->getcontentlist(
                                        ObjectID => $objid, # 0	
                                        Filter => $filter, # "*'
                                        StartingIndex => $startIndex, # 0
                                        RequestedCount => $reqCount, # 0
                                        SortCriteria => $sortCrit # ''
                                        );

Browse the content directory and return the content list. Please see L<Net::UPnP::AV::Content>, L<Net::UPnP::AV::Item> and L<Net::UPnP::AV::Container>.

=item B<walkcontent> - walk a bounded content tree.

    $visited = $mediaServer->walkcontent(
        ObjectID => '0', max_depth => 32, max_nodes => 4096, timeout => 30,
        callback => sub { my ($content, $depth) = @_; }
    );
    die $mediaServer->getwalkerror() if $mediaServer->getwalkerror();

Visits content in depth-first order without recursive calls. Container IDs are
visited once per walk; root children have depth 1. All parsed items, including
pending siblings, consume the node budget. The timeout covers traversal and
Browse requests, excluding caller callback time. Callback exceptions propagate.
The return value counts visited objects; inspect C<getwalkerror()> for a limit
or Browse failure that stopped the walk. C<getcontentlist()> remains one-level
and repeatable.

=back

=head1 SEE ALSO

L<Net::UPnP::AV::Content>

L<Net::UPnP::AV::Item>

L<Net::UPnP::AV::Container>

=head1 AUTHOR

Satoshi Konno
skonno@cybergarage.org

CyberGarage
http://www.cybergarage.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Satoshi Konno

It may be used, redistributed, and/or modified under the terms of BSD License.

=cut
