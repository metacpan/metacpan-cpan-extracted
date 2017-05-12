use utf8;
use Modern::Perl;

package SVN::Tree;
{
    $SVN::Tree::DIST = 'SVN-Tree';
}
use strict;

our $VERSION = '0.005';    # VERSION
use List::MoreUtils 'any';
use Path::Class;
use SVN::Core;
use SVN::Fs;
use SVN::Repos;
use Tree::Path::Class;
use Moose;
use MooseX::Has::Options;
use MooseX::Types::Moose qw(ArrayRef HashRef Maybe);
use MooseX::Types::SVN 'SvnRoot';
use MooseX::MarkAsMethods autoclean => 1;

has root => ( qw(:rw :required :coerce), isa => SvnRoot );

has tree => (
    qw(:ro :required :lazy),
    isa      => 'Tree::Path::Class',
    writer   => '_set_tree',
    init_arg => undef,
    default  => sub { $_[0]->_root_to_tree( $_[0]->root ) },
);

has projects => (
    qw(:ro :required :lazy_build),
    isa => ArrayRef [ Maybe ['Tree::Path::Class'] ],
    writer   => '_set_projects',
    init_arg => undef,
);

has branches => (
    qw(:ro :required :lazy_build),
    isa => HashRef [ ArrayRef [ Maybe ['Tree::Path::Class'] ] ],
    writer   => '_set_branches',
    init_arg => undef,
);

sub _build_projects {
    my $self = shift;
    my $tree = $self->tree;
    return [$tree] if _match_svn_dirs( _children_value($tree) );
    return [ $tree->children ]
        if _match_svn_dirs( map { _children_value($_) } $tree->children );
    return [];
}

sub _match_svn_dirs {
    my @dirs = @_;
    return any { $_ ~~ [qw(trunk branches tags)] } @dirs;
}

sub _children_value {
    return map { $_->value->stringify } shift->children;
}

sub _build_branches {
    my $self = shift;
    my %branches;
    for my $project ( @{ $self->projects } ) {
        @{ $branches{ $project->value->stringify } }
            = map { _trunk_or_branches($_) } $project->children;
    }
    return \%branches;
}

sub _trunk_or_branches {
    my $tree = shift;
    given ( $tree->value ) {
        when ('trunk') { return $tree }
        when ('branches') {
            my $path = $tree->path;
            return
                map { Tree::Path::Class->new( dir( $path, $_->value ) ) }
                $tree->children;
        }
    }
    return;
}

# recreate tree every time root is changed
after root => sub {
    my ( $self, $root ) = @_;
    return if !$root;
    $self->_set_tree( $self->_root_to_tree($root) );
    $self->_set_projects( $self->_build_projects );
    $self->_set_branches( $self->_build_branches );
    return;
};

sub _root_to_tree {
    my ( $self, $root ) = @_;
    my $tree        = Tree::Path::Class->new(q{/});
    my $entries_ref = $root->dir_entries(q{/});
    while ( my ( $name => $dirent ) = each %{$entries_ref} ) {
        $tree->add_child( $self->_dirent_to_tree( "/$name" => $dirent ) );
    }
    return $tree;
}

sub _dirent_to_tree {
    my ( $self, $entry_name, $dirent ) = @_;

    my $name = $dirent->name;
    my $tree = Tree::Path::Class->new();

    given ( $dirent->kind ) {
        ## no critic (Variables::ProhibitPackageVars)
        when ($SVN::Node::file) { $tree->set_value( file($name) ) }
        when ($SVN::Node::dir) {
            $tree->set_value( dir($name) );
            my %child_entries = %{ $self->root->dir_entries($entry_name) };
            while ( my ( $child_name => $child_dirent )
                = each %child_entries )
            {
                $tree->add_child(
                    $self->_dirent_to_tree(
                        "$entry_name/$child_name" => $child_dirent,
                    ),
                );
            }
        }
    }
    return $tree;
}

__PACKAGE__->meta->make_immutable();
no Moose;
1;

# ABSTRACT: SVN::Fs plus Tree::Path::Class

__END__

=pod

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=encoding utf8

=head1 NAME

SVN::Tree - SVN::Fs plus Tree::Path::Class

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use SVN::Tree;
    use SVN::Core;
    use SVN::Repos;
    use SVN::Fs;

    my $repos = SVN::Repos::open('/path/to/repository');
    my $fs = $repos->fs;

    my $tree = SVN::Tree->new(root => $fs->revision_root($fs->youngest_rev));
    print map {$_->path->stringify} $tree->tree->traverse;

=head1 DESCRIPTION

This module marries L<Tree::Path::Class|Tree::Path::Class> to the
L<Perl Subversion bindings|Alien::SVN>, enabling you to traverse the files and
directories of Subversion revisions and transactions, termed
L<roots|SVN::Fs/_p_svn_fs_root_t> in Subversion API parlance.

=head1 ATTRIBUTES

=head2 root

Required attribute referencing a L<_p_svn_fs_root|SVN::Fs/_p_svn_fs_root_t>
object.

=head2 tree

Read-only accessor for the L<Tree::Path::Class|Tree::Path::Class> object
describing the filesystem hierarchy contained in the C<root>.  Will be updated
every time the C<root> attribute is changed.

=head2 projects

Read-only accessor returning an array reference containing one or more
L<Tree::Path::Class|Tree::Path::Class> hierarchies for the top-level project
directories in the repository.  In the case of a repository with F<trunk>,
F<branches> and F<tags> at the top level, this will be one element referring
to the same hierarchy available through the C<tree> attribute.

Like C<tree> this will also be updated with C<root> changes.

=head2 branches

Read-only accessor returning a hash reference of arrays containing
L<Tree::Path::Class|Tree::Path::Class> objects for each branch in each project
in the repository.  The hash keys are the names of the projects, and F<trunk>
counts as a branch.

Like C<tree> this will also be updated with C<root> changes.

=head1 SEE ALSO

The distribution for this module also includes
L<MooseX::Types::SVN|MooseX::Types::SVN>, a
L<Moose type library|MooseX::Types> for the Subversion Perl bindings. This may
be split off into its own distribution at a later point if it proves useful in
other projects.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc SVN::Tree

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/SVN-Tree>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/SVN-Tree>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/SVN-Tree>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/SVN-Tree>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/S/SVN-Tree>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=SVN-Tree>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=SVN::Tree>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/SVN-Tree/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/SVN-Tree>

  git clone git://github.com/mjgardner/SVN-Tree.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by GSI Commerce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
