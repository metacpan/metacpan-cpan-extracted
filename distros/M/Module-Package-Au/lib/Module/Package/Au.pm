use strict;
use 5.008003;
package Module::Package::Au;
our $VERSION = 2;

use Module::Package 0.24 ();
use Module::Install::GithubMeta 0.10 ();
use Module::Install::ReadmeFromPod 0.12 ();
use Module::Install::ReadmeMarkdownFromPod 0.03 ();
use Pod::Markdown 1.110730 ();

package Module::Package::Au::dry;
use Module::Package::Plugin;
use base 'Module::Package::Plugin';

sub main {
    my ($self) = @_;

    $self->mi->license('unrestricted');
    $self->mi->readme_from($self->pod_or_pm_file);
    $self->mi->readme_markdown_from($self->pod_or_pm_file);
    $self->mi->clean_files('README.mkdn');
 
    $self->post_all_from(sub {
        $self->mi->sign;
        $self->mi->githubmeta;
    });
}

1;

__END__

=encoding utf8

=head1 NAME

Module::Package::Au - Reusable Module::Install bits

=head1 SYNOPSIS

In F<Makefile.PL>:

    #!/usr/bin/env perl
    use inc::Module::Package 'Au:dry 1';

    # Put distribution-specific metadata here
    requires "Some::Module";
    keywords qw[ put some tags here ];

=head1 DESCRIPTION

This module defines a set of standard configurations for F<Makefile.PL>
files based on L<Module::Package>.

=head1 SEE ALSO

L<Module::Package::Ingy>, L<Module::Package>

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to Module-Package-Au.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
