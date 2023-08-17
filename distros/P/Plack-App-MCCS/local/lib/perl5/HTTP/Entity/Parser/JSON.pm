package HTTP::Entity::Parser::JSON;

use strict;
use warnings;
use JSON::MaybeXS qw/decode_json/;
use Encode qw/encode_utf8/;

sub new {
    bless [''], $_[0];
}

sub add {
    my $self = shift;
    if (defined $_[0]) {
        $self->[0] .= $_[0];
    }
}

sub finalize {
    my $self = shift;

    my $p = decode_json($self->[0]);
    my @params;
    if (ref $p eq 'HASH') {
        while (my ($k, $v) = each %$p) {
            push @params, _encode($k), _encode($v);
        }
    }
    return (\@params, []);
}

sub _encode {
    my ($data) = @_;

    if (ref $data eq "ARRAY") {
        my @result;
        for my $d (@$data) {
            push @result, _encode($d);
        }
        return \@result;
    }
    elsif (ref $data eq "HASH") {
        my %result;
        while (my ($k, $v) = each %$data) {
            $result{_encode($k)} = _encode($v);
        }
        return \%result;
    }

    return defined $data ? encode_utf8($data) : undef;
}

1;

__END__

=encoding utf-8

=head1 NAME

HTTP::Entity::Parser::JSON - parser for application/json

=head1 SYNOPSIS

    use HTTP::Entity::Parser;

    my $parser = HTTP::Entity::Parser->new;
    $parser->register('application/json','HTTP::Entity::Parser::JSON');

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=cut
