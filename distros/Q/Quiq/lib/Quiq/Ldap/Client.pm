# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Ldap::Client - LDAP Client

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen LDAP-Client. Die Klasse
stellt eine Überdeckung der Klasse Net::LDAP dar, mit dem Vorteil,
dass keine Fehlerbehandlung nötig ist, sondern im Fehlerfall
eine Exception geworfen wird.

LDAP Test Zeppelin: /usr/local/bin/test_ldap_zeppelin.sh

Homepage: L<Net::LDAP|http://ldap.perl.org/>

=head1 EXAMPLE

  # The following example shows how to use the Class
  # to query the RootDSE of Acctive Directory
  
  my $ldap = Quiq::Ldap::Client->new('dc1');
  my $res = $ldap->search(
      base => '',
      filter => '(objectclass=*)',
      scope  => 'base',
  );
  for my $ent ($res->entries) {
      for my $key (sort $ent->attributes) {
          print "$key:";
          for my $val ($ent->get($key)) {
              print " $val";
          }
          print "\n";
      }
  }

=cut

# -----------------------------------------------------------------------------

package Quiq::Ldap::Client;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Net::LDAP ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $ldap = $class->new($uri,%options);

=head4 Arguments

=over 4

=item $uri

URI des LDAP-Servers. Siehe Net::LDAP.

=item %options

Optionen als Schlüssel/Wert-Paare. Siehe Net::LDAP.

=back

=head4 Returns

Object

=head4 Description

Instantiiere eine Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=head4 Example

=over 2

=item *

LDAP

  $ldap = Quiq::Ldap::Client->new(
      'ldap://dc1',
      debug => 12,
  );

=item *

LDAPS

  $ldap = Quiq::Ldap::Client->new(
      'ldaps://dc1',
      verify => 'none',
      debug => 12,
  );

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$uri) = splice @_,0,2;
    # @_: %options

    my $ldap = Net::LDAP->new($uri,
        onerror => sub {
            my $self = shift;
            $class->throw(
                'LDAP-00099: Request failed',
                Object => $self,
                Code => $self->code,
                Error => $self->error,
            );
        },
        @_,
    );
    if (!$ldap) {
        $class->throw(
            'LDAP-00099: Instantiation failed',
            Error => $@,
        );
    }

    return $class->SUPER::new(
        ldap => $ldap,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 bind() - Login auf LDAP-Server

=head4 Synopsis

  $ldap->bind;               # anonymous
  $ldap->bind($dn,%options);

=head4 Arguments

=over 4

=item $dn

DN, mit der gebunden wird.

=item %options

Optionen als Schlüssel/Wert-Paare. Siehe Net::LDAP.

=back

=head4 Description

Logge User auf LDAP-Server ein.

=cut

# -----------------------------------------------------------------------------

sub bind {
    my $self = shift;
    # $dn,%options
    return $self->ldap->bind(@_);
}

# -----------------------------------------------------------------------------

=head3 search() - Durchsuche Server

=head4 Synopsis

  $ldap->search(%options);

=head4 Arguments

=over 4

=item %options

Optionen als Schlüssel/Wert-Paare. Siehe Net::LDAP.

=back

=head4 Description

Durchsuche den LDAP-Server durch Anwendung eines Filters.

=cut

# -----------------------------------------------------------------------------

sub search {
    my $self = shift;
    # @_: %options
    return $self->ldap->search(@_);
}

# -----------------------------------------------------------------------------

=head3 startTls() - Wandele Verbindung nach TLS

=head4 Synopsis

  $ldap->startTls(%options);

=head4 Arguments

=over 4

=item %options

Optionen als Schlüssel/Wert-Paare. Siehe Net::LDAP.

=back

=head4 Description

Wandele Verbindung nach TLS

=cut

# -----------------------------------------------------------------------------

sub startTls {
    my $self = shift;
    # @_: %options
    return $self->ldap->start_tls(@_);
}

# -----------------------------------------------------------------------------

=head3 unbind() - Trenne Verbindung

=head4 Synopsis

  $ldap->unbind;

=head4 Description

Trenne die Verbindung zum LDAP-Server.

=cut

# -----------------------------------------------------------------------------

sub unbind {
    my $self = shift;
    return $self->ldap->unbind;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
