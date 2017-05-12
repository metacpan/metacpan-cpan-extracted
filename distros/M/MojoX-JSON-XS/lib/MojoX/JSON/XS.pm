package MojoX::JSON::XS;

use Mojo::Base 'Mojolicious::Plugin';
use strict;

use Mojo::Util qw(monkey_patch);
use JSON::XS;

our $VERSION = "0.01";

sub register
{
    monkey_patch "Mojo::JSON", encode => sub { return encode_json( $_[1] ); };
    monkey_patch "Mojo::JSON", decode => sub { return decode_json( $_[1] ); };
    monkey_patch "Mojo::JSON", j      => sub { if(ref $_[0]) { return encode_json( $_[0] ); }
                                               else          { return decode_json( $_[0] ); }
    };
}

1;

=encoding utf8

=head1 NAME

MojoX::JSON::XS - A JSON::XS backend replacement for Mojo::JSON

=head1 SYNOPSIS

    sub startup
    {
        # ...

        $self->plugin('MojoX::JSON::XS');

        # ...
    }
    

=head1 DESCRIPTION

Replaces Mojo::JSON methods encode, deocde and j with JSON::XS equivalient.
This gives faster processing, and removes the unnecessary encode of '/' chars in strings.

=head1 FEATURES

It does not gracefully handle or skip blessed hashes

=cut
