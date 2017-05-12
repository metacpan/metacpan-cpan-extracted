package MsgPack::Type::Boolean;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::Type::Boolean::VERSION = '1.0.1';
use strict;
use warnings;

use Moose;

use overload 'bool' => sub {
    $_[0]->value;
},
    fallback => 1;

has "value" => (
    isa => 'Bool',
    is => 'ro',
    required => 1,
);

sub BUILDARGS {
    my( $self, @args ) = @_;
    unshift @args, 'value' if @args == 1;

    return { @args };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Type::Boolean

=head1 VERSION

version 1.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
