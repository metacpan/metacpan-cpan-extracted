package Net::SSH::Any::Test::Isolated::Util;

use strict;
use warnings;
use feature qw(say);
use Carp;

use Data::Dumper;
use Exporter;
our @EXPORT = qw(_serialize);

sub _serialize {
    my $dump = Data::Dumper->new([@_], ['DATA']);
    $dump->Terse(1)->Purity(1)->Indent(0)->Useqq(1);
    return $dump->Dump;
}
