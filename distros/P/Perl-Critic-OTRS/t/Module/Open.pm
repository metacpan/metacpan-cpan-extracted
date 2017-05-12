package t::Module::Open;

use Data::Dumper;

# ABSTRACT: This module is a test module

sub test {
    my $Self = shift;

    open my $fh, '/tmp/test.tld' or die $!;
    close $fh;

    open( my $fh2, '<', '/tmp/text.tld' ) || die $!;
    close $fh2;

    CORE::open( my $fh3, '<', '/tmp/test.tld' ) or die $!;
    close $fh3;
}

1;
