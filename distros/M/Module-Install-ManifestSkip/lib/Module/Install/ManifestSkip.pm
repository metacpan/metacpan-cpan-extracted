use strict; use warnings;
package Module::Install::ManifestSkip;
our $VERSION = '0.24';

use base 'Module::Install::Base';

our $AUTHOR_ONLY = 1;

my $skip_file = "MANIFEST.SKIP";

sub manifest_skip {
    my $self = shift;
    return unless $self->is_admin;

    require Module::Manifest::Skip;

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
