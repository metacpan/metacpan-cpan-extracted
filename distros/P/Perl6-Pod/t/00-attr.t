#===============================================================================
#
#  DESCRIPTION:  Test Attributes
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Test::To;
use strict;
use warnings;
use base 'Perl6::Pod::To';
sub __default_method {
    my $self   = shift;
    my $n      = shift;
    $self->{ $n->{name} }  = $n;
}

1;
package main;
use strict;
use warnings;
use Test::More tests => 3;                      # last test to print
use Data::Dumper;
use Perl6::Pod::Utl;


my $t1 = Perl6::Pod::Utl::parse_pod(<<TXT, default_pod=>1);
=for para :t1 :e<1 223 > :h{ er=>1, e2=>1}
TXT
is_deeply $t1->[0]->get_attr,{
          'e' => [
                   '1',
                   '223'
                 ],
          'h' => {
                   'e2' => '1',
                   'er' => '1'
                 },
          't1' => 1
        }, "get_attr";
$t1 = Perl6::Pod::Utl::parse_pod(<<TXT, default_pod=>1);
=config para :formatted<I>
=for para :t1 :e<1 223 > :h{ er=>1, e2=>1}
TXT

my $test = new Test::To::;
$test->write($t1);

is_deeply  $test->{para}->get_attr, {
          'e' => [
                   '1',
                   '223'
                 ],
          'formatted' => 'I',
          'h' => {
                   'e2' => '1',
                   'er' => '1'
                 },
          't1' => 1
        }, '=config para formatted';


my $t2 = Perl6::Pod::Utl::parse_pod(<<TXT, default_pod=>1);
=config head1 :formatted<B>
=config para :like<head1>
=for para :t1 :e<1 223 > :h{ er=>1, e2=>1}
TXT

my $test2 = new Test::To::;
$test2->write($t2);

is_deeply $test2->{para}->get_attr, {
          'e' => [
                   '1',
                   '223'
                 ],
          'formatted' => 'B',
          'h' => {
                   'e2' => '1',
                   'er' => '1'
                 },
          't1' => 1
        }, ':like attr';


