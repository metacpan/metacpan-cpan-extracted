package Mojolicious::Plugin::Vparam::Address;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common qw(load_class decode_json);

use Mojo::JSON;
use Digest::MD5                     qw(md5_hex);
use Encode                          qw(encode is_utf8);


sub new {
    my ($class, $opts) = @_;
    return bless $opts => $class;
}

=head2 parse $str

Parse address from string

=cut

sub parse {
    my ($class, $str) = @_;

    return undef unless defined $str;
    my ($full, $address, $lon, $lat, $md5, $id, $type, $lang, $opt);

    if( $str =~ m{^\s*\[} and $str =~ m{\]\s*$} ) {
        # JSON format
        my $json = decode_json $str;
        if( $json and 'ARRAY' eq ref($json)) {
            $full       = sprintf '%s : %s , %s',
                            $json->[2]//'', $json->[3]//'', $json->[4]//'';
            $address    = $json->[2];
            $lon        = $json->[3];
            $lat        = $json->[4];
            $id         = $json->[0];
            $type       = $json->[1];
            $lang       = $json->[5];
            $opt        = 'ARRAY' eq ref($json->[6])
                            ? $class->new($json->[6])
                            : $json->[6];
        }
    } else {
        # Text format
        ($full, $address, $lon, $lat, $md5) = $str =~ m{^
            (
                \s*
                # address
                (\S.*?)
                \s*:\s*
                # longitude
                (-?\d{1,3}(?:\.\d+)?)
                \s*,\s*
                # latitude
                (-?\d{1,3}(?:\.\d+)?)
                \s*
            )
            # md5
            (?:\[\s*(\w*)\s*\])?
            \s*
        $}x;
    }

    return $class->new([
        $address, $lon, $lat, $md5, $full, $id, $type, $lang, $opt
    ]);
}

=head2 check_secret $secret

Check address sign for $secret

=cut

sub check_secret {
    my ($self, $secret) = @_;
    return 1 unless defined $secret;
    return 1 unless length  $secret;
    return 0 unless defined $self->md5;

    my $check = $secret . $self->fullname;
    $check = encode utf8 => $check if is_utf8 $check;
    return $self->md5 eq md5_hex( $check );
}

sub address     { return $_[0]->[0]; }
sub lon         { return $_[0]->[1]; }
sub lat         { return $_[0]->[2]; }
sub md5         { return $_[0]->[3]; }
sub fullname    { return $_[0]->[4]; }

sub id          { return $_[0]->[5]; }
sub type        { return $_[0]->[6]; }
sub lang        { return $_[0]->[7]; }

sub opt         { return $_[0]->[8]; }

sub is_extra {
    my ($self) = @_;
    return 0 unless defined $self->opt;
    return 1 if not ref( $self->opt ) and $self->opt eq 'extra';
    return 0;
}

sub is_near {
    my ($self) = @_;
    return 0 unless defined $self->opt;
    return 1 if ref( $self->opt );
    return 0;
}

sub near {
    my ($self) = @_;
    return unless $self->is_near;
    return $self->opt;
}

sub check_address($;$) {
    my ($self, $secret) = (@_);
    return 'Value not defined'          unless defined  $self;
    return 'Wrong format'               unless ref      $self;
    return 'Wrong format'               unless defined  $self->address;
    return 'Wrong format'               unless length   $self->address;

    if( $self->type ) {
        if( $self->type eq 'p' ) {
            # Standart point type

            my $e = load_class('Mojolicious::Plugin::Vparam::Numbers');
            die $e if $e;

            my $lon = Mojolicious::Plugin::Vparam::Numbers::check_lon(
                $self->lon
            );
            return $lon if $lon;

            my $lat = Mojolicious::Plugin::Vparam::Numbers::check_lat(
                $self->lat
            );
            return $lat if $lat;
        } elsif( $self->type eq 't' ) {
            # Some text without point

        } elsif( not defined $self->type ) {
            # Undefined type (legacy)

            my $e = load_class('Mojolicious::Plugin::Vparam::Numbers');
            die $e if $e;

            my $lon = Mojolicious::Plugin::Vparam::Numbers::check_lon(
                $self->lon
            );
            return $lon if $lon;

            my $lat = Mojolicious::Plugin::Vparam::Numbers::check_lat(
                $self->lat
            );
            return $lat if $lat;
        } else {
            return 'Unknown type';
        }
    }

    return 'Unknown source'             unless $self->check_secret( $secret );
    return 0;
}


sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vtype(
        address     =>
            load    => 'Mojolicious::Plugin::Vparam::Address',
            pre     => sub {
                return Mojolicious::Plugin::Vparam::Address->parse( $_[1] );
            },
            valid   => sub { check_address($_[1], $conf->{address_secret}) },
    );

    return;
}

1;

=head1 AUTHORS

Dmitry E. Oboukhov <unera@debian.org>
Roman V. Nikolaev <rshadow@rambler.ru>

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

This program is free software, you can redistribute it and/or
modify it under the terms of the Artistic License.

=cut
