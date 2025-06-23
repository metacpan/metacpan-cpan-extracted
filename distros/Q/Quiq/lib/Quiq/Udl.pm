# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Udl - Universal Database Locator

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Klasse laden:

  use Quiq::Udl;

Objekt instantiieren:

  my $udlStr = 'dbi#oracle:xyz%xyz_admin:koala3@pluto.gaga.de:1521';
  my $udl = Quiq::Udl->new($udlStr);

UDL aus Konfigurationsdatei:

  my $udl = Quiq::Udl->new('test-db');

UDL-Komponenten:

  print $udl->api,"\n";      # dbi
  print $udl->dbms,"\n";     # oracle
  print $udl->db,"\n";       # xyz
  print $udl->user,"\n";     # xyz_admin
  print $udl->password,"\n"; # koala3
  print $udl->host,"\n";     # pluto.gaga.de
  print $udl->port,"\n";     # 1521
  
  my $optionH = $udl->options;
  while (($key,$val) = each %$optionH) {
      print "$key=$val\n";
  }

UDL als String:

  print $udl->asString,"\n"; # $udlStr

=head1 DESCRIPTION

Ein Universal Database Locator (UDL) adressiert eine Datenbank,
wie ein Universal Resource Locator eine Web-Resource adressiert.

Ein UDL hat den Aufbau:

  api#dbms:db%user:password@host:port;options

Ein Objekt der Klasse kapselt einen UDL und bietet Methoden,
um auf die einzelnen Komponenten zuzugreifen. Kommen Metazeichen
im Passwort oder den Options vor, können diese mit \ maskiert werden.

=head1 ATTRIBUTES

=over 4

=item api => $str

Der Name der Schnittstelle (z.B. "dbi").

=item dbms => $str

Der Name der Datenbanksystems (z.B. oracle, postgresql, sqlite, mysql).

=item db => $str

Der Name der Datenbank.

=item user => $str

Der Name des Benutzers.

=item password => $str

Das Passwort des Benutzers.

=item host => $str

Der Name des Hosts, auf dem die Datenbank sich befindet.

=item port = $str

Der Port, über welchen die Netzverbindung aufgebaut wird.

=item options => \%hash

Referenz auf Hash mit optionalen Angaben.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Udl;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use Quiq::Hash;
use Quiq::Database::Config;
use Quiq::Option;
use Quiq::Path;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere UDL-Objekt

=head4 Synopsis

  $udl = $class->new;
  $udl = $class->new($udlStr);
  $udl = $class->new(@keyVal);
  $udl = $class->new($name);

=head4 Arguments

=over 4

=item $udlStr

UDL als Zeichenkette.

=item @keyVal

UDL-Komponenten.

=item $name

Name aus Konfigurationsdatei C<~/.db.conf>.

=back

=head4 Returns

UDL-Objekt

=head4 Description

Instantiiere ein UDL-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $udlStr -or- @keyVal -or- $name

    my $self = $class->SUPER::new(
        api => '',
        dbms => '',
        db => '',
        user => '',
        password => '',
        host => '',
        port => '',
        # FIXME: auf Quiq::Hash::Ordered umstellen
        options => Quiq::Hash->new->unlockKeys,
    );
    if (@_ == 1 && $_[0] !~ /^[a-z]+#/) {
        # Argument ist kein UDL. Wir interpretieren das Argument
        # als Name, suchen diesen in der Konfiguration und
        # nutzen den UDL des Eintrags.

        my $udlStr = Quiq::Database::Config->new->udl(shift);
        $self->udl($udlStr);
    }
    elsif (@_) {
        $self->udl(@_);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 api() - Setze/Liefere Wert des Attributs api

=head4 Synopsis

  $api = $udl->api;
  $api = $udl->api($api);

=cut

# -----------------------------------------------------------------------------

sub api {
    my $self = shift;

    if (@_) {
        $self->{'api'} = defined $_[0]? shift: '';
    }

    return $self->{'api'};
}

# -----------------------------------------------------------------------------

=head3 dbms() - Setze/Liefere Wert des Attributs dbms

=head4 Synopsis

  $dbms = $udl->dbms;
  $dbms = $udl->dbms($dbms);

=cut

# -----------------------------------------------------------------------------

sub dbms {
    my $self = shift;

    if (@_) {
        $self->{'dbms'} = defined $_[0]? shift: '';
    }

    return $self->{'dbms'};
}

# -----------------------------------------------------------------------------

=head3 db() - Setze/Liefere Wert des Attributs db

=head4 Synopsis

  $db = $udl->db;
  $db = $udl->db($db);

=cut

# -----------------------------------------------------------------------------

sub db {
    my $self = shift;

    if (@_) {
        $self->{'db'} = defined $_[0]? shift: '';
    }

    return $self->{'db'};
}

# -----------------------------------------------------------------------------

=head3 user() - Setze/Liefere Wert des Attributs user

=head4 Synopsis

  $user = $udl->user;
  $user = $udl->user($user);

=cut

# -----------------------------------------------------------------------------

sub user {
    my $self = shift;

    if (@_) {
        $self->{'user'} = defined $_[0]? shift: '';
    }

    return $self->{'user'};
}

# -----------------------------------------------------------------------------

=head3 password() - Setze/Liefere Wert des Attributs password

=head4 Synopsis

  $password = $udl->password;
  $password = $udl->password($password);

=cut

# -----------------------------------------------------------------------------

sub password {
    my $self = shift;

    if (@_) {
        $self->{'password'} = defined $_[0]? shift: '';
    }

    return $self->{'password'};
}

# -----------------------------------------------------------------------------

=head3 host() - Setze/Liefere Wert des Attributs host

=head4 Synopsis

  $host = $udl->host;
  $host = $udl->host($host);

=cut

# -----------------------------------------------------------------------------

sub host {
    my $self = shift;

    if (@_) {
        $self->{'host'} = defined $_[0]? shift: '';
    }

    return $self->{'host'};
}

# -----------------------------------------------------------------------------

=head3 port() - Setze/Liefere Wert des Attributs port

=head4 Synopsis

  $port = $udl->port;
  $port = $udl->port($port);

=cut

# -----------------------------------------------------------------------------

sub port {
    my $self = shift;

    if (@_) {
        $self->{'port'} = defined $_[0]? shift: '';
    }

    return $self->{'port'};
}

# -----------------------------------------------------------------------------

=head3 options() - Setze/Liefere Option-Hash

=head4 Synopsis

  $hash = $udl->options;
  $hash = $udl->options($str);
  $hash = $udl->options(@keyVal);
  $hash = $udl->options(\%hash);

=head4 Description

Setze/Liefere Hash mit den UDL-Optionen.

=cut

# -----------------------------------------------------------------------------

sub options {
    my $self = shift;
    # @_: Argument

    my $optH = $self->{'options'};

    if (@_) {
        if (ref $_[0]) { # HashRef
            $optH = $self->{'options'} = shift;
        }
        elsif (@_ > 1) { # KeyVal
            %$optH = @_;
        }
        else {           # String
            %$optH = ();
            for my $pair (split /;/,shift) {
                my ($key,$val) = split /=/,$pair;
                $optH->{$key} = $val;
            }
        }
    }

    return $optH;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 split() - Setze/Liefere UDL als Ganzes

=head4 Synopsis

  ($api,$dbms,$db,$user,$password,$host,$port,$options) =
      $udl->split($udl);

=head4 Description

Zerlege den UDL $udl in seine Komponenten und liefere diese zurück.
Für eine Komponente, die nicht im URL enthalten ist, wird ein
Leerstring ('') geliefert.

=cut

# -----------------------------------------------------------------------------

sub split {
    my ($class,$udl) = @_;
    return $class->new($udl)->components;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 apiClass() - API-Klasse

=head4 Synopsis

  $apiClass = $udl->apiClass;

=head4 Description

Liefere die Datanbank API-Klasse. Über diese findet intern der
Verbindungsaufbau zur Datenbank statt.

Die API-Klasse für das DBI-API ist:

  Quiq::Database::Api::Dbi::Connection

=cut

# -----------------------------------------------------------------------------

sub apiClass {
    my $self = shift;
    return 'Quiq::Database::Api::'.ucfirst($self->api).'::Connection';
}

# -----------------------------------------------------------------------------

=head3 asString() - UDL als String

=head4 Synopsis

  $udlStr = $udl->asString;

=head4 Options

=over 4

=item -secure => $bool (Default: 0)

Ersetze das Passwort durch einen Stern.

=back

=cut

# -----------------------------------------------------------------------------

sub asString {
    my $self = shift;

    # Optionen

    my $secure = 0;
    
    Quiq::Option->extract(\@_,
        -secure => \$secure,
    );

    my $str = '';

    # api

    my $api = $self->api;
    if ($api) {
        $str .= $api.'#';
    }

    # dbms, db

    my $dbms = $self->dbms;
    my $db = $self->db;
    if ($dbms || $db) {
        if ($dbms) {
            $str .= $dbms;
        }
        if ($db) {
            $str .= ":$db";
        }
    }

    # user, password

    my $user = $self->user;
    my $password = $self->password;
    if ($user || $password) {
        $str .= '%';
        if ($user) {
            $str .= $user;
        }
        if ($password) {
            if ($secure) {
                $password = '*';
            }
            $str .= ":$password";
        }
    }

    # host, port

    my $host = $self->host;
    my $port = $self->port;
    if ($host || $port) {
        $str .= '@';
        if ($host) {
            $str .= $host;
        }
        if ($port) {
            $str .= ":$port";
        }
    }

    # options

    my $optionH = $self->options;
    while (my ($key,$val) = each %$optionH) {
        if ($str) {
            $str .= ';';
        }
        $str .= "$key=$val";
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 components() - Komponenten des UDL

=head4 Synopsis

  ($api,$dbms,$db,$user,$password,$host,$port,$options) = $udl->components;

=head4 Description

Liefere die Komponenten des UDL in der oben angegebenen Reihenfolge.

=cut

# -----------------------------------------------------------------------------

sub components {
    my $self = shift;

    return (
        $self->api,
        $self->dbms,
        $self->db,
        $self->user,
        $self->password,
        $self->host,
        $self->port,
        $self->options,
    );
}

# -----------------------------------------------------------------------------

=head3 dsn() - DBI DSN-String

=head4 Synopsis

  $dsn = $udl->dsn;

=head4 Description

Liefere den DSN-String, um per DBI->connect() eine
Verbindung zur Datenbank aufzubauen.

=cut

# -----------------------------------------------------------------------------

sub dsn {
    my $self = shift;

    my ($api,$dbms,$db,$user,$passw,$host,$port,$options) = $self->components;

    if ($api ne 'dbi') {
        $self->throw(
            'UDL-00001: DSN defined for DBI API only',
            API => $api,
        );
    }

    my $dsn;
    if ($dbms eq 'mysql') {
        $dsn = "DBI:mysql:database=$db";
        if ($host) {
            $dsn .= ";host=$host";
        }
        if ($port) {
            $dsn .= ";port=$port";
        }
    }
    elsif ($dbms eq 'oracle') {
        if ($host) {
            # Connect ohne tnsnames.ora, siehe DBD::Oracle,
            # wird konkret benötigt für FINO.
            # FIXME: Wie wird der Port eingestellt?
            $dsn = "DBI:Oracle:host=$host;sid=$db";
        }
        else {
            $dsn = "DBI:Oracle:$db";
        }
    }
    elsif ($dbms eq 'postgresql') {
        $dsn = "DBI:Pg:dbname=$db";
        if ($host) {
            $dsn .= ";host=$host";
        }
        if ($port) {
            $dsn .= ";port=$port";
        }
    }
    elsif ($dbms eq 'sqlite') {
        $db = Quiq::Path->expandTilde($db);
        $dsn = "DBI:SQLite:dbname=$db";
        if ($host) {
            # Wenn Host (und Port) angegeben sind, bauen wir
            # eine Verbindung über den DBIProxy auf (der remote
            # laufen muss)
            $dsn = "DBI:Proxy:hostname=$host;port=$port;dsn=$dsn";
        }
    }
    elsif ($dbms eq 'access') {
        $dsn = "DBI:ODBC:$db";
    }
    elsif ($dbms eq 'mssql') {
        $dsn = "DBI:ODBC:$db";
    }
    elsif ($dbms eq 'jdbc') {
        $dsn = "DBI:JDBC:hostname=$host;port=$port";
        for my $key (keys %$options) {
            $dsn .= ";$key=$options->{$key}";
        }
    }
    else {
        $self->throw(
            'UDL-00002: DBMS not supported',
            Dbms => $dbms,
        );
    }

    return $dsn;    
}

# -----------------------------------------------------------------------------

=head3 udl() - Setze/Liefere UDL als Ganzes

=head4 Synopsis

  $udl->udl($udlStr);
  $udl->udl(@keyVal);
  $udlStr = $udl->udl;

=head4 Description

Liefere UDL oder setze UDL als Ganzes aus String oder Liste von
Schlüssel/Wert-Paaren. Die Methode liefert keinen Wert zurück.

Der Aufruf ohne Parameter ist identisch zum Aufruf von asString().

=cut

# -----------------------------------------------------------------------------

sub udl {
    my $self = shift;

    if (!@_) {
        return $self->asString;
    }

    # UDL neu aufsetzen

    $self->set(api=>'',dbms=>'',db=>'',user=>'',password=>'',host=>'',
        port=>'');
    %{$self->{'options'}} = ();

    if (@_ == 1) { # $udlStr
        my $udl = shift;

        # Zerlege UDL auf den Metazeichen: #%@;
        # Mit \ können die Metazeichen maskiert werden.

        my @arr = split /((?<!\\)[#%@;])/,$udl;
        $self->api(shift @arr);

        my ($dbms,$db,$user,$password,$host,$port,@options);
        while (@arr) {
            my $key = shift @arr;
            my $val = shift @arr;
            $val =~ s|\\([#%@;])|$1|g; # #%@; entmaskieren

            if ($key eq '#') {
                ($dbms,$db) = split /:/,$val,2;
                if (!defined $dbms) {
                    $dbms = '';
                }
            }
            elsif ($key eq '%') {
                ($user,$password) = split /:/,$val,2;
            }
            elsif ($key eq '@') {
                ($host,$port) = split /:/,$val,2;
            }
            else { # ;
                push @options,split /=/,$val,2;
            }
        }

        # Alte Implementierung. Wegen neuer Möglichkeit zur Maskierung
        # der Metazeichen durch \, durch obige Implementierung ersetzt.

        #if ($udl =~ s|^([a-z]+)#||) {
        #    $self->api($1);
        #}
        #if ($udl =~ s|;(.*)||) {
        #    $self->options($1);
        #}
        #if ($udl =~ s|\@([^%]+)||) {
        #    my ($host,$port) = split(/:/,$1,2);
        #    $self->host($host);
        #    $self->port($port);
        #}
        #my ($dbms,$db,$user,$password);
        #if ($udl =~ s|%([^@]+)||) {
        #    ($user,$password) = split(/:/,$1,2);
        #}
        #($dbms,$db) = split(/:/,$udl,2);
        #if (!defined $dbms) {
        #    $dbms = '';
        #}

        # Rückwärtskompatibilität

        if (!grep { $dbms eq $_ } qw/oracle postgresql sqlite mysql
                access mssql jdbc/) {
            ($dbms,$db,$user,$password) = ($user,$password,$dbms,$db);
        }

        $self->user($user);
        $self->password($password);
        $self->dbms($dbms);
        $self->db($db);
        $self->host($host);
        $self->port($port);
        $self->options(@options);
    }
    else { # @keyVal
        while (@_) {
            my $key = shift;
            $self->$key(shift);
        }
    }

    return;
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
