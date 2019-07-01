use strict;
use warnings;
use v5.22;

my $hi = Hello->new(memory => []);
$hi->memorize('Hi, how are you?');
$hi->say();

# slick way of OO:
# http://blogs.perl.org/users/yuki_kimoto/2019/01/bless-is-good-parts-of-perl-language.html
package Hello;

sub new {
  my $self = shift;
  bless {@_}, $self;
}

sub memorize { push @{shift->{memory}}, shift }
sub say { say join '. ', @{shift->{memory}} }
