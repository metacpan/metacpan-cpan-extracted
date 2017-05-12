package Net::YahooMessenger::HTTPS;
use strict;
use warnings;
use WWW::Mechanize;
use MD5;
use URI::Escape;

use constant YMSG_LOGIN_URL =>
'https://login.yahoo.com/config/pwtoken_get?src=ymsgr&ts=&login=%s&passwd=%s&chal=%s';
use constant YMSG_TOKEN_URL =>
  'https://login.yahoo.com/config/pwtoken_login?src=ymsgr&ts=&token=';

sub new {
    my ( $class, $id, $password, $seed ) = @_;
    my $self = bless { _SEED_ => $seed }, $class;
    $self->_https_login( $id, $password, $seed );
    return $self;
}

sub _https_login {
    my ( $self, $username, $password, $seed ) = @_;
    my $mech = WWW::Mechanize->new( agent => 'Mozilla/5.0', noproxy => 1 );

    my $url =
      sprintf( YMSG_LOGIN_URL, $username, $password, uri_escape($seed) );

    $mech->get($url);
    my @lines = split( "\r\n", $mech->content() );
    chomp(@lines);

    my ( undef, $token ) = split( '=', $lines[1] );
    chomp($token);

    $url = YMSG_TOKEN_URL . $token;

    $mech->get($url);

    @lines = split( "\r\n", $mech->content() );
    chomp(@lines);

    $self->{_CRUMB_} = $lines[1];
    $self->{_Y_}     = $lines[2];
    $self->{_T_}     = $lines[3];
    $self->{_CRUMB_} =~ s/crumb=//g;
    $self->{_Y_}     =~ s/Y=//g;
    $self->{_T_}     =~ s/T=//g;

    return $self;
}

sub y_string {
    return shift->{_Y_};
}

sub t_string {
    return shift->{_T_};
}

sub crumb {
    return shift->{_CRUMB_};
}

sub md5_string {
    my $self = shift;
    return $self->ym_hash( MD5->hash("$self->{_CRUMB_}$self->{_SEED_}") );
}

sub ym_hash {
    my ( $self, $in ) = @_;
    my @base64digits = split( '',
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
          . "abcdefghijklmnopqrstuvwxyz"
          . "0123456789._" );
    my @in     = split( '', $in );
    my $out    = '';
    my $length = 16;
    for ( ; $length >= 3 ; $length -= 3 ) {
        $out .= $base64digits[ ord( $in[0] ) >> 2 ];
        $out .=
          $base64digits[ ( ( ord( $in[0] ) << 4 ) & 0x30 ) |
          ( ord( $in[1] ) >> 4 ) ];
        $out .=
          $base64digits[ ( ( ord( $in[1] ) << 2 ) & 0x3c ) |
          ( ord( $in[2] ) >> 6 ) ];
        $out .= $base64digits[ ord( $in[2] ) & 0x3f ];
        shift(@in);
        shift(@in);
        shift(@in);
    }
    if ( $length > 0 ) {
        $out .= $base64digits[ ord( $in[0] ) >> 2 ];
        my $fragment = ( ord( $in[0] ) << 4 ) & 0x30;
        if ( $length > 1 ) {
            $fragment |= ord( $in[1] ) >> 4;
        }
        $out .= $base64digits[$fragment];
        $out .=
          ( $length < 2 )
          ? '-'
          : $base64digits[ ( ord( $in[1] ) << 2 ) & 0x3c ];
        $out .= '-';

    }
    return $out;
}

1;
