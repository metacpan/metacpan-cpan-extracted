use utf8;
use Modern::Perl;

package SVN::Simple::Path_Change;
use strict;

our $VERSION = '0.312';    # VERSION
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use Any::Moose 'X::Types::Moose'       => ['Undef'];
use Any::Moose 'X::Types::Path::Class' => [qw(Dir File)];
use Path::Class;
use SVN::Core;
use SVN::Fs;
use namespace::autoclean;

has svn_change => (
    is       => 'ro',
    isa      => '_p_svn_fs_path_change_t',
    required => 1,
    handles  => [
        grep { not $_ ~~ [qw(new DESTROY)] }
            map { $_->name }
            any_moose('::Meta::Class')->initialize('_p_svn_fs_path_change_t')
            ->get_all_methods(),
    ],
);

coerce Dir,  from Undef => via { dir(q{}) };
coerce File, from Undef => via { file($_) };

has path => (
    is       => 'ro',
    isa      => Dir | File,    ## no critic (Bangs::ProhibitBitwiseOperators)
    required => 1,
    coerce   => 1,
);

1;

# ABSTRACT: A class for easier manipulation of Subversion path changes

__END__

=pod

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=encoding utf8

=head1 NAME

SVN::Simple::Path_Change - A class for easier manipulation of Subversion path changes

=head1 VERSION

version 0.312

=head1 SYNOPSIS

    use SVN::Simple::Path_Change;
    use SVN::Core;
    use SVN::Fs;
    use SVN::Repos;

    my $repos = SVN::Repos::open('/path/to/svn/repos');
    my $fs = $repos->fs;
    my %paths_changed = %{$fs->revision_root($fs->youngest_rev)->paths_changed};

    my @path_changes  = map {
        SVN::Simple::Path_Change->new(
            path       => $_,
            svn_change => $paths_changed{$_},
    ) } keys %paths_changed;

=head1 DESCRIPTION

This is a simple class that wraps a
L<Subversion path change object|SVN::Fs/_p_svn_fs_path_change_t> along with the
path it describes.

=head1 ATTRIBUTES

=head2 svn_change

The L<_p_svn_fs_path_change_t|SVN::Fs/_p_svn_fs_path_change_t> object as
returned from the C<< $root->paths_changed() >> method.

=head2 path

Undefined, or a L<Path::Class::Dir|Path::Class::Dir> or
L<Path::Class::File|Path::Class::File> representing the changed entity.

=head1 METHODS

All the methods supported by
L<_p_svn_fs_path_change_t|SVN::Fs/_p_svn_fs_path_change_t> are delegated by and
act on the L</svn_change> attribute.

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
