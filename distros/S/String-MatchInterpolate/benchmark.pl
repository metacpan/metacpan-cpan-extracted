#!/usr/bin/perl -w

use strict;

use Benchmark qw( :hireswallclock :all );

use String::MatchInterpolate;

my $count = -3;

my $template = 'My name is ${NAME/\w+/}';
my $smi = String::MatchInterpolate->new( $template );

my $var = { NAME => "Bob" };

my $target = "My name is Bob";

print "\nComparing 'interpolate':\n\n";

cmpthese( $count,
   {
      's///' => sub {
         my $str = $template;
         $str =~ s#\${(.+?)/.*?/}#$var->{$1}#g;
         $str eq $target or die;
      },

      'S::MI' => sub {
         my $str = $smi->interpolate( $var );
         $str eq $target or die;
      },

      'native' => sub {
         my $str = "My name is " . $var->{NAME};
         $str eq $target or die;
      },
   }
);

print "\nComparing 'match':\n\n";

cmpthese( $count,
   {
      'm//' => sub {
         my @varnames = $template =~ m#\${(.+?)/.*?/}#g;
         ( my $re = $template ) =~ s#\${.+?/(.*?)/}#($1)#g;
         my %vars;
         @vars{@varnames} = $target =~ m/^$re$/;
         $vars{NAME} eq $var->{NAME} or die;
      },

      'S::MI' => sub {
         my $vars = $smi->match( $target );
         $vars->{NAME} eq $var->{NAME} or die;
      },

      'native' => sub {
         $target =~ m/^My name is (\w+)$/ or die;
         my %vars = ( NAME => $1 );
         $vars{NAME} eq $var->{NAME} or die;
      },
   }
);
