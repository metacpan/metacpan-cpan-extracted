package Net::RRP;

=head1 NAME

Net::RRP - there are file for RRP protocol and operations.

=head1 SYNOPSIS

 use IO::Socket::SSL;

 use Net::RRP::Protocol;
 use Net::RRP::Request::Add;
 use Net::RRP::Entity::Domain;

 my $socket = new IO::Socket::SSL ( ... );
 my $protocol = new Net::RRP::Protocol ( socket => $socket );

 $protocol->getHello();

 my $entity   = new Net::RRP::Entity::Domain();
 $entity->setAttribute ( 'DomainName' => 'test.ru' );
 $entity->setAttribute ( 'NameServer' => [ 'ns1.test.ru', 'ns2.test.ru' ] );

 my $request  = new Net::RRP::Request::Add();
 $request->setEntity ( $entity );
 $request->setOption ( Period => 10 );

 $protocol->sendRequest ( $request );
 my $response = $protocol->getResponse ();

 die unless $request->isSuccessResponse ( $response );

=head1 DESCRIPTION

Net::RRP - there are file for RRP protocol and operations.

=cut

$Net::RRP::VERSION = '0.02';

=head1 AUTHOR AND COPYRIGHT

 Net::RRP (C) Zenon N.S.P., Michael Kulakov, 2000
              125124, 19, 1-st Jamskogo polja st,
              Moscow, Russian Federation

              mkul@cpan.org

 All rights reserved.

 You may distribute this package under the terms of either the GNU
 General Public License or the Artistic License, as specified in the
 Perl README file.

=head1 SEE ALSO

RFC 2832,
L<Net::RRP::Codec(3)>,
L<Net::RRP::Protocol(3)>,
L<Net::RRP::Request(3)>,
L<Net::RRP::Entity(3)>,
L<Net::RRP::Response(3)>,
L<Net::RRP::Toolkit(3)>,
L<Net::RRP::Entity::Domain(3)>,
L<Net::RRP::Entity::NameServer(3)>,
L<Net::RRP::Request::Add(3)>,
L<Net::RRP::Request::Check(3)>,
L<Net::RRP::Request::Del(3)>,
L<Net::RRP::Request::Describe(3)>,
L<Net::RRP::Request::Mod(3)>,
L<Net::RRP::Request::Quit(3)>,
L<Net::RRP::Request::Session(3)>,
L<Net::RRP::Request::Status(3)>,
L<Net::RRP::Request::Transfer(3)>,
L<Net::RRP::Request::Renew(3)>,
L<Net::RRP::Response::n200(3)>,
L<Net::RRP::Response::n210(3)>,
L<Net::RRP::Response::n211(3)>,
L<Net::RRP::Response::n212(3)>,
L<Net::RRP::Response::n213(3)>,
L<Net::RRP::Response::n220(3)>,
L<Net::RRP::Response::n420(3)>,
L<Net::RRP::Response::n421(3)>,
L<Net::RRP::Response::n500(3)>,
L<Net::RRP::Response::n501(3)>,
L<Net::RRP::Response::n502(3)>,
L<Net::RRP::Response::n503(3)>,
L<Net::RRP::Response::n504(3)>,
L<Net::RRP::Response::n505(3)>,
L<Net::RRP::Response::n506(3)>,
L<Net::RRP::Response::n507(3)>,
L<Net::RRP::Response::n508(3)>,
L<Net::RRP::Response::n509(3)>,
L<Net::RRP::Response::n520(3)>,
L<Net::RRP::Response::n521(3)>,
L<Net::RRP::Response::n530(3)>,
L<Net::RRP::Response::n531(3)>,
L<Net::RRP::Response::n532(3)>,
L<Net::RRP::Response::n533(3)>,
L<Net::RRP::Response::n534(3)>,
L<Net::RRP::Response::n535(3)>,
L<Net::RRP::Response::n536(3)>,
L<Net::RRP::Response::n540(3)>,
L<Net::RRP::Response::n541(3)>,
L<Net::RRP::Response::n542(3)>,
L<Net::RRP::Response::n543(3)>,
L<Net::RRP::Response::n544(3)>,
L<Net::RRP::Response::n545(3)>,
L<Net::RRP::Response::n546(3)>,
L<Net::RRP::Response::n547(3)>,
L<Net::RRP::Response::n548(3)>,
L<Net::RRP::Response::n549(3)>,
L<Net::RRP::Response::n550(3)>,
L<Net::RRP::Response::n551(3)>,
L<Net::RRP::Response::n552(3)>,
L<Net::RRP::Response::n553(3)>,
L<Net::RRP::Response::n554(3)>,
L<Net::RRP::Response::n555(3)>,
L<Net::RRP::Response::n556(3)>

=cut

1;

__END__
