#!/usr/local/bin/perl -w

# extracting the POD docu of all pp2html options.
# store in a data structure for further usage.

#use Pod::Text;
use strict;

my $me = $0;
$me =~ s#.*/##;
$me =~ s#.*\\##;
my @DDD;
my @DOC;
my @all_opts;
my $optname;
my $start = 0;
my $collect_option_names = 1; # 
my $in_options_block = 0; # within the OPTIONS chapter
my $in_option_docu   = 0; # within the description of one or more options
my @OPT_NAMES = ();       # option names 
my @OPT_DOCU = ();        # docu for one or more options


while(<>){

  if (/^=head1\s+OPTIONS/){
    $in_options_block = 1;
    next;
  }
  next unless $in_options_block;

  if (/^=item --(\w+)(.*)/){
    $in_option_docu = 0;
    $optname=$1;
    my $rest = $2;
    $collect_option_names = 1;
    $start = 1;

    if (@OPT_DOCU){
      # we have a description for the PREVIOUS option:
     #print "\n";
      print_opts();
      print_pod();
      @OPT_NAMES = ();
      @OPT_DOCU = ();
    }

    push @OPT_NAMES, "$optname$rest";
    push @all_opts, "$optname$rest";
    next;
  }
  next unless $start;

  if (/^=cut/){
    $in_options_block = 0;
      print_opts();
      print_pod();
  }

  if (! /^=item --(\w+)/){  # we are in the options block and
    # have a line which is NOT an option item:
    # must be part of the description of an option!
    if ( $collect_option_names == 1 ){
      next if /^$/;
    }
    $in_option_docu = 1;
    $collect_option_names = 0;
  }

  if ($in_option_docu){
    push @OPT_DOCU, $_;
  }
}

print_header();

print @DDD;

#000000000000000000000000000

sub print_header {
  print<<EOT;

// vim: set filetype=pp2html:
//
// ATTENTION: File automatically created by $me
//            DO NOT EDIT, changes will be lost

EOT

  foreach my $opt (sort @all_opts){
    print <<EOT;
* \\XREF{name="--$opt"}<--$opt>

EOT
  }
}

#-----
sub print_opts {
  my $first = $OPT_NAMES[0];
  push @DDD, "\n\n==$first\n\n";
  foreach my $line (@OPT_NAMES){
   #print "--$line\n";
    push @DDD, "\n\\A{name=\"--$line\"}";
    push @DDD, "\\B<\\X<--$line>>\n\n";
  }
}
#-----
sub print_pod {

  my $col = 0;
  my $M = 70;
  foreach my $line (@OPT_DOCU){
    if ($line =~ /^ /)  {
     #print $line; # sample text
      push @DDD, $line; # sample text
    } else {
      if ($line =~ /^\s+$/){
       #print "\n\n";
        push @DDD, "\n\n";
        $col = 0;
      }
      # replace I<> B<> C<>
      while( $line =~ /I<.*?>/){
       #$line =~ s/I<(.*?)>/$1/;
        $line =~ s/I<(.*?)>/MKITALIC-<$1>/;
      }
      while( $line =~ /B<.*?>/){
       #$line =~ s/B<(.*?)>/$1/;
        $line =~ s/B<(.*?)>/MKBOLD-<$1>/;
      }
      while( $line =~ /C<.*?>/){
       #$line =~ s/C<(.*?)>/$1/;
        $line =~ s/C<(.*?)>/MKCODE-<$1>/;
      }
      $line =~ s/\\IMAGE/\\\\IMAGE/g;
      $line =~ s/E<gt>/>/g;
      $line =~ s/E<lt>/</g;
      $line =~ s/MKITALIC-/\\I/g;
      $line =~ s/MKBOLD-/\\B/g;
      $line =~ s/MKCODE-/\\C/g;
      chomp($line);
      my @words = split(" " , $line);
      while (@words){
        my $word = shift @words;
        if (length($word) + $col <= $M){
#         print "$word ";
          push @DDD, "$word ";
          $col += length("$word ");
        } else {
#         print "\n$word ";
          push @DDD, "\n$word ";
          $col = length("$word ");
        }
      }
    }

  }
}

