package MooseX::MultiMethods::Meta::Method;
our $VERSION = '0.10';

use Carp;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw/CodeRef/;
use Devel::PartialDump qw/dump/;
use aliased 'MooseX::Types::VariantTable';

use namespace::autoclean;

extends 'Moose::Object', 'Moose::Meta::Method';

has _variant_table => (
    is      => 'ro',
    isa     => VariantTable,
    default => sub {
        VariantTable->new(
            ambigious_match_callback => sub {
                my ($self, $value, @matches) = @_;
                local $Carp::CarpLevel = 2;
                croak sprintf 'Ambiguous match for multi method %s: %s with value %s',
                    $matches[0]->{value}->name,
                    join(q{, }, map { $_->{value}->signature } @matches),
                    dump($value);
            },
        );
    },
    handles => [qw/add_variant/],
);

has body => (
    is      => 'ro',
    isa     => CodeRef,
    lazy    => 1,
    builder => 'initialize_body',
);

method initialize_body {
    my $name          = $self->name;
    my $variant_table = $self->_variant_table;

    return sub {
        my ($args) = \@_;

        my $result = $variant_table->find_variant($args)
            || Class::MOP::class_of($args->[0])->find_next_method_by_name($name);

        confess "no variant of method '${name}' found for ", dump($args)
            unless $result;

        goto $result->body;
    };
}

1;

__END__
=pod

=head1 NAME

MooseX::MultiMethods::Meta::Method

=head1 VERSION

version 0.10

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

