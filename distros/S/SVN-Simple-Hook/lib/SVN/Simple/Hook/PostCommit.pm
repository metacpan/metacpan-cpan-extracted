use utf8;
use Modern::Perl;

package SVN::Simple::Hook::PostCommit;
use strict;

our $VERSION = '0.312';    # VERSION
use Any::Moose '::Role';
use Any::Moose 'X::Types::Common::Numeric' => ['PositiveInt'];
use SVN::Core;
use SVN::Repos;
use SVN::Fs;
use namespace::autoclean;
with 'SVN::Simple::Hook';

has revision_number => (
    is            => 'ro',
    isa           => PositiveInt,
    required      => 1,
    traits        => ['Getopt'],
    cmd_aliases   => [qw(rev revnum rev_num revision_number)],
    documentation => 'commit revision number',
);

has _svn_filesystem => (
    is       => 'ro',
    isa      => '_p_svn_fs_t',
    required => 1,
    lazy     => 1,
    default  => sub { shift->repository->fs },
);

sub _build_author {
    my $self = shift;
    return $self->_svn_filesystem->revision_prop( $self->revision_number,
        'svn:author' );
}

sub _build_root {
    my $self = shift;
    return $self->_svn_filesystem->revision_root( $self->revision_number );
}

1;

# ABSTRACT: Role for Subversion post-commit hooks

__END__

=pod

=for :stopwords Mark Gardner GSI Commerce cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=encoding utf8

=head1 NAME

SVN::Simple::Hook::PostCommit - Role for Subversion post-commit hooks

=head1 VERSION

version 0.312

=head1 SYNOPSIS

    package MyHook::Cmd;
    use Any::Moose;
    extends any_moose('X::App::Cmd');

    package MyHook::Cmd::Command::post_commit;
    use Any::Moose;
    extends any_moose('X::App::Cmd::Command');
    with 'SVN::Simple::Hook::PostCommit';

    sub execute {
        my ( $self, $opt, $args ) = @_;

        warn $self->author, ' changed ',
            scalar keys %{ $self->root->paths_changed() }, " paths\n";

        return;
    }

=head1 DESCRIPTION

This L<Moose|Moose::Role> / L<Mouse|Mouse::Role> role gives you access to the
Subversion revision just committed for use in a post-commit hook.  It's designed
for use with
L<MooseX|MooseX::App::Cmd::Command> /
L<MouseX|MouseX::App::Cmd::Command>::App::Cmd::Command
classes, so consult the main
L<MooseX|MooseX::App::Cmd> / L<MouseX|MouseX::App::Cmd>::App::Cmd documentation
for details on how to extend it to create your scripts.

=head1 ATTRIBUTES

=head2 revision_number

Revision number created by the commit.

=head2 author

The author of the current transaction as required by all
L<SVN::Simple::Hook|SVN::Simple::Hook> consumers.

=head2 root

The L<Subversion root|SVN::Fs/_p_svn_fs_root_t> node as required by all
L<SVN::Simple::Hook|SVN::Simple::Hook> consumers.

=head1 Example F<hooks/post-commit> hook script

    #!/bin/sh

    REPOS="$1"
    REV="$2"

    perl -MMyHook::Cmd -e 'MyHook::Cmd->run()' post_commit -r "$REPOS" --rev "$REV" || exit 1
    exit 0

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
