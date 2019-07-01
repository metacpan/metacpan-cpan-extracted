package MsgPack::Decoder::Generator::Nil;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::Decoder::Generator::Nil::VERSION = '2.0.3';
use Moose;
use MooseX::MungeHas 'is_ro';

extends 'MsgPack::Decoder::Generator';

has '+bytes' => sub { 0 };

has 'push_decoded' => (
    trigger => sub { $_[0]->push_decoded->(undef) },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Decoder::Generator::Nil

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
