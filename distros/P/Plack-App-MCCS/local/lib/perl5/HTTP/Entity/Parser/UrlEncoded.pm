package HTTP::Entity::Parser::UrlEncoded;

use strict;
use warnings;
use WWW::Form::UrlEncoded qw/parse_urlencoded_arrayref/;

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
    return (parse_urlencoded_arrayref($_[0]->[0]), []);
}


1;
__END__

=encoding utf-8

=head1 NAME

HTTP::Entity::Parser::UrlEncoded - parser for application/x-www-form-urlencoded

=head1 SYNOPSIS

    use HTTP::Entity::Parser;
    
    my $parser = HTTP::Entity::Parser->new;
    $parser->register('application/x-www-form-urlencoded','HTTP::Entity::Parser::UrlEncoded');

=head1 DESCRIPTION

This is a parser class for application/x-www-form-urlencoded.

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=cut


