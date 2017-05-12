
use strict;
use warnings;
use blib;
use Term::Spinner;
use Term::MultiSpinner;

print STDERR "Single: ";
{
    my $spinner = Term::Spinner->new( clear_on_destruct => 0 );
    for my $i (1..30) {
        $spinner->advance();
        select(undef, undef, undef, 0.1);
    }
}
print STDERR "\n";
sleep(1);

print STDERR "Factor of Ten: ";

{
    my $spinner = Term::MultiSpinner->new( clear_on_destruct => 0 );

    for my $i (1..50) {
        $spinner->advance(1);
        $spinner->advance(0) if not $i % 10;
        select(undef, undef, undef, 0.1);
    }
}
print STDERR "\n";
sleep(1);

print STDERR "Rolling Finish: ";
{
    my $spinner = Term::MultiSpinner->new( clear_on_destruct => 0 );

    for my $i (1..50) {
        if(not $i % 10) {
            $spinner->finish(($i/10)-1);
        }
        if($i < 50) {
         $spinner->advance(4);
         if($i < 40) {
          $spinner->advance(3);
          if($i < 30) {
           $spinner->advance(2);
           if($i < 20) {
            $spinner->advance(1);
            if($i < 10) {
             $spinner->advance(0);
            }
           }
          }
         }
        }
        select(undef, undef, undef, 0.1);
    }
}
print STDERR "\n";
sleep(1);

print STDERR "Randomized Rolling Finish: ";
{
    my $spinner = Term::MultiSpinner->new( clear_on_destruct => 0 );
    my $map = [7,5,2,9,6,1,4,0,8,3];

    for my $i (1..100) {
        if(not $i % 10) {
            $spinner->finish($map->[($i/10)-1]);
        }
        if($i < 100) {
         $spinner->advance($map->[9]) if int(rand(3));
         if($i < 90) {
          $spinner->advance($map->[8]) if int(rand(3));
          if($i < 80) {
           $spinner->advance($map->[7]) if int(rand(3));
           if($i < 70) {
            $spinner->advance($map->[6]) if int(rand(3));
            if($i < 60) {
             $spinner->advance($map->[5]) if int(rand(3));
             if($i < 50) {
              $spinner->advance($map->[4]) if int(rand(3));
              if($i < 40) {
               $spinner->advance($map->[3]) if int(rand(3));
               if($i < 30) {
                $spinner->advance($map->[2]) if int(rand(3));
                if($i < 20) {
                 $spinner->advance($map->[1]) if int(rand(3));
                 if($i < 10) {
                  $spinner->advance($map->[0]) if int(rand(3));
                 }
                }
               }
              }
             }
            }
           }
          }
         }
        }
        select(undef, undef, undef, 0.1);
    }
}
print STDERR "\n";

print STDERR "a through f: ";

{
    my $spinner = Term::MultiSpinner->new(
        spin_chars => [qw/a b c d e f/],
        clear_on_destruct => 0
    );

    for my $i (1..25) {
        $spinner->advance(1);
        $spinner->advance(0) if not $i % 5;
        select(undef, undef, undef, 0.1);
    }
}
print STDERR "\n";
sleep(1);

