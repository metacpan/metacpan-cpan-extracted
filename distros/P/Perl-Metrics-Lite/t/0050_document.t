use strict;
use warnings;
use File::Spec qw();
use FindBin qw($Bin);
use lib "$Bin/lib";
use Perl::Metrics::Lite::Analysis::DocumentFactory;
use Test::More;

Readonly::Scalar my $TEST_DIRECTORY => "$Bin/test_files";

subtest create_normalized_document => sub {
    my $path = File::Spec->join( $TEST_DIRECTORY, 'subs_no_package.pl' );
    my $document = Perl::Metrics::Lite::Analysis::DocumentFactory
        ->create_normalized_document( $path );

    my $sub_elements = $document->find('PPI::Statement::Sub');
    is($sub_elements->[0]->name, 'foo');
    is($sub_elements->[0]->line_number, 17);

    done_testing;
};

done_testing;
