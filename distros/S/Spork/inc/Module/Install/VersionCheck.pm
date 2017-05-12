#line 1
##
# name:      Module::Install::VersionCheck
# abstract:  Show Author the Current Versions
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Module::Install::VersionCheck;
use 5.008003;
use strict;
use warnings;

use Module::Install::Base;
use base 'Module::Install::Base';

our $VERSION = '0.14';
our $AUTHOR_ONLY = 1;

my $DEFAULT = '0.00';

sub version_check {
    my $self = shift;
    return unless $self->is_admin;

    my $module_version = $self->_get_module_version();
    my $changes_version = $self->_get_changes_version();
    my $git_tag_version = $self->_get_git_tag_version();

    $self->_report(
        $module_version,
        $changes_version,
        $git_tag_version,
    );
}

sub _get_module_version {
    my $self = shift;
    return $DEFAULT unless $self->admin->{extensions};
    my ($metadata) = grep {
        ref($_) eq 'Module::Install::Metadata';
    } @{$self->admin->{extensions}};
    return $DEFAULT unless $metadata;
    return $metadata->{values}{version} || $DEFAULT;
}

sub _get_changes_version {
    my $self = shift;
    return $DEFAULT unless -e 'Changes';
    open IN, 'Changes' or die "Can't open 'Changes' for input: $!";
    my $text = do {local $/; <IN>};
    $text =~ /\b(\d\.\d\d)\b/ or return $DEFAULT;
    return $1;
}

sub _get_git_tag_version {
    my $self = shift;
    return $DEFAULT unless -e '.git';
    require Capture::Tiny;
    my $text = Capture::Tiny::capture_merged(sub { system('git tag') });
    my $version = $DEFAULT;
    for (split "\n", $text) {
        if (/\b(\d\.\d\d)\b/ and $1 > $version) {
            $version = $1;
        }
    }
    return $version;
}

sub _report {
    my $self = shift;
    print "version_check @_\n";
}

1;

