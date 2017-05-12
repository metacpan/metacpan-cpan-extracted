################################################################################
package Test::Formatter;
use Spoon::Formatter -Base;
const top_class => 'Test::Formatter::Top';
const class_prefix => 'Test::Formatter::';
const all_blocks => [qw(wafl_block)];
const all_phrases => [qw(wafl_phrase)];

sub formatter_classes { qw(Spoon::Formatter::WaflBlock Spoon::Formatter::WaflPhrase) }

################################################################################
package Test::Formatter::Top;
use base 'Spoon::Formatter::Container';
const formatter_id => 'top';
const contains_phrases => [qw(wafl_phrase)];
