package Test::DBChanges::Role::Base;
use Moo::Role;
use 5.024;
use Types::Standard qw(ArrayRef Str);
use Test::DBChanges::ChangeSet;
use namespace::autoclean;

our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: base role for all DBChanges classes


has source_names => ( is => 'ro', required => 1, isa => ArrayRef[Str] );

has _table_source_map => (
    is => 'lazy',
    builder => sub {
        my ($self) = @_;

        my %table_source_map = map {
            my $source_name = $_;
            my ($table_name, $factory) = $self->_table_and_factory_for_source($source_name);
            ( $table_name => { name => $source_name, factory => $factory } );
        } $self->source_names->@*;

        return \%table_source_map;
    },
);

requires qw(_table_and_factory_for_source changeset_for_code);

sub _make_changeset {
    my ($self,$raw_changes) = @_;

    return Test::DBChanges::ChangeSet->new({
        table_source_map => $self->_table_source_map,
        raw_changes => $raw_changes,
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::Role::Base - base role for all DBChanges classes

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

All DBChanges classes should consume this role, it sets up the
required attributes and methods.

=for Pod::Coverage source_names

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
