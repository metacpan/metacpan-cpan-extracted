package Serengeti::Util;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(trim);
our @EXPORT_OK = @EXPORT;

sub trim { 
    my $v = @_ ? pop : $_;
    $v =~ s/^\s*//;
    $v =~ s/\s*$//;
    $v;
}

1;
__END__