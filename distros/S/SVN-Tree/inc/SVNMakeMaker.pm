use 5.010;
use utf8;

package inc::SVNMakeMaker;
use strict;
use warnings;

# VERSION
use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my ($self) = @_;

    my $template = super();
    $template .= <<'END_TEMPLATE';
if (eval {require Alien::SVN; 1}) {
    eval {require SVN::Core; SVN::Core->import; 1}
        or die 'botched Alien::SVN install detected, cannot continue';
}
END_TEMPLATE

    return $template;
};

__PACKAGE__->meta->make_immutable();
no Moose;
1;

# ABSTRACT: Add check for SVN::Core problems to Makefile.PL

=head1 SYNOPSIS

In F<dist.ini>:

   [=inc::SVNMakeMaker / SVNMakeMaker]

=head1 DESCRIPTION

This is a subclass of
L<Dist::Zilla::MakeMaker::Awesome|Dist::Zilla::MakeMaker::Awesome>
that checks if L<Alien::SVN|Alien::SVN> can be loaded, and if so tries
to load L<SVN::Core|SVN::Core>.  If the latter fails then an exception
is thrown indicating a botched C<Alien::SVN> installation.
