# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::UrlObj - URL Klasse

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen URL. Auf dessen Bestandteilen
kann mit den Objektmethoden der Klasse operiert werden. Ferner enthält
die Klasse allgemeine Methoden im Zusammenhang mit URLs, die als
Klassenmethoden implementiert sind.

=cut

# -----------------------------------------------------------------------------

package Quiq::UrlObj;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Url;
use Quiq::Hash::Ordered;
use Scalar::Util ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $urlObj = $class->new;
  $urlObj = $class->new($url);
  $urlObj = $class->new(@keyVal);

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $url -or- @keyVal

    my ($schema,$user,$password,$host,$port,$path,$fragment) = ('') x 8;
    if (@_ == 1) {
        # $url

        my $url = shift;
        ($schema,$user,$password,$host,$port,$path,my $query,$fragment) =
            Quiq::Url->split($url);
        @_ = map {Quiq::Url->decode($_)}
            Quiq::Url->queryDecode($query);
    }

    my $self = $class->SUPER::new(
        schema => $schema,
        user => $user,
        password => $password,
        host => $host,
        port => $port,
        path => $path,
        queryH => Quiq::Hash::Ordered->new,
        fragment => $fragment,
    );
    $self->setQuery(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 queryString() - liefere Querystring des URL-Objekts

=head4 Synopsis

  $query = $urlObj->queryString;

=head4 Returns

(String) Querystring

=head4 Description

Erzeuge den Querystring des URL-Objekts und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub queryString {
    my $self = shift;

    my $queryH = $self->queryH;

    my @keyVal;
    for my $key ($queryH->keys) {
        my $arr = $queryH->get($key);
        for my $val (@$arr) {
            push @keyVal,$key=>$val;
        }
    }

    return Quiq::Url->queryEncode(@keyVal);
}

# -----------------------------------------------------------------------------

=head3 setQuery() - Setze Querystring-Parameter des URL-Objekts

=head4 Synopsis

  $urlObj = $urlObj->setQuery(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Liste von Schlüssel-Wert-Paaren

=back

=head4 Returns

(Object) Das URl-Objekt (für Methodenverkettung)

=head4 Description

Setze die angegebenen Querystring-Parameter auf den jeweils angegebenen
Wert. Existiert ein Parameter bereits, wird sein Wert überschrieben.
Tritt derselbe Parameter mehrfach auf, werden die einzelnen Werte zu
einem Array zusammengefasst. Ist der Wert eine Arrayreferenz, werden
alle Werte des Arrays dem Parameter hinzugefügt.

=cut

# -----------------------------------------------------------------------------

sub setQuery {
    my $self = shift;
    # @_ @keyVal

    my $queryH = $self->queryH;

    my %seen;
    while (@_) {
        my $key = shift;
        my $val = shift;

        if (!defined $val) {
            # undef -> lösche Parameter
            delete $seen{$key};
            $queryH->delete($key);
            next;
        }
        elsif (!$seen{$key}++) {
            # neuen Parameter hinzufügen
            $queryH->set($key=>[]);
        }

        # Wert(e) zur Liste der Parameterwerte hinzufügen

        my $arr = $queryH->get($key);
        my $type = Scalar::Util::reftype($val) // '';
        push @$arr,$type eq 'ARRAY'? @$val: $val;
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head3 url() - URL als Zeichenkette

=head4 Synopsis

  $url = $urlObj->url;

=head4 Returns

(String) URL als Zeichenkette

=head4 Description

Erzeuge eine externe Repräsentation des URL-Objekts und liefere
diese zurück.

=cut

# -----------------------------------------------------------------------------

sub url {
    my $self = shift;

    my $schema = $self->schema;
    my $user = $self->user;
    my $password = $self->password;
    my $host = $self->host;
    my $port = $self->port;
    my $path = $self->path;
    my $query = $self->queryString;
    my $fragment = $self->fragment;
    
    my $url = $schema;
    $url .= '://' if $url;
    $url .= $user;
    $url .= ":$password" if $password;
    if ($user && $host) {
        $url .= '@';
    }
    $url .= $host;
    $url .= ":$port" if $port;
    $url .= $path;
    $url .= "?$query" if $query;
    $url .= "#$fragment" if $fragment;

    return $url;
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
