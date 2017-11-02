package Net::HTTP::Spore::Meta;

# ABSTRACT: Meta class for all SPORE object

use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;

our $VERSION = '0.14';

Moose::Exporter->setup_import_methods(
    with_meta => [qw/spore_method/],
    also      => [qw/Moose/]
);

sub spore_method {
    my $meta = shift;
    my $name = shift;
    $meta->add_spore_method($name, @_);
}

sub init_meta {
    my ($class, %options) = @_;

    my $for = $options{for_class};
    Moose->init_meta(%options);

    my $meta = Moose::Util::MetaRole::apply_metaroles(
        for       => $for,
        class_metaroles => {
            class => ['Net::HTTP::Spore::Meta::Class'],
        },
    );

    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $for,
        roles => [
            qw/
              Net::HTTP::Spore::Role::Debug
              Net::HTTP::Spore::Role::Description
              Net::HTTP::Spore::Role::UserAgent
              Net::HTTP::Spore::Role::Request
              Net::HTTP::Spore::Role::Middleware
              /
        ],
    );

    $meta;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Meta - Meta class for all SPORE object

=head1 VERSION

version 0.09

=head1 AUTHORS

=over 4

=item *

Franck Cuny <franck.cuny@gmail.com>

=item *

Ash Berlin <ash@cpan.org>

=item *

Ahmad Fatoum <athreef@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
