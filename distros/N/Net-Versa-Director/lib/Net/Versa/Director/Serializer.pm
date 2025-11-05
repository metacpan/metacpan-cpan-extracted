package Net::Versa::Director::Serializer;
$Net::Versa::Director::Serializer::VERSION = '0.004000';
# ABSTRACT: Versa Director REST API serializer

use v5.36;
use Moo;
use Types::Standard qw(Enum);

extends 'Role::REST::Client::Serializer';

has '+type' => (
    isa => Enum[qw{application/json application/vnd.yang.data+json}],
    default => sub { 'application/json' },
);

our %modules = (
    'application/json' => {
        module => 'JSON',
    },
    'application/vnd.yang.data+json' => {
        module => 'JSON',
    },
);

has '+serializer' => (
    default => \&_set_serializer,
);

sub _set_serializer ($self) {
    return unless $modules{$self->type};

    my $module = $modules{$self->type}{module};

    return Data::Serializer::Raw->new(
            serializer => $module,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Versa::Director::Serializer - Versa Director REST API serializer

=head1 VERSION

version 0.004000

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
