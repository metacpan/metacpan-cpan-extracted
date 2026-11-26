package Module::Build::Pluggable::GithubMeta;
use strict;
use warnings;
use utf8;
use parent qw(Module::Build::Pluggable::Base);
use Cwd ();

sub HOOK_configure {
    my ($self) = shift;

    return unless _under_git();
    return unless $self->can_run('git');

    my $remote = shift || 'origin';
    return unless my ($git_url) = `git remote show -n $remote` =~ /URL: (.*)$/m;
    return unless $git_url =~ /github\.com/;    # Not a Github repository

    my $http_url = $git_url;
    $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;
    $http_url =~ s![\w\-]+\@([^:]+):!https://$1/!;
    $http_url =~ s!\.git$!/tree!;

    $self->builder->meta_merge('resources', {
        'repository' => $git_url,
        'homepage'   => $http_url,
    });
    return 1;
}

sub _under_git {
    return 1 if -e '.git';
    my $cwd   = Cwd::getcwd;
    my $last  = $cwd;
    my $found = 0;
    while (1) {
        chdir '..' or last;
        my $current = Cwd::getcwd;
        last if $last eq $current;
        $last = $current;
        if ( -e '.git' ) {
            $found = 1;
            last;
        }
    }
    chdir $cwd;
    return $found;
}

1;
__END__

=head1 NAME

Module::Build::Pluggable::GithubMeta - A Module::Build extension to include GitHub meta information in META.yml


=head1 SYNOPSIS

    use Module::Build::Pluggable qw(
        GithubMeta
    );

    my $builder = Module::Build::Pluggable->new(
        ...
    );
    $builder->crate_build_script();

=head1 DESCRIPTION

Module::Build::GithubMeta is a Module::Build extension to include GitHub http://github.com meta information in META.yml.

It automatically detects if the distribution directory is under git version control and whether the origin is a GitHub repository and will set the repository and homepage meta in META.yml to the appropriate URLs for GitHub.

=head1 AUTHOR

Tokuhiro Matsuno

Based on code from L<Module::Install::GithubMeta> by Chris C<BinGOs> Williams, Based on code from L<Module::Install::Repository> by Tatsuhiko Miyagawa


=head1 LICENSE

Copyright E<copy> Tokuhiro Matsuno, Chris Williams and Tatsuhiko Miyagawa
 
This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Module::Build::Pluggable>
