package Quiq::Http::Client::Lwp;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Option;
use LWP::UserAgent ();
use HTTP::Request ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Http::Client::Lwp - HTTP Operationen

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 get() - Führe GET-Request aus

=head4 Synopsis

    $data = $class->get($url,@opt);

=head4 Options

=over 4

=item -debug => $bool (Default: 1)

Gib Request auf STDOUT aus.

=item -header => $bool (Default: 0)

Ergänze die Antwort um die vom Server gesetzten Response-Header.
Per Default wird nur der Rumpf der HTTP-Antwort geliefert.

=item -redirect => $bool (Default: 1)

Führe Redirection automatisch aus.

=item -sloppy => $bool (Default: 0)

Wirf im Fehlerfall keine Exception, sondern liefere die Fehlerantwort.

=item -timeout => $n (Default: 0)

Timeout.

=back

=head4 Description

Führe HTTP-Request für URL $url aus und liefere die vom
Server gelieferte Antwort zurück.

=cut

# -----------------------------------------------------------------------------

sub get {
    my $class = shift;
    my $url = shift;
    # @_: @opt

    my $debug = 0;
    my $header = 0;
    my $redirect = 1;
    my $sloppy = 1;
    my $timeout = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -debug => \$debug,
            -header => \$header,
            -redirect => \$redirect,
            -sloppy => \$sloppy,
            -timeout => \$timeout,
        );
    }

    my $ua =  LWP::UserAgent->new;
    $ua->env_proxy; # Lies etwaiges Proxy-Environment
    if ($timeout) {
        $ua->timeout($timeout);
    }
    my $req = HTTP::Request->new(GET=>$url);

    if ($debug) {
        print $req->as_string;
    }

    my $res = $redirect? $ua->request($req): $ua->simple_request($req);
    if ($res->is_error && !$sloppy) {
        $class->throw(
            'HTTP-00001: GET Request failed',
            Url => $url,
            StatusLine => $res->status_line,
        );
    }

    return $header? $res->as_string: $res->content;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
