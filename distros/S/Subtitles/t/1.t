# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More qw(no_plan);
BEGIN { use_ok('Subtitles') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Subtitles;

# 2: codecs
my @codecs = codecs;
ok( scalar @codecs);

# 3: object API
my $x = Subtitles->new();
ok($x);

push @{$x-> {from}}, 1;
push @{$x-> {to}}, 2;
push @{$x-> {text}}, 'hello';

push @{$x-> {from}}, 10;
push @{$x-> {to}}, 11;
push @{$x-> {text}}, 'world';

# 4: split
my ( $a1, $a2) = $x-> split( 5);
ok( $a1 && $a2 && $a1-> length == 2 && $a2-> length == 6);

# 5: join
$a1-> join( $a2, 0);
ok( $a1-> length == 8);

# etc, file write, file read
my $l = $x-> length;
for ( @codecs) {
   next if m/idx$/; # test separately

   if ( open F, ">test.sub") {
      $x-> codec( $_);
      ok( $x-> save(\*F));
      close F;
   } else {
      last;
   }

   # file read
   if ( open F, "<test.sub") {
      my $y = Subtitles-> new;
      ok( $y-> load(\*F));
      close F;
      ok ( abs($y-> length - $l) < 0.5);  
   }

   unlink 'test.sub';
}
