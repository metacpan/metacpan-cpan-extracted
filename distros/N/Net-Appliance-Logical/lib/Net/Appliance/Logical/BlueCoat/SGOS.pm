package Net::Appliance::Logical::BlueCoat::SGOS;
use base 'Net::Appliance::Logical';

use HTTP::Request::Common qw (GET POST);

use Carp;

=head1 NAME

Net::Appliance::Logical::BlueCoat::SGOS - Perl extension for interaction with Bluecoat
proxy devices

=head1 SYNOPSIS

    use Net::Appliance::Logical::BlueCoat::SGOS;
    
    my $sg = Net::Appliance::Logical::BlueCoat::SGOS->new( 'proxy-hostname' );
    
    printf "%s (running version %s) has been up since %s\n",
            $sg->platform,
            $sg->version,
            $sg->started;
    
    $sg->delete_from_cache('http://cpan.perl.org/');

=head1 DESCRIPTION

This module is a simple way to interact with BlueCoat SG proxy servers.

=head1 NOTES

This code has only been tested on SGOS version 4.x

=head1 OBJECT CREATION

=over 4

=item new

    my $sg = Net::Appliance::Logical::BlueCoat::SGOS->new( $host [ $opts ] );

This class method constructs a new C<Net::Appliance::Logical::BlueCoat::SGOS> object.
It takes one required option, the hostname or IP of the proxy server, plus any
additional options to override the defaults.

B<OPTIONS:>

  user       => Admin username (default: admin)

  password   => Admin password
  
  enable     => Enable password (currently not used)

  port       => Port for the HTTP admin interface (default: 8081)

  protocol   => Protocol for the HTTP admin interface (default: http)

  community  => SNMP community string (default: public)
  
  timeout    => How long to wait for an HTTP admin command (default: 10)

=cut

sub new {
    my ( $class, $host, $opts ) = @_;

    my $self = bless {}, $class;

    croak "Must provide host"
      unless $host;

    $opts->{host} = $host;

    # Set some sensible defaults
    $opts->{user}      ||= 'admin';
    $opts->{port}      ||= '8081';
    $opts->{protocol}  ||= 'http';
    $opts->{community} ||= 'public';
    
    $opts->{timeout}   ||= 10;

    $self->{config} = $opts;

    return $self;
}

=pod

=item webget

  my $val = $sg->webget( $path | $actionref , [ $opts ]  );

Accepts either a path or a hashref to an action item, plus optional arguments.

You can use this to get specific pages wholesale, for instance:

    $sg->webget('OPP/statistics');
    
Or you can use it to send back a hashref of data, for instance:

    my $s = $sg->webget({ path => 'ContentFilter/Status', delim => ':' });
    printf "Content-Provider: %s (%s)\n", $s->{Provider}, $s->{Status};

=cut

sub webget {
    my ( $self, $action, $opts ) = @_;

    my $admin_path =
      ref $action
      ? $action->{path}
      : $action;

    my $method = ref $action
        ? $action->{method}
        : 'GET';

    my $content = ref $action
        ? $action->{content}
        : '';

    my $delimiter = $action->{delim}
      if ref $action;

    my $url = sprintf '%s://%s:%s@%s:%s/%s', $self->{config}->{protocol},
      $self->{config}->{user}, $self->{config}->{password},
      $self->{config}->{host}, $self->{config}->{port}, $admin_path;

    my $arg =
      ref $opts
      ? $opts->{arg}
      : $opts;

    $arg and $url .= sprintf '/%s', $arg;

    my $req = $method eq 'GET'
        ? HTTP::Request->new( GET => $url )
        : POST $url,
          Content_Type=>'form-data',
          Content=>['file'=>[undef,'',Content=>$content] ];

    # Set our timout
    $self->ua->timeout($self->{config}->{timeout});
    
    # Make our request
    my $res = $self->ua->request( $req )
      or croak "Could not get URL $url";

    if ($delimiter) {
        my $h = {};
        map {
            my ( $k, $v ) = split /$delimiter/, $_, 2;
            $h->{ $self->trim($k) } = $self->trim($v);
        } split "\n", $res->content;

        return $h;
    }
    else {
        return $res->content;
    }
}


=pod

=item privcmd

  my $response = $sg->privcmd('pcap stop');
  $response=>{errors} and die "Error: " . $response->{errors};
  print $response->{output};
  
Issues commands to the proxy as if you were logged in via ssh, enabled, and in
config mode.  Returns a hashref with the number of errors, warnings, and the
output of the command.

If you issue an array of commands, they will be executed as separate requests
A command that is a listref will be joined with newlines and issued as one
command.  For instance:

  my @commands = ('show ver', 'show clock', 'show disk all', 'restart regular');
  my @responses = $sg->privcmd(@commands);
  
versus
  
  my $commands = [ 'exceptions', 'path http://foo', 'exit', 'load exceptions' ];
  my $response = $sg->privcmd($commands);

You would want to use the latter if you have multi-step operations that need
to be executed within one command.


=cut


sub privcmd {
    my ($self, @cmds) = @_;
    
    use Data::Dumper;
    my @out;
    foreach (@cmds) {
        my $cmd = ref $_
            ? join "\n", @$_
            : $_;

        my $result = $self->webget({
            method => 'POST',
            path => 'Secure/Local/console/install_upload_action/archconf_post_setup.txt',
            content => $cmd
        });
        
        $result =~ /<pre>\r\n(.*)\r\n<\/pre>.*<p><B><I><FONT COLOR="#3333FF">There.*(\d+) error.*(\d+) warning/s;
        my $output = $1;
        my $errors = $2;
        my $warnings = $3;

        $result =~/^500 / and $errors++;

        push @out, {
            errors => $errors,
            warnings => $warnings,
            output => $output,
            raw => $result
        };
        
    }
    return $out[1]
        ? @out
        : $out[0];
}


=pod

=item cmd

Because of the current implementation, this is the same as privcmd above. 

=cut

sub cmd { return shift->privcmd(@_) };



=pod

=item cpu

=item version_string

=item server_http_errors

=item server_http_requests

=item server_http_traffic_in

=item server_http_traffic_out

=item config

=item config_brief

=item show_policy_local

=item show_policy_central

=item show_policy_forward

=item show_policy_vpm

The above options pretty much do what you would expect.

=cut


__PACKAGE__->actions(
    {

        %{ Net::Appliance::Logical->actions },

        cpu                  => { snmpget => '1.3.6.1.4.1.3417.2.4.1.1.1.4.1' },
        version_string       => { snmpget => '1.3.6.1.2.1.65.1.1.1.1.2.1' },
        server_http_errors   => { snmpget => '1.3.6.1.3.25.17.3.2.2.2.0' },
        server_http_requests => { snmpget => '1.3.6.1.3.25.17.3.2.2.1.0' },
        server_http_traffic_in  => { snmpget => '1.3.6.1.3.25.17.3.2.2.3.0' },
        server_http_traffic_out => { snmpget => '1.3.6.1.3.25.17.3.2.2.4.0' },

        config         => { webget => 'archconf_expanded.txt' },
        config_brief   => { webget => 'archconf_brief.txt' },
        policy_local   => { webget => 'local_policy_source.txt' },
        policy_central => { webget => 'central_policy_source.txt' },
        policy_forward => { webget => 'forward_policy_source.txt' },
        policy_vpm     => { webget => 'config_policy_source.txt' },
        

        object_cache_info => { webget => 'HTTP/Info' },

        delete_from_cache => { webget => 'CE/Delete' },

        http_stats        => { webget => {
            path => 'HTTP/Statistics',
            delim => '\s+'
        } },

        smartfilter => { webget => {
            path  => 'ContentFilter/SmartFilter/Log',
            delim => ':'
        } },

        clear_cache     => { privcmd => 'clear_cache' },
        purge_dns_cache => { privcmd => 'purge_dns_cache' }
    }
);



=pod

=item uptime

  $sg->uptime;		# 1060242.8

Returns the uptime of the appliance in seconds.

=cut

sub uptime {
    return ( shift->action('uptime') / 100 );
}

=pod

=item started

  $sg->started;		# 2006-06-02 10:39:57

Returns the time the system was last re-started as a L<Class::Date> object. 

=cut

sub started {
    return date( time - shift->uptime );
}

=pod

=item version

  $sg->version		# 3.2.6.8

Returns the version number of the OS

=cut

sub version {
    my $v = shift->version_string;

    $v =~ s/.*\/(.*)/$1/;
    return $v;
}

=pod

=item platform

  $sg->platform;	# Blue Coat SG800 Series

Returns the platform identifier of the proxy

=cut

sub platform {
    my $v = shift->version_string;

    $v =~ s/(.*)\/.*/$1/;
    return $v;
}

=pod

=item smartfilter_version

  $sg->smartfilter_version;		# 937

Returns the running version of the Smartfilter database

=cut

sub smartfilter_version {
    return shift->smartfilter->{'Database version'};
}

=pod

=item smartfilter_download_date

  $sg->smartfilter_download_date;	# 2006-06-14 01:00:04

=cut

sub smartfilter_download_date {
    return date shift->smartfilter->{'SmartFilter download at'};
}


=pod

=item categorize_url

  my $category   = $sg->categorize_url('http://www.bluecoat.com/');
  my @categories = $sg->categorize_url('http://www.bluecoat.com/');

Returns content-filter categorization for the argument.  Called in list
context it returns them as an array.

=cut

sub categorize_url {
    my ($self, $url) = @_;
    
    my $return = $self->webget('ContentFilter/TestUrl/' . $url );
    return wantarray
        ? split '; /', $return
        : $return;
}


=pod

=item current_workers 

  $sg->current_workers;  # 42

=cut

sub current_workers {
    return shift->http_stats->{HTTP_MAIN_0091};
}


=pod

=item object_cache_info

  $sg->delete_from_cache( $uri );

Deletes a URI from the cache.  Returns true on success, false on failure.

=cut

sub object_cache_info {
    my ( $self, $url ) = @_;

    croak "$url is not a valid URL"
      unless $url =~ /$RE{URI}/;

    my $result = $self->action( 'object_cache_info', $url );
    
    $result =~ /CE_OBJECT_NOT_IN_CACHE/ and return 0;
    
    return $result;
}

=pod

=item delete_from_cache

  $sg->delete_from_cache( $uri );

Deletes a URI from the cache.  Returns true on success, false on failure.

=cut

sub delete_from_cache {
    my ( $self, $url ) = @_;

    croak "$url is not a valid URL"
      unless $url =~ /$RE{URI}/;

    $url =~ /(.*):\/\/(.*)/;

    my $result =
      $self->action( 'delete_from_cache', sprintf( "%s/%s", $1, $2 ) );

    $result =~ /successfully/ and return 1;
    return 0;
}


=pod

=item conf_net

  $sg->conf_net( $url );

Loads a config from a specified URL

=cut

sub conf_net {
    my ($self, $url) = @_;
    
    return $self->cmd('conf net ' . $url);
}


# =pod
# 
# =item benchmark
# 
#   $sg->benchmark('http://www.yahoo.com/', 'http://www.google.com/');
# 
# Returns the amount of time in seconds taken to fetch the URLs passed.
# 
# =cut
# 
# sub benchmark {
#     my ($self, @urls) = @_;
# 
#     # ...
# }


1;

__END__

=head1 AUTHOR

Christopher Heschong, <F<chris@wiw.org>>, with assistance from Sam McLane

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
