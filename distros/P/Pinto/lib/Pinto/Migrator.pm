# ABSTRACT: Migrate an existing repository to a new version

package Pinto::Migrator;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Types qw(Dir);
use Pinto::Repository;

#------------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#------------------------------------------------------------------------------

has root => (
    is      => 'ro',
    isa     => Dir,
    default => $ENV{PINTO_REPOSITORY_ROOT},
    coerce  => 1,
);

#------------------------------------------------------------------------------

sub migrate {
    my ($self) = @_;

    my $repo = Pinto::Repository->new( root => $self->root );

    my $repo_version = $repo->get_version;
    my $code_version = $Pinto::Repository::REPOSITORY_VERSION;

    die "This repository is too old to migrate.\n" . "Contact thaljef\@cpan.org for a migration plan.\n"
        if not $repo_version;

    die "This repository is already up to date.\n"
        if $repo_version == $code_version;

    die "This repository too new.  Upgrade Pinto instead.\n"
        if $repo_version > $code_version;

    die "Migration is not implemented yet\n";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Migrator - Migrate an existing repository to a new version

=head1 VERSION

version 0.12

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
