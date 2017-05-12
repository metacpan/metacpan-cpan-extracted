use Test::More;
use PPI;
use Data::Dumper;
use Pod::Weaver;
use lib qw(t/inc);

# Make some 'test' documents..
my $doc = new_ok( 'PPI::Document', ['t/inc/Tester.pm']);
my $weaver;
ok( $weaver = Pod::Weaver->new_from_config({ root => 't'}) );
ok( my $document = $weaver->weave_document({
   ppi_document => $doc,
   mopper => { },
   authors => ['Bob MctestAthor']
}), 'Weaving document..');

my $expected = <<HERE;
=pod

=head1 NAME

Tester

=head1 ATTRIBUTES

=head2 testattr1

Reader: testattr1

Writer: testattr1

Type: Str

=head2 testattr2

Reader: testattr2

Type: Num

Additional documentation: This is a documentation option test.  It is a string.  With some L<links>

=head1 METHODS

=head2 method1

Method originates in Tester.

=head2 testattr1

Method originates in Tester.

=head2 testattr2

Method originates in Tester.

=head1 AUTHOR

Bob MctestAthor

=cut
HERE

is( $document->as_pod_string, $expected, 'Did it work?');

done_testing;
