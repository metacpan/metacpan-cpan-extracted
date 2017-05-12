package TOML::Dumper::Name;
use strict;
use warnings;

use subs qw/join format/;

sub join { CORE::join '.', map { &format($_) } @_ }

sub format {
    my $name = shift;
    return $name if $name =~ /^[A-Za-z0-9_-]+$/;
    $name =~ s/\"/\\\"/;
    return qq{"$name"};
}

1;
__END__
