use utf8;
use Modern::Perl;

package SVN::Simple::Hook;
use strict;

our $VERSION = '0.312';    # VERSION
use Any::Moose '::Role';
use Any::Moose 'X::Types::Moose'       => ['Str'];
use Any::Moose 'X::Types::Path::Class' => ['Dir'];
use List::MoreUtils 'any';
use Path::Class;
use Try::Tiny;
use SVN::Core;
use SVN::Repos;
use SVN::Fs;
use SVN::Simple::Path_Change;
use namespace::autoclean;
with any_moose('X::Getopt');

has repos_path => (
    is            => 'ro',
    isa           => Dir,
    documentation => 'repository path',
    traits        => ['Getopt'],
    cmd_aliases   => [qw(r repo repos repository repository_dir)],
    required      => 1,
    coerce        => 1,
);

has repository => (
    is       => 'ro',
    isa      => '_p_svn_repos_t',
    init_arg => undef,
    required => 1,
    lazy     => 1,
    ## no critic (ProhibitCallsToUnexportedSubs)
    default => sub { SVN::Repos::open( shift->repos_path->stringify() ) },
);

has author => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_author',
    required => 1,
);

has root => (
    is       => 'ro',
    isa      => '_p_svn_fs_root_t',
    init_arg => undef,
    required => 1,
    lazy     => 1,
    builder  => '_build_root',
);

has paths_changed => (
    is       => 'ro',
    isa      => 'HashRef[SVN::Simple::Path_Change]',
    init_arg => undef,
    required => 1,
    lazy     => 1,
    builder  => '_build_paths_changed',
);

sub _build_paths_changed {
    my $self = shift;
    my $root = $self->root;
    my $fs   = $root->fs;

    my $rev_root    = $fs->revision_root( $fs->youngest_rev );
    my $changed_ref = $root->paths_changed;

    my %last_rev;
    for my $revnum ( 0 .. $fs->youngest_rev ) {
        try {
            $self->repository->get_logs(
                [ keys %{$changed_ref} ],
                $revnum, $revnum, 1, 0,
                sub {
                    my @paths = keys %{ +shift };
                    @last_rev{@paths} = (shift) x @paths;
                },
            );
        };
    }

    my %paths_changed;
    while ( my ( $path, $info_ref ) = each %{$changed_ref} ) {
        my $path_obj;
        my $hist_root = $fs->begin_txn( $last_rev{$path} )->root;

        if ( any { $_->is_dir($path) } ( $root, $rev_root, $hist_root ) ) {
            $path_obj = dir($path);
        }
        if ( any { $_->is_file($path) } ( $root, $rev_root, $hist_root ) ) {
            $path_obj = file($path);
        }

        $paths_changed{$path} = SVN::Simple::Path_Change->new(
            svn_change => $info_ref,
            path       => $path_obj,
        );
    }
    return \%paths_changed;
}

1;

# ABSTRACT: Simple Moose/Mouse-based framework for Subversion hooks

__END__

=pod

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=encoding utf8

=head1 NAME

SVN::Simple::Hook - Simple Moose/Mouse-based framework for Subversion hooks

=head1 VERSION

version 0.312

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a collection of roles for L<Moose|Moose::Role> and L<Mouse|Mouse::Role>
that help you implement Subversion repository hooks by providing simple
attribute access to relevant parts of the Subversion API.
This is a work in progress and the interface is extremely unstable at the
moment.  You have been warned!

=head1 ATTRIBUTES

=head2 repos_path

L<Directory|Path::Class::Dir> containing the Subversion repository.

=head2 repository

Subversion L<repository object|SVN::Repos>.  Opened on first
call to the accessor.

=head2 author

Author of the current revision or transaction.  Role consumers must provide a
C<_build_author> method to set a default value.

=head2 root

L<Subversion root object|SVN::Fs/_p_svn_fs_root_t> from the repository.  Role
consumers must provide a C<_build_root> method to set a default value.

=head2 paths_changed

A hash reference where the keys are paths in the L</root> and values are
L<SVN::Simple::Path_Change|SVN::Simple::Path_Change> objects.  Enables hooks
to access the changes that triggered them.

=for test_synopsis 1;

=for test_synopsis __END__

=head1 SEE ALSO

See L<SVN::Simple::Hook::PreCommit|SVN::Simple::Hook::PreCommit/SYNOPSIS> for
an example.  This role exists solely to be composed into other roles.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc SVN::Simple::Hook

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/SVN-Simple-Hook>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/SVN-Simple-Hook>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/SVN-Simple-Hook>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/SVN-Simple-Hook>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/S/SVN-Simple-Hook>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=SVN-Simple-Hook>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=SVN::Simple::Hook>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/svn-simple-hook/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/svn-simple-hook>

  git clone git://github.com/mjgardner/svn-simple-hook.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by GSI Commerce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
