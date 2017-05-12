package Plack::Middleware::Headers;
#ABSTRACT: modify HTTP response headers

use strict;
use 5.008_001;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(set append unset code when);

use Plack::Util;
use Scalar::Util qw(reftype);

our $VERSION = '0.11'; #VERSION

sub prepare_app {
    my $self = shift; 

    if (ref $self->when and ref $self->when eq 'ARRAY') {
        my @when  = @{$self->when};
        $self->when( sub {
            my @headers = @_;
            my $match = 0;
            for (my $i = 0; $i < @when; $i += 2) {
                my ($key, $check) = ($when[ $i ], $when[ $i + 1 ]);

                my $value = Plack::Util::header_get(\@headers, $key);

                if (!defined $check) {            # missing header check
                    next if defined $value;     
                } elsif( !defined $value ) {      # header missing
                    next;
                } elsif( ref $check ) {           # regex match header
                    next if $value !~ $check;
                } elsif ( $value ne $check ) {    # exact header
                    next;
                }

                return 1; 
            }
            return;
        });
    }
}

sub call {
    my $self = shift; 
    my $res  = $self->app->(@_);

    $self->response_cb(
        $res,
        sub {
            my $res = shift;

            if ($self->code and $self->code ne $res->[0]) {
                return;
            }

            my $headers = $res->[1];

            if ($self->when and !$self->when->(@$headers)) {
                return;
            }

            if ( $self->set ) {
                Plack::Util::header_iter(
                    $self->set, sub {Plack::Util::header_set($headers, @_)}
                );
            }
            if ( $self->append ) {
                push @$headers, @{$self->append};
            }
            if ( $self->unset ) {
                Plack::Util::header_remove($headers, $_) for @{$self->unset};
            }
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Headers - modify HTTP response headers

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable 'Headers',
        set    => ['X-Plack-One' => '1'],
        append => ['X-Plack-Two' => '2'],
        unset  => ['X-Plack-Three'];
      enable 'Headers',
        code   => '404',
        set    => ['X-Robots-Tag' => 'noindex, noarchive, follow'];
      enable 'Headers',
        when   => ['Content-Type' => qr{^text/}],
        set    => ['Content-Type' => 'text/plain'];

      sub {['200', [], ['hello']]};
  };

=head1 DESCRIPTION

This L<Plack::Middleware> simplifies creation (C<set> or C<append>), deletion
(C<unset>), and modification (C<set>) of L<PSGI> response headers. The
modification can be enabled based on response code (C<code>) or existing
response headers(C<when>). Use L<Plack::Middleware::Conditional> to enable the
middleware based in I<request> headers.

=head1 CONFIGURATION

=over 4

=item set

Overwrites existent header(s).

=item unset

Remove existing header(s).

=item append

Add header(s).

=item code

Optional HTTP response code that modification of response headers is limited
to.

=item when

Optional check on the response headers that must be true to actually modify
headers. Either one provides a list of headers for which one of them must
match. Matching can be tested against:

    header => undef,    # missing header
    header => $scalar   # exact value
    header => /$regexp/ # regular expression

Alternatively one can check with a code reference that all response headers
are passed to as list.

=back

=head1 CONTRIBUTORS

This module is an extened fork of L<Plack::Middleware::Header>, originally
created by Masahiro Chiba. Additional contributions by Wallace Reis.

=head1 SEE ALSO

L<Plack::Middleware>, L<Plack::Builder>

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
