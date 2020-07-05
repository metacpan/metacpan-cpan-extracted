package Plack::Middleware::Acme::AAHTTPHeader;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::Util;
use Plack::Util::Accessor qw/
    aa
    key
/;

our $VERSION = '0.01';

# https://www.asciiart.eu/holiday-and-events/4th-of-july
my $DEFAULT_AA = <<'_TXT_';
                                       .
              . .                     -:-             .  .  .
            .'.:,'.        .  .  .     ' .           . \ | / .
            .'.;.`.       ._. ! ._.       \          .__\:/__.
             `,:.'         ._\!/_.                     .';`.      . ' .
             ,'             . ! .        ,.,      ..======..       .:.
            ,                 .         ._!_.     ||::: : | .        ',
     .====.,                  .           ;  .~.===: : : :|   ..===.
     |.::'||      .=====.,    ..=======.~,   |"|: :|::::::|   ||:::|=====|
  ___| :::|!__.,  |:::::|!_,   |: :: ::|"|l_l|"|:: |:;;:::|___!| ::|: : :|
 |: :|::: |:: |!__|; :: |: |===::: :: :|"||_||"| : |: :: :|: : |:: |:::::|
 |:::| _::|: :|:::|:===:|::|:::|:===F=:|"!/|\!"|::F|:====:|::_:|: :|::__:|
 !_[]![_]_!_[]![]_!_[__]![]![_]![_][I_]!//_:_\\![]I![_][_]!_[_]![]_!_[__]!
 -----------------------------------"---''''```---"-----------------------
 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ |= _ _:_ _ =| _ _ _ _ _ _ _ _ _ _ _ _
                                     |=    :    =|                Valkyrie
_____________________________________L___________J________________________
--------------------------------------------------------------------------
_TXT_

sub prepare_app {
    my $self = shift;

    if (!$self->aa) {
        $self->aa([split /(?:\r\n|\n|\r)/, $DEFAULT_AA]);
    }
    elsif (ref($self->aa) ne 'ARRAY') {
        $self->aa([split /(?:\r\n|\n|\r)/, $self->aa]);
    }

    $self->key or $self->key('happy')
}

sub call {
    my $self = shift;
    my $res  = $self->app->(@_);

    $self->response_cb(
        $res,
        sub {
            my $res = shift;

            return if $res->[0] != 200;
            return unless defined $res->[2];

            my $headers = $res->[1];

            my $count = 1;
            for my $line (@{$self->aa}) {
                Plack::Util::header_set(
                    $headers,
                    sprintf("x-%s%03d", $self->key, $count),
                    $line
                );
                $count++;
            }
        },
    );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Plack::Middleware::Acme::AAHTTPHeader - Add ASCII Art into HTTP Header

=head1 SYNOPSIS

    enable 'Acme::AAHTTPHeader';

See HTTP header from a server.

    $ curl -sD /dev/stdout http://127.0.0.1:5000/
    HTTP/1.0 200 OK
    Date: Sat, 04 Jul 2020 01:15:52 GMT
    Server: HTTP::Server::PSGI
    x-happy001:                                        .
    x-happy002:               . .                     -:-             .  .  .
    x-happy003:             .'.:,'.        .  .  .     ' .           . \ | / .
    x-happy004:             .'.;.`.       ._. ! ._.       \          .__\:/__.
    x-happy005:              `,:.'         ._\!/_.                     .';`.      . ' .
    x-happy006:              ,'             . ! .        ,.,      ..======..       .:.
    x-happy007:             ,                 .         ._!_.     ||::: : | .        ',
    x-happy008:      .====.,                  .           ;  .~.===: : : :|   ..===.
    x-happy009:      |.::'||      .=====.,    ..=======.~,   |"|: :|::::::|   ||:::|=====|
    x-happy010:   ___| :::|!__.,  |:::::|!_,   |: :: ::|"|l_l|"|:: |:;;:::|___!| ::|: : :|
    x-happy011:  |: :|::: |:: |!__|; :: |: |===::: :: :|"||_||"| : |: :: :|: : |:: |:::::|
    x-happy012:  |:::| _::|: :|:::|:===:|::|:::|:===F=:|"!/|\!"|::F|:====:|::_:|: :|::__:|
    x-happy013:  !_[]![_]_!_[]![]_!_[__]![]![_]![_][I_]!//_:_\\![]I![_][_]!_[_]![]_!_[__]!
    x-happy014:  -----------------------------------"---''''```---"-----------------------
    x-happy015:  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ |= _ _:_ _ =| _ _ _ _ _ _ _ _ _ _ _ _
    x-happy016:                                      |=    :    =|                Valkyrie
    x-happy017: _____________________________________L___________J________________________
    x-happy018: --------------------------------------------------------------------------


=head1 DESCRIPTION

Plack::Middleware::Acme::AAHTTPHeader is the Plack middleware to add ASCII Art into HTTP Header.


=head1 METHODS

There are 2 methods to customize HTTP Header.

    enable 'Acme::AAHTTPHeader',
        key => 'easy',
        aa => <<'_AA_';
                  ,,__
        ..  ..   / o._)                   .---.
       /--'/--\  \-'||        .----.    .'     '.
      /        \_/ / |      .'      '..'         '-.
    .'\  \__\  __.'.'     .'          i-._
      )\ |  )\ |      _.'
     // \\ // \\
    ||_  \\|_  \\_
mrf '--' '--'' '--'
_AA_

=head2 aa($text)

Setter of ASCII Art text. By default, it's AA of fireworks.

=head2 key($text : 'happy')

Setter of the key for HTTP Header

=head2 call
=head2 prepare_app


=head1 OTHER EXAMPLE

plackup App like below,

    use Acme::SuddenlyDeath;

    enable 'Acme::AAHTTPHeader',
        key => 'you',
        aa  => sudden_death('Do NOT scrape!');
    sub { [ 200, ['Content-Type' => 'text/plain'], ['OK'] ] };

Then,

    $ curl -sD /dev/stdout http://127.0.0.1:5000/
    HTTP/1.0 200 OK
    Date: Sat, 04 Jul 2020 01:38:47 GMT
    Server: HTTP::Server::PSGI
    x-you001: ＿人人人人人人人人＿
    x-you002: ＞ Do NOT Scrape! ＜
    x-you003: ￣^Y^Y^Y^Y^Y^Y^Y^￣
    Content-Length: 2

A Bot doesn't see this though :)


=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/Plack-Middleware-Acme-AAHTTPHeader/blob/main/README.pod"><img src="https://img.shields.io/badge/Version-0.01-green?style=flat"></a> <a href="https://github.com/bayashi/Plack-Middleware-Acme-AAHTTPHeader/blob/main/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="https://github.com/bayashi/Plack-Middleware-Acme-AAHTTPHeader/actions"><img src="https://github.com/bayashi/Plack-Middleware-Acme-AAHTTPHeader/workflows/main/badge.svg"/></a> <a href="https://coveralls.io/r/bayashi/Plack-Middleware-Acme-AAHTTPHeader"><img src="https://coveralls.io/repos/bayashi/Plack-Middleware-Acme-AAHTTPHeader/badge.png?branch=main"/></a>

=end html

Plack::Middleware::Acme::AAHTTPHeader is hosted on github: L<http://github.com/bayashi/Plack-Middleware-Acme-AAHTTPHeader>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<https://www.asciiart.eu/>

Deprecating the "X-" Prefix
L<https://www.ietf.org/rfc/rfc6648.txt>


=head1 LICENSE

C<Plack::Middleware::Acme::AAHTTPHeader> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
