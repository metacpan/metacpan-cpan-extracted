package Munin::Node::Client;

# Name: HealthMatrix
## Author: Sebastian Stellingwerff
## Copyright: 2008
## See COPYRIGHT section in the manpage for usage and distribution rights.
## perltidy -pt=1 -sbt=1 -bt=1 -ce -vt=2 -vtc=0 -nsak="if while for elsif foreach unless"
## vim: set ts=4 et

=head1 NAME

Munin::Node::Client - Client module for munin nodes.

=head1 SYNOPSIS

  use Munin::Node::Client;

  my $node = Munin::Node::Client->connect(Host => '127.0.0.1',
                                          Port => '4949');

  my $version    = $node->version;
  my @hostnames  = $node->nodes;   # get the hostnames
  my @items      = $node->list();  # or $node->list($hostnames[0]);

  $node->quit;

=head1 DESCRIPTION

Munin::Node::Client is a client module for munin nodes. This helps simple scripts to talk to munin nodes.

=cut

use 5.8.0;
use strict;
use warnings;
use IO::Socket::INET;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.01';

=head1 FUNCTIONS

Here all functions are specified, for all functions that return in list context (such as with hashes), the scalar context is undocumented and might get a function in the future.

=over

=item connect(host => $hostname, port => $port)

Connects to a node and returns an Munin::Node::Client object.
Currently only support plain connections, ssl and tls are planned.
Returns undef if connection fails (and $! probably contains something useful).
Returns false if connection is not a munin connection.
    my $node = Munin::Node::Client->connect(Host => '127.0.0.1:4949');
=cut
sub connect {
    my ($class, %settings) = @_;
    $settings{port} = 4949 unless($settings{port});

    my $sock = IO::Socket::INET->new(PeerAddr => $settings{host},
                                     PeerPort => $settings{port},
                                     Proto    => 'tcp') or return undef;

    my $intro = <$sock>;
    my $hostname;
    if($intro =~ /munin node at (.+)$/) {
        $hostname = $1
    } else {
        # this is not a munin connection??
        close($sock);
        return 0;
    }

    my %obj = ( settings => \%settings,
                sock     => $sock,
                intro    => $intro,
                hostname => $hostname);

    bless \%obj;
}

=item error();

Returns the last error message.
    print $node->error();
=cut
sub error {
    my ($self, $data) = @_;
    if(defined($data)) {
        $self->{error} = $data;
        return undef;
    } else {
        return $self->{error};
    }
}

sub print {
    my ($self, @data) = @_;
    my $sock = $self->{sock};
    my $sep = $, ? $, : '';
    my $line = join($sep, @data);
    print $sock "$line\r\n";
}

sub read {
    my ($self, @data) = @_;
    my $sock = $self->{sock};
    my $data = <$sock>;
    return $data;
}

sub read_list {
    my ($self) = @_;
    my @data;
    my $line = $self->read;
    while($line !~ /^\.$/) {
        chomp $line;
        push(@data, $line);
        $line = $self->read;
    }
    $self->error('read_list: No data') if($#data < 0);
    return @data;
}

=item version()

Returns the node's version
    my $version = $node->version();
=cut
sub version {
    my ($self) = @_;
    $self->print('version');
    my $line = $self->read();
    my ($version) = $line =~ /version: (.+)$/;
    return $version;
}

=item nodes()

Returns the available hostnames on this 'node' in a list.
    my @hosts = $node->nodes();
    print "$_\n" for(@plugins);
=cut
sub nodes {
    my ($self) = @_;
    $self->print('nodes');
    my @hosts = $self->read_list;
    return @hosts if(wantarray);
}

=item hosts()

=cut
sub hosts {
    my ($self) = @_;
    return $self->nodes();
}

=item list($node)

Returns the list of plugins for a host (or default host when left out)
    my @plugins = $node->list($host);
    print "$_\n" for(@plugins);
=cut
sub list {
    my ($self, $node) = @_;
    $node = $node ? $node : $self->{hostname};
    $self->print("list $node");
    my $line = $self->read;
    my @items = split(/\s/, $line);
    return @items if(wantarray);
}

=item config($plugin)

Returns the configuration settings of a plugin as a hash with hasrefs
    my %config  = config($plugin);
    my $globals = $config{globals};
    my $datasrc = $config{datasource};
    print $globals{graph_title};
    print $datasrc{system}->{label};
=cut
sub config {
    my ($self, $item) = @_;

    $self->print("config $item");
    my (%global, %datasrc);
    for($self->read_list) {
        if($_ =~ /^([A-Za-z0-9_-]+)\s+(.+)$/) {
            $global{$1} = $2;
        } elsif($_ =~ /^([A-Za-z0-9_-]+)\.([A-Za-z]+)\s+(.+)$/) {
            $datasrc{$1}->{$2} = $3;
        }
    }
    if(wantarray) {
        return ( global => \%global, datasource => \%datasrc );
    } else {
        # return item object;
    }
       
}

=item fetch($plugin)

Returns the values of a plugin as a hash
    my %value = fetch($plugin);
    print $value{system};
=cut
sub fetch {
    my ($self, $item) = @_;
    
    $self->print("fetch $item");
    my %values;
    for($self->read_list) {
        if($_ =~ /^([A-Za-z0-9_-]+)\.value\s+(.+)$/) {
            $values{$1} = $2;
        }
    }    

    return %values if(wantarray);
}

sub plugin {
    my ($self, $plugin) = @_;
    my %config = $self->config($plugin);
    my %value  = $self->fetch($plugin);
    my $datasource = $config{datasource};
    my $globals    = $config{globals};
    
    my %item;
    for (keys(%{ $datasource })) {
        my $cfg = $datasource->{$_};
        $item{$_} = $cfg;
        $item{$_}->{value} = $value{$_};
    }
    
    return ( )
}

=item quit()

quits/disconnects the connection to the node.
    $node->quit();
=cut
sub quit {
    my ($self) = @_;
    $self->print('quit');
    my $last = $self->read();
    close($self->{sock});
    return $last
}

=item disconnect()

alias for quit
=cut
sub disconnect {
    my ($self) = @_;
    $self->quit();
}

1;
__END__
=back

=head1 SEE ALSO

IO::Socket::INET

=head1 AUTHOR

Sebastian Stellingwerff <sebastian@expr42.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Sebastian Stellingwerff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
