use strict;
use warnings;
use v5.10.1;
package Plack::App::DAIA::Test;
#ABSTRACT: Test DAIA Servers
our $VERSION = '0.55'; #VERSION
use base 'Test::Builder::Module';
our @EXPORT = qw(test_daia_psgi test_daia daia_app);

use URI::Escape;
use Test::More;
use Plack::Test;
use Plack::App::DAIA;
use Scalar::Util qw(reftype blessed);
use HTTP::Request::Common;
use Test::JSON::Entails;
use JSON;

sub test_daia {
    my $app = daia_app(shift) || do {
        __PACKAGE__->builder->ok(0,"Could not construct DAIA application");
        return;
    };
    my $test_name = "test_daia";
    $test_name = pop(@_) if @_ % 2;
    while (@_) {
        my $id = shift;
        my $expected = shift;
        my $res = $app->retrieve($id);
        if (!_if_daia_check( $res, $expected, $test_name )) {
            $@ = "retrieve method returned a DAIA::Response" unless $@;
            __PACKAGE__->builder->ok(0, $@);
        }
    }
}

sub test_daia_psgi {
    my $app = shift;

    # TODO: load psgi file if string given and allow for URL
    my $test_name = "test_daia";
    $test_name = pop(@_) if @_ % 2;
    while (@_) {
        my $id = shift;
        my $expected = shift;
        test_psgi $app, sub {
            my $req = shift->(GET "/?id=".uri_escape($id).'&format=xml');
            my $res = eval { DAIA::parse( $req->content ); };
            if ($@) {
                $@ =~ s/DAIA::([A-Z]+::)?[a-z_]+\(\)://ig;
                $@ =~ s/ at .* line.*//g;
                $@ =~ s/\s*$//sg;
            }
            if (!_if_daia_check( $res, $expected, $test_name )) {
                $@ = "application returned a DAIA::Response" unless $@;
                __PACKAGE__->builder->ok(0, $@);
            }
        };
    }
}

sub daia_app {
    my $app = shift;
    if ( blessed($app) and $app->isa('Plack::App::DAIA') ) {
        return $app;
    } elsif ( $app =~ qr{^https?://} ) {
        my $baseurl = $app . ($app =~ /\?/ ? '&id=' : '?id=');
        $app = sub {
            my $id = shift;
            my $url = $baseurl.$id."&format=json";
            my @daia = eval { DAIA->parse($url) };
            if (!@daia) {
                $@ ||= '';
                if ($@) {
                    $@ =~ s/DAIA::([A-Z]+::)?[a-z_]+\(\)://ig;
                    $@ =~ s/ at .* line.*//g;
                    $@ =~ s/\s*$//sg;
                }
                $@ = "invalid DAIA from $url: $@";
            }
            return $daia[0];
        };
    }
    if ( ref($app) and reftype($app) eq 'CODE' ) {
        return Plack::App::DAIA->new( code => $app );
    }
    return;
}

# Call C<$code> with C<$daia> and set as C<$_>, if C<$daia> is a L<DAIA::Response>
# and return C<$daia> on success. Return C<undef> otherwise.
sub _if_daia_check {
    my ($daia, $expected, $test_name) = @_;
    if ( blessed($daia) and $daia->isa('DAIA::Response') ) {
        if ( (reftype($expected)||'') eq 'CODE') {
            local $_ = $daia;
            $expected->($daia);
        } else {
            local $Test::Builder::Level = $Test::Builder::Level + 2;
            my $json = decode_json( $daia->json );
            entails $json, $expected, $test_name;
        }
        return $daia;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::DAIA::Test - Test DAIA Servers

=head1 VERSION

version 0.55

=head1 SYNOPSIS

    use Test::More;
    use Plack::App::DAIA::Test;

    use Your::App; # your subclass of Plack::App::DAIA
    my $app = Your::App->new;

    # or wrap a DAIA server
    my $app = daia_app( 'http://your.host/pathtodaia' );

    test_daia $app,
        'some:id' => sub {
            my $daia = shift; # or = $_
            my @docs = $daia->document;
            is (scalar @docs, 1, 'returned one document');
            ...
        },
        'another:id' => sub {
            my $daia = shift;
            ...
        };

    # same usage, shown here with an inline server

    test_daia_psgi
        sub {
            my $id = shift;
            my $daia = DAIA::Response->new;
            ...
            return $daia;
        },
        'some:id' => sub {
            my $daia = $_; # or shift
            ...
        };

    done_testing;

=head1 DESCRIPTION

I<This model is experimental, so take care!> The current version has different
behaviour for C<test_daia> and C<test_daia_psgi>, that might get fixed.

This module exports two methods for testing L<DAIA> servers. You must provide a
DAIA server as code reference or as instance of L<Plack::App::DAIA> and a list
of request identifiers and testing code. The testing code is passed a valid
L<DAIA::Response> object on success (C<$_> is also set to this response).

=head1 METHODS

=head2 test_daia ( $app, $id1 => $expected, $id2 => ...  )

Calls a DAIA server C<$app>'s retrieve method with one or more identifiers,
each given a test function or an expected JSON structure to be tested with
L<Test::JSON::Entails>. This does not add warnings and the error option is
ignored (use test_daia_psgi instead if needed).

=head2 test_daia_psgi ( $app, $id => $expected, $id => ...  )

Calls a DAIA server C<$app> as L<PSGI> application with one or more
identifiers, each given a test function or an expected JSON structure.

=head2 daia_app ( $plack_app_daia | $url | $code )

Returns an instance of L<Plack::App::DAIA> or undef. Code references or URLs
are wrapped. For wrapped URLs C<$@> is set on failure. This method may be removed
to be used internally only!

=head1 SEE ALSO

L<Plack::App::DAIA::Test::Suite> and L<provedaia>.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
