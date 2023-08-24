# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and 
# related or neighboring rights to the content of this file.  
# Attribution is requested but is not required.
package Mydump;

use ODF::lpOD_Helper;
use t_Common qw/oops/; # strict, warnings, Carp, utf8 etc.
use strict; use warnings  FATAL => 'all'; 
use feature qw/say state current_sub/;

require Exporter;
use parent 'Exporter';
our @EXPORT = qw/mydump/;

sub mydump_old($;@) {
  my ($top, @args) = @_;
  my $msg = "";
  my $off = 0;
  my @paragraphs = $top->descendants_or_self(qr/text:(p|h)/);
  foreach my $para (@paragraphs) {
    my $pmsg = "";
    my $pilcrow = "¶";
    foreach my $seg ($para->descendants_or_self(
                       qr/^(#PCDATA|text:tab|text:line-break|text:s)$/)) {
      #local $_ = $seg->get_text();
      local $_ = ODF::lpOD_Helper::__leaf2vtext($seg);
      while (/\G[^\n]*\n/gsc || /\G[^\n]+/gsc) {
        my $len = length($&);
        my $s = $&;
        $s =~ s/\t/\\t/g;
        $s =~ s/\n/\\n/g;
        $pmsg .= sprintf " %d:", $off;
        $pmsg .= $pilcrow; $pilcrow = "";
        $pmsg .= "[$s]";
        $pmsg .= "\n" if substr($s,-2) eq "\\n";
        $off += $len;
      }
    }
    #$pmsg .= "(no newline)" unless substr($pmsg,-2) eq "\\n";
    if ($pmsg) {
      $msg .= $pilcrow.$pmsg."\n";
    } else {
      $msg .= $pilcrow."[empty paragraph]\n";
    }
  }
  $msg
}
sub mydump_new($;@) {
  my ($top, @args) = @_;
  my $show_addrs = grep /addr/, @args;
  my $msg = "";
  my $off = 0;
  my $level_discount;
  my sub append($$) {
    my ($e, $start_flag) = @_;
    my sub wrap($) {
      my $e = shift;
      $msg .= "\n" if $msg;
      $msg .= ("  " x ($e->level - $level_discount));
    }
    my $tag = $e->get_tag;
    if ($e->is_elt) {  # a "real" element (not text)
      my $show;
      if ($tag =~ /^text:[ph]$/) {
        $start_flag = 'p';
        $show = 1;
        wrap($e);
      }
      elsif ($tag =~ /^(?:text:tab|text:line-break)$/) {
        $off += 1;
        $show = 1;
      }
      elsif ($tag eq 'text:s') {
        my $c = $e->att("text:c") // 1;
        $off += $c;
        $show = 1;
      }
      elsif ($tag eq "text:span") {
        $start_flag = 's';
        $show = 1;
        wrap($e);
      }
      else {
        oops if $tag =~ /CDATA/;
      }
      if ($show) {
        $msg .= addrvis(refaddr $e) if $show_addrs;
        $msg .= "<".($e->gi);
        if (my @atts = $e->att_names) {
          $msg .= ' '.join(' ', map { 
                                      (my $name = $_) =~ s/^text://;
                                      $name.'="'.$e->att($_).'"' 
                                    } @atts);
        }
        $msg .= ">";
        $msg .= "\n" if $tag eq 'text:line-break';
      }
      for (my $c=$e->first_child; $c; $c=$c->next_sibling) {
        __SUB__->($c, $start_flag);
        $start_flag = '';
      }
    }
    elsif ($tag eq '#PCDATA') {
      local $_ = $e->get_text;
      wrap($e) if $start_flag;
      $msg .= " " if substr($msg,-1) ne "\n";
      $msg .= sprintf "%d:", $off;
      $off += length($_);
      $msg .= "¶" if $start_flag eq "p";
      s/\t/\\t/g; s/\n/\\n\n/g;
      $msg .= "[$_]";
    } else {
      $msg .= "\n<??? $tag ???>";
    }
  }
  $level_discount = $top->level;
  append($top, '');
  $msg
}
sub mydump_twig_dump($;@) {
  my $top = shift;
  "(XML::Twig::_dump)\n" .  XML::Twig::_dump($top, {short_text => 240})
}
sub mydump_twig_print($;@) {
  my $top = shift;
  my $pretty = $_[0] // "wrapped";
  my $doc = $top->document // die "doc oops";

  # Necessary so wide chars come through as Perl chars
  my $saved_output_filter = XML::Twig::output_filter();
  XML::Twig::set_output_filter(undef);
  # Not sure why set_output_text_filter() isn't what should be used here

#  # Derived from ODF::lpOD::Document
#  foreach my $part_name ($doc->loaded_xmlparts) {
#    next unless $part_name;
#    my $part = $doc->{$part_name}  or next;
#    #my $twig = $part->{twig} // die "twig oops";
#    #$twig->output_encoding(undef);
#    #$twig->set_pretty_print($pretty);
#  }

  my $result = "(XML::Twig sprint method)\n" 
               . $top->sprint({PrettyPrint => $pretty});

  XML::Twig::set_output_filter( $saved_output_filter );
  $result
}
sub mydump_fmt_tree($;@) {
  my $top = shift;
  fmt_tree($top); # starts with characteristic "--------" separator
}

our $DumpKind = 5;  # the default

# Return a dump of an object tree
sub mydump($;$@) {
  my ($obj, $opts, @other_args) = @_;
  $opts //= {};
  croak "opts must be a {hashref}" unless ref($opts) eq "HASH";
  croak "return_only is no longer an option" if $opts->{return_only};
  my $kind = $opts->{dump_kind} // $opts->{kind} // $DumpKind // oops;
  my $num = $kind;
  $num =~ s/^old.*/1/i;
  $num =~ s/^new.*/2/i;
  $num =~ s/^t\w*dump.*/3/i;  # e.g. twigdump
  $num =~ s/^t\w*print.*/5/i;

  state $num2funcname = {
    1 => "mydump_old",
    2 => "mydump_new",
    3 => "mydump_twig_dump",
    4 => "mydump_twig_print",
    5 => "mydump_fmt_tree",
  };
  my $funcname = $num2funcname->{$num} // do{
    die "mydump: Unknown kind '${kind}'\n",
        join("\n", map{ "  $_ -> ".$num2funcname->{$_} } 
                   sort {$a <=> $b} keys %$num2funcname
            ), "\n";
  };

  no strict 'refs';
  my $result = "=== $funcname ===\n". &{$funcname}($obj, @other_args);

  $result;
}

1;
