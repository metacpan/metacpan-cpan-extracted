package POE::Component::Client::Whois::Smart;

use strict;
use warnings;

use Socket;
use POE;
use HTTP::Request;
use Net::Whois::Raw::Common;
use Net::Whois::Raw::Data;
use Storable;

use CLASS;

use Data::Dumper;

use utf8;

use Module::Pluggable::Ordered search_path => 'POE::Component::Client::Whois::Smart';
use UNIVERSAL::require;

our $VERSION = '0.187';
our $DEBUG;

our @local_ips = ();
our $local_ip_index;
our %servers_ban = ();

# HIJACK POE::Filter::HTTPChunk
{
    package # hide from PAUSE
	POE::Filter::HTTPChunk;

    use POE::Filter::HTTPChunk;

    no warnings 'once', 'redefine';

    *get_one_old = \&get_one;

    *get_one = sub {
        my $self = shift;

        my $retval = $self->get_one_old();

        if ( 
                $self->[CURRENT_STATE] & STATE_SIZE
            &&  join('', @$retval) 
                    =~
                m{\A <\?xml.*?\?> \s* <(\S+) .* </\1> \z}smx
        )
        {
            DEBUG and warn "HIJACKED: XML tags found";
            if (    scalar @{ $self->[FRAMING_BUFFER] }
                &&  $self->[FRAMING_BUFFER]->[0] =~ m/^0+\D/
            )
            {
                # my heart is skipping, skipping
                shift @{ $self->[FRAMING_BUFFER] };
            }
            # finish him!
            push @$retval, bless {}, 'HTTP::Headers';
        }

        return $retval;
    };
}


my $plugins_initialized;

# init whois query 
sub whois {
    my $class = shift;
    my %args = @_;

    if ( not $plugins_initialized ) {

	foreach my $plugin ($class->plugins) {
	    #warn $plugin;
	    eval {
		$plugin->require
		    or die "Cannot require plugin $plugin: $@";

		my $init = $plugin->can('initialize');

		$init && $init->($poe_kernel, \%args)
		    or die "Cannot initialize plugin $plugin: $@";
		
		if ( $DEBUG ) {
		    no strict 'refs';
		    no warnings 'redefine';
		    *{$plugin.'::DEBUG'} = sub { $DEBUG };
		}
	    };

	    warn $@ if $@;
	}

	$plugins_initialized = 1;
    }

    $args{session} = $args{session} || $poe_kernel->get_active_session();        
    #warn Dumper \%args;
    
    POE::Session->create(
        inline_states => {
            _start      => \&_start_manager,
            _query_done => \&_query_done,
        },
        args => [ \%args ],
    );
  
    undef;
}

# start manager, which manages all process and returns result to caller 
sub _start_manager {
    my ($heap, $session, $arg_ref) = @_[HEAP, SESSION, ARG0];
    my %args = %$arg_ref;

    my %params;

    $params{parent_session_id} = delete($args{session})->ID();

    foreach my $plugin ( CLASS->plugins ) {
	my %plugin_params = 
	    $plugin->can('plugin_params') ? $plugin->plugin_params() : ();
	
	foreach (keys %plugin_params) {
            if (not exists $params{$_}) {
                $params{$_} = exists $args{$_}  ? 
                              delete($args{$_}) : $plugin_params{$_};
            }
	    defined $params{$_} or delete $params{$_};
	}
    }

    $params{event}  = delete $args{event};

    $heap->{params} = \%params;

    $args{host}       = delete $args{server},
    $args{manager_id} = $session->ID();
    $args{event}      = "_query_done";
    $args{timeout}    = $args{timeout} || 30;

    $heap->{tasks}  = 0;
    $heap->{result} = {};
    
    if ( $args{local_ips} && "@{ $args{local_ips} }" ne "@local_ips" ) {
	@local_ips = @{$args{local_ips}} if $args{local_ips};
	$local_ip_index = 0;
    }
    
    delete $args{local_ips};

    $args{query}
	or return CLASS->check_if_done(@_[KERNEL, HEAP]);

    my (@query_list) = @{$args{query}};
    delete $args{query};
    
    my $iteration = 0;
    while ( @query_list && $iteration++ < 10 ) {
	CLASS->call_plugins(
	    'query', \@query_list,
	    $heap, \%args
	);
    }

    # it can be already finished for that time
    CLASS->check_if_done( @_[KERNEL, HEAP] );

    return;
}

sub check_if_done {
    my ($self, $kernel, $heap) = @_;

    unless ($heap->{tasks}) {     
        my @result;

	CLASS->call_plugins( '_on_done', $heap );

	foreach my $query (keys %{$heap->{result}}) {            
	    my $num = $heap->{params}->{referral} == 0 ? 0 : -1;

	    my $result = $heap->{result}{ $query }->[ $num ];

	    my %res = (
		query  => $query,
		whois  => $result->{whois},
		server => $result->{server},
		error  => $result->{error},
	    );

	    $res{subqueries} = $heap->{result}->{$query}
		if $heap->{params}->{referral} == 2;
	    
	    push @result, \%res;
	}

        $kernel->post( $heap->{params}->{parent_session_id},
            $heap->{params}->{event}, \@result )
    }
}

# caches retrieved whois-info, return result if no more tasks
sub _query_done {
    my ($kernel, $heap, $session, $response) = @_[KERNEL, HEAP, SESSION, ARG0];

    #warn "$response->{query} done...\n";

    $heap->{tasks}--;
    return CLASS->check_if_done( $kernel, $heap );
}

sub next_local_ip {
    @local_ips or return 'default';
    $local_ip_index = ++$local_ip_index % @local_ips;
    return $local_ips[ $local_ip_index ];
}

sub local_ips {
    return @local_ips;
}

sub __next_local_ip {
    my ($server, $clientname, $rism) = @_;
    clean_bans();
    
    my $i = 0;
    while ($i <= @local_ips) {
        $i++;
        my $next_ip = shift @local_ips || 'localhost';
        push @local_ips, $next_ip
            unless $next_ip eq 'localhost';
        if (!$servers_ban{$server} || !$servers_ban{$server}->{$next_ip}) {
            return $next_ip;
        }
    }
    
    return undef;
}

sub clean_bans {
    foreach my $server (keys %servers_ban) {
        foreach my $ip (keys %{$servers_ban{$server}}) {
            #print $Net::Whois::Raw::Data::ban_time{$server}."\n";
            delete $servers_ban{$server}->{$ip}
                if time - $servers_ban{$server}->{$ip}
                    >=
                    (
                        $Net::Whois::Raw::Data::ban_time{$server}
                        || $Net::Whois::Raw::Data::default_ban_time
                    )
                ;
        }
        delete $servers_ban{$server} unless %{$servers_ban{$server}};
    }
}

sub unban_time {
    my ($server, $clientname, $rism) = @_;
    my $unban_time;
    
    my (@my_local_ips) = @local_ips || ('localhost');
    
    foreach my $ip (@my_local_ips) {
        my $ip_unban_time
            = (
                $Net::Whois::Raw::Data::ban_time{$server}
                || $Net::Whois::Raw::Data::default_ban_time
              )
            - (time - ($servers_ban{$server}->{$ip}||0) );
        $ip_unban_time = 0 if $ip_unban_time < 0;
        $unban_time = $ip_unban_time
            if !defined $unban_time || $unban_time > $ip_unban_time; 
    }

    return $unban_time+1;    
}


1;
__END__

=head1 NAME

POE::Component::Client::Whois::Smart - Provides very quick WHOIS queries with smart features.

=head1 DESCRIPTION

POE::Component::Client::Whois::Smart provides a very quick WHOIS queries
with smart features to other POE sessions and components.
The component will attempt to guess the appropriate whois server to connect
to. Supports cacheing, HTTP-queries to some servers, stripping useless information, using more then one local IP, handling server's bans.

B<WARNING>: This module changes body of POE::Filter::HTTPChunk to work correctly with DirectI SSL connection. See code for details.

=head1 SYNOPSIS

    use strict; 
    use warnings;
    use POE qw(Component::Client::Whois::Smart);
    
    my @queries = qw(
        google.com
        yandex.ru
        84.45.68.23
        REGRU-REG-RIPN        
    );
    
    POE::Session->create(
	package_states => [
	    'main' => [ qw(_start _response) ],
	],
    );
    
    $poe_kernel->run();
    exit 0;
    
    sub _start {
        POE::Component::Client::Whois::Smart->whois(
            query => \@queries,
            event => '_response',
        );
    }
    
    sub _response {
        my $all_results = $_[ARG0];
        foreach my $result ( @{$all_results} ) {
            my $query = $result->{query} if $result;
            if ($result->{error}) {
                print "Can't resolve WHOIS-info for ".$result->{query}."\n";
            } else {
                print "QUERY: ".$result->{query}."\n";
                print "SERVER: ".$result->{server}."\n";
                print "WHOIS: ".$result->{whois}."\n\n";
            };
        }                            
    }

=head1 Constructor

=over

=item whois()

Creates a POE::Component::Client::Whois session. Takes two mandatory arguments and a number of optional:

=back

=over 2

=item query

query is an arrayref of domains, IPs or registaras to send to
whois server. Required.

=item event

The event name to call on success/failure. Required.

=item session

A session or alias to send the above 'event' to, defaults to calling session. Optional.

=item server

Specify server to connect. Defaults try to be determined by the component. Optional.

=item referral

Optional.

0 - make just one query, do not follow if redirections can be done;

1 - follow redirections if possible, return last response from server; # default

2 - follow redirections if possible, return all responses;


Exapmle:
   
    #...
    POE::Component::Client::Whois->whois(
        query    => [ 'google.com', 'godaddy.com' ],
        event    => '_response',
        referral => 2,
    );
    #...
    sub _response {
        my $all_results = $_[ARG0];
        
        foreach my $result ( @{$all_results} ) {
            my $query = $result->{query} if $result;
            if ($result->{error}) {
                print "Can't resolve WHOIS-info for ".$result->{query}."\n";
            } else {
                print "Query for: ".$result->{query}."\n";
                # process all subqueries
                my $count = scalar @{$result->{subqueries}};
                print "There were $count subqueries:\n";
                foreach my $subquery (@{$result->{subqueries}}) {
                    print "\tTo server ".$subquery->{server}."\n";
                    # print "\tQuery: ".$subquery->{query}."\n";
                    # print "\tResponse:\n".$subquery->{whois}."\n";
                }
            }
        }                            
    }    
    #...

=item omit_msg

0 - give the whole response.

1 - attempt to strip several known copyright messages and disclaimers.

2 - will try some additional stripping rules if some are known for the spcific server.

Default is 2;

=item use_cnames

Use whois-servers.net to get the whois server name when possible.
Default is to use the hardcoded defaults.

=item timeout

Cancel the request if connection is not made within a specific number of seconds.
Default 30 sec.

=item local_ips

List of local IP addresses to use for WHOIS queries.

=item cache_dir

Whois information will be cached in this directory. Default is no cache.

=item cache_time

Number of minutes to save cache. 1 minute by default.

=item exceed_wait

If exceed_wait true, will wait for for 1 minute and requery server in case if your IP banned for excessive querying.
By default return 'Connection rate exceeded' in $result->{error};

=head1 OUTPUT

ARG0 will be an array of hashrefs, which contains replies.
See example above.

=head1 AUTHOR

=over 2

=item * Pavel Boldin   <davinchi@cpan.org>

=item * Sergey Kotenko <graykot@gmail.com>

=back

This module is based on the Net::Whois::Raw L<http://search.cpan.org/perldoc?Net::Whois::Raw>
and POE::Component::Client::Whois L<http://search.cpan.org/perldoc?POE::Component::Client::Whois>

Some corrects by Odintsov Pavel E<lt>nrg[at]cpan.orgE<gt>

=head1 SEE ALSO

RFC 812 L<http://www.faqs.org/rfcs/rfc812.html>.
