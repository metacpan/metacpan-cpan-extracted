package POE::Component::IRC::Plugin::Blowfish;

use strict;
use warnings;
use POE;
use POE::Component::IRC::Plugin qw( :ALL );
use Crypt::Blowfish_PP;
use Carp qw/croak/;
use vars qw($VERSION);

$VERSION = '0.01';

use constant B64 =>
  './0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

use constant states => qw/set_blowfish_key del_blowfish_key/;

sub new {
    my $package = shift;
    croak "Plugin requires an even number of parameters" if @_ % 2;

    my $self = { targets => {@_} };
    bless $self, $package;

    foreach my $chan ( keys %{ $self->{targets} } ) {
        $self->_set_key( $chan, $self->{targets}->{$chan} );
    }

    return $self;
}

sub PCI_register {
    my ( $self, $irc ) = splice @_, 0, 2;

    $irc->plugin_register( $self, 'SERVER', qw(public 001) );
    $irc->plugin_register( $self, 'USER',   qw(privmsg) );

    $self->{session_id} =
      POE::Session->create( object_states =>
          [ $self => [ qw/_shutdown _start/, map { "_$_" } states ], ], )->ID;

    $poe_kernel->state( $_ => $self ) for states;

    return 1;
}

sub PCI_unregister {
    my ( $self, $irc ) = splice @_, 0, 2;

    $poe_kernel->state($_) for states;
    $poe_kernel->call( $self->{session_id} => '_shutdown' );
    return 1;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{session_id} = $_[SESSION]->ID();
    $kernel->refcount_increment( $self->{session_id}, __PACKAGE__ );
}

sub _shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $kernel->alarm_remove_all();
    $kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ );
}

sub set_blowfish_key {
    my ( $kernel, $self, $sender ) = @_[ KERNEL, OBJECT, SENDER ];
    $kernel->post( $self->{session_id}, '_set_blowfish_key', $sender,
        @_[ ARG0 .. $#_ ] );
}

sub del_blowfish_key {
    my ( $kernel, $self, $sender ) = @_[ KERNEL, OBJECT, SENDER ];
    $kernel->post( $self->{session_id}, '_del_blowfish_key', $sender,
        @_[ ARG0 .. $#_ ] );
}

sub _set_blowfish_key {
    my ( $kernel, $self, $sender, $chan, $key ) =
      @_[ KERNEL, OBJECT, ARG0 .. ARG2 ];
    my $old_key;
    $old_key = $self->{targets}->{$chan}->[1]
      if defined $self->{targets}->{$chan};
    $self->_set_key( $chan, $key );
}

sub _del_blowfish_key {
    my ( $kernel, $self, $sender, $chan ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
        delete $self->{targets}->{$chan} if defined $self->{targets}->{$chan};
}

sub S_001 {
    my ( $self, $irc ) = splice @_, 0, 2;

    # get this plugin to the pole position
    $irc->pipeline->bump_up($self) while $irc->pipeline->get_index($self) > 0;

    return PCI_EAT_NONE;
}

sub U_privmsg {
    my ( $self, $irc ) = splice @_, 0, 2;

    my $line = ${ $_[0] };
    my ( $target, $msg ) = $line =~ /PRIVMSG (.*?) :(.*?)$/;

    return PCI_EAT_NONE unless defined $self->{targets}->{$target};

    $msg = sprintf '+OK %s',
      $self->_encrypt( $msg, $self->{targets}->{$target}->[0] );

    ${ $_[0] } = sprintf 'PRIVMSG %s :%s', $target, $msg;

    return PCI_EAT_NONE;
}

sub S_public {
    my ( $self, $irc ) = splice @_, 0, 2;

    my ($nick)   = ( split /!/, ${ $_[0] } )[0];
    my ($target) = ${ $_[1] }->[0];
    my ($msg)    = ${ $_[2] };

    if ( defined $self->{targets}->{$target} ) {
        if ($msg =~ s/^\+OK //) {
            $msg = $self->_decrypt( $msg, $self->{targets}->{$target}->[0] );
            $msg =~ s/\0//g;
            ${ $_[2] } = $msg;
        }
    }

    return PCI_EAT_NONE;
}

sub _encrypt {
    my ( $self, $text, $key ) = @_;

    $text =~ s/(.{8})/$1\n/g;
    my $result = '';
    my $cipher = new Crypt::Blowfish_PP $key;
    foreach ( split /\n/, $text ) {
        $result .= $self->_inflate( $cipher->encrypt($_) );
    }

    return $result;
}

sub _decrypt {
    my ( $self, $text, $key ) = @_;

    $text =~ s/(.{12})/$1\n/g;
    my $result = '';
    my $cipher = new Crypt::Blowfish_PP $key;
    foreach ( split /\n/, $text ) {
        $result .= $cipher->decrypt( $self->_deflate($_) );
    }

    return $result;
}

sub _set_key {
    my ( $self, $chan, $key ) = @_;

    $self->{targets}->{$chan} = [ $key, $key ];

    my $l = length($key);

    if ( $l < 8 ) {
        my $longkey = '';
        my $i       = 8 / $l;
        $i = $1 + 1 if $i =~ /(\d+)\.\d+/;
        while ( $i > 0 ) {
            $longkey .= $key;
            $i--;
        }
        $self->{targets}->{$chan} = [ $longkey, $key ];
    }
}

sub _inflate {
    my ( $self, $text ) = @_;
    my $result = '';
    my $k      = -1;

    while ( $k < ( length($text) - 1 ) ) {
        my ( $l, $r ) = ( 0, 0 );
        for ( $l, $r ) {
            foreach my $i ( 24, 16, 8 ) {
                $_ += ord( substr( $text, ++$k, 1 ) ) << $i;
            }
            $_ += ord( substr( $text, ++$k, 1 ) );
        }
        for ( $r, $l ) {
            foreach my $i ( 0 .. 5 ) {
                $result .= substr( B64, $_ & 0x3F, 1 );
                $_ = $_ >> 6;
            }
        }
    }
    return $result;
}

sub _deflate {
    my ( $self, $text ) = @_;
    my $result = '';
    my $k      = -1;

    while ( $k < ( length($text) - 1 ) ) {
        my ( $l, $r ) = ( 0, 0 );
        for ( $r, $l ) {
            foreach my $i ( 0 .. 5 ) {
                $_ |= index( B64, substr( $text, ++$k, 1 ) ) << ( $i * 6 );
            }
        }
        for ( $l, $r ) {
            foreach my $i ( 0 .. 3 ) {
                $result .=
                  chr( ( $_ & ( 0xFF << ( ( 3 - $i ) * 8 ) ) )
                    >> ( ( 3 - $i ) * 8 ) );
            }
        }
    }

    return $result;
}

1;
__END__

=head1 NAME

POE::Component::IRC::Plugin::Blowfish - A POE::Component::IRC plugin that provides blowfish encryption.

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;
    use POE qw(Component::IRC Component::IRC::Plugin::Blowfish);

    my $nickname  = 'BlowFish' . $$;
    my $ircname   = 'Blowing fish';
    my $ircserver = 'irc.perl.org';
    my $port      = 6667;
    my $channel   = '#POE-Component-IRC-Plugin-Blowfish';
    my $bfkey     = 'secret';

    my $irc = POE::Component::IRC->spawn(
        nick         => $nickname,
        server       => $ircserver,
        port         => $port,
        ircname      => $ircname,
        debug        => 0,
        plugin_debug => 1,
        options      => { trace => 0 },
    ) or die "Oh noooo! $!";

    POE::Session->create(
        package_states => [ 'main' => [qw(_start irc_public irc_001 irc_join)], ],
    );

    $poe_kernel->run();
    exit 0;

    sub _start {

        # Create and load our plugin
        $irc->plugin_add( 'BlowFish' =>
              POE::Component::IRC::Plugin::Blowfish->new( $channel => $bfkey ) );

        $irc->yield( register => 'all' );
        $irc->yield( connect  => {} );
        undef;
    }

    sub irc_001 {
        $irc->yield( join => $channel );
        undef;
    }

    sub irc_join {
        my ( $kernel, $sender, $channel ) = @_[ KERNEL, SENDER, ARG1 ];
        $kernel->post(
            $irc => privmsg => $channel => 'hello this is an encrypted message' );
        undef;
    }

    sub irc_public {
        my ( $kernel, $sender, $who, $where, $msg ) =
          @_[ KERNEL, SENDER, ARG0, ARG1, ARG2 ];
        my $nick = ( split /!/, $who )[0];
        my $chan = $where->[0];

        my @args = split /\s+/, $msg;
        my $cmd = shift @args;

        if ( $cmd eq '!setkey' ) {
            $kernel->yield( set_blowfish_key => (@args)[ 0, 1 ] );
        }

        elsif ( $cmd eq '!delkey' ) {
            $kernel->yield( del_blowfish_key => $args[0] );
        }

        elsif ( $cmd eq '!test' ) {
            $kernel->post(
                $irc => privmsg => $chan => 'this is a test message...' );
        }
    }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::Blowfish, is a L<POE::Component::IRC|POE::Component::IRC> plugin that provides
a mechanism for encrypting and decrypting IRC messages using L<Crypt::Blowfish_PP|Crypt::Blowfish_PP>. If there is a
blowfish key set for a IRC channel this plugin will always encrypt and decrypt IRC messages of that
channel. After the plugin has registered it will push itself to the first position in the plugin
pipeline. This is necessary that all other plugins will get the decrypted IRC messages.

This plugin is compatible to blowfish irssi plugin: L<http://fish.sekure.us/irssi/>

=head1 CONSTRUCTOR

=over 

=item new

Creates a new plugin object. Takes a hash to set blowfish keys for channels:

    '#perl' => 'secret',
    '#poe' => 'foo',
    
It's possible to change this later using L<"INPUT EVENTS">.

=back

=head1 INPUT EVENTS

The plugin registers the following state handler within your session:

=head2 set_blowfish_key

Parameters: $channel $blowfish_key

Set blowfish key for a channel. If there was a key set already it will be overwritten.

=head2 del_blowfish_key

Remove blowfish key from a channel.

Parameters: $channel

=head1 AUTHOR

Johannes 'plu' Plunien E<lt>L<plu@cpan.org|mailto:plu@cpan.org>E<gt>

=head1 SEE ALSO

L<POE::Component::IRC|POE::Component::IRC>

L<Crypt::Blowfish_PP|Crypt::Blowfish_PP>
