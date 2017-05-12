use strict;
use warnings;
package inc::DownloadShareDirContent;

use Moose;
use Dist::Zilla::Plugin::MakeMaker::Awesome 0.14;   # base class to [MakeMaker::Fallback]
extends 'Dist::Zilla::Plugin::MakeMaker::Fallback';
use File::Basename;
use namespace::autoclean;

has url => (
    is => 'ro', isa => 'Str',
    required => 1,
);

around register_prereqs => sub
{
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self->zilla->register_prereqs(
        { phase => 'configure' },
        'File::Spec' => 0,
        'File::Temp' => 0,
        'HTTP::Tiny' => 0,
        'Archive::Extract' => 0,
        'File::ShareDir::Install' => 0.03,
    );
};

has download_app_content => (
    is => 'ro', isa => 'Str',
    lazy => 1, default => sub {
        my $self = shift;

        my $url = $self->url;
        my $filename = basename($url);

        # we need to download the file to share/ or Module::Build::Tiny won't like it.
        return <<"DOWNLOAD_PHP_APP";
# begin inc::DownloadShareDirContent (1)
use File::Spec;
use File::Temp 'tempdir';
use HTTP::Tiny;
use Archive::Extract;

my \$archive_file = File::Spec->catfile(tempdir(CLEANUP => 1), '$filename');
print "downloading $url to \$archive_file...\n";
my \$response = HTTP::Tiny->new->mirror('$url', \$archive_file);
\$response->{success} or die "failed to download $url into \$archive_file";

my \$extract_dir = '.';
my \$share_dir = 'share';
my \$ae = Archive::Extract->new(archive => \$archive_file);
\$ae->extract(to => \$extract_dir) or die "failed to extract \$archive_file to \$extract_dir";
rename('beanstalk_console-master', \$share_dir);

# ensure local data storage file is writable
chmod(0644, File::Spec->catfile(\$share_dir, 'storage.json'));

# end inc::DownloadShareDirContent (1)
DOWNLOAD_PHP_APP
    },
);

around setup_installer => sub
{
    my $orig = shift;
    my $self = shift;

    my @build_files  = grep { $_->name eq 'Build.PL' } @{ $self->zilla->files };

    $self->log_fatal('No Build.PL was found. This plugin should appear in dist.ini after [ModuleBuild*]!')
        if not @build_files;

    foreach my $file (@build_files)
    {
        $file->content($self->download_app_content . $file->content);
    }

    # continue with [MakeMaker::Awesome]'s stuff
    return $self->$orig(@_);
};

around _build_share_dir_block => sub
{
    my $orig = shift;
    my $self = shift;

    my $url = $self->url;
    my $filename = basename($url);

    my $share_dir_code = $self->$orig(@_);

    my $pre_preamble = $self->download_app_content . <<'INSTALL_SHARE';

# begin inc::DownloadShareDirContent (2)
install_share dist => $share_dir;
# end inc::DownloadShareDirContent (2)
INSTALL_SHARE

    $share_dir_code->[0] =
        $share_dir_code->[0]
        ? $pre_preamble . $share_dir_code->[0]
        : qq{use File::ShareDir::Install;\n} . $pre_preamble;

    $share_dir_code->[1] =
        qq{\{\npackage\nMY;\nuse File::ShareDir::Install qw(postamble);\n\}\n}
        if not $share_dir_code->[1];

    return $share_dir_code;
};

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

    # remove [MakeMaker], and add:

    [DownloadShareDirContent]
    url = http://foo.com/bar.baz.gz

=head1 DESCRIPTION

At build time, the content at the indicated URL is downloaded, extracted, and
included as sharedir content, which can be accessed normally via
L<File::ShareDir>.

Please consider also using [NoAutomatedTesting], so the entire cpantesters
network doesn't hammer your server to download your content!

=head1 LIMITATIONS

Only distributions built via L<ExtUtils::MakeMaker> (that use
L<Dist::Zilla::Plugin::MakeMaker>) are currently supported.  This plugin must
be included in C<dist.ini> B<before> C<[MakeMaker]>.

=head1 TODO

ship this as its own dist!

=head1 SEE ALSO

L<Dist::Zilla::Plugin::MakeMaker>

L<Dist::Zilla::Plugin::ShareDir>

=cut
