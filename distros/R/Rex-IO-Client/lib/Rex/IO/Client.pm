#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::IO::Client - Client Library for Rex::IO::Server

=head1 GETTING HELP

=over 4

=item * IRC: irc.freenode.net #rex

=item * Bug Tracker: L<https://github.com/krimdomu/rex-io-client/issues>

=back

=head1 SYNOPSIS

 my $cl = Rex::IO::Client->create(
   protocol => 1,
   endpoint => "http://"
     . $user . ":"
     . $password . '@'
     . $server_url
 );
   
 my $ret = $cl->call("GET", "1.0", "user", user => undef)->{data};
  
 my $ret = $cl->call(
   "POST", "1.0", "user",
   user => undef,
   ref  => $self->req->json->{data},
 );
  
 my $ret = $cl->call( "DELETE", "1.0", "user", user => $self->param("user_id") );

=head1 METHODS

=over 4

=item get_plugins()

List all known server plugins.

=item call($verb, $version, $plugin, @param)

Creates a backend request.

=back

=cut

package Rex::IO::Client;

use strict;
use warnings;
use Data::Dumper;

our $VERSION = '0.6'; # VERSION

sub create {

    my ( $class, %option ) = @_;

    my $version = $option{protocol} || 1;

    my $klass = "Rex::IO::Client::Protocol::V$version";
    eval "use $klass";

    if ($@) {
        die("Protocol Version $version not found. $@");
    }

    return $klass->new(%option);
}

1;
