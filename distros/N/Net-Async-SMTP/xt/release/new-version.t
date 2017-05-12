# this test was generated with Dist::Zilla::Plugin::Test::NewVersion 0.009

use strict;
use warnings FATAL => 'all';

use Test::More 0.88;
use Encode;
use HTTP::Tiny;
use JSON;
use version;
use Module::Metadata;
use List::Util 'first';
use CPAN::Meta 2.120920;

# 'provides' field from dist metadata, if needed
my $dist_provides;

# returns bool, detailed message
sub version_is_bumped
{
    my ($module_metadata, $pkg) = @_;

    my $res = HTTP::Tiny->new->get("http://cpanidx.org/cpanidx/json/mod/$pkg");
    return (0, 'index could not be queried?') if not $res->{success};

    # JSON wants UTF-8 bytestreams, so we need to re-encode no matter what
    # encoding we got. -- rjbs, 2011-08-18 (in
    # Dist::Zilla::Plugin::CheckPrereqsIndexed)
    my $json_octets = Encode::encode_utf8($res->{content});
    my $payload = JSON::->new->decode($json_octets);

    return (0, 'no valid JSON returned') unless $payload;

    return (1, 'not indexed') if not defined $payload->[0]{mod_vers};
    return (1, 'VERSION is not set in index') if $payload->[0]{mod_vers} eq 'undef';

    my $indexed_version = version->parse($payload->[0]{mod_vers});
    my $current_version = $module_metadata->version($pkg);

    if (not defined $current_version)
    {
        $dist_provides ||= do {
            my $metafile = first { -e $_ } qw(MYMETA.json MYMETA.yml META.json META.yml);
            my $dist_metadata = $metafile ? CPAN::Meta->load_file($metafile) : undef;
            $dist_metadata->provides if $dist_metadata;
        };

        $current_version = $dist_provides->{$pkg}{version};
        return (0, 'VERSION is not set; indexed version is ' . $indexed_version)
            if not $dist_provides or not $current_version;
    }

    return (
        $indexed_version < $current_version,
        'indexed at ' . $indexed_version . '; local version is ' . $current_version,
    );
}

foreach my $filename (
    "lib\/Net\/Async\/SMTP\.pm",
    "lib\/Net\/Async\/SMTP\/Client\.pm",
    "lib\/Net\/Async\/SMTP\/Client\.pod",
    "lib\/Net\/Async\/SMTP\/Connection\.pm",
    "lib\/Net\/Async\/SMTP\/Connection\.pod"
)
{
    my $module_metadata = Module::Metadata->new_from_file($filename);
    foreach my $pkg ($module_metadata->packages_inside)
    {
        my ($bumped, $message) = version_is_bumped($module_metadata, $pkg);
        ok($bumped, $pkg . ' (' . $filename . ') VERSION is ok'
            . ( $message ? (' (' . $message . ')') : '' )
        );
    }
}

done_testing;
