use strict; use warnings;
use PadWalker 'closed_over', 'set_closed_over';

print "1..30\n";

my $x=2;
my $h = closed_over (my $sub = sub {my $y = $x++});
my @keys = keys %$h;

print (@keys == 1 ? "ok 1\n" : "not ok 1\n");
print (${$h->{'$x'}} eq 2 ? "ok 2\n" : "not ok 2\n");

print ($sub->() == 2 ? "ok 3\n" : "not ok 3\n");
print ($sub->() == 3 ? "ok 4\n" : "not ok 4\n");

${$h->{"\$x"}} = 7;

print ($sub->() == 7 ? "ok 5\n" : "not ok 5\n");
print ($sub->() == 8 ? "ok 6\n" : "not ok 6\n");

{my $x = "hello";

sub foo {
  ++$x
}}

$h = closed_over(\&foo);
@keys = keys %$h;

print (@keys == 1 ? "ok 7\n" : "not ok 7\n");
print (${$h->{'$x'}} eq "hello" ? "ok 8\n" : "not ok 8 # $h->{'$x'} -> ${$h->{'$x'}}\n");

foo();
print (${$h->{'$x'}} eq "hellp" ? "ok 9\n" : "not ok 9 # $h->{'$x'} -> ${$h->{'$x'}}\n");

${$h->{'$x'}} = "phooey";
foo();
print (${$h->{'$x'}} eq "phooez" ? "ok 10\n" : "not ok 10 # $h->{'$x'} -> ${$h->{'$x'}}\n");

sub bar{
  bar(2) if !@_;
  my $m = 13 - (@_ && $_[0]);
  my $n = $m+1;

  $h = closed_over(\&bar);
  @keys = keys %$h;
  print (@keys == 2 ? "ok $m\n" : "not ok $m\n");
  print ($h->{'$h'} = \$h ? "ok $n\n" : "not ok $n\n");
  
  # Break the circular data structure:
  delete $h->{'$h'};
}
bar();

our $blah = 9;
no warnings 'misc';
my $blah = sub {$blah};
my ($vars, $indices) = closed_over($blah);
print (keys %$vars == 0 ? "ok 15\n" : "not ok 15\n");
print (keys %$indices == 0 ? "ok 16\n" : "not ok 16\n");


{
    my $x     = 1;
    my @foo   = ();
    my $other = 5;
    my $ref   = \"foo";
    my $h     = closed_over( my $sub = sub { my $y = $x++; push @foo, $y; $y } );

    my @keys = keys %$h;

    print( @keys == 2 ? "ok 17\n" : "not ok 17\n" );
    print( ${ $h->{'$x'} } eq 1 ? "ok 18\n" : "not ok 18\n" );

    print( $sub->() == 1 ? "ok 19\n" : "not ok 19\n" );

    set_closed_over( $sub, { '$x' => \$other } );

    print( $sub->() == 5 ? "ok 20\n" : "not ok 20\n" );

    print( $x == 2     ? "ok 21\n" : "not ok 21\n" );
    print( $other == 6 ? "ok 22\n" : "not ok 22\n" );

    print( @foo == 2 ? "ok 23\n" : "not ok 23\n" );

    print( $foo[0] == 1 ? "ok 24\n" : "not ok 24\n" );

    print( $foo[1] == 5 ? "ok 25\n" : "not ok 25\n" );

    my @other;

    set_closed_over( $sub, { '@foo' => \@other } );

    print( $sub->() == 6 ? "ok 26\n" : "not ok 26\n" );

    print( @other == 1 ? "ok 27\n" : "not ok 27\n" );

    eval { set_closed_over( $sub, { '@foo' => \"foo" } ) };

    print( $@ ? "ok 28\n" : "not ok 28\n" );

    # test that REF and SCALAR are interchangiable
    eval { set_closed_over( $sub, { '$x' => \$ref } ) };

    print( $@ ? "not ok 29\n" : "ok 29\n" );
}

$h = closed_over(\&utf8::encode);
print +(%$h == 0 ? "ok 30" : "not ok 30") . " - closed_over on XSUB\n";
