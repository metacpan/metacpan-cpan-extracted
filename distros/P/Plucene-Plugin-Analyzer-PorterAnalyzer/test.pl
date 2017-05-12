# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use IO::Scalar;
use_ok("Plucene::Plugin::Analyzer::PorterAnalyzer");

my @tests = (
    [ "testing the analyzer" => [qw(test the analyz)]],
   [ "U.S.A."                     => [ "u",   "s",   "a" ]],
    [ "C++"                        => ["c"] ], 
);

my $a = Plucene::Plugin::Analyzer::PorterAnalyzer->new;
for (@tests) {
    my ($input, $output) = @$_;
    my $stream = $a->tokenstream({
            field  => "dummy",
            reader => IO::Scalar->new(\$input) });
    my @data;
    push @data, $_->text while $_ = $stream->next;
    is_deeply(\@data, $output, "Analyzed $input");
}
