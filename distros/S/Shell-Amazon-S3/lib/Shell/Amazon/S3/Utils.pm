package Shell::Amazon::S3::Utils;
use strict;
use warnings;

sub classsuffix {
    my ( $class, $class_name ) = @_;
    my @parts = split '::', lc $class_name;
    my $suffix = pop @parts;
    return $suffix;
}

1;
