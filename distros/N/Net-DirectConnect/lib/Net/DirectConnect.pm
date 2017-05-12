#$Id: DirectConnect.pm 817 2011-07-04 16:12:36Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect.pm $
package Net::DirectConnect;
use strict;
our $VERSION = '0.10';# . '_' . ( split ' ', '$Revision: 817 $' )[1];
no warnings qw(uninitialized);
use utf8;
use Encode;
use Socket;
use IO::Socket;
use IO::Select;
use POSIX;
#use Fcntl;
use Time::HiRes qw(time sleep);
use Data::Dumper;
$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
our $AUTOLOAD;
our %global;

sub float {    #v1
  my $self = shift if ref $_[0];
  return ( $_[0] < 8 and $_[0] - int( $_[0] ) )
    ? sprintf( '%.' . ( $_[0] < 1 ? 3 : ( $_[0] < 3 ? 2 : 1 ) ) . 'f', $_[0] )
    : int( $_[0] );
}

sub mkdir_rec(;$$) {
  local $_ = shift // $_;
  $_ .= '/' unless m{/$};
  while (m{/}g) { @_ ? mkdir $`, $_[0] : mkdir $` if length $` }
}

sub send_udp ($$;@) {
  my $self = shift if ref $_[0];
  my $host = shift;
  $host =~ s/:(\d+)$//;
  my $port = shift;
  $port ||= $1;
  $self->log( 'dcdev', "sending UDP to [$host]:[$port] = [$_[0]]" );
  my $opt = $_[1] || {};
  if (
    my $s = IO::Socket::INET->new(
      'PeerAddr' => $host,
      'PeerPort' => $port,
      'Proto'    => 'udp',
      'Timeout'  => $opt->{'Timeout'}, (
        #$opt->{'nonblocking'} ? (
        'Blocking' => 0,
        #'MultiHomed' => 1,    #del
        #) : ()
      ),
      %{ $opt->{'sockopts'} || {} },
    )
    )
  {
    $s->send( Encode::encode $self->{charset_protocol}, $_[0] );
    $self->{bytes_send} += length $_[0];
    #$s->shutdown(2);
    $s->close();
    #close($s);
    #$self->log( 'dcdev', "sent ",length $_[0]," closed [$s],");
  } else {
    $self->log( 'dcerr', "FAILED sending UDP to $host :$port = [$_[0]]" );
  }
}

sub socket_addr ($) {
  my ($socket) = @_;
  local @_;
  eval { @_ = unpack_sockaddr_in( getpeername($socket) || return ) };
  return unless $_[1];
  return unless $_[1] = inet_ntoa( $_[1] );
  return @_;
}

sub schedule($$;@)
{    #$Id: DirectConnect.pm 817 2011-07-04 16:12:36Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect.pm $
  our %schedule;
  my ( $every, $func ) = ( shift, shift );
  my $p;
  ( $p->{'wait'}, $p->{'every'}, $p->{'runs'}, $p->{'cond'}, $p->{'id'} ) = @$every
    if ref $every eq 'ARRAY';
  $p = $every if ref $every eq 'HASH';
  $p->{'every'} ||= $every if !ref $every;
  $p->{'id'} ||= join ';', caller;
  $schedule{ $p->{'id'} }{'func'} = $func
    if !$schedule{ $p->{'id'} }{'func'}
      or $p->{'update'};
  $schedule{ $p->{'id'} }{'last'} = time - $p->{'every'} + $p->{'wait'}
    if $p->{'wait'} and !$schedule{ $p->{'id'} }{'last'};
  $schedule{ $p->{'id'} }{'func'}->(@_), $schedule{ $p->{'id'} }{'last'} = time
    if ( $schedule{ $p->{'id'} }{'last'} + $p->{'every'} < time )
    and ( !$p->{'runs'} or $schedule{ $p->{'id'} }{'runs'}++ < $p->{'runs'} )
    and ( !( ref $p->{'cond'} eq 'CODE' )
    or $p->{'cond'}->( $p, $schedule{ $p->{'id'} }, @_ ) )
    and ref $schedule{ $p->{'id'} }{'func'} eq 'CODE';
}

sub use_try ($;@) {
  my $self = shift if ref $_[0];
  our %tried;
  ( my $path = ( my $module = shift ) . '.pm' ) =~ s{::}{/}g;
  return $tried{$module} if exists $tried{$module};
  local $SIG{__DIE__} = undef;
  $tried{$module} = ( $INC{$path} or eval 'use ' . $module . ' qw(' . ( join ' ', @_ ) . ');1;' and $INC{$path} );
}

sub module_load {
  my $self = shift if ref $_[0];
  local $_ = shift;
  return unless length $_;
  my $module = __PACKAGE__ . '::' . $_;
  #eval "use $module;";
  use_try $module;
  $self->log( 'err', 'cant load', $module, $@ ), return if $@;
  #${module}::new($self, @_) if $module->can('new');
  #${module}::init($self, @_) if $module->can('init');
  eval "$module\::new(\$self, \@_);";    #, \@param
  $self->log( 'err', 'cant new', $module, $@ ), return if $@;
  eval "$module\::init(\$self, \@_);";    #, \@param
  $self->log( 'err', 'cant init', $module, $@ ), return if $@;
  #$self->log( 'dev', 'loaded  module', $_, $module, );
  1;
}

sub new {
  #print Dumper \@_;
  my $class = shift;
  my $self  = {};
  if ( ref $class eq __PACKAGE__ ) { $self = $class; }
  else                             { bless( $self, $class ) unless ref $class; }
  #print ref $self;
  #$self-
  #psmisc::printlog('dev', 'func', Dumper @_);
  $self->func(@_);    #@param
  eval { $self->{'recv_flags'} = MSG_DONTWAIT; } unless $^O =~ /win/i;
  $self->{'recv_flags'} ||= 0;
  #psmisc::printlog('dev', 'init');
  $self->{'number'} ||= ++$global{'total'};
  ++$global{'count'};
  $self->init_main(@_);    #@param
  $self->init(@_);         #@param
                           #}
  $self->{activity} = time;
#$self->{$_} ||= $self->{'parent'}{$_} for grep { exists $self->{'parent'}{$_} } qw(log sockets select select_send);
#(!$self->{'parent'}{$_} ? () :  $self->{$_} = $self->{'parent'}{$_} ) for qw(log );
#$self->{'log'} = $self->{'parent'}{'log'} if $self->{'parent'}{'log'};
#$self->{$_} ||= $self->{'parent'}{$_} ||= {}
#$self->log( 'dev', '1uphandler my=',$self->{handler},Dumper($self->{handler}) , 'p=',Dumper($self->{'parent'}{handler}),$self->{'parent'}{handler},);
#$self->{'parent'}{$_} ||= {} ,  $self->{$_} ||= $self->{'parent'}{$_},
#$self->log( 'dev', '2uphandler my=',$self->{handler},Dumper($self->{handler}) , 'p=',Dumper($self->{'parent'}{handler}),$self->{'parent'}{handler},);
#$self->log( 'dev', "my number=$self->{'number'} total=$global{'total'} count=$global{'count'}" );
  if ( $class eq __PACKAGE__ ) {
    #local %_ = (@param);
    #for keys
    #$self->{$_} = $_{$_} for keys %_;
    #$self->log( 'init00', $self, "h=$self->{'host'}", 'p=', $self->{'protocol'}, 'm=', $self->{'module'} );
    if ( $self->{'host'} eq 'broadcast' or $self->{'host'} =~ /^255\./ ) {
      $self->{'protocol'} ||= 'adc';
      $self->{'auto_listen'}           = 1;
      $self->{'Proto'}                 = 'udp';
      $self->{'sockopts'}{'Broadcast'} = 1;
      $self->{'sockopts'}{'ReuseAddr'} = 1;
      $self->{'host'}                  = inet_ntoa(INADDR_BROADCAST)
        if $self->{'host'} !~ /^255\./;
      #$self->{'port'},
      #$self->log( 'dev',  "send to", );
      $self->{'broadcast'} = 1;
      #$self->{'lis'} = 1;
    }
    if ( !$self->{'module'} and !$self->{'protocol'} and $self->{'host'} ) {
      #$self->log( 'proto0 ', $1);
      my $p = lc $1 if $self->{'host'} =~ m{^(.+?)://};
      #$self->protocol_init($p);
      $self->{'protocol'} = $p;
      $self->{'protocol'} = 'nmdc'
        if !$self->{'protocol'}
          or $self->{'protocol'} eq 'dchub';
      #$self->{'protocol'}
      #$self->log( 'proto ', $self->{'protocol'} );
    }
    $self->{'module'} ||= $self->{'protocol'};
    if ( $self->{'module'} eq 'nmdc' ) {
      $self->{'module'} = [ 'nmdc', ( $self->{'hub'} ? 'hubcli' : 'clihub' ) ];
    }
    #$self->log( 'module load', $self->{'module'});
    #if ( $self->{'module'} ) {
  }
  #psmisc::printlog('dev', 'modules load', ( $self->{'module'}, @{ $self->{'modules'} || [] } ));
  my @modules;    #= ($self->{'module'});
  for (qw(module modules)) {
    push @modules, @{ $self->{$_} }      if ref $self->{$_} eq 'ARRAY';
    push @modules, keys %{ $self->{$_} } if ref $self->{$_} eq 'HASH';
    push @modules, split /[;,\s]/, $self->{$_} unless ref $self->{$_};
  }
  #$self->log( 'modules load', @modules);
  $self->module_load($_) for @modules;
  #@param
  #}
  $self->{charset_chat} ||= $self->{charset_protocol};
  #$self->protocol_init();
  #$self->log( 'dev', $self, 'new inited', "MT:$self->{'message_type'}", 'autolisten=', $self->{'auto_listen'} );
  #$self->{charset_console} = 'utf8';
  # $self->log( 'dev', "set console encoding  [$self->{charset_console}]");
  #eval qq{use encoding $self->{charset_console}};
  eval qq{use encoding '$self->{charset_internal}', STDOUT=> '$self->{charset_console}', STDIN => '$self->{charset_console}'}
    if !$self->{parent} and !$self->{no_charset_console} and $self->{charset_internal} and $self->{charset_console};
  #$self->log( 'dev', 'utf8: УТф восемь');
  #$self->log( 'dev', Dumper $self);
  if ( $self->{'auto_say'} ) {
    $self->log( 'dcdbg', "using encodings console:[$self->{charset_console}] protocol:[$self->{charset_protocol}]" );
    for my $cmd ( @{ $self->{'auto_say_cmd'} || [] } ) {
      #$self->log('AS', $cmd);
      $self->{'handler_int'}{$cmd} = sub {
        my $dc = shift;
        #$self->log('ASH', $cmd);
        $self->say( $cmd, @_ );    #print with console encoding
      };
    }
  }
  if ( $self->{'auto_listen'} ) {
    #$self->{'disconnect_recursive'} = $self->{'parent'}{'disconnect_recursive'};
    $self->{'incomingclass'} ||= $self->{'parent'}{'incomingclass'};
    $self->listen();
    $self->cmd('connect_aft') if $self->{'broadcast'};
  } elsif ( $self->{'auto_connect'} ) {
    #$self->log( $self, 'new inited', "auto_connect MT:$self->{'message_type'}", ' with' );
    $self->connect();
    #$self->work();
    $self->wait_connect();
  } else {
    $self->get_my_addr();
    $self->get_peer_addr();
  }
  if ( $self->{'auto_work'} ) {
    #$self->log( $self, '', "auto_work ", $self->active() );
    while ( $self->active() ) {
      $self->work();    #forever
                        #$self->{'auto_work'}->($self) if ref $self->{'auto_work'} eq 'CODE';
    }
    $self->disconnect();
  }
  #@  psmisc::file_rewrite( 'dump.new', Dumper $self);
  return $self;
}

sub log(@) {
  my $self = shift;
  return $self->{'log'}->( $self, @_ ) if ref $self->{'log'} eq 'CODE';
  print( join( ' ', "[$self->{'number'}]", @_ ), "\n" );
}

sub cmd {
  my $self = shift;
  #return unless $self->{'cmd'};
  my $dst;
  $dst =    #$_[0]
    shift if $self->{'adc'} and length $_[0] == 1;
  my $cmd = shift;
  my ( @ret, $ret );
  #$self->{'log'}->($self,'dev', 'cmd', $cmd, @_) if $cmd ne 'log';
  #$self->{'log'}->($self,'dev', $self->{number},'cmd', $cmd, @_) if $cmd ne 'log';
  my ( $func, $handler );
  if ($self->{'cmd'} and ref $self->{'cmd'}{$cmd} eq 'CODE' ) {
    $func    = $self->{'cmd'}{$cmd};
    $handler = '_cmd';
    unshift @_, $dst if $dst;
  } elsif ( ref $self->{$cmd} eq 'CODE' ) {
    $func = $self->{$cmd};
  } elsif ($self->{'cmd'} and ref $self->{'cmd'}{ $dst . $cmd } eq 'CODE' ) {
    $func    = $self->{'cmd'}{ $dst . $cmd };
    $handler = '_cmd';
    #unshift @_, $dst if $dst;
  }
  $self->handler( $cmd . $handler . '_bef_bef', \@_ );
  if ( $self->{'min_cmd_delay'}
    and ( time - $self->{'last_cmd_time'} < $self->{'min_cmd_delay'} ) )
  {
    $self->log( 'dbg', 'sleepcmd', $self->{'min_cmd_delay'} - time + $self->{'last_cmd_time'} );
    sleep( $self->{'min_cmd_delay'} - time + $self->{'last_cmd_time'} );
  }
  $self->{'last_cmd_time'} = time;
  $self->handler( $cmd . $handler . '_bef', \@_ );
  #$self->{'log'}->($self,'dev', $self->{number},'cmdrun', $cmd, @_, $func) if $cmd ne 'log';
  if ($func) {
    @ret = $func->( $self, @_ );    #$self->{'cmd'}{$cmd}->(@_);
  } elsif ( exists $self->{$cmd} ) {
    $self->log( 'dev', "cmd call by var name $cmd=$self->{$cmd}" );
    @ret = ( $self->{$cmd} );
  } elsif ( $self->{'adc'} and length $dst == 1 and length $cmd == 3 ) {
    @ret = $self->cmd_adc( $dst, $cmd, @_ );
  } else {
    $self->log(
      'dev',
      "UNKNOWN CMD:[$cmd]{@_} : please add \$dc->{'cmd'}{'$cmd'} = sub { ... };",
      "self=", ref $self,
      #Dumper $self->{'cmd'},
      $self->{'parse'}
    ) if !grep { $cmd eq $_ } qw(new init);
    $self->{'cmd'}{$cmd} = sub { } if $self->{'cmd'};
  }
  $ret = scalar @ret > 1 ? \@ret : $ret[0];
  $self->handler( $cmd . $handler . '_aft', \@_, $ret );
  if ($self->{'cmd'} and $self->{'cmd'}{$cmd} ) {
    if    ( $self->{'auto_wait'} ) { $self->wait(); }
    elsif ( $self->{'auto_recv'} ) { $self->recv_try(); }
  }
  $self->handler( $cmd . $handler . '_aft_aft', \@_, $ret );
  return wantarray ? @ret : $ret[0];
}

sub AUTOLOAD {
  #psmisc::printlog('autoload', $AUTOLOAD,@_);
  my $self = shift      || return;
  my $type = ref($self) || return;
  #my @p    = @_;
  my $name = $AUTOLOAD;
  $name =~ s/.*\://;
  #return $self->cmd( $name, @p );
  return $self->cmd( $name, @_ );
}

sub DESTROY {
  my $self = shift;
  #print "DESTROYing $self->{number}\n";
  #$self->log( 'dev', 'DESTROYing' );
  $self->destroy();
  --$global{'count'};
}

sub handler {
  my $self = shift;
  shift if ref $_[0];
  my $cmd = shift;
  #$self->log('dev', 'handler select', $cmd, $self->{'handler_int'}{$cmd}, $self->{'handler'}{$cmd});
  $self->{'handler_int'}{$cmd}->( $self, @_ )
    if $self->{'handler_int'}
      and ref $self->{'handler_int'}{$cmd} eq 'CODE';    #internal lib
  $self->{'handler'}{$cmd}->( $self, @_ )
    if $self->{'handler'} and ref $self->{'handler'}{$cmd} eq 'CODE';
}
#sub baseinit {
#my $self = shift;
#$self->{'number'} = ++$global{'total'};
#$self->myport_generate();
#$self->{'port'} = $1 if $self->{'host'} =~ s/:(\d+)//;
#$self->{'want'}     ||= {};
#$self->{'NickList'} ||= {};
#$self->{'IpList'}   ||= {};
#$self->{'PortList'} ||= {};
#++$global{'count'};
#$self->{'status'} = 'disconnected';
#$self->protocol_init( $self->{'protocol'} );
#}
sub func {
  my $self = shift;
  #$self->log( 'dev', 'func', __PACKAGE__, 'func', __FILE__, __LINE__ );
  $self->{'init_main'} ||= sub {
    my $self = shift;
    #$self->log( 'dev', 'init', __PACKAGE__, 'func', __FILE__, __LINE__ );
    local %_ = @_;
#warn Dumper \%_;
    #$self->log(__LINE__, "Proto=$self->{Proto}");
    $self->{$_} = $_{$_} for keys %_;
    local %_ = (
      'Listen'        => 10,
      'Timeout'       => 10, #connect
      'Timeout_connected'       => 300,
      'myport'        => 412,                                                               #first try
      'myport_base'   => 40000,
      'myport_random' => 1000,
      'myport_tries'  => 5,
      'cmd_sep'       => ' ',
      'no_print'      => { map { $_ => 1 } qw(Search Quit MyINFO Hello SR UserCommand) },
      'log'           => sub (@) {
        my $self = ref $_[0] ? shift() : {};
        if ( ref $self->{'parent'}{'log'} eq 'CODE' ) {
          return $self->{'parent'}->log( "[$self->{'number'}]", @_ );
        }
        #utf8::valid(join '', @_) and
        print( join( ' ', "[$self->{'number'}]", @_ ), "\n" );
        #Dumper \
      },
      #'auto_recv'          => 1,
      'max_reads'          => 20,
      #'wait_once'          => 0.1,
      'waits'              => 100,
      'wait_finish_tries'  => 600,
      'wait_finish_by'     => 1,
      #'wait_connect_tries' => 600,
      'clients_max'        => 50,
      'wait_clients_tries' => 200,
      #del    'wait_clients_by'    => 0.01,
      'work_sleep'        => 0.01,
      'select_timeout'    => 1,
      'cmd_recurse_sleep' => 0,
      #( $^O eq 'MSWin32' ? () : ( 'nonblocking' => 1 ) ),
      #'nonblocking' => 1,
      'informative' => [qw(number peernick status host port filebytes filetotal proxy bytes_send bytes_recv)],    # sharesize
      #'informative_hash' => [qw(clients)],                   #NickList IpList PortList
                                                             #'disconnect_recursive' => 1,
      'reconnect_sleep'  => 5,
      'partial_ext'      => '.partial',
      'file_send_by'     => 1024 * 1024,                     #1024 * 64,
      'local_mask_rfc'   => [qw(10 172.[123]\d 192\.168)],
      'status'           => 'disconnected',
      'time_start'       => time,
      #'peers' => {},
      'download_to' => './downloads/',
      #'partial_prefix' => './downloads/Incomplete/',
      #ADC
      #number => ++$global{'total'},
      #};
      'charset_fs' => (
          $^O eq 'MSWin32' ? 'cp1251'
        : $^O eq 'freebsd' ? 'koi8r'
        : 'utf8'
      ),
      'charset_console' => ( $^O eq 'MSWin32' ? 'cp866' : $^O eq 'freebsd' ? 'koi8r' : 'utf8' ),
      'charset_protocol' => 'utf8',
      'charset_internal' => 'utf8',
      #charset_nick => 'utf8',
    );
    #$self->log(__LINE__, "Proto=$self->{Proto}");
    $self->{'wait_connect_tries'} //= $self->{'Timeout'};

    $self->{$_} //= $_{$_} for keys %_;
    $self->{'partial_prefix'} //= $self->{'download_to'} . 'Incomplete/';
    $self->{$_} //= $self->{'parent'}{$_} ||= {} for qw(peers peers_sid peers_cid handler clients);   #want share_full share_tth
           #$self->{$_} ||= $self->{'parent'}{$_} ||= {}, for qw(   );
    $self->{$_} //= $self->{'parent'}{$_} ||= [] for qw(queue_download);
    $self->{$_} //= $self->{'parent'}{$_} ||= $global{$_} ||= {},
      for qw(sockets share_full share_tth want want_download want_download_filename downloading);
    $self->{'parent'}{$_} ? $self->{$_} = $self->{'parent'}{$_} : ()
      for qw(log disconnect_recursive  partial_prefix partial_ext download_to Proto);
    #$self->log("Proto=$self->{Proto}");

    #$self->log("charset_console=$self->{charset_console} charset_fs=$self->{charset_fs}");
    #psmisc::printlog('dev', 'init0', Dumper $self);
  };
  $self->{'myport_generate'} ||= sub {
    my $self = shift;
    #$self->log( 'myport', "$self->{'myport'}: $self->{'myport_base'} or $self->{'myport_random'}" );
    return $self->{'myport'}
      unless $self->{'myport_base'}
        or $self->{'myport_random'};
    $self->{'myport'} = undef if $_[0];
    return $self->{'myport'} ||= $self->{'myport_base'} + int( rand( $self->{'myport_random'} ) );
  };
  $self->{'select_add'} ||= sub {
    my $self = shift;
#$self->{'select'} ||= $self->{parent}{'select'}         $self->{'select_send'} ||= $self->{parent}{'select_send'}    if $self->{parent};
#$self->{'sockets'} ||= $self->{parent}{'sockets'} if $self->{parent};
    $self->{$_} ||= $self->{parent}{$_} ||= $global{$_} ||= IO::Select->new() for qw (select select_send);
    #$self->{'select'}      ||= IO::Select->new();    #$self->{'socket'}
    #$self->{'select_send'} ||= IO::Select->new();    #$self->{'socket'}
    return unless $self->{'socket'};
    $self->{'select'}->add( $self->{'socket'} );
    $self->{'select_send'}->add( $self->{'socket'} );
    $self->{'sockets'}{ $self->{'socket'} } = $self;
    #$self->log( 'dev', 'current select', $self->{'select'}->handles );
  };
  $self->{'connect'} ||= sub {
    my $self = shift;
    #$self->log( $self, 'connect0 inited', "MT:$self->{'message_type'}", ' with' );
    if ( $_[0] or $self->{'host'} =~ /:/ ) {
      $self->{'host'} = $_[0] if $_[0];
      $self->{'host'} =~ s{^(.*?)://}{};
      my $p = lc $1;
      #$self->protocol_init($p) if $p =~ /^adc/;
      $self->{'host'} =~ s{/.*}{}g;
      $self->{'port'} = $1 if $self->{'host'} =~ s{:(\d+)}{};
    }
    $self->{'port'} = $_[1] if $_[1];
    #print "Hhohohhhh" ,$self->{'protocol'},$self->{'host'};
    return 0
      if ( $self->{'socket'} and $self->{'socket'}->connected() )
      or grep { $self->{'status'} eq $_ } qw(destroy);    #connected
    $self->log( 'info', "connecting to $self->{'protocol'}://$self->{'host'}:$self->{'port'} via $self->{'Proto'} ", %{ $self->{'sockopts'} || {} } );
    #$self->{'status'}   = 'connecting';
    $self->{'status'}   = 'connecting_tcp';
    $self->{'outgoing'} = 1;
    $self->{'port'}     = $1 if $self->{'host'} =~ s/:(\d+)//;
    delete $self->{'recv_buf'};
    #$self->log('dev', 'conn strt', $self->{'Timeout'});
    $self->{'socket'} ||= IO::Socket::INET->new(
      'PeerAddr' => $self->{'host'},
      'PeerPort' => $self->{'port'},
      'Proto'    => $self->{'Proto'} || 'tcp',
      #'Timeout'  => $self->{'Timeout'},
      #(
      #$self->{'nonblocking'} ? (
      'Blocking' => 0,
      #'MultiHomed' => 1,    #del
      #) : ()
      #),
      %{ $self->{'sockopts'} || {} },
    );
    #$self->log('dev', 'conn end');
    $self->log( 'err', "connect socket  error: $@,", Encode::decode( $self->{charset_fs}, $! ), "[$self->{'socket'}]" ),
      return 1
      if !$self->{'socket'};
        #$self->log( 'dev',  'timeout to', $self->{'Timeout'});

         $self->{'socket'}->timeout( $self->{'Timeout'} ) if $self->{'Timeout'};   #timeout must be after new, ifyou want nonblocking
         #$self->log( 'err', "connect socket  error: $@, $! [$self->{'socket'}]" ), return 1 if !$self->{'socket'};
         #$self->{'socket'}->binmode(":encoding($self->{charset_protocol})");
         #$self->{charset_protocol} = 'utf8';
         #$self->log( 'dev', "set encoding of socket to [$self->{charset_protocol}]");
         #    binmode($self->{'socket'}, ":encoding($self->{charset_protocol})");
         #    binmode($self->{'socket'}, ":raw:encoding($self->{charset_protocol})");
         #    binmode($self->{'socket'}, ":encoding($self->{charset_protocol}):bytes");
         #    binmode($self->{'socket'}, ":$self->{charset_protocol}");
         #eval {$self->{'socket'}->fcntl( Fcntl::O_ASYNC,1);};    $self->log('warn', "cant Fcntl::O_ASYNC : $@") if $@;
         #eval {$self->{'socket'}->fcntl( Fcntl::O_NONBLOCK,1);};    $self->log('warn', "cant Fcntl::O_NONBLOCK : $@") if $@;
    $self->select_add();
    $self->{time_start} = time;
    #$self->log($self, 'connected2 inited',"MT:$self->{'message_type'}", ' with');
    #$self->log( 'dev', "connect_aft after", );
    #!!$self->recv_try();
    #$self->log( 'dev', "connect after", );
    return 0;
  };
  $self->{'connected'} ||= sub {
    my $self = shift;
    $self->get_my_addr();
    #$self->log( 'info', 'broken socket, cant get my ip'), 
    #$self->destroy(), 
    return unless $self->{'myip'};
    $self->{'status'} = 'connecting';
#$self->log( 'dev', "connected0", "[$self->{'socket'}] c=", $self->{'socket'}->connected(), 'p=', $self->{'socket'}->protocol() );
    #$self->log( 'dev',  'timeout to', $self->{'Timeout_connected'});
    $self->{'socket'}->timeout( $self->{'Timeout_connected'} ) if $self->{'Timeout_connected'};
    $self->get_peer_addr();
    $self->{'hostip'} ||= $self->{'host'};
    #my $localmask ||= join '|', @{ $self->{'local_mask_rfc'} || [] }, @{ $self->{'local_mask'} || [] };
    my $localmask ||= join '|', map { ref $_ eq 'ARRAY' ? @$_ : $_ }
      grep { $_ } $self->{'local_mask_rfc'},
      $self->{'local_mask'};
    my $is_local_ip = sub ($) {
      #$self->log( 'info', "test ip [$_[0]] in [$localmask] ");
      return $_[0] =~ /^(?:$localmask)\./;
    };
    $self->log( 'info', "my internal ip detected, using passive mode", $self->{'myip'}, $self->{'hostip'}, $localmask ),
      $self->{'M'} = 'P'
      if !$self->{'M'}
        and $is_local_ip->( $self->{'myip'} )
        and !$is_local_ip->( $self->{'hostip'} );
    $self->{'M'} ||= 'A';
    #$self->log( 'info', "mode set [$self->{'M'}] ");
    $self->log( 'info', "connect to $self->{'host'}($self->{'hostip'}):$self->{'port'} [me=$self->{'myip'}] ok ", );
    #$self->log( $self, 'connected1 inited', "MT:$self->{'message_type'}", ' with' );
    $self->cmd('connect_aft');
  };
  $self->{'connect_check'} ||= sub {
    my $self = shift;
    return 0
      if $self->{'Proto'} eq 'udp'
        or $self->{'incoming'}
        or $self->{'status'} eq 'listening'
        or (
          $self->{'socket'}
          #and $self->{'socket'}->connected()
        ) or !$self->active();
    #$self->log(          'warn', 'connect_check: must reconnect', Dumper $self->{'socket'}->connected(), $self->{'socket'}, $self->{'status'});
    $self->{'status'} = 'reconnecting';
    $self->every(
      $self->{'reconnect_sleep'},
      $self->{'reconnect_func'} ||= sub {
        if ( $self->{'reconnect_tries'}++ <= $self->{'reconnects'} ) {
          $self->log(
            'warn',
            "reconnecting [$self->{'reconnect_tries'}/$self->{'reconnects'}] every",
            $self->{'reconnect_sleep'}
          );
          $self->connect();
        } else {
          $self->{'status'} = 'disconnected';
        }
      }
    );
    return 1;
  };
  $self->{'reconnect'} ||= sub {
    my $self = shift;
#$self->log(          'dev', 'reconnect');
    $self->disconnect();
    $self->{'status'} = 'reconnecting';
    sleep $self->{'reconnect_sleep'};
    $self->connect();
  };
  $self->{'listen'} ||= sub {
    my $self = shift;
    $self->log( 'err', 'listen off', "[$self->{'Listen'}] [$self->{'M'}] [$self->{'allow_passive_ConnectToMe'}]" ), return
      if !$self->{'Listen'}
        or ( $self->{'M'} eq 'P' and !$self->{'allow_passive_ConnectToMe'} );    #RENAME
    $self->myport_generate();
    for ( 1 .. $self->{'myport_tries'} ) {
      $self->{'socket'} ||= IO::Socket::INET->new(
        'LocalPort' => $self->{'myport'},
        'Proto'     => $self->{'Proto'} || 'tcp', (
          $self->{'Proto'} ne 'udp'
          ? ( 'Listen' => $self->{'Listen'} )
          : ()
        ),
        #( $self->{'nonblocking'} ? ( 'Blocking' => 0 ) : () ),
        'Blocking' => 0,
        %{ $self->{'sockopts'} || {} },
      );
      $self->select_add(), last if $self->{'socket'};
      $self->log( 'err', "listen $self->{'myport'} socket error: $@" ), $self->myport_generate(1),
        unless $self->{'socket'};
    }
    $self->log( 'err', 'cant listen' ), return unless $self->{'socket'};
    $self->log( 'dcdbg', "listening $self->{'myport'} $self->{'Proto'}" );
    $self->{'accept'} = 1 if $self->{'Proto'} ne 'udp';
    $self->{'status'} = 'listening';
    #$self->recv_try();
  };
  $self->{'disconnect'} ||= sub {
    my $self = shift;
    #$self->log('dev', 'in disconnect', $self->{'status'});
    #$self->log( 'dev', "[$self->{'number'}] status=",$self->{'status'}, $self->{'destroying'});
    $self->{'status'} = 'disconnected';
    if ( $self->{'socket'} ) {
      #$self->log( 'dev', "[$self->{'number'}] Closing socket",
      $self->{'select'}->remove( $self->{'socket'} ) if $self->{'select'};
      $self->{'select_send'}->remove( $self->{'socket'} )
        if $self->{'select_send'};
      delete $self->{'sockets'}{ $self->{'socket'} };
      #$self->{'socket'}->shutdown(2);
      $self->{'socket'}->close();
      delete $self->{'socket'};
    }
#delete $self->{'select'};
#$self->log('dev',"delclient($self->{'clients'}{$_}->{'number'})[$_][$self->{'clients'}{$_}]\n") for grep {$_} keys %{ $self->{'clients'} };
#$self->log('dev', 'run file_close');
    $self->file_close();
    if ( $self->{'disconnect_recursive'} ) {
      for my $client (
        grep {
          #$self->{'clients'}{$_} and
          !$self->{'clients'}{$_}{'auto_listen'}
        }
        #keys %{ $self->{'clients'} }
        $self->clients_my()
        )
      {
        #next if $self->{'clients'}{$client} eq $self;
        #$self->log( 'dev', "destroy cli", $self->{'clients'}{$_}, ref $self->{'clients'}{$_} ),
          $self->{'clients'}{$client}->destroy()
          if ref $self->{'clients'}{$client}
            and $self->{'clients'}{$client}{'destroy'};
        $self->{$_} += $self->{'clients'}{$client}{$_} for qw(bytes_recv bytes_send);
        #%{$self->{'clients'}{$client}} = ();
        delete( $self->{'clients'}{$client} );
      }
    }
    delete $self->{$_} for qw(NickList IpList PortList PortList_udp peers);
    #$self->log( 'info', "disconnected", __FILE__, __LINE__ );
    #$self->log('dev', caller($_)) for 0..5;
  };
  $self->{'destroy'} ||= sub {
    my $self = shift;
    #$self->log('dev', 'in destroy');
    $self->disconnect() if ref $self and !$self->{'destroying'}++;
    #!?  delete $self->{$_} for keys %$self;
    $self->info();
    #$self->{'status'} = 'destroy';
    #$self = {};
    %$self = ();
  };
  $self->{'recv'} ||= sub {
    my $self   = shift;
    my $client = shift;
    #my $socket = shift;
    #$self->log( 'dev', 'recv', $client, $self->{'socket'}, $self->{'accept'});
    if (
      $self->{'accept'}
      #and $client eq $self->{'socket'}
      )
    {
      if ( local $_ = $self->{'socket'}->accept() ) {
        #$self->log( 'traceDEV', 'DC::recv', 'accept', $self->{'incomingclass'} );
        $self->log( 'err', 'cant accept, no incomingclass' ), return,
          unless $self->{'incomingclass'};
        my ( undef, $host ) = socket_addr $_;
        ;    # || $self->{parent}{'allow'};
             #$self->log( 'warn', "$host eq $allow ");
        if ( my $allow = $self->{'allow'} ) {
          my ( undef, $host ) = socket_addr $_;
          $self->log( 'warn', "disallowed connect from $host" ), return
            unless $host eq $allow;
        }
        $_ = $self->{'incomingclass'}->new(
          #%$self,                                clear(),
          'socket'    => $_,
          'LocalPort' => $self->{'myport'},
          'incoming'  => 1,
#'want'         => \%{ $self->{'want'} },                'NickList'     => \%{ $self->{'NickList'} },                'IpList'       => \%{ $self->{'IpList'} },                'PortList'     => \%{ $self->{'PortList'} },
#'want'         => $self->{'want'},
#'NickList'     => $self->{'NickList'},
#'IpList'       => $self->{'IpList'},
#'PortList'     => $self->{'PortList'},
#'auto_listen' => 0, 'auto_connect' => 0,
          'parent' => $self,
          #'share_tth'      => $self->{'share_tth'},
          'status' => 'connected',
          #$self->incomingopt(),
          %{ $self->{'incomingopt'} || {} },
        );
        my $name = ( $_->{hostip} || $_->{host} ) . ( $_->{port} ? ':' : () ) . $_->{port};
        $self->{'clients'}{$name} ||= $_;
        $self->{'clients'}{$name}->select_add();
        #$self->log( 'dev', 'child created',            $_,   $self->{'clients'}{$_});
        #++$ret;
      } else {
        $self->log( 'err', "Accepting fail! [$self->{'Proto'}]" );
      }
      #next;
      return;
    }
    $self->log( 'dev', "SOCKERR", $client, $self->{'socket'}, $self->{'select'} )
      if $client ne $self->{'socket'};
    $self->{'databuf'} = '';
    #my $r;
    if ( !defined( $self->{'recv_addr'} = $client->recv( $self->{'databuf'}, POSIX::BUFSIZ, $self->{'recv_flags'} ) )
      or !length( $self->{'databuf'} ) )
    {
      #TODO not here
      if (  $self->active()
        and !$self->{'incoming'}
        and $self->{'reconnect_tries'}++ < $self->{'reconnects'} )
      {
        $self->log( 'dcdbg', "recv err, reconnect. d=[$self->{'databuf'}] i=[$self->{'incoming'}]" );
        #$self->log( 'dcdbg',  "recv err, reconnect," );
        $self->reconnect();
      } elsif ( $self->{'status'} ne 'listening' ) {
        $self->log( 'dcdbg', "recv err, destroy," );
        $self->destroy();
      }
    } else {
      #++$readed;
      #++$ret;
      $self->{bytes_recv} += length $self->{'databuf'};
      $self->{activity} = time;
      #$self->log( 'dcdmp', "[$self->{'number'}]", "raw recv ", length( $self->{'databuf'} ), $self->{'databuf'} );
    }
    #$self->log( 'dcdmp', "0rawrawrcv [fh:$self->{'filehandle'}]:", $self->{'databuf'} );
    if ( $self->{'filehandle'} ) {
      $self->file_write( \$self->{'databuf'} );
    } elsif(length $self->{'databuf'}) {
      #$self->log( 'dcdmp', "rawrawrcv:", $self->{'databuf'} );
      $self->{'recv_buf'} .= $self->{'databuf'};
      #$self->log( 'dcdmp', "rawrawbuf:", $self->{'recv_buf'} );
      local $self->{'cmd_aft'} = "\x0A"
        if !$self->{'adc'}
          and $self->{'recv_buf'} =~ /^[BCDEFHITU][A-Z]{,5} /;
#$self->log( 'dcdbg', "[$self->{'number'}]", "raw to parse [$self->{'buf'}] sep[$self->{'cmd_aft'}]" ) unless $self->{'filehandle'};
      $self->{'recv_buf'} .= $self->{'cmd_aft'}
        if $self->{'Proto'} eq 'udp' and $self->{'status'} eq 'listening';
      while ( $self->{'recv_buf'} =~ s/^(.*?)\Q$self->{'cmd_aft'}//s ) {
        local $_ = $1;
        #$self->log('dcdmp', 'DC::recv', "parse [$_]($self->{'cmd_aft'})");
        last if $self->{'status'} eq 'destroy';
        #$self->log( 'dcdbg',"[$self->{'number'}] dev cycle ",length $_," [$_]", );
        last unless length $_ and length $self->{'cmd_aft'};
        next unless length;
        $self->get_peer_addr_recv() if $self->{'broadcast'};
        $_ = Encode::decode $self->{charset_protocol}, $_;
        #        $Encode::encode $self->{charset_console},
        $self->parser($_);
        #$self->log( 'dcdbg', "[$self->{'number'}]", "left to parse [$self->{'buf'}] sep[$self->{'cmd_aft'}] now was [$_]" );
        last if ( $self->{'filehandle'} );
      }
      $self->file_write( \$self->{'recv_buf'} ), $self->{'recv_buf'} = ''
        if length( $self->{'recv_buf'} )
          and $self->{'filehandle'};
    }
  };
  $self->{'recv_try'} ||= sub {
    my $self = shift;
    #$self->{'recv_runned'}{ $self->{'number'} } = 1;
    my $sleep = shift || $self->{'select_timeout'};
    my $ret = 0;
    #$self->connect_check();
    #$self->log( 'dev', 'cant recv, ret' ),
    #return unless $self->{'socket'} and ( $self->{'status'} eq 'listening' or $self->{'socket'}->connected );
    #$self->{'select'} = IO::Select->new( $self->{'socket'} ) if !$self->{'select'} and $self->{'socket'};
    #my ( $readed, $reads );
    #$self->{'databuf'} = '';
    #$self->log( 'dev', 'recv_try', 'bef' );
    my ( $recv, $send, $exeption ) = IO::Select->select( $self->{'select'}, $self->{'select_send'}, $self->{'select'}, $sleep );
#$self->log( 'traceD', 'DC::select', 'aft' , Dumper ($recv, $send, $exeption));
#schedule(10, sub {        $self->log( 'dev', 'DC::select', 'aft' , Dumper ($recv, $send, $exeption), 'from', $self->{'select'}->handles() ,    'and ', $self->{'select_send'}->handles());        });
    #$self->{'select'}->remove(@$exeption) if $exeption;
    for (@$exeption) {
      #$self->log( 'dcdbg', 'exeption', $_, $self->{sockets}{$_}{number} ),
        #$self->{'select'}->remove($_);
        $self->{sockets}{$_}->destroy() if ref $self->{sockets}{$_};
      delete $self->{sockets}{$_};
      ++$ret,
    }
    #for (@$recv, @$send) {
    for ( keys %{ $self->{sockets} } ) {
      #$self->log( 'dev', 'connected chk' , $self->{sockets}{$_}{socket}, $self->{sockets}{$_}{socket}->connected());
      #$self->log( 'dev', 'connected call' ),
      $self->{sockets}{$_}->connected(),
      ++$ret,
        if $self->{sockets}{$_}{status} eq 'connecting_tcp' and $self->{sockets}{$_}{socket}->connected();
    }
    for (@$recv) {
      $self->log( 'err', 'no object for recv handle', $_, ), next,
        #if !$self->{sockets}{$_} or !ref $self->{sockets}{$_};
        if !ref $self->{sockets}{$_} or ref $self->{sockets}{$_} eq 'HASH';
#$self->log( 'dev',ref $self->{sockets}{$_});
      $ret += $self->{sockets}{$_}->recv($_);
    }
    for (@$send) {
      #$self->log( 'err', 'no object for send handle',$_,  ) , next , unless $self->{sockets}{$_};
      #++$self->{sockets}{$_}{send_can};
      #$self->log( 'dev', 'can_send', $_, $self->{sockets}{$_}{number}, $self->{sockets}{$_}{send_can} );
      if ( $self->{sockets}{$_}{'filehandle_send'} ) {
        $ret += $self->{sockets}{$_}->file_send_part();
      }
      #$self->{sockets}{$_}->send();
    }
    #if ( $self->{'filehandle_send'} ) { $self->file_send_part(); }
    #$self->{'recv_runned'}{ $self->{'number'} } = undef;
    return $ret;
  };
  $self->{'wait'} ||= sub {
    my $self = shift;
    my ( $waits, $wait_once ) = @_;
    $waits     ||= $self->{'waits'};
    #$wait_once ||= $self->{'wait_once'};
    local $_;
    my $ret;
    #$self->log( 'dev', "start wait", $waits);
    while ( --$waits > 0 and !$ret ) {
      #$ret += $self->recv_try($wait_once);
      last unless $self->active();
      $ret += $self->recv_try();
      #$self->log( 'dev', "wait", $waits, $ret);
      #sleep 0.1 if !$ret;
    }
    #$ret += $self->work($wait_once) while --$waits > 0 and !$ret;
    return $ret;
  };
  $self->{'finished'} ||= sub {
    my $self = shift;
    $self->log( 'dcdev', 'not finished file:', "$self->{'filebytes'} / $self->{'filetotal'}", $self->{'peernick'} ), return 0
      if ($self->{'filebytes'}
      and $self->{'filetotal'}
      and $self->{'filebytes'} < $self->{'filetotal'} - 1 );
    local @_;
    $self->log( 'dcdev', 'not finished clients:', @_ ), return 0
      if @_ =
        grep { !$self->{'clients'}{$_}->finished() } $self->clients_my();    #keys %{ $self->{'clients'} };
    return 1;
  };
  $self->{'wait_connect'} ||= sub {
    my $self = shift;
    for ( 0 .. ( $_[0] || $self->{'wait_connect_tries'} ) ) {
#$self->log('dev', 'ws', $self->{'status'}, $_, ( $_[0] , $self->{'wait_connect_tries'}));
      last if grep {$self->{'status'} eq $_} qw(connected transfer disconnecting disconnected destroy), '';
      $self->wait_sleep(1);
      #$self->work(1);
    }
    return $self->{'status'};
  };
  $self->{'wait_finish'} ||= sub {
    my $self = shift;
    for ( 0 .. $self->{'wait_finish_tries'} ) {
      last if $self->finished();
      #$self->wait( undef, $self->{'wait_finish_by'} );
      #$self->log( 'dev', 'wait_finish', $_);
      $self->wait_sleep();
      #$self->work( undef, $self->{'wait_finish_by'} );
    }
    local @_;
    $self->info(),
      $self->log(
      'info',
      'finished, but clients still active:',
      map { "[$self->{'clients'}{$_}{'number'}]$_;st=$self->{'clients'}{$_}{'status'}" } @_
      ) if @_ = $self->clients_my();    #keys %{ $self->{'clients'} };
  };
  $self->{'wait_clients'} ||= sub {
    my $self = shift;
    for my $n ( 0 .. $self->{'wait_clients_tries'} ) {
      local @_;
      last
        if !$self->{'clients_max'}
          or $self->{'clients_max'} > ( @_ = $self->clients_my() );    #keys %{ $self->{'clients'} };
      $self->info() unless $_;
      $self->log( 'info', "wait clients",
        scalar( @_ = $self->clients_my() ) . "/$self->{'clients_max'}  $n/$self->{'wait_clients_tries'}" );
      #$self->wait( undef, $self->{'wait_clients_by'} );
      $self->work(5);
    }
  };
  $self->{'wait_sleep'} ||= sub {
    my $self      = shift;
    my $how       = shift || 1;
    my $starttime = time();
    #$self->log( 'dev', "wait_sleep",$starttime , $how , time(), "==", $starttime + $how),
    my $ret;
    while ($starttime + $how > time()) {
      last unless $self->active();
      $ret += $self->wait(@_);
    }
    return $ret;
    #$self->log( 'dev', "wait_sleep",$starttime , $how , time(), "==", $starttime + $how),
    #$self->work(@_) while $starttime + $how > time();
  };
  $self->{'work'} ||= sub {
    my $self   = shift;
    my @params = @_;
    #$self->periodic();
    #$self->log( 'dev', 'work', @params);
    schedule(
      1,
      our $___work_every ||= sub {
        $self->connect_check();
        $_->() for grep { ref $_ eq 'CODE' } values %{ $self->{periodic} || {} };
        #print ("P:$_\n"),
        #$self->{periodic}{$_}->() for grep {ref$self->{periodic}{$_} eq 'CODE'}keys %{$self->{periodic} || {}};
        #$self->log('dev', 'work for', keys %{$self->{'clients'}});
        for (
          keys %{ $self->{'clients'} }
          #$self->clients_my()
          )
        {
          if (
               !$self->{'clients'}{$_}{'socket'}
            or !length $self->{'clients'}{$_}{'status'}
            or $self->{'clients'}{$_}{'status'} eq 'destroy'
            or (  $self->{'clients'}{$_}{'status'} ne 'listening'
              and $self->{'clients'}{$_}{inactive_timeout}
              and time - $self->{'clients'}{$_}{activity} > $self->{'clients'}{$_}{inactive_timeout} )
            )
          {
            $self->log(
              'dev',
"del client[$self->{'clients'}{$_}{'number'}][$_] socket=[$self->{'clients'}{$_}{'socket'}] status=[$self->{'clients'}{$_}{'status'}] last active=",
              time - $self->{'clients'}{$_}{activity}
            );
            (
              !ref $self->{'clients'}{$_}{destroy}
              ? ()
              : $self->{'clients'}{$_}->destroy()
            );
            #%{$self->{'clients'}{$_}} = (),
            delete( $self->{'clients'}{$_} );
            #$self->log('dev', "now clients", map { "$_" }sort keys %{ $self->{'clients'} });
            next;
          }
          #$ret += $self->{'clients'}{$_}->recv();
          #$self->log('dev', 'work', $self->{'clients'}{$_}{'number'}, $self->{'clients'}{$_}, $self);
          #next if $self->{'clients'}{$_} eq $self;
          #$self->{'clients'}{$_}->work();
        }
        for ( keys %{ $self->{'sockets'} } ) {
          next if $self->{'sockets'}{$_} and %{ $self->{'sockets'}{$_} };
          delete $self->{'sockets'}{$_};
        }
        $self->{$_}->($self) for grep { ref $self->{$_} eq 'CODE' } qw(worker auto_work);
        #$self->log('dev', 'work exit',      );
      }
    );
    schedule(
      10,
      our $___work_downloader ||= sub {
        my $time = time;
        for my $tth ( keys %{ $self->{'downloading'} } ) {
          if (  $self->{'downloading'}{$tth}{connect_start}
            and $self->{'downloading'}{$tth}{connect_start} < $time - 60 )
          {
            #$self->log('dev', 'want', $tth,'no connection, return to want queue');
            $self->{'want_download'}{$tth} = $self->{'downloading'}{$tth};
            delete $self->{'downloading'}{$tth};
          }
        }
        for my $tth ( keys %{ $self->{'want_download'} } ) {
          delete $self->{'want_download'}{$tth}{connect_start};
        }
        if ( $self->{'queue_download'}
          and @{ $self->{'queue_download'} } )
        {
          my $file = shift @{ $self->{'queue_download'} };
          $self->search($file);
        }
        #if (!)
        #=todo
        #$self->log('dev', 'work want:', Dumper $self->{'want_download'});
        for my $tth (
          grep { keys %{ $self->{'want_download'}{$_} } }
          keys %{ $self->{'want_download'} }
          )
        {
          my $wdls = $self->{'want_download'}{$tth} || {};
          local @_ = (
            #grep { $wdls->{$_}{slotsfree} or $wdls->{$_}{SL} }
            sort {
              $wdls->{$a}{tries} <=> $wdls->{$b}{tries}
                or ( $wdls->{$b}{slotsfree} || $wdls->{$b}{SL} ) <=> ( $wdls->{$a}{slotsfree} || $wdls->{$a}{SL} )
              } keys %$wdls
          );
          #$self->log('dev', 'from can:',     @_   );
          if ( my ($fromk) = $_[0] ) {
            my $from = $wdls->{$fromk};
            my ($filename);
            for my $file ( keys %{ $self->{'want_download_filename'}{$tth} } ) {
              my $partial = $file;
$self->log('dev',  'partial prepare1', $partial);
              $partial = $self->{'partial_prefix'} . $partial . $self->{'partial_ext'};
$self->log('dev',  'partial prepare2', $partial);
              $partial = Encode::encode $self->{charset_fs}, $file
                if $self->{charset_fs};
$self->log('dev',  'partial prepare3', $partial);
              if ( -s $partial ) {
                $self->log('dev',  'already downloading: ' ,$file, -s $partial);
                $filename = $file;
                last;
              }
            }
            $filename //= (
              sort { $self->{'want_download_filename'}{$tth}{$a} <=> $self->{'want_download_filename'}{$tth}{$b} }
                keys %{ $self->{'want_download_filename'}{$tth} }
            )[0];
            $filename //= $from->{FN};
            $filename =~ s{^.*[/\\]}{}g;
#$self->log( "selected22 [$filename] keys",( grep { $wdls->{$_}{slotsfree} or $wdls->{$_}{SL} } sort {$wdls->{$b}{tries} <=> $wdls->{$a}{tries} }keys %$wdls  ),"    from", Dumper $from,);
#my $dst = $self->{'get_dir'} . $filename;
            my $size = $from->{size} || $from->{SI} || 0;
            #my $sizenow = -s $dst || 0;
            #$self->log( 'dcdev', "selected23 -e $dst and ( !$size or $sizenow < $size" );
            #if ( !-e $dst or ( !$size or $sizenow < $size ) ) {
            ++$self->{'want_download'}{$tth}{$fromk}{tries};
            $self->get(
              $from->{nick} || $from->{CID} || $from->{NI},
              #'TTH/' . $tth,
              undef, $filename, undef, undef, $size, $tth
            );
            $self->{'downloading'}{$tth} = $self->{'want_download'}{$tth};
            $self->{'downloading'}{$tth}{connect_start} = $time;
            delete $self->{'want_download'}{$tth};
            last;
            #}
            #$work{'tthfrom'}{$s{tth}}
          }
        }
        #=cut
      }
    );
    schedule(
      [ $self->{dev_auto_dump_first} || 20, $self->{dev_auto_dump_every} || 100 ],
      our $dump_sub__ ||= sub {
        $self->log( 'dev', "Writing dump" );
        open my $fh, '>', $self->{dev_auto_dump_file} || $0 .($self->{dev_auto_dump_timed} ? '.'.time : ()). '.dump'
          or return;
        print $fh Dumper $self;
        close $fh;
      }
    ) if $self->{dev_auto_dump};

#$self->log( 'dev', "work -> sleep" ),
    return $self->wait_sleep(@params) if @params;
    return $self->recv_try( $self->{'work_sleep'} );
  };
  $self->{'parser'} ||= sub {
    my $self = shift;
    for ( local @_ = @_ ) {
      $self->log(
        'dcdmp',
        "rawrcv["
          . (
            $self->{'recv_hostip'}
          ? $self->{'recv_hostip'} . ':' . $self->{'recv_port'}
          : $self->{'host'}
          )
          . "]:",
        $_
      );
      my ( $dst, $cmd, @param );
      if (/^[<*]/) {
        $cmd = ( $self->{'status'} eq 'connected' ? 'chatline' : 'welcome' );
      }
      s/^\$?([\w\-]+)\s*//, $cmd = $1 unless $cmd;
      if ( $self->{'adc'} ) {
        $cmd =~ s/^([BCDEFHIU])//, $dst = $1;
        @param = ( [$dst], split / / );
        if ( $dst eq 'B'
          or $dst eq 'F'
          or $dst eq 'U'
          or $self->{broadcast} )
        {
          #$self->log( 'dcdmp', "P0 $dst$cmd p=",(Dumper \@param));
          #push @{ $param[0] }, shift@param;
          push @{ $param[0] }, splice @param, 1, 1;
          #$self->log( 'dcdmp', "P0 $dst$cmd p=",(Dumper \@param));
          if ( $dst eq 'F' ) {
            #$self->log( 'dcdmp', 'feature'
            push @{ $param[0] }, splice @param, 1, 1 while $param[1] =~ /^[+\-]/;
          }
          #$self->log( 'dcdmp', "P1 $dst$cmd p=",(Dumper \@param));
        } elsif ( $dst eq 'D' or $dst eq 'E' ) {
          #push @{ $param[0] }, shift@param, shift@param;
          push @{ $param[0] }, splice @param, 1, 2;
        }
        #elsif ( $dst eq 'I'  ) { push @{ $param[0] }, undef }
      } else {
        @param = ($_);
      }
      #$self->log( 'dcdmp', "P3 $dst$cmd p=",(Dumper \@param));
      $cmd = $dst . $cmd
        if !exists $self->{'parse'}{$cmd}
          and exists $self->{'parse'}{ $dst . $cmd };
      #$self->log( 'dcinf', "UNKNOWN PEERCMD:[$cmd]->($_) : please add \$dc->{'parse'}{'$cmd'} = sub { ... };" ),
      $self->{'parse'}{$cmd} = sub { }, $cmd = ( $self->{'status'} eq 'connected' ? 'chatline' : 'welcome' )
        if $self->{'nmdc'} and !exists $self->{'parse'}{$cmd};
      if ( $cmd eq 'chatline' or $cmd eq 'welcome' or $cmd eq 'To' ) {
        #$self->log( 'dev', 'RCV pre encode', ($self->{charset_chat} ), @param, Dumper \@param);
        #$_ =  Encode::decode(($self->{charset_chat} ), $_) for @param;
        #!        $_ = Encode::encode $self->{charset_internal}, Encode::decode $self->{charset_chat}, $_ for @param;
        #$self->log( 'dev', 'RCV postencode', @param, Dumper \@param);
        #Encode::encode $self->{charset_console},;
      } else {
        #$_ =  Encode::encode $self->{charset_internal},
        #TODO $_ = Encode::decode($self->{charset_protocol}, $_),             for @param;
      }
      my ( @ret, $ret );
      #$self->log( 'dcinf', "parsing", $cmd, @_ ,'with',$self->{'parse'}{$cmd}, ref $self->{'parse'}{$cmd});
      my @self;
      #@self = $self if $self->{'adc'};
      @self = $self;    #if !$self->{'nmdc'};
                        #$self->handler( @self, $cmd . '_parse_bef_bef', @param );
      $self->handler( @self, $cmd . '_parse_bef', @param );
      if ( ref $self->{'parse'}{$cmd} eq 'CODE' ) {
        if ( !exists $self->{'no_print'}{$cmd} ) {
          local $_ = $_;
          local @_ =
            map  { "$_:$self->{'skip_print_'.$_}" }
            grep { $self->{ 'skip_print_' . $_ } }
            keys %{ $self->{'no_print'} || {} };
    #$self->log( 'dcdmp', "rcv: $dst$cmd p=[",(Dumper \@param),"] ", ( @_ ? ( '  [', @_, ']' ) : () ) );
    #$self->log( 'dcdmp', "rcv: $dst$cmd p=[", (map {ref $_ eq 'ARRAY'?@$_:$_}@param), "] ", ( @_ ? ( '  [', @_, ']' ) : () ) );
          $self->{ 'skip_print_' . $_ } = 0 for keys %{ $self->{'no_print'} || {} };
        } else {
          ++$self->{ 'skip_print_' . $cmd },
            if exists $self->{'no_print'}{$cmd};
        }
        #$self->handler( @self, $cmd . '_parse_bef', @param );
        @ret = $self->{'parse'}{$cmd}->( @self, @param );
        $ret = scalar @ret > 1 ? \@ret : $ret[0];
        #$self->handler( @self, $cmd . '_parse_aft', @param, $ret );
        ++$self->{count_parse}{$cmd};
      } else {
#$self->log( 'dcinf', "unknown", $cmd, @_ ,'with',$self->{'parse'}{$cmd}, ref $self->{'parse'}{$cmd}, 'run=', @self, 'unknown', $cmd,@param,);
        $self->handler( @self, 'unknown', $cmd, @param, );
      }
      #if ($self->{'parent'}{'hub'}) {           }
      $self->handler( @self, $cmd, @param, $ret );
      #$self->handler( @self, $cmd . '_parse_aft_aft', @param, $ret );
    }
  };
  $self->{'send'} ||= sub {
    my $self = shift;
    local $_;    # = join( '', @_ );
                 #$self->{bytes_send} += length $_;
                 #eval { $_ = $self->{'socket'}->send( join( '', @_ ) ); } if $self->{'socket'};
=no
    unless ($self->{send_can}) {
    	$self->{send_buffer_raw} = \@_;
    	return 0;
    }
    if ($self->{send_buffer_raw}) {
	unshift @_, @{$self->{send_buffer_raw}};
	$self->{send_buffer_raw} = undef;
    }
=cut
    return unless @_;
    eval { $_ = $self->{'socket'}->send(@_); } if $self->{'socket'};
    $self->{bytes_send} += $_;
    $self->log( 'err', 'send error', $@ ) if $@;
    $self->{activity} = time;
    return $_;
  };
  $self->{'sendcmd'} ||= sub {
    my $self = shift;
    return if $self->connect_check();
    #$self->{'log'}->( $self,'sendcmd0', @_);
    local @_ = @_, $_[0] .= splice @_, 1, 1
      if $self->{'adc'} and length $_[0] == 1;
    $self->log( 'dcdmp', 'sendcmd1', $self->{number}, @_ );
    push @{ $self->{'send_buffer'} }, $self->{'cmd_bef'} . join( $self->{'cmd_sep'}, @_ ) . $self->{'cmd_aft'}
      if @_;
    ++$self->{count_sendcmd}{ $_[0] };
    if ( ( $self->{'sendbuf'} and @_ )
      or !@{ $self->{'send_buffer'} || [] } )
    {
    } else {
      if ( $self->{'broadcast'} ) {
        $self->send_udp( $self->{'host'}, $self->{'port'}, join( '', @{ $self->{'send_buffer'} }, ) ),;
      } else {
        $self->log( 'err', "ERROR! no socket to send" ), return
          unless $self->{'socket'};
        $self->send( Encode::encode $self->{charset_protocol}, join( '', @{ $self->{'send_buffer'} }, ) );
        #local $_;
        #eval { $_ = $self->{'socket'}->send( join( '', @{ $self->{'send_buffer'} }, ) ); };
        #$self->log( 'err', 'send error', $@ ) if $@;
      }
      $self->log( 'dcdmp', "we send [" . join( '', @{ $self->{'send_buffer'} } ) . "]:", $! );
      $self->{'send_buffer'} = [];
      $self->{'sendbuf'}     = 0;
    }
  };
  $self->{'sendcmd_all'} ||= sub {
    my $self = shift;
    #%{ $self->{'peers_sid'} }
    #eval {
    $_->sendcmd(@_)    #, $self->wait_sleep( $self->{'cmd_recurse_sleep'} )
      for grep { $_ } values( %{ $self->{'clients'} } );    #, $self;
  };
  $self->{'rcmd'} ||= sub {
    my $self = shift;
    eval {
      eval { $_->cmd(@_) }, $self->wait_sleep( $self->{'cmd_recurse_sleep'} )
        for grep { $_ } values( %{ $self->{'clients'} } ), $self;
    };
  };
  $self->{'get'} ||= sub {
    my ( $self, $nick, $file, $as, $from, $to, $size, $tth ) = @_;    #TODO hash
                #$self->log( 'dcdev', 'wantcall', $self, $nick, $file, $as, $from, $to, $size);
                #my $size;
                #$size = $to unless $from;
                #$from, $to
    my ( $sid, $cid );
    $sid = $nick if $nick =~ /^[A-Z0-9]{4}$/;
    $cid = $nick if $nick =~ /^[A-Z0-9]{39}$/;
    $cid ||= $self->{peers}{$sid}{INF}{ID};
    $sid ||= $self->{peers}{$cid}{SID};
    $sid ||= $cid if $self->{broadcast};
    $file //= 'TTH/' . $tth if $tth;
    my $full = ( $as || $file );
    $full = $self->{'download_to'} . $full unless $full =~ m{[/\\]};
    #$self->log( 'dev', "cid[$cid] sid[$sid] nick[$nick] full[$full] as,file[$as || $file]");
    my $sizenow = -s $full;
    if ($sizenow) {
      $self->log( 'info', "file [$_] already exists size=$sizenow must be=$size" );
      return;
      #return if $size and $size == $sizenow;
      #$from = $sizenow  if $sizenow < $size;
    }
    #$to ||= $size - $from;
    #todo by nick
    $self->wait_clients();
    #$self->{'want'}{ $self->{peers}{$cid}{'INF'}{'ID'} || $nick }{$file} = $as || $file || '';
    #$self->log( 'dcdev', "wantid: $self->{peers}{$cid}{'INF'}{'ID'} || $self->{peers}{$sid}{'INF'}{'ID'} ||  $nick");
    $self->{'want'}{ $self->{peers}{$cid}{'INF'}{'ID'} || $self->{peers}{$sid}{'INF'}{'ID'} || $nick }{$file} = {
      'filename'       => $file,
      'fileas'         => $as || $file || '',
      'file_recv_to'   => $to,
      'file_recv_from' => $from,
      'file_recv_size' => $size,
      'file_recv_tth'  => $tth,
      #'file_recv_full'  => $full
    };
    my $peer =
         $self->{peers}{$cid}
      || $self->{peers}{$sid}
      || $self->{peers}{$nick}
      || {};
    $self->log( 'dbg', "getting [$nick] $file as $as  sid=[$sid]" );    #, Dumper $peer->{INF});
    if ( $self->{'adc'} ) {
      #my $token = $self->make_token($nick);
      local @_;
      if (  $self->{'M'} eq 'A'
        and $self->{'myip'}
        and !$self->{'passive_get'} )
      {
        @_ = ( 'CTM', $sid, $self->{'connect_protocol'}, $self->{'myport'}, $self->make_token($nick) );
      } else {
        @_ = ( 'RCM', $sid, $self->{'connect_protocol'}, $self->make_token($nick) );
      }
      $self->cmd( 'D', @_ );
      #$self->cmd( $dst, 'CTM', $peerid, $_[0], $self->{'myport'}, $_[1], )
    } else {
      $self->cmd( ( ( $self->{'M'} eq 'A' and $self->{'myip'} and !$self->{'passive_get'} ) ? '' : 'Rev' ) . 'ConnectToMe',
        $nick );
    }
  };
  $self->{'file_select'} ||= sub {
    my $self = shift;
    return if length $self->{'filename'};
    my $peerid = $self->{'peerid'} || $self->{'peernick'};
    #$self->log( 'dcdev','file_select000',$peerid,  $self->{'filename'}, $self->{'fileas'}, Dumper $self->{'want'});
    for my $file ( keys %{ $self->{'want'}{$peerid} } ) {
      #( $self->{'filename'}, $self->{'fileas'} ) = ( $_, $self->{'want'}{$peerid}{$_} );
      $self->{$_} = $self->{'want'}{$peerid}{$file}{$_} for keys %{ $self->{'want'}{$peerid}{$file} };
      #$self->log( 'dcdev', 'file_select1', $self->{'filename'}, $self->{'fileas'} );
      next unless defined $self->{'filename'};
      $self->{'filecurrent'} = $self->{'filename'};
      #delete  $self->{'want'}{ $peerid }{$_} ;   $self->{'filecurrent'}
      #$self->{'file_recv_from'}
      #$self->{'fileas'}
      last;
    }
    delete $self->{'downloading'}{ $self->{'file_recv_tth'} }{connect_start};
    #$self->log( 'dcdev', 'file_select2', $self->{'filename'}, $self->{'fileas'} );
    return unless defined $self->{'filename'};
    unless ( $self->{'filename'} ) {
      if ( $self->{'peers'}{$peerid}{'SUP'}{'BZIP'}
        or $self->{'NickList'}->{$peerid}{'XmlBZList'} )
      {
        $self->{'fileext'}  = '.xml.bz2';
        $self->{'filename'} = 'files' . $self->{'fileext'};
      } elsif ( $self->{'adc'} ) {
        $self->{'fileext'}  = '.xml';
        $self->{'filename'} = 'files' . $self->{'fileext'};
      } elsif ( $self->{'NickList'}->{$peerid}{'BZList'} ) {
        $self->{'fileext'}  = '.bz2';
        $self->{'filename'} = 'MyList' . $self->{'fileext'};
      } else {
        $self->{'fileext'}  = '.DcLst';
        $self->{'filename'} = 'MyList' . $self->{'fileext'};
      }
      $self->{'fileas'} .= $self->{'fileext'} if $self->{'fileas'};
      $self->{'file_recv_filelist'} = 1;
    }
    $self->{'file_recv_dest'} = ( $self->{'fileas'} || $self->{'filename'} );
    $self->{'file_recv_full'} = $self->{'file_recv_dest'};
    $self->{'file_recv_full'} = $self->{'download_to'} . $self->{'file_recv_full'}
      unless $self->{'file_recv_full'} =~ m{[/\\]};
    #$self->{'file_recv_dest'} = Encode::encode $self->{charset_fs}, $self->{'file_recv_dest'} if $self->{charset_fs};    # ne $self->{charset_protocol};
                                 #$self->{'file_recv_dest'}
       #$self->log( 'dcdev', "pre enc filename [$self->{'file_recv_dest'}] [$self->{charset_fs} ne $self->{charset_protocol}]");
       #$self->{'file_recv_dest'} = Encode::encode $self->{charset_fs}, Encode::decode $self->{charset_protocol},
       #$self->log( 'dcdev', "pst enc filename [$self->{'file_recv_dest'}]");
    mkdir_rec $self->{'partial_prefix'} if $self->{'partial_prefix'};
    $self->{'file_recv_partial'} = "$self->{'file_recv_dest'}.$self->{'file_recv_tth'}$self->{'partial_ext'}";
$self->log( 'dcdev', "file_recv_partial1 [$self->{'file_recv_partial'}]");
    $self->{'file_recv_partial'} = $self->{'partial_prefix'} . $self->{'file_recv_partial'}
      unless $self->{'file_recv_partial'} =~ m{[/\\]};
$self->log( 'dcdev', "file_recv_partial2 [$self->{'file_recv_partial'}]");
    $self->{'file_recv_partial'} = Encode::encode $self->{charset_fs}, $self->{'file_recv_partial'} if $self->{charset_fs};
    $self->{'filebytes'} = $self->{'file_recv_from'} = -s $self->{'file_recv_partial'};
    $self->{'file_recv_to'} ||= $self->{'file_recv_size'} - $self->{'file_recv_from'}
      if $self->{'file_recv_size'} and $self->{'file_recv_from'};
    #$self->log('dcdev', 'file_select3',               $self->{'filename'}, $self->{'fileas'},
    #  'part:', $self->{'file_recv_partial'}, 'full:',             $self->{'file_recv_full'},
    #  'from',  $self->{'file_recv_from'});
  };
  $self->{'file_open'} ||= sub {
    my $self = shift;
    #$self->{'fileas'}=$_[0] if !length $self->{'fileas'} or length $_[0];
    #$self->{'filetotal'} = $_[1]if ! $self->{'filetotal'} or $_[1];
    #$self->{'filetotal'} //= $self->{'file_recv_size'}
    my $oparam = $self->{'fileas'} eq '-' ? '>-' : '>>' . $self->{'file_recv_partial'};
    $self->handler( 'file_open_bef', $oparam );
# $self->log(      'dbg',             "file_open pre", $oparam, 'want bytes', $self->{'filetotal'}, 'as=',      $self->{'fileas'}, 'f=',            $self->{'filename'}    );
#$self->log( 'dcdev', "open [$oparam]" );
    open( $self->{'filehandle'}, $oparam )
      or $self->log( 'dcerr', "file_open error", $!, $oparam ),
      $self->handler( 'file_open_error', $!, $oparam ), return 1;
    binmode( $self->{'filehandle'} );
    $self->{'status'} = 'transfer';
    return 0;
  };
  $self->{'file_write'} ||= sub {
    my $self = shift;
    $self->{'file_start_time'} ||= time;
    my $fh = $self->{'filehandle'}
      or $self->log( 'err', 'cant write, no filehandle' ), return;
    for my $databuf (@_) {
      $self->{'filebytes'} += length $$databuf;
#$self->log( 'dcdbg', "($self->{'number'}) recv ".length($$databuf)." [$self->{'filebytes'}] of $self->{'filetotal'} file $self->{'filename'}" );
      $self->log( 'dcdbg', "recv " . length($$databuf) . " [$$databuf]" )
        if length $$databuf < 10;
      print $fh $$databuf;
      $self->log( 'err', "file download error! extra bytes ($self->{'filebytes'}/$self->{'filetotal'}) " )
        if $self->{'filebytes'} > $self->{'filetotal'};
      $self->log(
        'info',
        "file complete ($self->{'filebytes'}) per",
        $self->float( time - $self->{'file_start_time'} ),
        's at', $self->float( $self->{'filebytes'} / ( ( time - $self->{'file_start_time'} ) or 1 ) ), 'b/s'
        ),
        $self->disconnect(), $self->{'status'} = 'destroy',
        $self->{'file_start_time'} = 0, $self->{'filename'} = '',
        $self->{'fileas'} = '',
        delete $self->{'want'}{ $self->{'peerid'} }{ $self->{'filecurrent'} },
        $self->{'filecurrent'} = '', $self->{'file_recv_partial'} = '',
        $self->{'file_recv_from'} = $self->{'file_recv_to'} = undef,
        if $self->{'filebytes'} >= $self->{'filetotal'};
    }
  };
  $self->{'file_close'} ||= sub {
    my $self = shift;
    #$self->log( 'dcerr', 'file_close', 1);
    if ( $self->{'filehandle'} ) {
      #$self->log( 'dcerr', 'file_close',2);
      close( $self->{'filehandle'} ), delete $self->{'filehandle'};
      if ( $self->{'filebytes'} == $self->{'filetotal'} ) {
        mkdir_rec $self->{'download_to'} if $self->{'download_to'};
        if ( length $self->{'partial_ext'} ) {
          local $self->{'file_recv_full'} = Encode::encode $self->{charset_fs}, $self->{'file_recv_full'}
            if $self->{charset_fs};    # ne $self->{charset_protocol};
          $self->log( 'dcdev', 'file_close',3, $self->{'file_recv_partial'}, $self->{'file_recv_full'});
          $self->log( 'dcerr', 'cant move finished file', $self->{'file_recv_partial'}, $self->{'file_recv_full'} )
            if !rename $self->{'file_recv_partial'},
            $self->{'file_recv_full'};
        }
        delete $self->{'downloading'}{ $self->{'file_recv_tth'} };
        ( $self->{parent} || $self )->handler( 'file_recieved', $self->{'file_recv_full'}, $self->{'filename'} );
      }
    }
    if ( $self->{'downloading'}{ $self->{'file_recv_tth'} } ) {
#$self->log( 'dev', "onclose: downloading [$self->{'file_recv_tth'}], b$self->{'filebytes'} <= t$self->{'filetotal'} || $self->{'file_recv_size'}" );
      if ( $self->{'filebytes'} <= $self->{'filetotal'}
        || $self->{'file_recv_size'} )
      {
        $self->{'want_download'}{ $self->{'file_recv_tth'} } = $self->{'downloading'}{ $self->{'file_recv_tth'} };
      }    #else {                }
      delete $self->{'downloading'}{ $self->{'file_recv_tth'} };
    }
    $self->{'select_send'}->remove( $self->{'socket'} ), close( $self->{'filehandle_send'} ), delete $self->{'filehandle_send'},
      #$self->{'socket'}->flush(),
      if $self->{'filehandle_send'};
    delete $self->{$_} for 'file_send_left', 'file_send_total', 'file_recv_filelist';
    $self->{'status'} = 'connected';
  };
  $self->{'file_send_tth'} ||= sub {
    my $self = shift;
    my ( $file, $start, $size, $as ) = @_;
#$self->log( 'dcdev', 'my share', $self->{'share_full'}, scalar keys %{$self->{'share_full'} }, 'p share', $self->{'parent'}{'share_full'}, scalar keys %{$self->{'parent'}{'share_full'} }, );
#$self->{'share_tth'} ||=$self->{'parent'}{'share_tth'};
    if ( $self->{'share_full'}{$file} ) {
      $self->{'share_full'}{$file} =~ tr{\\}{/};
      #$self->log( 'dcdev', 'call send', $self->{'share_full'}{$file}, $start, $size, $as );
      $self->file_send( $self->{'share_full'}{$file}, $start, $size, $as );
    } else {
      $self->log(
        'dcerr', 'send', 'cant find file',
        $file, $self->{'share_full'}{$file},
        'from', scalar keys %{ $self->{'share_full'} }
      );
      return 1;
    }
    return undef;
  };
  $self->{'file_send'} ||= sub {
    my $self = shift;
    #$self->log( 'dcdev', 'file_send', Dumper \@_ );
    my ( $file, $start, $size, $as ) = @_;
    $start //= 0;
    my $filesize = -s $file;
    $size = $filesize - $start if $size <= 0;
    $self->log( 'dcerr', "cant find [$file]" ), $self->disconnect(), return
      if !-e $file
        or -d $file;
    if ( open $self->{'filehandle_send'}, '<', $file ) {
      binmode( $self->{'filehandle_send'} );
      seek( $self->{'filehandle_send'}, $start, SEEK_SET ) if $start;
      my $name = $file;
      $name =~ s{^.*[\\/]}{}g;
      $self->{'file_send_total'}  = $filesize;
      $self->{'file_send_offset'} = $start || 0;
      $self->{'file_send_left'}   = $size;
      $self->log( 'dev', "sendsize=$size filesize=$filesize from", $start, 'e', -e $file, $file, $self->{'file_send_total'} );
      #$self->{'filetotal'} = $self->{'file_send_offset'} + $self->{'file_send_left'};
      $self->file_close(), return if $start >= $self->{'file_send_total'};
      if ( $self->{'adc'} ) {
        $self->cmd( 'C', 'SND', 'file', $as || $name, $start, $size );
      } else {
        $self->cmd( 'ADCSND', 'file', $as || $name, $start, $size );
      }
      $self->{'status'} = 'transfer';
      #$self->file_send_part();
      $self->{'select_send'}->add( $self->{'socket'} );
    } else {
      $self->file_close();
    }
  };
  $self->{'file_send_part'} ||= sub {
    #psmisc::printlog 'call', 'file_send_part', @_;
    my $self = shift;
    #my ($file, $start, $size) = @_;
    #return unless $self->{'file_send_left'};
    #my $buf;
    #$self->disconnect(),
    return
      unless ( $self->{'socket'}
      and $self->{'socket'}->connected()
      and $self->{'filehandle_send'}
      and $self->{'file_send_left'} );
    my $read = $self->{'file_send_left'};
    $read = $self->{'file_send_by'}
      if $self->{'file_send_by'} < $self->{'file_send_left'};
    #my $readed =
    my $sent;
    if ( $INC{'Sys/Sendfile.pm'} ) {    #works
          #Sys::Sendfile::sendfile fileno($self->{'socket'}), fileno($self->{'filehandle_send'}), $read;
      $self->{'file_send_offset'} += $sent =
        Sys::Sendfile::sendfile( $self->{'socket'}, $self->{'filehandle_send'}, $read, $self->{'file_send_offset'} );
     #);
     #$self->log( 'dev', 'ssendfile0', "$read, offset=$self->{'file_send_offset'}, left=$self->{'file_send_left'} sent=$sent" );
     #$self->{'file_send_offset'} += $sent;
    }
#sux
#elsif ( $INC{'Sys/Sendfile/FreeBSD.pm'}) {
#use Sys::Sendfile::FreeBSD qw(sendfile);
#use Errno qw(EINTR EIO :POSIX);
#$self->log(      'dev','fsendfile1',  $self->{'file_send_offset'}, $read, 'left', $self->{'file_send_left'}, '=', $sent, 'ff=', fileno($self->{'filehandle_send'}), fileno($self->{'socket'}));
#my $result = sendfile(fileno($self->{'filehandle_send'}), fileno($self->{'socket'}), $self->{'file_send_offset'}, $read, $sent);
#my $result = sendfile( fileno($self->{'socket'}), fileno($self->{'filehandle_send'}),$self->{'file_send_offset'}, $read, $sent);
#$self->log(      'dev','fsendfile1',  $self->{'file_send_offset'}, $read, 'left', $self->{'file_send_left'}, 's=', $sent, 'r=',  $result, $!,
##Dumper \%!
#grep {$!{$_}} keys %!
#);
#}
#sux
#elsif ($INC{'IO/AIO.pm'}) {
#$self->log(      'dev','sendfile0',  $self->{'file_send_offset'}, $read, 'left', $self->{'file_send_left'}, '=', $sent);
#use IO::AIO;
#$sent = IO::AIO::sendfile(  fileno($self->{'filehandle_send'}), $self->{'socket'}->fileno(),$self->{'file_send_offset'}, $read );
#$sent = IO::AIO::sendfile(   $self->{'socket'}->fileno(), fileno($self->{'filehandle_send'}),$self->{'file_send_offset'}, $read );
#$sent = IO::AIO::sendfile(   fileno($self->{'socket'}), fileno($self->{'filehandle_send'}),$self->{'file_send_offset'}, $read );
#$sent = IO::AIO::sendfile(   $self->{'socket'}, $self->{'filehandle_send'},$self->{'file_send_offset'}, $read );
##$self->{'file_send_left'}
    #
    #$self->log(      'dev','sendfile1',  $self->{'file_send_offset'}, $read, 'left', $self->{'file_send_left'}, '=', $sent);
    #$self->{'file_send_offset'} += $sent;
    #$self->{'file_send_offset'} += $read, $sent = $read,if $sent == 12;
    #}
    else {
      read( $self->{'filehandle_send'}, $self->{'file_send_buf'}, $read ),
        $self->{'file_send_offset'} = tell $self->{'filehandle_send'},
        unless length $self->{'file_send_buf'};    #$self->{'file_send_by'};
                                                   #send $self->{'socket'},
                                                   #$self->{'socket'}->send( buf, POSIX::BUFSIZ, $self->{'recv_flags'} )
                                                   #my $sent;
                                                   #$self->log(      'snd',      length $self->{'file_send_buf'},
      $sent = $self->send( $self->{'file_send_buf'} );
      #eval {
      #$sent = $self->{'socket'}->send( $self->{'file_send_buf'} );
      #$_;
      #length $buf;
      #$sent;
      #};                                           # if $self->{'socket'};
      #$!    );
      #$self->log( 'err', 'send error', $@ ) if $@;
    }
    schedule(
      1,
      $self->{__stat_} ||= sub {
        my $self = shift;
        our ( $lastmark, $lasttime );
        $self->log(
          'dev',                   "sent bytes",                      #length $self->{'file_send_buf'},
          "sent=[$sent] of buf [", length $self->{'file_send_buf'},
          "] by [$read:$self->{'file_send_by'}] left $self->{'file_send_left'}, now",
          $self->{'file_send_offset'}, 'of',
          $self->{'file_send_total'},  's=',
          ( $self->{'file_send_offset'} - $lastmark ) /
            ( time - $lasttime or 1 ),
          "status=[$self->{'status'}]",
          ),
          $lastmark = $self->{'file_send_offset'}, $lasttime = time,
          #if time - $lasttime > 1;
      },
      $self
    );
    #$self->{activity} = time if $sent;
    #$self->{bytes_send} += $sent;
    $self->{'file_send_left'} -= $sent;
    substr( $self->{'file_send_buf'}, 0, $sent ) = undef;
#if (length $self->{'file_send_buf'}) {         $self->log( 'info', 'sent small', $sent, 'todo', length $self->{'file_send_buf'});    }
#$readed;
    if ( $self->{'file_send_left'} < 0 ) {
      $self->log( 'err', "oversend [$self->{'file_send_left'}]" );
      $self->{'file_send_left'} = 0;
    }
    if (
      #$readed < $self->{'file_send_by'} or
      $self->{'file_send_left'} <= 0
      )
    {
      $self->log(
        'dev', 'file completed', "r:", length $self->{'file_send_buf'},
        " by:$self->{'file_send_by'} left:$self->{'file_send_left'} total:$self->{'file_send_total'}",
        #caller 2
      );
      $self->file_close();
      #$self->{'status'} = 'connected';
      #?
      #$self->disconnect();
      $self->destroy();
    }
    return $sent;
  };
  $self->{'file_send_parse'} =
    #$self->{'ADCSND'} =
    sub {
    my $self = shift if ref $_[0];
    #$self->log(    'cmd_adcSND', Dumper \@_);
    #my ( $dst, $peerid, $toid ) = @{ shift() };
    if ( $_[0] eq 'file' ) {
      my $file = $_[1];
      if ( $file =~ s{^TTH/}{} ) {
        return $self->file_send_tth( $file, $_[2], $_[3], $_[1] );
      } else {
        #$self->file_send($file, $_[2], $_[3]);
        return $self->file_send_tth( $file, $_[2], $_[3], $_[1] );
      }
    } elsif ( $_[0] eq 'list' ) {
      return $self->file_send_tth( 'files.xml.bz2', );
    } elsif ( $_[0] eq 'tthl' ) {
      #TODO!! now fake
      ( my $tth = $_[1] ) =~ s{^TTH/}{};
      eval q{
        use MIME::Base32 qw( RFC );
        $tth = MIME::Base32::decode $tth;
      };
      if ( $self->{'adc'} ) {
        $self->cmd( 'C', 'SND', $_[0], $_[1], $_[2], length $tth );
      } else {
        $self->cmd( 'ADCSND', $_[0], $_[1], $_[2], length $tth );
      }
      $self->send($tth);
    } else {
      $self->log( 'dcerr', 'SND', "unknown type", @_ );
      return 2;
    }
    return undef;
    };
  $self->{'download'} ||= sub {
    my $self = shift;
    my ($file) = @_;
    #$self->log('dev', "0s=[$self]; download [$file] now $self->{'want_download'}{$file} ", Dumper \@_);
    push @{ $self->{'queue_download'} ||= [] }, $file;
    #$self->log('dev', "1s=[$self]; download [$file] now $self->{'want_download'}{$file} ", Dumper \@_);
    $self->{'want_download'}{$file} ||= {};
  };
  $self->{'get_peer_addr'} ||= sub () {
    my ( $self, $recv ) = @_;
    return unless $self->{'socket'};
    local @_ = socket_addr $self->{'socket'};
    #eval { @_ = unpack_sockaddr_in( getpeername( $self->{'socket'} ) || return ) };
    #return unless $_[1];
    #return unless $_[1] = inet_ntoa( $_[1] );
    $self->{'port'} = $_[0] if $_[0];    #;and !$self->{'incoming'};
    $self->{'hostip'} = $_[1], $self->{'host'} ||= $self->{'hostip'}
      if $_[1];
    return $self->{'hostip'};
  };
  $self->{'get_peer_addr_recv'} ||= sub (;$) {
    my ( $self, $recv ) = @_;
    #return unless $self->{'socket'};
    $recv ||= $self->{'recv_addr'};
    ( $self->{'recv_port'}, my $hostn ) = sockaddr_in($recv);
    $self->{'recv_host'} = gethostbyaddr( $hostn, AF_INET );
    $self->{'recv_hostip'} = inet_ntoa($hostn);
    return $self->{'hostip'};
  };
  $self->{'get_my_addr'} ||= sub {
    my ($self) = @_;
    return unless $self->{'socket'};
    eval { @_ = unpack_sockaddr_in( getsockname( $self->{'socket'} ) || return ); };
    $self->log('dcerr', "cant get my ip [$@]", Dumper \@_) if $@;
    #$self->log('dcerr', "cant get my ip [0.0.0.0:$_[0]]"), 
    return if $_[1] eq "\0\0\0\0";
    #$self->log('dev', "1my ip", Dumper \@_);
    #return unless $_[1];
    return unless $_[1] and $_[1] = inet_ntoa( $_[1] );
    #$self->log('dev', "2my ip", Dumper \@_);
    #return if $_[1] eq '0.0.0.0';
    #$self->{'log'}->('dev', "MYIP($self->{'myip'}) [$self->{'number'}] SOCKNAME $_[0],$_[1];");
    return $self->{'myip'} ||= $_[1];
  };
  $self->{'info'} ||= sub {
    my $self = shift;
    $self->log(
      'info',
      map( {"$_=$self->{$_}"} grep { $self->{$_} } @{ $self->{'informative'} } ),
      #map( { $_ . '(' . scalar( keys %{ $self->{$_} } ) . ')=' . join( ',', sort keys %{ $self->{$_} } ) }
        #grep { keys %{ $self->{$_} } } @{ $self->{'informative_hash'} } )
        'clients:', scalar keys %{ $self->{'clients'} }, 
        map {"($self->{'clients'}{$_}{'number'})$_=$self->{'clients'}{$_}{'status'}"} 
        sort keys %{ $self->{'clients'}},
    );
    $self->log(
      'dcdbg',
      "protocol stat",
      Dumper( {
          map { $_ => $self->{$_} }
          grep { $self->{$_} } qw(count_sendcmd count_parse)
        }
      ),
    );
    #( ref $self->{'clients'}{$_}{info} ? $self->{'clients'}{$_}->info() : () ) for sort keys %{ $self->{'clients'} };
  };
  $self->{'active'} ||= sub {
    my $self = shift;
    return $self->{'status'}
      if grep { $self->{'status'} eq $_ } qw(connecting_tcp connecting connected reconnecting listening transfer);
    return 0;
  };
  #sub status {
  #now states:
  #listening  connecting_tcp connecting   connected   reconnecting transfer  disconnecting disconnected destroy
  #need checks:
  #\ connected?/             \-----/
  #\-----------------------active?-------------------------/
  #}
  $self->{'every'} ||= sub {
    my ( $self, $sec, $func ) = ( shift, shift, shift );
    if (  ( $self->{'every_list'}{$func} + $sec < time )
      and ( ref $func eq 'CODE' ) )
    {
      $self->{'every_list'}{$func} = time;
      $func->(@_);
    }
  };
  $self->{'adc_make_string'} = sub (@) {
    my $self = shift if ref $_[0];
    join ' ', map {
      ref $_ eq 'ARRAY' ? @$_ : ref $_ eq 'HASH' ? do {
        my $h = $_;
        map { "$_$h->{$_}" } keys %$h;
        }
        : $_
    } @_;
  };
  $self->{'cmd_adc'} ||= sub {
    my ( $self, $dst, $cmd ) = ( shift, shift, shift );
    #$self->sendcmd( $dst, $cmd,map {ref $_ eq 'HASH'}@_);
    #$self->log( 'cmd_adc', $dst, $cmd, "SI[$self->{'INF'}{'SID'}]",Dumper \@_ );
    $self->sendcmd(
      $dst, $cmd,
      #map {ref $_ eq 'ARRAY' ? @$_:ref $_ eq 'HASH' ? each : $_)    }@_
      (    #$self->{'broadcast'} ? $self->{'INF'}{'SID'} #$self->{'INF'}{'ID'}
            #:
        ( $dst eq 'C' or !length $self->{'INF'}{'SID'} )
        ? ()
        : $self->{'INF'}{'SID'}
      ),
      $self->adc_make_string(@_)
        #( $dst eq 'D' || !length $self->{'sid'} ? () : $self->{'sid'} ),
    );
  };
  #sub adc_string_decode ($) {
  $self->{'adc_string_decode'} ||= sub ($) {
    my $self = shift;
    local ($_) = @_;
    s{\\s}{ }g;
    s{\\n}{\x0A}g;
    s{\\\\}{\\}g;
    $_;
  };
  #sub adc_string_encode ($) {
  $self->{'adc_string_encode'} = sub ($) {
    my $self = shift;
    local ($_) = @_;
    s{\\}{\\\\}g;
    s{ }{\\s}g;
    s{\x0A}{\\n}g;
    $_;
  };
  $self->{'adc_path_encode'} = sub ($) {
    my $self = shift;
    local ($_) = @_;
    s{^(\w:)}{/${1}_}g;
    s{\\}{/}g;
    $self->adc_string_encode($_);
  };
  #sub adc_strings_decode (\@) {
  $self->{'adc_strings_decode'} = sub (\@) {
    my $self = shift;
    map { $self->adc_string_decode($_) } @_;
  };
  #sub adc_strings_encode (\@) {
  $self->{'adc_strings_encode'} = sub (\@) {
    my $self = shift;
    map { $self->adc_string_encode($_) } @_;
  };
  $self->{'adc_parse_named'} = sub (@) {
    my $self = shift;
    #sub adc_parse_named (@) {
    #my ($dst,$peerid) = @{ shift() };
    #$self->log('dev', "p0:", @_);
    local %_;
    for ( local @_ = @_ ) {
      s/^([A-Z][A-Z0-9])//;
      #my $name=
      #print "PARSE[$1=$_]\n",
      $_{$1} = $self->adc_string_decode($_);
      #$self->log('dev', "p1:$1=$_{$1}");
    }
    return \%_;
    #return ($dst,$peerid)
  };
  $self->{'make_token'} = sub (;$) {
    my $self   = shift;
    my $peerid = shift;
    my $token;
    local $_;
    $_ = $self->{'peers'}{$peerid}{'INF'}{I4}
      if $peerid and exists $self->{'peers'}{$peerid};
    s/\D//g;
    $token += $_;
    $_ = $self->{myip};
    s/\D//g;
    return $token + $_ + int time;
  };
  $self->{'say'} = sub (@) {
    my $self = shift;
    @_ = $_[2] if $_[0] eq 'MSG';
    #local $_ = Encode::encode $self->{charset_console} , join ' ', @_;print $_, "\n";
    print Encode::encode( $self->{charset_console}, join ' ', @_ ), "\n";
  };
  local %_ = (
    'search' => sub {
      my $self = shift if ref $_[0];
      #$self->log( 'search', @_ );
      return $self->cmd( 'search_tth', @_ )
        if length $_[0] == 39 and $_[0] =~ /^[0-9A-Z]+$/;
      return $self->cmd( 'search_string', @_ ) if length $_[0];
    },
    'search_retry' => sub {
      my $self = shift if ref $_[0];
      unshift( @{ $self->{'search_todo'} }, $self->{'search_last'} )
        if ref $self->{'search_last'} eq 'ARRAY';
      $self->{'search_last'} = undef;
    },
    'search_buffer' => sub {
      my $self = shift if ref $_[0];
      push( @{ $self->{'search_todo'} }, [@_] ) if @_;
      return unless @{ $self->{'search_todo'} || return };
#$self->log($self, 'search', Dumper \@_);
#$self->log( 'dcdev', "search too fast [$self->{'search_every'}], len=", scalar @{ $self->{'search_todo'} } )        if @_ and scalar @{ $self->{'search_todo'} } > 1;
      return
        if time() - $self->{'search_last_time'} < $self->{'search_every'} + 2;
      $self->{'search_last'} = shift( @{ $self->{'search_todo'} } );
      $self->{'search_todo'} = undef unless @{ $self->{'search_todo'} };
      $self->cmd('search_send');
#if ( $self->{'adc'} ) {
#}      else {
#$self->sendcmd( 'Search', $self->{'M'} eq 'P' ? 'Hub:' . $self->{'Nick'} : "$self->{'myip'}:$self->{'myport_udp'}", join '?', @{ $self->{'search_last'} } );
#}
      $self->{'search_last_time'} = time();
    },
    'nick_generate' => sub {
      my $self = shift if ref $_[0];
      $self->{'nick_base'} ||= $self->{'Nick'};
      $self->{'Nick'} = $self->{'nick_base'} . int( rand( $self->{'nick_random'} || 100 ) );
    },
    'clients_my' => sub {
      my $self = shift if ref $_[0];
      grep { $self->{'clients'}{$_} and $self->{'clients'}{$_}{parent} eq $self }
        keys %{ $self->{'clients'} };
    },
  );
  $self->{$_} = $_{$_} for keys %_;
}
#print "N:DC:CALLER=", caller, "\n";
do {
  use lib '../';
  __PACKAGE__->new( auto_work => 1, @ARGV ),;
} unless caller;
1;
__END__

=head1 NAME

Net::DirectConnect - Perl Direct Connect protocol implementation

=head1 SYNOPSIS

  use Net::DirectConnect;
  my $dc = Net::DirectConnect->new(
    'host' => 'dc.mynet.com:4111', #if not 411
    'Nick' => 'Bender', 
    'description' => 'kill all humans',
     #'M'           => 'P', #passive mode, autodetect by default
     #'local_mask'       => [qw(80.240)], #mode=active if hub in this nets and your ip in gray
  );
  $dc->wait_connect();
  $dc->chatline( 'hi all' );

  while ( $dc->active() ) {
    $dc->work();    
  }
  $dc->destroy();

look at examples for handlers


=head1 DESCRIPTION

 Currently NOT supported:
 segmented, multisource download;
 async connect;


=head1 INSTALLATION

 To install this module type the following:

   perl Makefile.PL && make install clean
   

=head1 SEE ALSO

 latest snapshot
 svn co svn://svn.setun.net/dcppp/trunk/ dcppp

 http://svn.setun.net/dcppp/timeline/browser/trunk

 usage example:
 used in [and created for] http://sourceforge.net/projects/pro-search http://pro.setun.net/search/
 ( http://svn.setun.net/search/trac.cgi/browser/trunk/crawler.pl )


 protocol info:
 http://en.wikipedia.org/wiki/Direct_Connect_network
 http://www.teamfair.info/DC-Protocol.htm
 http://adc.sourceforge.net/ADC.html

 also useful for creating links from web:
 http://magnet-uri.sourceforge.net/
 http://en.wikipedia.org/wiki/Magnet:_URI_scheme

=head1 TODO
 
 CGET file files.xml.bz2 0 -1 ZL1<<<

 Rewrite better

=head1 AUTHOR

Oleg Alexeenkov, E<lt>pro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2011 Oleg Alexeenkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
