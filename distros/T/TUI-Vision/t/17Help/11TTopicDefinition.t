use strict;
use warnings;

use Test::More;
use Scalar::Util qw( weaken );

BEGIN {
  use_ok 'TUI::Help::TopicDefinition';
}

my $definition = new_TTopicDefinition( 'Introduction', 100 );
is( $definition->topic, 'Introduction', 'stores the topic name' );
is( $definition->value, 100, 'stores the numeric value' );
ok( !defined $definition->next, 'new definition has no successor' );

my $next = new_TTopicDefinition( 'Details', 101 );
$definition->next( $next );
is( $definition->next->topic, 'Details', 'links to the next definition' );

weaken( $next );
undef $definition;
ok( !defined $next, 'releasing the head also releases the owned successor' );

done_testing();
