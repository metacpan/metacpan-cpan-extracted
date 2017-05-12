use warnings;
use strict;

use Test::More tests => 26;

use vars qw/$BUFFER/;

use_ok 'String::BufferStack';

my $stack = String::BufferStack->new( out_method => sub { $BUFFER .= join("", @_) });
ok($stack, "Made an object");
isa_ok($stack, 'String::BufferStack');

$stack->append(q{<start elem="something"});
my $closed = 0;
$stack->push( pre_append => 
                  sub {
                      my $stack = shift;
                      $stack->set_pre_append(undef);
                      $closed = 1;
                      $stack->direct_append(">");
                  }
              );
$stack->append("Content!");
is($closed, 1);
$stack->pop;
is($stack->buffer, q{<start elem="something">Content!});
$stack->append($closed ? q{</start>} : q{ />}); 
is($stack->buffer, q{<start elem="something">Content!</start>});
$stack->clear;

$stack->append(q{<start elem="something"});
$closed = 0;
$stack->push( pre_append => 
                  sub {
                      my $stack = shift;
                      $stack->set_pre_append(undef);
                      $closed = 1;
                      $stack->direct_append(">");
                  }
              );
$stack->pop;
$stack->append($closed ? q{</start>} : q{ />}); 
is($stack->buffer, q{<start elem="something" />});
$stack->clear;

# Filters and pre_appends
$stack->append(q{<start elem="something"});
$closed = 0;
$stack->push( pre_append => 
                  sub {
                      my $stack = shift;
                      $stack->set_pre_append(undef);
                      $closed = 1;
                      $stack->direct_append(' hi="there">');
                  },
              filter => sub {
                  return uc shift;
              }
          );
$stack->append("Content!");
$stack->pop;
$stack->append($closed ? q{</start>} : q{ />}); 
is($stack->buffer, q{<start elem="something" hi="there">CONTENT!</start>});
$stack->clear;

# Multiple pre_appends for a single buffer
my $first = 0;
my $second = 0;
$stack->push( pre_append => sub { $first++ } );
$stack->append("Whee!");
is($first, 1, "First pre-append seen");
$stack->push( pre_append => sub { $second++ } );
$stack->append("More!");
is($first, 2, "First pre-append seen again");
is($second, 1, "Second pre-append seen as well");
$stack->pop;
$stack->append("Almost done!");
is($first, 3, "First pre-append seen yet again");
is($second, 1, "But not second");
$stack->pop;
$stack->append("Done!");
is($first, 3, "No change in first");
is($second, 1, "Nor second");
$stack->clear;

# Altering pre_appends mid-course
$first = $second = 0;
$stack->push( pre_append => sub {shift->set_pre_append(undef) if ++$first >= 3});
$stack->append("one");
is($first, 1, "First pre-append seen");
$stack->push( pre_append => sub {shift->set_pre_append(undef) if ++$second >= 3});
$stack->append("two");
is($first, 2, "First pre-append seen again");
is($second, 1, "Second pre-append seen as well");
$stack->append("three");
is($first, 3, "First hits again!");
is($second, 2, "Second as well");
$stack->append("four");
is($first, 3, "First is done");
is($second, 3, "Second still going strong");
$stack->append("five");
is($first, 3, "First is done");
is($second, 3, "Second is also done");
$stack->pop;
$stack->append("popped");
is($first, 3, "First is still done");
is($second, 3, "Second is also done");
$stack->pop;
