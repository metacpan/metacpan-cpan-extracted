package Poker::Robot;
use Moo;
use Mojo::JSON qw(j);
use Mojo::Log;
use Mojo::UserAgent;
use Poker::Robot::Login;
use Poker::Robot::Ring;
use Poker::Robot::Chair;
use DBI;
use DBD::SQLite;
use EV;

=encoding utf8

=head1 NAME

Poker::Robot - base class for building custom poker robots 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    package Poker::Robot::Mybot;
    use Moo;
    
    # Poker::Robot::Random shows a working example
    extends 'Poker::Robot::Random';

    # override default method 
    sub move {
      # move selection logic goes here
    }

    # and elsewhere in a script ...
    use Poker::Robot::Mybot;

    # Note: you must pick a unique username!
    $robot = Poker::Robot::Mybot->new(
      websocket => 'wss://aitestbed.com:443/websocket',
      username => 'Mybot',  
      ring_ids => [ 1 ], 
    );

    $robot->connect;

=head1 INTRODUCTION

Handlers are automatically executed at appropriate stages of the game, allowing your bot to run on autopilot.  By default, these handlers return legal but essentially random values. Your job is to override them in your subclass with something that makes more sense. Poker::Robot::Random shows a working example.

=head1 SERVERS

https://aitestbed.com is the default test server.  This is where you can deploy your bot once it is ready and have it compete against other bots and humans in real-time.

=head1 LOGGING

To see what your bot is doing, do a tail -f on robot.log

=head1 ATTRIBUTES

=head2 websocket

Websocket address of the test server.  Default is wss://aitestbed:443/websocket

=cut

has 'websocket' => (
  is      => 'rw',
  builder => '_build_websocket',
);

sub _build_websocket {
  return 'wss://aitestbed.com:443/websocket';
}

=head2 ring_ids

Required.  Ids of ring games to join. Before setting this attribute, bring up the test site on your browser to see which tables have open seats.

=cut

has 'ring_ids' => (
  is      => 'rw',
  isa     => sub { die "Not an array!" unless ref $_[0] eq 'ARRAY' },
  builder => '_build_ring_ids',
);

sub _build_ring_ids {
  return [];
}

has 'log' => (
  is  => 'rw',
  isa => sub { die "Not a Mojo::Log!" unless $_[0]->isa('Mojo::Log') },
  default =>
    sub { return Mojo::Log->new( path => 'robot.log' ) },
);

has 'login_id' => ( is => 'rw', );

has 'username' => (
  is       => 'rw',
  required => 1,
);

has 'user_id' => ( is => 'rw', );

has 'password' => ( is => 'rw', );

has 'bookmark' => ( is => 'rw', );

has 'login_list' => (
  is      => 'rw',
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_login_list',
);

sub _build_login_list {
  return {};
}

sub fetch_login {
  my ( $self, $id ) = @_;
  return $self->login_list->{$id};
}

has 'table_list' => (
  is      => 'rw',
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_table_list',
);

sub _build_table_list {
  return {};
}

sub fetch_ring {
  my ( $self, $id ) = @_;
  return $self->table_list->{$id};
}

sub response_handler {
  my ( $self, $aref ) = @_;

  if ( ref $aref ne 'ARRAY' ) {
    $self->log->info('invalid_format');
    return;
  }

  my ( $cmd, $opts ) = @$aref;

  if ( ref $cmd || !exists $self->client_update->{$cmd} ) {
    $self->log->info("invalid_client_update: $cmd");
    return;
  }

  $self->client_update->{$cmd}( $self, $opts );
}

has 'client_update' => (
  is      => 'rw',
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_client_update',
);

sub _build_client_update {
  return {

    # SERVER CODES
    guest_login      => sub { shift->guest_login(shift) },
    login_snap       => sub { shift->login_snap(shift) },
    ring_snap        => sub { shift->ring_snap(shift) },
    tour_snap        => sub { shift->tour_snap(shift) },
    player_snap      => sub { shift->player_snap(shift) },
    table_snap       => sub { shift->table_snap(shift) },
    message_snap     => sub { },
    table_update     => sub { shift->table_update(shift) },
    player_update    => sub { shift->player_update(shift) },
    login_update     => sub { shift->login_update(shift) },
    new_game         => sub { shift->new_game(shift) },
    end_game         => sub { shift->end_game(shift) },
    deal_hole        => sub { shift->deal_hole(shift) },
    begin_new_round  => sub { shift->begin_new_round(shift) },
    begin_new_action => sub { shift->begin_new_action(shift) },
    deal_community => sub { shift->deal_community(shift) },
    showdown       => sub { shift->showdown(shift) },
    high_winner    => sub { shift->high_winner(shift) },
    low_winner     => sub { shift->low_winner(shift) },
    move_button    => sub { shift->move_button(shift) },
    forced_logout  => sub { shift->forced_logout(shift) },

    # NOTIFICATION CODES
    notify_login        => sub { shift->notify_login(shift) },
    notify_update_login => sub { shift->notify_update_login(shift) },
    notify_logout       => sub { shift->notify_logout(shift) },
    notify_create_ring  => sub { shift->notify_create_ring(shift) },
    notify_join_table   => sub { shift->notify_join_table(shift) },
    notify_unjoin_table => sub { shift->notify_unjoin_ring(shift) },
    notify_post         => sub { shift->notify_bet(shift) },
    notify_bet          => sub { shift->notify_bet(shift) },
    notify_check        => sub { shift->notify_check(shift) },
    notify_fold         => sub { shift->notify_fold(shift) },
    notify_discard      => sub { shift->notify_discard(shift) },
    notify_draw         => sub { shift->notify_draw(shift) },
    notify_credit_chips => sub { shift->notify_credit_chips(shift) },
    notify_table_chips  => sub { shift->notify_table_chips(shift) },
    notify_lobby_update => sub { },
    notify_message      => sub { },
    notify_pick_game    => sub { },
    notify_lr_update    => sub { },

    # RESPONSE CODES
    join_ring_res   => sub { shift->join_ring_res(shift) },
    unjoin_ring_res => sub { shift->unjoin_ring_res(shift) },
    watch_table_res => sub { shift->watch_table_res(shift) },
    unwatch_table_res => sub { shift->unwatch_table_res(shift) },
    login_res         => sub { shift->login_res(shift) },
    logout_res        => sub { shift->logout_res(shift) },
    register_res      => sub { shift->register_res(shift) },
    bet_res           => sub { shift->bet_res(shift) },
    check_res         => sub { shift->check_res(shift) },
    fold_res          => sub { shift->fold_res(shift) },
    discard_res       => sub { shift->discard_res(shift) },
    draw_res          => sub { shift->draw_res(shift) },
    credit_chips_res  => sub { shift->add_chips_res(shift) },
    pick_game_res     => sub { },
  };
}

=head1 HANDLERS

The following handlers can be overriden in your subclass with custom code for you robot.  At some point I'll get around to documenting this better, but this will have to do for now.  

=head2 SERVER CODES

    guest_login     
    login_snap   
    ring_snap   
    tour_snap        
    player_snap     
    table_snap       
    message_snap     
    table_update    
    player_update    
    login_update     
    new_game         
    end_game         
    deal_hole        
    begin_new_round  
    begin_new_action 
    deal_community 
    showdown       
    high_winner    
    low_winner     
    move_button    
    forced_logout  

=head2 NOTIFICATION CODES

    notify_login        
    notify_update_login 
    notify_logout       
    notify_create_ring  
    notify_join_table   
    notify_unjoin_table 
    notify_post         
    notify_bet          
    notify_check        
    notify_fold         
    notify_discard      
    notify_draw         
    notify_credit_chips 
    notify_table_chips  
    notify_lobby_update
    notify_message    
    notify_pick_game    
    notify_lr_update   

=head2 RESPONSE CODES

    join_ring_res   
    unjoin_ring_res 
    watch_table_res 
    unwatch_table_res
    login_res         
    logout_res        
    register_res      
    bet_res           
    check_res         
    fold_res          
    discard_res       
    draw_res         
    pick_game_res     
    reload_res 

=head2 REQUEST CODES

    join_ring
    unjoin_ring
    watch_table
    unwatch_table
    login
    logout
    register
    bet      
    check      
    fold          
    discard       
    draw        
    pick_game
    reload 

=cut

sub forced_logout {
  my ( $self, $opts ) = @_;
}

sub add_ring {
  my ( $self, $opts ) = @_;
  delete $self->table_list->{ $opts->{table_id} };
  my $ring = Poker::Robot::Ring->new($opts);
  $self->table_list->{ $opts->{table_id} } = $ring;
  if ( exists $self->ring_hash->{ $opts->{table_id} } ) {
    $self->respond( [ 'watch_table', { table_id => $opts->{table_id} } ] );
  }
}

sub add_login {
  my ( $self, $opts ) = @_;
  $self->login_list->{ $opts->{login_id} } = Poker::Robot::Login->new($opts);
}

# SERVER CODES

sub guest_login {
  my ( $self, $opts ) = @_;
  $self->login_id( $opts->{login_id} );
  if ( defined $self->bookmark ) {
    $self->respond( [ 'login_book', { bookmark => $self->bookmark } ] );
  }
  else {
    my $reg = [ 'register', { username => $self->username } ];
    $reg->[1]->{password} = $self->password if $self->password;
    $reg->[1]->{email}    = $self->email    if $self->email;
    $reg->[1]->{birthday} = $self->birthday if $self->birthday;
    $reg->[1]->{handle}   = $self->handle   if $self->handle;
    $self->respond($reg);
  }
}

sub login_snap {
  my ( $self, $opts ) = @_;
  $self->add_login($_) for (@$opts);
}

sub ring_snap {
  my ( $self, $opts ) = @_;
  $self->add_ring($_) for (@$opts);
}

sub tour_snap {
  my ( $self, $opts ) = @_;
}

sub table_update {
  my ( $self, $opts ) = @_;
  $self->table_snap($opts);
}

sub table_snap {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  %$ring = ( %$ring, %$opts );
}

sub player_snap {
  my ( $self, $opts ) = @_;
  for my $r (@$opts) {
    $self->_join_table($r);
  }
}

sub player_update {
  my ( $self, $opts ) = @_;
  my $ring  = $self->table_list->{ $opts->{table_id} };
  my $chair = $ring->chairs->[ $opts->{chair} ];
  %$chair = ( %$chair, %$opts ) if $chair;
}

sub new_game {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  $ring->reset;
  %$ring = ( %$ring, %$opts );
}

sub end_game {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  $ring->game_over(1);
}

sub deal_hole {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  $ring->chairs->[ $opts->{chair} ]->cards( $opts->{cards} );
}

sub begin_new_round {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  for my $chair ( grep { defined } @{ $ring->chairs } ) {
    $chair->in_pot_this_round(0);
  }
  %$ring = ( %$ring, %$opts );
}

sub deal_community {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  %$ring = ( %$ring, %$opts );
}

sub showdown {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  %$ring = ( %$ring, %$opts );
}

sub high_winner {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  %$ring = ( %$ring, %$opts );
}

sub low_winner {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  %$ring = ( %$ring, %$opts );
}

sub move_button {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  %$ring = ( %$ring, %$opts );
}

# NOTIFICATION CODES

sub notify_login {
  my ( $self, $opts ) = @_;
  $self->login_list->{ $opts->{login_id} } = Poker::Robot::Login->new($opts)
    unless $opts->{login_id} == $self->login_id;
}

sub notify_update_login {
  my ( $self, $opts ) = @_;
  my $login = $self->login_list->{ $opts->{login_id} };
  %$login = %$opts;
}

sub notify_logout {
  my ( $self, $opts ) = @_;
  delete $self->login_list->{ $opts->{login_id} };
}

sub notify_create_ring {
  my ( $self, $opts ) = @_;
  $self->add_ring($opts);
}

sub notify_join_table {
  my ( $self, $opts ) = @_;
  $self->_join_table($opts);
}

sub _join_table {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  $ring->chairs->[ $opts->{chair} ] = Poker::Robot::Chair->new($opts);
}

sub notify_unjoin_ring {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  $ring->chairs->[ $opts->{chair} ] = undef;
}

sub notify_fold {
  my ( $self, $opts ) = @_;
  my $ring  = $self->table_list->{ $opts->{table_id} };
  my $chair = $ring->chairs->[ $opts->{chair} ];
  $chair->is_in_hand(0);
  $chair->cards( [] );
}

sub notify_bet {
  my ( $self, $opts ) = @_;
  my $ring  = $self->table_list->{ $opts->{table_id} };
  my $chair = $ring->chairs->[ $opts->{chair} ];
  $chair->in_pot_this_round( $chair->in_pot_this_round + $opts->{chips} );
  $chair->in_pot( $chair->in_pot + $opts->{chips} );
}

sub notify_check {
  my ( $self, $opts ) = @_;
}

sub notify_discard {
  my ( $self, $opts ) = @_;
  my $ring  = $self->table_list->{ $opts->{table_id} };
  my $chair = $ring->chairs->[ $opts->{chair} ];
  unless ( $chair->login_id == $self->login_id ) {
    for my $id ( @{ $opts->{card_idx} } ) {
      splice( @{ $chair->cards }, $id, 1 );
    }
  }
}

sub notify_draw {
  my ( $self, $opts ) = @_;
}

sub notify_credit_chips {
  my ( $self, $opts ) = @_;
  my $login = $self->login_list->{ $opts->{login_id} };
  $login->chips->{ $opts->{director_id} } = $opts->{chips};
}

sub notify_table_chips {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  $ring->chair->[ $opts->{chair} ]->chips( $opts->{chips} );
}

# RESPONSE CODES

sub join_ring_res {
  my ( $self, $opts ) = @_;
}

sub unjoin_ring_res {
  my ( $self, $opts ) = @_;
}

sub watch_table_res {
  my ( $self, $opts ) = @_;
  $self->table_snap($opts);
  my $login = $self->login_list->{ $self->login_id };
  my $chips = $login->chips->{ $opts->{director_id} };
  my $table = $self->table_list->{ $opts->{table_id} };
  return unless $chips && $table;
  $chips = $table->table_max if $table->table_max && $chips > $table->table_max;
  $self->respond(
    [
      'join_ring',
      { table_id => $opts->{table_id}, chips => $chips, auto_rebuy => $chips }
    ]
  );
}

sub unwatch_table_res {
  my ( $self, $opts ) = @_;
}

sub login_res {
  my ( $self, $opts ) = @_;
  if ( $opts->{success} ) {
    $self->login_id( $opts->{login_id} );
    my $login = $self->login_list->{ $opts->{login_id} };
    %$login = %$opts;
  }
}

sub login_update {
  my ( $self, $opts ) = @_;
  my $login = $self->login_list->{ $self->{login_id} };
  %$login = %$opts;
}

sub logout_res {
  my ( $self, $opts ) = @_;
  $self->tx->finish;
}

sub register_res {
  my ( $self, $opts ) = @_;
  if ( $opts->{success} ) {
    $self->login_id( $opts->{login_id} );
    my $login = $self->login_list->{ $opts->{login_id} };
    %$login = %$opts;
    $self->_replace_bot($opts);
  }
  else {
    $self->respond( ['logout'] );
  }
}

sub bet_res {
  my ( $self, $opts ) = @_;
}

sub check_res {
  my ( $self, $opts ) = @_;
}

sub fold_res {
  my ( $self, $opts ) = @_;
}

sub discard_res {
  my ( $self, $opts ) = @_;
}

sub draw_res {
  my ( $self, $opts ) = @_;
}

sub credit_chips_res {
  my ( $self, $opts ) = @_;
}

1;

has 'db' => ( is => 'rw', );

sub _build_db {
  my $self = shift;
  return DBI->connect( "dbi:SQLite:dbname=robots.db", "", "" );
}

has 'ring_hash' => (
  is      => 'rw',
  isa     => sub { die "Not a hash!" unless ref $_[0] eq 'HASH' },
);

sub _build_ring_hash {
  my $self = shift;
  return { map { $_ => 1 } @{ $self->ring_ids } } ;
}

has 'move_timer' => (
  is  => 'rw',
  isa => sub { die "Not a hash!" unless ref $_[0] eq 'HASH' },
  default => sub { {} },
);

has 'tx' => ( is => 'rw', );

has 'ua' => (
  is      => 'rw',
  builder => '_build_ua',
);

sub _build_ua {
  return Mojo::UserAgent->new( inactivity_timeout => 0 );
}

has 'valid_actions' => (
  is      => 'rw',
  builder => '_build_valid_actions',
);

sub _build_valid_actions {
  return {
    bet     => sub { shift->bet(shift) },
    check   => sub { shift->check(shift) },
    fold    => sub { shift->fold(shift) },
    draw    => sub { shift->draw(shift) },
    discard => sub { shift->discard(shift) },
    choice  => sub { shift->choice(shift) },
    bring   => sub { shift->bet(shift) },
  };
}

has 'email' => ( is => 'rw', );

has 'birthday' => ( is => 'rw', );

has 'handle' => ( is => 'rw', );

sub respond {
  my ( $self, $data ) = @_;

  my $json = j($data);
  $self->tx->send( $json );
  $self->log->info("robot: $json");
}

sub begin_new_action {
  my ( $self, $opts ) = @_;
  my $ring = $self->table_list->{ $opts->{table_id} };
  %$ring = ( %$ring, %$opts );
  my $table = $self->table_list->{ $opts->{table_id} };

  my $login_id = $table->chairs->[ $opts->{action} ]->login_id;
  $self->move($table) if $login_id == $self->login_id;
}

sub move {
  my ( $self, $table ) = @_;
}

sub size_bring {
  my ( $self, $table ) = @_;
  my @bets = ( $table->bring, $table->max_bet );
  $table->bet_size( $bets[ int( rand( scalar @bets ) ) ] );
}

sub bet {
  my ( $self, $table ) = @_;
  $self->respond(
    [ 'bet', { table_id => $table->table_id, chips => $table->bet_size } ] );
}

sub check {
  my ( $self, $table ) = @_;
  $self->respond( [ 'check', { table_id => $table->table_id } ] );
}

sub fold {
  my ( $self, $table ) = @_;
  $self->respond( [ 'fold', { table_id => $table->table_id } ] );
}

sub choice {
  my ( $self, $table ) = @_;
  $self->respond(
    [
      'pick_game', { table_id => $table->table_id, game => $table->game_choice }
    ]
  );
}

sub discard {
  my ( $self, $table ) = @_;
  $self->respond(
    [
      'discard',
      { table_id => $table->table_id, card_idx => $table->card_select }
    ]
  );
}

sub draw {
  my ( $self, $table ) = @_;
  $self->respond(
    [
      'draw', { table_id => $table->table_id, card_idx => $table->card_select }
    ]
  );
}

sub connect {
  my $self = shift;

  $self->ua->websocket(
    $self->websocket => sub {
      my ( $ua, $tx ) = @_;
      $self->log->error($tx->error->{message}) if $tx->error;

      # Check if WebSocket handshake was successful
      $self->log->error('WebSocket handshake failed!') and return unless $tx->is_websocket;
      $self->tx($tx);

      # Wait for WebSocket to be closed
      $tx->on(
        finish => sub {
          my ( $tx, $code ) = @_;
          $self->log->error( $tx->error->{message}) if $tx->error;
          $self->log->info("WebSocket closed with code $code.");
        }
      );

      $tx->on(
        json => sub {
          my ( $tx, $js ) = @_;
          if ($js) {
            $self->log->info('server: ' . j($js));
            $self->response_handler($js);
          }
        }
      );
      $tx->send('["guest_login"]');
    }
  );
  EV::run;
}

sub _select_bot {
  my $self = shift;
  my $sql  = 'SELECT * FROM bots WHERE username = ?';
  my $sth  = $self->db->prepare($sql);
  $sth->execute( $self->username );
  my $opts = $sth->fetchrow_hashref;
  if ( ref $opts eq 'HASH' ) {
    $self->bookmark( $opts->{bookmark} );
  }
}

sub _replace_bot {
  my ( $self, $opts ) = @_;
  my $sql = <<SQL;
REPLACE INTO bots (username, password, bookmark, modified)
VALUES (?,?,?,?)
SQL
  my $sth = $self->db->prepare($sql);
  $sth->execute( $opts->{username}, $opts->{password}, $opts->{bookmark},
    time );
}

sub _create_bots {
  my $self = shift;
  my $sql  = <<SQL;
CREATE TABLE bots (
  id INTEGER PRIMARY KEY NOT NULL,
  bookmark varchar(40) NOT NULL,
  username varchar(255) NOT NULL,
  password varchar(40),
  modified datetime
);
SQL

  $self->db->do($sql);
  $self->db->do('CREATE UNIQUE INDEX bots_idx1 ON bots (username)');
  $self->db->do('CREATE UNIQUE INDEX bots_idx2 ON bots (bookmark)');
}

sub BUILD {
  my $self = shift;
  $self->ring_hash( $self->_build_ring_hash );
  $self->db( $self->_build_db );
  eval { $self->db->prepare("SELECT 1 FROM bots") } or $self->_create_bots;
  $self->_select_bot; 
}

=head1 AUTHOR

Nathaniel Graham, C<ngraham@cpan.org> 

=head1 BUGS

Please report any bugs or feature requests directly to C<ngraham@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT license.

=cut

1;  
