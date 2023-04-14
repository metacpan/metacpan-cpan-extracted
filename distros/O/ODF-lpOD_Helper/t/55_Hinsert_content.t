#!/usr/bin/perl

BEGIN {
  unless (($ENV{PERL_PERTURB_KEYS}//"") eq "2") {
    $ENV{PERL_PERTURB_KEYS} = "2"; # deterministic
    $ENV{PERL_HASH_SEED} = "0xDEADBEEF";
    #$ENV{PERL_HASH_SEED_DEBUG} = "1";
    exec $^X, $0, @ARGV; # for reproducible results
  }
}

use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug ok_with_lineno like_with_lineno
                    rawstr showstr showcontrols displaystr 
                    show_white show_empty_string
                    fmt_codestring 
                    timed_run
                    checkeq_literal check _check_end
                    $debug
                  /;

use Mydump qw/mydump/;

use ODF::lpOD;
use ODF::lpOD_Helper qw/:DEFAULT :chars fmt_node fmt_tree fmt_match/;

use File::Copy ();
use Guard qw/guard scope_guard/;

my $master_copy_path = "$Bin/../tlib/Skel.odt";

# Prevent any possibility of over-writing the input file
my $input_path = "./_TMP_".basename($master_copy_path);
my $input_path_remover = guard { unlink $input_path };
File::Copy::copy($master_copy_path, $input_path) or die "File::Copy $!";

my $doc = odf_get_document($input_path, read_only => 1);
my $body = $doc->get_body;
 
{
  my $count = 0;
  my $initial_vtext = $body->Hsearch("Front Stuff")->{paragraph}->get_text;
  my $prev_item = "Front Stuff";
  foreach (
           [["bold"], "NEW"],
           ["NEW"], ["NEW"], 
           ["\t"], ["NEW\t"], ["\tNEW"], ["NEW\t006"],
           ["\n"], ["NEW\n"], ["\nNEW"], ["NEW\n009"],
           [" "], ["NEW "], [" NEW"], ["NEW 009"],
           ["  "], ["NEW  "], ["  NEW"], ["NEW  009"],
           ["   "], ["NEW   "], ["   NEW"], ["NEW   009"],
           ["NEW \t\t\n   \n\n  "],
           [["italic"], "foobarNEWfoobar", " NEW foobar", [17], "17ptNEW", ["bold", 38], " 38ptNEW"],
          ) 
  { my $new_content = $_;
    foreach (@$new_content) { 
      s/NEW/sprintf("NEW%03d", $count++)/esg unless ref; 
    }
    my $m = $body->Hsearch($prev_item) // bug;
    my $para = $m->{paragraph};
    my $curr_vtext = $para->get_text;
    oops unless $initial_vtext 
      eq $curr_vtext =~ s/${prev_item}/Front Stuff/rs; # /r -> non-destructive
  
    note dvis 'BEFORE: $prev_item $new_content para:\n', fmt_tree($para)
      if $debug;
    
    $para->Hreplace(qr/\Q${prev_item}\E/, $new_content, debug => $debug);
  
    note "AFTER :\n", fmt_tree($para) if $debug;
  
    my $n_item = join("", grep{! ref} @$new_content);

    my $new_vtext = $para->get_text;
    oops unless $initial_vtext 
      eq $new_vtext =~ s/${n_item}/Front Stuff/rs; # /r -> non-destructive
    
    ok(1, "Hreplace ".vis($prev_item)." with ".vis($new_content));
      
    $prev_item = $n_item;
  }

  # Check replacing something with nothing
  { my $m = $body->Hsearch("foobar") // oops;
    my $para = $m->{paragraph};
    my $before_vtext = $para->get_text;
    oops unless $initial_vtext 
      eq $before_vtext =~ s/${prev_item}/Front Stuff/rs; # /r -> non-destructive
    $para->Hreplace("foobar", [], multi => 1); # I think multi is the default(?)
    my $after_vtext = $para->get_text;
    ok($after_vtext
        eq $before_vtext =~ s/foobar//gsr, "multi replace with []");
  }
    
}

# TODO: Write Hreplace tests covering all the corner cases in Hsearch.t
# (Idea: discard and re-read the doc before each test, possibly using
# an in-memory xml rep instead of re-reading from disk each time).

#my $output_path = "./_OUTPUT_".basename($master_copy_path);
#$doc->save(target => $output_path);

done_testing();

