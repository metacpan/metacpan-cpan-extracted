package Mojo::UserAgent::CookieJar::ChromeMacOS;

use strict;
use warnings;
use v5.10;
our $VERSION = '0.01';

use Mojo::Base 'Mojo::UserAgent::CookieJar';

use Mojo::Cookie::Request;
use DBI;
use PBKDF2::Tiny qw/derive/;
use Crypt::CBC;

# default Chrome cookie file for MacOSx
has 'file' => sub {
    return $ENV{HOME} . "/Library/Application Support/Google/Chrome/Default/Cookies";
};

# readonly
sub add {}
sub collect {}

sub find {
    my ($self, $url) = @_;

    return [] unless my $domain = my $host = $url->ihost;

    my $salt = 'saltysalt';
    my $iv = ' ' x 16;
    my $salt_len = 16;
    my $pass = __get_pass();
    my $iterations = 1003;
    my $key = derive( 'SHA-1', $pass, $salt, $iterations, $salt_len );
    my $cipher = Crypt::CBC->new(
        -cipher => 'Crypt::OpenSSL::AES',
        -key    => $key,
        -keysize => 16,
        -iv => $iv,
        -header => 'none',
        -literal_key => 1,
    );

    my @found;
    my $dbh = $self->__get_dbh;

    my $path = $url->path->to_abs_string;
    while ($domain) {
        next if $domain eq 'com'; # skip bad
        my $new = $self->{jar}{$domain} = [];

        my $sth = $dbh->prepare('SELECT * FROM cookies WHERE host_key = ? OR host_key = ?');
        $sth->execute($domain, '.' . $domain);
        while (my $row = $sth->fetchrow_hashref) {
            my $value = $row->{value} || $row->{encrypted_value} || '';
            if ( $value =~ /^v10/ ) {
                $value =~ s/^v10//;
                $value = $cipher->decrypt( $value );
            }

            my $cookie = Mojo::Cookie::Request->new(name => $row->{name}, value => $value);
            push @$new, $cookie;

            # Taste cookie (no care about expires since Chrome will handle it)
            next if $row->{secure} && $url->protocol ne 'https';
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

sub __get_dbh {
    my ($self) = @_;

    state $dbh;
    return $dbh if $dbh && $dbh->ping;
    $dbh = DBI->connect( "dbi:SQLite:dbname=" . $self->file, '', '', {
      sqlite_see_if_its_a_number => 1,
    } );

    return $dbh;
}

sub __get_pass {
    state $pass;
    return $pass if $pass;
    $pass = `security find-generic-password -w -s "Chrome Safe Storage"`;
    chomp( $pass );
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
