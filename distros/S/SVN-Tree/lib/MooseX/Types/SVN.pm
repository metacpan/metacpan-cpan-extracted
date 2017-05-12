use utf8;
use Modern::Perl;

package MooseX::Types::SVN;
{
    $MooseX::Types::SVN::DIST = 'SVN-Tree';
}
use strict;

our $VERSION = '0.005';    # VERSION
use Try::Tiny;
use SVN::Core;
use SVN::Fs;
use SVN::Repos;
use MooseX::Types -declare => [qw(SvnRoot SvnFs SvnTxn SvnRepos)];
## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
use MooseX::Types::Path::Class 'Dir';

class_type SvnRoot,  { class => '_p_svn_fs_root_t' };
class_type SvnFs,    { class => '_p_svn_fs_t' };
class_type SvnTxn,   { class => '_p_svn_fs_txn_t' };
class_type SvnRepos, { class => '_p_svn_repos_t' };

coerce SvnRoot,
    from SvnFs,  via { $_->revision_root( $_->youngest_rev ) },
    from SvnTxn, via { $_->root };

coerce SvnFs, from SvnRepos, via { $_->fs };
coerce SvnRepos, from Dir, via {
    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    my $dir = $_;
    my $repos;
    try { $repos = SVN::Repos::open("$dir") }
    catch {
        ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
        $repos = SVN::Repos::create( "$dir", (undef) x 4 );
    };
    return $repos;
};

1;

# ABSTRACT: Moose types for the Subversion Perl bindings

__END__

=pod

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=encoding utf8

=head1 NAME

MooseX::Types::SVN - Moose types for the Subversion Perl bindings

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Moose;
    use MooseX::Types::SVN qw(SvnRoot SvnFs SvnTxn SvnRepos);

    has root => (
        is     => 'ro',
        isa    => SvnRoot,
        coerce => 1,
    );

=head1 DESCRIPTION

This is a L<Moose type library|MooseX::Types> for some of the classes provided
by the L<Subversion Perl bindings|Alien::SVN>.  Some of the types have
sensible coercions available to make it less tedious to move from one class to
another.

=head1 TYPES

=head2 SvnRoot

Represents a L<_p_svn_fs_root|SVN::Fs/_p_svn_fs_root_t>, and can coerce from a
C<SvnFs> (retrieving the youngest revision root) or a C<SvnTxn> (retrieving
the transaction root).

=head2 SvnFs

Represents a L<_p_svn_fs_t|SVN::Fs/_p_svn_fs_t>, and can coerce from a
C<SvnRepos> by retrieving the repository filesystem object.

=head2 SvnTxn

Represents a L<_p_svn_fs_txn_t|SVN::Fs/_p_svn_fs_txn_t>.

=head2 SvnRepos

Represents a L<_p_svn_repos_t|SVN::Repos>, and can coerce from
a L<Path::Class::Dir|Path::Class::Dir> object by first trying to open, then
create a repository at the specified directory location.

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
