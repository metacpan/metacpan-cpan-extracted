# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'
# fixed on-error bug
use strict;
use lib ('../lib', './lib');
use Test::More tests => 3;
BEGIN { use_ok('Petal::Tiny') };
package CGI;
sub new { bless {param=>{}}, $_[0] }
sub param {
  my ($self, $key, $val) = @_;
  return if @_ < 2;
  return $self->{param}{$key} if @_ < 3;
  $self->{param}{$key} = $val;
}

package MockObject;
sub cgi   { shift->{cgi} };
sub cli   { return { Result => 100 } }

package main;

my $mock = bless { cgi => CGI->new() }, "MockObject";
$mock->cgi()->param (pcode => 'dje');

my $data = join '', <DATA>;
my $t = Petal::Tiny->new ($data);
my $out = $t->process (self => $mock);
like ($out, qr /100/);
like ($out, qr /dje/);

__DATA__
<xml petal:on-error="string:foo" petal:define="pcode self/cgi/param --pcode; query self/cli --type pcode --count" petal:attributes="foo pcode" petal:content="query/Result">dfksd</xml>
