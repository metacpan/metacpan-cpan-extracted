use strict;
use warnings;
use English qw(-no_match_vars);
use FindBin qw($Bin);
use lib "$Bin/lib";
use PPI;
use PPI::Document;
use Readonly;
use Test::More;
use Perl::Metrics::Lite::Analysis::Util;

Readonly::Scalar my $TEST_DIRECTORY => "$Bin/test_files";
Readonly::Scalar my $EMPTY_STRING   => q{};

subtest "get_node_length" => sub {
    my $test_file        = "$TEST_DIRECTORY/not_a_perl_file";
    my $one_line_of_code = q{print "Hello world\n";};
    my $one_line_node    = PPI::Document->new( \$one_line_of_code );
    is( Perl::Metrics::Lite::Analysis::Util::get_node_length($one_line_node),
        1, 'get_node_length for one line of code.'
    );

    my $four_lines_of_code = <<'EOS';
    use Foo;
    my $object = Foo->new;
    # This is a comment.
    my $result = $object->calculate();
    return $result;
EOS
    my $four_line_node = PPI::Document->new( \$four_lines_of_code );
    is( Perl::Metrics::Lite::Analysis::Util::get_node_length($four_line_node),
        4,
        'get_node_length for 4 lines of code.'
    ) || diag $four_lines_of_code;

    done_testing;
};

done_testing;
