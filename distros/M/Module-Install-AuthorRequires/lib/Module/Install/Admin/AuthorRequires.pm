use strict;
use warnings;

package Module::Install::Admin::AuthorRequires;

use base 'Module::Install::Base';

# cargo cult
BEGIN {
    our $VERSION = '0.02';
    our $ISCORE  = 1;
}

sub author_requires {
    my $self = shift;

    my @err;
    for my $dep (@_) {
        my ($mod, $ver) = @{ $dep };
        push @err, "Can't find author dependency ${mod}" . ($ver ? " version ${ver}" : '')
            unless $self->can_use($mod => $ver);
    }

    die join "\n" => @err if @err;
}

1;
