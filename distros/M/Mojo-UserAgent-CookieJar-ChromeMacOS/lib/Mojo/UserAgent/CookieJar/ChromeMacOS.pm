package Mojo::UserAgent::CookieJar::ChromeMacOS;

use strict;
use warnings;
use v5.10;
our $VERSION = '0.04';

use Mojo::Base 'Mojo::UserAgent::CookieJar';

use Mojo::Cookie::Request;
use DBI;
use File::Temp qw/tempfile/;
use File::Copy ();
use PBKDF2::Tiny qw/derive/;
use Crypt::Rijndael;

# default Chrome cookie file for MacOSx
has 'file' => sub {
    if ($^O eq 'linux') {
        return $ENV{HOME} . "/.config/google-chrome/Default/Cookies";
    }
    return $ENV{HOME} . "/Library/Application Support/Google/Chrome/Default/Cookies";
};
has 'pass'; # for Linux

# readonly
sub add {}
sub collect {}

sub find {
    my ($self, $url) = @_;

    return [] unless my $domain = my $host = $url->ihost;

    my $cipher = $self->_make_cipher;

    my @found;
    my $dbh = $self->__get_dbh;

    my $path = $url->path->to_abs_string;
    while ($domain) {
        next if $domain eq 'com'; # skip bad
        my $new = $self->{jar}{$domain} = [];

        my $sth = $dbh->prepare('SELECT * FROM cookies WHERE host_key = ? OR host_key = ?');
        $sth->execute($domain, '.' . $domain);
        while (my $row = $sth->fetchrow_hashref) {
            my $value = $row->{value} || '';
            my $encrypted = $row->{encrypted_value} || '';
            if ( $encrypted =~ /^(v10|v11)/ ) {
                $value = $self->_decrypt( $encrypted, $row->{host_key} );
            }

            my $cookie = Mojo::Cookie::Request->new(
                name     => $row->{name},
                value   => $value,
                httponly => $row->{is_httponly} ? 1 : 0,
            );
            push @$new, $cookie;

            # Taste cookie (no care about expires since Chrome will handle it)
            next if $row->{is_secure} && $url->protocol ne 'https';
            next unless _path($row->{path}, $path);

            push @found, $cookie;
        }
    }
    # Remove another part
    continue { $domain =~ s/^[^.]*\.*// }

    return \@found;
}

sub prepare {
    my ($self, $tx) = @_;
    my $req = $tx->req;
    $req->cookies(@{$self->find($req->url)});
}

sub _make_cipher {
    my ($self) = @_;

    state $cipher;
    return $cipher if $cipher;

    my $salt = 'saltysalt';
    my $salt_len = 16;
    my $pass = $self->_get_pass();
    my $iterations = 1003;
    $iterations = 1 if $^O eq 'linux'; # Linux
    my $key = derive( 'SHA-1', $pass, $salt, $iterations, $salt_len );

    $cipher = Crypt::Rijndael->new( $key, Crypt::Rijndael::MODE_CBC() );
    $cipher->set_iv( ' ' x 16 );
    return $cipher;
}

sub _decrypt {
    my( $self, $blob, $host_key ) = @_;

    my $cipher = $self->_make_cipher;

    my $type = substr $blob, 0, 3, '';

    unless( $type eq 'v10' || $type eq 'v11' ) {
        warn "Encrypted value is unexpected type <$type>\n";
        return '';
    }

    my $plaintext = $cipher->decrypt( $blob );

    # DB version 24+ prepends SHA256 of domain to plaintext
    if( $self->_db_version >= 24 ) {
        substr $plaintext, 0, 32, '';
    }

    # Remove PKCS7 padding
    my $padding_count = ord( substr $plaintext, -1 );
    if( $padding_count <= 16 && $padding_count > 0 ) {
        substr( $plaintext, -$padding_count ) = '';
    }

    return $plaintext;
}

sub _db_version {
    my( $self ) = @_;

    state $version;
    return $version if defined $version;

    my $dbh = $self->__get_dbh;

    my $has_meta = eval {
        my $sql = q(SELECT 1 FROM sqlite_master WHERE type='table' AND name='meta');
        my $array = $dbh->selectall_arrayref( $sql );
        @$array > 0;
    };
    if( $@ ) { warn $@ }

    return ($version = 0) unless $has_meta;

    $version = eval {
        my $sql = q(SELECT * FROM meta WHERE key = 'version');
        my $rv = $dbh->selectall_arrayref( $sql );
        @$rv ? $rv->[0][1] : 0;
    } // 0;
    if( $@ ) { warn $@ }

    return $version;
}

sub __get_dbh {
    my ($self) = @_;

    state $dbh;
    return $dbh if $dbh && $dbh->ping;

    # copy to read
    my ($fh, $filename) = tempfile();
    close $fh;
    File::Copy::copy($self->file, $filename);
    my $sqlite_file = -e $filename ? $filename : $self->file; # make sure copy works
    # warn "READ $sqlite_file\n";

    $dbh = DBI->connect( "dbi:SQLite:dbname=" . $sqlite_file, '', '', {
      sqlite_see_if_its_a_number => 1,
    } );

    return $dbh;
}

sub _get_pass {
    my ($self) = @_;

    return $self->pass if $self->pass; # for Linux which passed in ->new

    my $pass;
    if ($^O eq 'linux') {
        # # secret-tool search application chrome
        # [/org/freedesktop/secrets/collection/Default_5fkeyring/1]
        # label = Chrome Safe Storage
        # secret = 5B9eGeijTg1xQTh+K70Czg==
        # created = 2022-02-18 02:23:25
        # modified = 2022-02-18 02:23:25
        # schema = chrome_libsecret_os_crypt_password_v2
        # attribute.application = chrome
        my $text = `secret-tool search application chrome`;
        ($pass) = ($text =~ /secret\s*\=\s*(\S+)/m);
    } else {
        $pass = `security find-generic-password -w -s "Chrome Safe Storage"`;
        chomp( $pass );
    }

    $self->pass($pass);
    return $pass;
}

# copied from Mojo::UserAgent::CookieJar
sub _path { $_[0] eq '/' || $_[0] eq $_[1] || index($_[1], "$_[0]/") == 0 }

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::UserAgent::CookieJar::ChromeMacOS - readonly Chrome(MacOSx) cookies for Mojo::UserAgent

=head1 SYNOPSIS

    use Mojo::UserAgent;
    use Mojo::UserAgent::CookieJar::ChromeMacOS;

    my $ua = Mojo::UserAgent->new;
    $ua->cookie_jar(Mojo::UserAgent::CookieJar::ChromeMacOS->new);

    # For Linux
    Mojo::UserAgent::CookieJar::ChromeMacOS->new(
        file => '~/.config/google-chrome/Default/Cookies',
        pass => 'peanuts', # hardcode for Linux
    );

=head1 DESCRIPTION

Mojo::UserAgent::CookieJar::ChromeMacOS tries to read the cookie from Chrome on MacOSx.

it would be useful when you need handle tricky logins or captchas.

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Cookies::ChromeMacOS>

=cut
