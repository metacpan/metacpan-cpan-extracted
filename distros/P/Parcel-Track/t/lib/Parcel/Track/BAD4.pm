package Parcel::Track::BAD4;

use Moo;

with 'Parcel::Track::Role::Base';

use vars qw{$VERSION};

BEGIN {
    $VERSION = '0.01';
}

sub BUILD {
    die "new dies as expected";
}

sub uri   { }
sub track { }

1;
