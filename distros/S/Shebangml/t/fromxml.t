#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use Shebangml::FromXML;

sub mk_expect {
  my $data = shift;
  open(my $fh, '<', \$data);

  my @outs;
  my $test;
  my $current = '';
  my $store = sub {
    my ($where) = @_;
    $current =~ s/^\s+//;
    $current =~ s/\s+$//;
    $test->{$where} = $current;
    $current = ''
  };
  while(my $line = <$fh>) {
    if($line =~ m/^\s+=== */) {
      if($test) {
        $store->('want');
      }
      $test = {};
      push(@outs, $test);
    }
    elsif($line eq "  ---\n") {
      $store->('input');
    }
    else {
      $current .= $line;
    }
  }
  $store->('want');

  return(@outs);
}

my @expect = mk_expect(<<'EXPECT');
  ===
    <p>foo</p>
  ---
    p{foo}
  ===
    <p>bar <img src="baz" /> </p>
  ---
    p{bar img[src="baz"] }
  ===
    <p>bar <img src="baz" /></p>
  ---
    p{bar img[src="baz"]}
  ===
    <p>bar<img src="baz" /></p>
  ---
    p{bar\img[src="baz"]}
  ===
    <p>bar\<img src="baz" /></p>
  ---
    p{bar\\img[src="baz"]}
  ===
    <p>bar\ <img src="baz" /></p>
  ---
    p{bar\\ img[src="baz"]}
  ===
    <p>bar <img src="baz" /></p>
  ---
    p{bar img[src="baz"]}
  ===
    <thing></thing>
  ---
    thing{}
  ===
    <thing />
  ---
    thing[]
  ===
    <thing><deal /></thing>
  ---
    thing{deal[]}
  ===
    <thing><deal></deal></thing>
  ---
    thing{deal{}}
  ===
    <this>&amp; &lt;></this>
  ---
    this{& <>}
  ===
    <br/>
  ---
    \n;
  ===
    <foo><br /></foo>
  ---
    foo{\n;}
EXPECT

foreach my $test (@expect) {
  my $parser = Shebangml::FromXML->new;
  $parser->parse($test->{input});
  my $parsed = join('', $parser->output);
  is($parsed, $test->{want}) or die "failed $test->{input}";
}

# vim:ts=2:sw=2:et:sta
