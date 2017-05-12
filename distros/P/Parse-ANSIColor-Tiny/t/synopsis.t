use strict;
use warnings;
use Test::More 0.96;
use File::Spec (); # core

  my $pm = File::Spec->catfile(qw(lib Parse ANSIColor Tiny.pm));
  -e $pm or die "Cannot find module file '$pm'";
  require $pm;

  open  my $fh, '<', $pm
    or die "Failed to open '$pm': $!";

  # incredibly basic pod parser
  my $in_synopsis = 0;
  my $pod = '';
  while( <$fh> ){
    if( /^=for test_synopsis(.*)/ ){
      my $prep = $1;
      while( my $ts = <$fh> ){
        last if $ts =~ /^$/;
        $prep .= $ts;
      }
      $pod = $prep . "\n" . $pod;
    }
    elsif( /^=head1 SYNOPSIS/ ){
      $in_synopsis = 1;
    }
    elsif( $in_synopsis && /^=\w+/ ){
      $in_synopsis = 0;
    }
    elsif( $in_synopsis ){
      $pod .= $_;
    }
  }

  eval $pod;
  die $@ if $@;

done_testing;
