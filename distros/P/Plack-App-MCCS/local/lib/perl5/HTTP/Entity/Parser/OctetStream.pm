package HTTP::Entity::Parser::OctetStream;

use strict;
use warnings;

sub new {
    bless [], $_[0];
}

sub add { }

sub finalize {
    return ([],[]);
}

1;

__END__

=encoding utf-8

=head1 NAME

HTTP::Entity::Parser::OctetStream - parser for application/octet-stream

=head1 SYNOPSIS

    use HTTP::Entity::Parser;
    
    my $parser = HTTP::Entity::Parser->new;
    my ($params, $uplaods) = $parser->parse($env); # [] , []

=head1 DESCRIPTION

This is a parser class for application/octet-stream and other.
This is used as default parser.

OctetStream always returns empty list.

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=cut


