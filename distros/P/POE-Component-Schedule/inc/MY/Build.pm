use strict;
package inc::MY::Build;
use Module::Build;
our @ISA;
BEGIN {
    push @ISA, 'Module::Build';
}


sub ACTION_distmeta
{
    my $self = shift;
    $self->SUPER::depends_on('distrss');
    $self->SUPER::ACTION_distmeta;
}


# Override 'dist' to force a 'distcheck'
# (this is unfortunately not the default in M::B, which means it let you build
#  and distribute a distribution which has an incorrect MANIFEST and lacks some
#  files)
sub ACTION_dist
{
    my $self = shift;
    $self->SUPER::depends_on('distcheck');
    $self->SUPER::ACTION_dist;
}


sub ACTION_tag
{
    my $self = shift;

    my $version = $self->dist_version;
    my $tag = "release-$version";

    my ($trunk, $repo, $revision);

    local %ENV;
    $ENV{LANG} = 'C';

    open(my $svn_info, 'svn info|')
	or die "Can't run 'svn info: $!'";

    while (<$svn_info>) {
	chomp;
	/^URL: (.*)$/ and $trunk = $1;
    }
    close $svn_info;
    die "'URL' not found in 'svn info' output " unless $trunk;

    open($svn_info, "svn info $trunk|")
	or die "Can't run 'svn info $trunk: $!'";

    while (<$svn_info>) {
	chomp;
	/^Repository Root: (.*)$/ and $repo = $1;
	/^Last Changed Rev: (\d+)/ and $revision = $1;
    }
    close $svn_info;
    die "'Repository Root' or 'Last Changed Rev' not found in 'svn info' output " unless $repo && $revision;

    # TODO Check if the tag already exists

    print "Creating tag '$tag' from revision $revision\n";
    my $cmd = qq|svn copy $trunk $repo/tags/$tag -m "CPAN release $version from r$revision."|;

    print "$cmd\n";
    if ($self->y_n("Do it?", 'n')) {
	system $cmd;
    } else {
	printf "Abort.\n";
	return 1;
    }
}


sub ACTION_distrss
{
    my $self = shift;
    $self->do_create_Changes_RSS;
}


sub do_create_Changes_RSS
{
    my $self = shift;

    print "Creating Changes.{rss,yml}\n";

    my %deps = (
	'DateTime' => '0.53',
	'Regexp::Grammars' => '1.002',
	'Data::Recursive::Encode' => '0.03',
	'DateTime::Format::W3CDTF' => '0.04',
	'YAML' => '0.71',
	'XML::RSS' => '1.47',
	#'Toto' => '3',
    );

    my $ok = 1;
    while (my ($mod, $ver) = each %deps) {
	unless ($self->check_installed_version($mod, $ver)) {
	    $self->log_warn("missing module $mod $ver");
	    $ok = 0;
	}
    }
    die "Can't build Changes.{rss,yml}" unless $ok;


    #system $^X $^X, 'make-Changes-rss-2.pl';
    require inc::MY::Build::Changes;
    inc::MY::Build::Changes->build(dist_name => $self->dist_name);

    # Prepare Changes.rss online distribution in the wiki of the Google Code
    # project
    require File::Spec;
    my $f = File::Spec->catfile('..', $self->dist_name.".wiki", 'Changes.rss');
    if (-e $f) {
	require File::Copy;
	File::Copy::syscopy('Changes.rss', $f);
    }
}


1;
__END__
=head1 ACTIONS

=over 4

=item distrss

Creates 'Changes.rss' and 'Changes.yml' from 'Changes'.

=item tag

Makes the Subversion tag for the release.

=back

=cut



