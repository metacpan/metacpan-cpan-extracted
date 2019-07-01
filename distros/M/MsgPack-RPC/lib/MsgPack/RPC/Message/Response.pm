package MsgPack::RPC::Message::Response;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::RPC::Message::Response::VERSION = '2.0.3';
use strict;
use warnings;

use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::RPC::Message';

has id => ( required => 1 );

has result => ();

has error => ();

sub is_error { !!$_[0]->error }

sub pack {
    my $self = shift;
    return [ 1, $self->id, $self->error, $self->result ];
}

sub is_response { 1}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::RPC::Message::Response

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
