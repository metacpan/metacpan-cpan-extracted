# $Id: Web.pm 37 2008-03-09 01:10:00Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/lib/Teamspeak/Web.pm $

package Teamspeak::Web;

use 5.004;
use strict;
use Carp;
use WWW::Mechanize;
use vars qw( $VERSION );
$VERSION = '0.6';

sub _slogin {
    my ( $self, $login, $password ) = @_;
    my $mech = $self->{mech};
    $mech->follow_link;
    $mech->submit_form(
        fields => { username => $login, password => $password } )
        or return $self->error('slogin');
    $self->{slogin} = $login;
    $self->{err}    = undef;
    $self->{errstr} = undef;
    return 1;
}    # slogin

sub connect {
    my ( $self, %arg ) = @_;
    my $url  = "http://$self->{w_host}:$self->{w_port}/";
    my $mech = WWW::Mechanize->new;
    $mech->get($url) or return $self->error('connect');
    $self->{mech}    = $mech;
    $self->{connect} = 1;
    $self->_login( $arg{login}, $arg{pwd} ) if ( $arg{login} );
    $self->_slogin( $arg{slogin}, $arg{pwd} ) if ( $arg{slogin} );
    return 1;    # Success
}    # connect

sub new {
    my ( $class, %arg ) = @_;
    my $s = {
        w_host => $arg{host} || 'localhost',
        w_port => $arg{port} || 14534,
        connected => 0,
    };
    bless $s, ref($class) || $class;
}    # new

1;

__END__

=head1 NAME

Teamspeak::Web - The HTTP-Interface to administrate Teamspeak-Server.

=head2 connect

=head2 new

=head1 SEE ALSO

C<Teamspeak>

=head1 AUTHOR

Martin von Oertzen (maletin@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2005-2008, Martin von Oertzen. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.
