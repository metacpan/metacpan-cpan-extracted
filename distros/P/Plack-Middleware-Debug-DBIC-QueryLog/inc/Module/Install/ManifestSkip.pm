#line 1
##
# name:      Module::Install::ManifestSkip
# abstract:  Generate a MANIFEST.SKIP file
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011
# see:
# - Module::Manifest::Skip

package Module::Install::ManifestSkip;
use 5.008001;
use strict;
use warnings;

use base 'Module::Install::Base';

my $requires = "
use Module::Manifest::Skip 0.10 ();
";

our $VERSION = '0.20';
our $AUTHOR_ONLY = 1;

my $skip_file = "MANIFEST.SKIP";

sub manifest_skip {
    my $self = shift;
    return unless $self->is_admin;

    eval $requires; die $@ if $@;

    print "Writing $skip_file\n";

    open OUT, '>', $skip_file
        or die "Can't open $skip_file for output: $!";;

    print OUT Module::Manifest::Skip->new->text;

    close OUT;

    $self->clean_files('MANIFEST');
    $self->clean_files($skip_file)
        if grep /^clean$/, @_;
}

1;

