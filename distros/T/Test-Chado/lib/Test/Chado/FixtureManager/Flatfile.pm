package Test::Chado::FixtureManager::Flatfile;
{
  $Test::Chado::FixtureManager::Flatfile::VERSION = 'v4.1.1';
}
use File::ShareDir qw/module_dir/;
use Moo;
use MooX::late;
use Types::Standard qw/Str/;
use Carp;
use File::Spec::Functions;
use Test::Chado;

has 'default_fixture_path' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { return catfile( module_dir('Test::Chado') ) }
);

has 'fixture_path' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->default_fixture_path;
    }
);

has 'organism_fixture' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return catfile( $self->default_fixture_path, 'organism.yaml' );
    }
);

has 'rel_fixture' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return catfile( $self->default_fixture_path, 'relationship.obo_xml' );
    }
);

has 'so_fixture' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return catfile( $self->default_fixture_path, 'sofa.obo_xml' );
    }
);

1;

__END__

=pod

=head1 NAME

Test::Chado::FixtureManager::Flatfile

=head1 VERSION

version v4.1.1

=head1 DESCRIPTION

Manages the filesystem location of various test fixtures that comes bundled with this distribution

=head1 API

=head2 Attributes

=over

=item default_fixture_path [ro]

Base folder of all fixutres

=item fixture_path [rw]

To set a custom base path of all fixtures. By default, it returns the L<default_fixture_path>

=item organism_fixture [rw]

Get/Set attribute for organism fixture file, default is B<organism.yaml>

=item rel_fixture [rw]

Get/Set attribute for relationship ontology file in xml format, default is B<relationship.obo_xml>

=item so_fixture [rw]

Get/Set attribute for sequence ontology file in xml format, default is B<sofa.obo_xml>

=back

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
