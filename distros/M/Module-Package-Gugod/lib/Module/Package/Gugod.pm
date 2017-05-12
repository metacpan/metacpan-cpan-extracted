package Module::Package::Gugod;
use strict;
use 5.008003;
our $VERSION = '0.01';

use Module::Package 0.24 ();
use Module::Install::GithubMeta 0.10 ();
use Module::Install::RequiresList 0.10 ();
use Module::Install::ReadmeFromPod 0.12 ();
use Module::Install::ReadmeMarkdownFromPod 0.03 ();
use Pod::Markdown 1.110730 ();

package Module::Package::Gugod::style;
use Module::Package::Plugin;
use base 'Module::Package::Plugin';

sub main {
    my ($self) = @_;
    $self->mi->license('CC0');
    $self->mi->readme_from($self->pod_or_pm_file);
    $self->mi->readme_markdown_from($self->pod_or_pm_file);
    $self->mi->clean_files('README.mkdn');
    $self->mi->clean_files('LICENSE');

    $self->post_all_from(
        sub {
            $self->mi->auto_license;
            $self->mi->githubmeta;
        }
    );
    $self->post_WriteAll(
        sub {
            $self->mi->requires_list
        }
    );
}

1;

=encoding utf8

=head1 NAME

Module::Package::Gugod

=head1 SYNOPSIS

In Makefile.PL

    use inc::Module::Package 'Gugod';

=head1 DESCRIPTION

Well...

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 COPYRIGHT

Copyright (c) 2011 Kang-min Liu C<< <gugod@gugod.org> >>.

=head1 LICENSE

CC0

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
