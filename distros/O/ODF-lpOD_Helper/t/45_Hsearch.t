#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug tmpcopy_if_writeable $debug/;

# TO SEE OFFSETS, ETC.
#    run bin/dumpodf -o showoff=1 tlib/Skel.odt
# or call  say fmt_tree($body)

use ODF::lpOD;
use ODF::lpOD_Helper qw/:DEFAULT PARA_FILTER/;

my $master_copy_path = "$Bin/../tlib/Skel.odt";
my $input_path = tmpcopy_if_writeable($master_copy_path);
my $doc = odf_get_document($input_path, read_only => 1);
my $body = $doc->get_body;

my $para0 = $body->next_elt($body, qr/^text:[ph]$/) // oops;
my $leaf0 = $body->next_elt($body, '#TEXT') // oops;

my $alltext = $body->Hget_text();
my @all_paras = $body->descendants(qr/^text:[ph]$/);
my @para_text_lengths = map{ my $t = $_->get_text();
                             defined($t) ? length($t) : undef } @all_paras;
my @paras_with_text = @all_paras[ grep{defined $para_text_lengths[$_]}
                                  0..$#all_paras ];

say "body=",fmt_tree($body) if $debug;

# The first segment of the first paragraph contains "Front Stuff "
foreach ([$body,"body"], [$para0,"para0"], [$leaf0,"leaf0"]) {
  my ($context, $context_desc) = @$_;
  foreach ([qr/Front/s, "regex"],
           [qr/^Front/s, "^anchored regex"],
           [qr/\AFront/s, "\\Aanchored regex"],
           ['Front', "plain string"],
          ) {
    my ($expr, $expr_desc) = @$_;
    is( $context->Hsearch($expr),
      hash {
        field segments => array{ item 1 => DNE };
        field offset  => 0;
        field end     => 5;
        field voffset => 0;
        field vend    => 5;
        etc();
      },
      "${context_desc}->Hsearch($expr_desc) matches start"
    );
  }
  foreach ([qr/Stuff/s, "regex", 1],
           [qr/^Stuff/s, "^anchored regex", 0],
           [qr/\AStuff/s, "\\Aanchored regex", 0],
           ['Stuff', "plain string", 1],
          ) {
    my ($expr, $expr_desc, $should_succeed) = @$_;
    if ($should_succeed) {
      is($context->Hsearch($expr),
          hash {
            field segments => array{ item 1 => DNE };
            field offset  => 6; field end  => 11;
            field voffset => 6; field vend => 11;
            etc();
          },
          "${context_desc}->Hsearch($expr_desc) matches middle"
      );
    } else {
      is( $context->Hsearch($expr), undef,
          "${context_desc}->Hsearch($expr_desc) for middle fails as expected" );
    }
  }
}

is( $body->Hsearch(qr/Front Stuff /s),
    hash {
      field segments => array{ item 1 => DNE };
      field offset  => 0; field end  => 12;
      field voffset => 0; field vend => 12;
      etc();
    },
    "Hsearch match entire first segment"
);

is( $body->Hsearch(qr/Front Stuff o/s, debug => 0),
    hash {
      field segments => array{ item 2 => DNE };
      field offset  => 0; field end  => 1;
      field voffset => 0; field vend => 13;
      etc();
    },
    "Hsearch match first segment + start of second"
);

is( $body->Hsearch(qr/utside/s),
    hash {
      field segments => array{ item 1 => DNE };
      field offset  => 1;  field end  => 7;
      field voffset => 13; field vend => 19;
      etc();
    },
    "Hsearch match middle of second segment"
);

is( $body->Hsearch(qr/outside the 2-column Section/s),
    hash {
      field segments => array{ item 1 => DNE };
      field offset  => 0;  field end  => 28;
      field voffset => 12; field vend => 40;
      etc();
    },
    "Hsearch match entire second segment",
);

is( $body->Hsearch(qr/^outside/s, debug => 0), undef,
    "Hsearch ^anchored match start of second seg fails");

is( $body->Hsearch('o'),
    hash {
      field segments => array{ item 1 => DNE };
      field offset  => 2; field end  => 3;
      field voffset => 2; field vend => 3;
      etc();
    },
    "Hsearch first 'o' (string)",
);

is( $body->Hsearch(qr/o/),
    hash {
      field segments => array{ item 1 => DNE };
      field offset  => 2; field end  => 3;
      field voffset => 2; field vend => 3;
      etc();
    },
    "Hsearch first 'o' (regex)",
);

is( $body->Hsearch(qr/o.*o/),
    hash {
      field segments => array{ item 2 => DNE };
      field offset  => 2; field end  => 27;
      field voffset => 2; field vend => 39;
      etc();
    },
    "Hsearch longest match across mult segs ('o.*o')",
);

is( $body->Hsearch(qr/^Lorem.*another/s, debug => 0),
    hash {
      field segments => array{ item 11 => DNE };
      field offset  => 0;  field end  => 7;
      field voffset => 76; field vend => 168;
      etc();
    },
    "Hsearch match past one newline",
);

is( $body->Hsearch(qr/^Lorem.*laborum\./s),
    hash {
      field segments => array{ item 33 => DNE };
      field offset  => 0;  field end  => 305;
      field voffset => 76; field vend => 708;
      etc();
    },
    "Hsearch match past multiple newlines",
);


#####################

is( $body->Hsearch(qr/5 consecutive-spaces:/),
    hash {
      field segments => array{ item 2 => DNE };
      field offset  => 0;  field end  => 19;
      field voffset => 91; field vend => 112;
      etc();
    },
    "Hsearch until just b4 space b4 multi-space",
);
is( $body->Hsearch(qr/5 consecutive-spaces: /),
    hash {
      field segments => array{ item 2 => DNE };
      field offset  => 0;  field end  => 20;
      field voffset => 91; field vend => 113;
      etc();
    },
    "Hsearch until just b4 multi-space",
);
for my $n (1..6) {
  my $regex_src = '5 consecutive-spaces: '.(" " x $n);
  if ($n < 5) {
    is( $body->Hsearch(qr/$regex_src/, debug => 0),
        hash {
          field segments => array{ item 3 => DNE };
          field offset  => 0;  field end  => $n;
          field voffset => 91; field vend => 113+$n;
          etc();
        },
        "Hsearch including $n of multi-space",
    );
  } else {
    is( $body->Hsearch(qr/$regex_src/, debug => 0), undef,
        "Hsearch beyond end of multi-space ($n total)" );
  }
}

#####################

{
  my $tab_match;
  is( $tab_match = $body->Hsearch(qr/\t/),
      hash {
        field match => "\t"; field offset=>0; field end=>1;
        etc();
      },
      "Hsearch for tab alone",
  );
  is( $body->Hsearch(qr/tab here:\t/),
      hash{
        field match => "tab here:\t";
        field offset=>0; field end=>1;
        field voffset => $tab_match->{voffset}-9;
        field vend    => $tab_match->{voffset}+1;
        etc;
      },
      "Hsearch for stuff+tab"
  );

  is( $body->Hsearch(qr/tab here:\t:there/),
      hash{
        field match => "tab here:\t:there";
        field offset=>0; field end=>6;
        field voffset => $tab_match->{voffset}-9;
        field vend    => $tab_match->{voffset}+1+6;
        etc;
      },
      "Hsearch for stuff+tab+stuff"
  );

  is( $body->Hsearch(qr/\t:there/),
      hash{
        field match => "\t:there";
        field offset=>0; field end=>6;
        field voffset => $tab_match->{voffset};
        field vend    => $tab_match->{voffset}+1+6;
        etc;
      },
      "Hsearch for tab+stuff"
  );
}

#####################

is( $body->Hsearch(qr/.*Unicode .*/s),
    hash{
      field offset=>0; field voffset=>758;
      field match => "This «Paragraph» has ☺Unicode and bold\t<tabthere and     multi-space and italic and underlined and larger text.";
      etc;
    },
    "Hsearch match variety para"
);

#####################

{ # Null matches
  my @matches = $para0->Hsearch(qr//, multi => TRUE, debug => 0);
  my $t = join("", map{$_->{match}} @matches);
  is ($t, "", "Hsearch(qr//) produces only null matches", dvis '@matches');
  my $off = 0;
  foreach my $m (@matches) {
    fail("Unexpected voffset") unless $m->{voffset} == $off;
    fail("Unexpected vend")    unless $m->{vend}    == $off;
    $off++
  }
}
{ # Maximal matches
  my @matches = $body->Hsearch(qr/.*/s, multi => TRUE, debug => 0);
  my $t = join("", map{$_->{match}} @matches);
  is ($t, $alltext, "Hsearch(qr/.*/s) matches body->Hget_text",
      dvis '@matches');
  fail("Unexpected number of matches\n".do{
    my $s = scalar(@matches)." matches, ".scalar(@paras_with_text)." neparas.\n";
    $s .= "MATCHES:\n".join("\n", map{"    ".vis $_->{match}} @matches)."\n";
    $s .= "PARAS:\n".join("\n", map{"    ".fmt_node_brief($_,wrapindent=>4)} @paras_with_text)."\n";
    $s
  })
    unless @matches == @paras_with_text;
}

# Ground truth check that correct content is being retrieved
# The Skel.txt file is the result of "save as text" which inserts
# \n between paragraphs.
{ my sub smashwhite($) { $_[0] =~ s/[ \t\n\N{NO-BREAK SPACE}]+/ /gsr }
  (my $input_txt = $master_copy_path) =~ s/\.o..$/.txt/ or bug;
  my $Skeldottxt = path($input_txt)->slurp_utf8;

  # Insert newline after each paragraph sub-text to match Skel.txt
  # FIXME: Why doesnt this get "use of uninitialized value... in join" ???
  my @paras = $body->descendants(qr/^text:[ph]$/);
  my $text2 = join("\n", map{$_->Hget_text(prune_cond => PARA_FILTER)}
                         @paras_with_text)."\n";
  is(smashwhite($text2), smashwhite($Skeldottxt), "corresponds to ".basename($input_txt));
}

# Check various offsets

{
  my $max_para_textlen = max(map{ $_//0 } @para_text_lengths);
  note dvis '$max_para_textlen';
  for my $maxlen (1..$max_para_textlen+2) {
    my $text = "";
    for my $para (@all_paras) {
      my $offset = 0;
      while (my $m = $para->Hsearch(qr/.{1,${maxlen}}/s, offset => $offset, debug=>0)) {
        $text .= $m->{match};
        $offset = $m->{vend};
        #say "GOT MATCH:", fmt_match($m);
        bug unless $m->{para} == $para;
      }
    }
    fail("Hsearch for $maxlen-char chunks") unless $text eq $alltext;
  }
  ok(1, "Total text matches with many match lengths");
}
#####################

is( $body->Hsearch(qr//s),
    hash {
      field offset=>0; field end=>0; field voffset=>0; field vend=>0; etc();
    },
    "Hsearch with qr//s"
);
is( $body->Hsearch(qr//),
    hash {
      field offset=>0; field end=>0; field voffset=>0; field vend=>0; etc();
    },
    "Hsearch with qr//"
);

#
# NOTE: To determine offsets, examine output of "t/dumpskel.pl 2"
#

######################

is( [ $body->Hsearch(qr/ADDR./, multi => 1, debug => 0) ],
    array{
      item hash{ field voffset=>925; field match => 'ADDR1'; etc; };
      item hash{ field voffset=>934; field match => 'ADDR2'; etc; };
      item hash{ field voffset=>943; field match => 'ADDR3'; etc; };
      end;
    },
    "Multi-match ADDR{1,2,3} in different table cells"
);

{ #Multi-match in same paragraph
  my $off = 941; # -> "**ADDR3**" in the last cell (nothing follows)
  my @m = $body->Hsearch(qr/(?:AD|R3|.)/s, multi => 1, offset => $off);
  is( [ @m ],
      array {
        item hash{ field match => '*';
                   field voffset=>$off+0 ; field vend => $off+0+1; etc; };
        item hash{ field match => '*';
                   field voffset=>$off+1 ; field vend => $off+1+1; etc; };
        item hash{ field match => 'AD';
                   field voffset=>$off+2 ; field vend => $off+2+2; etc; };
        item hash{ field match => 'D';
                   field voffset=>$off+4 ; field vend => $off+4+1; etc; };
        item hash{ field match => 'R3';
                   field voffset=>$off+5 ; field vend => $off+5+2; etc; };
        item hash{ field match => '*';
                   field voffset=>$off+7 ; field vend => $off+7+1; etc; };
        item hash{ field match => '*';
                   field voffset=>$off+8 ; field vend => $off+8+1; etc; };
        end;
      },
      "Multi-match in same paragraph"
  );
  my $totstr = reduce { $a . $b } (map{ $_->{match} } @m);
  like($totstr, qr/^\*\*ADDR3\*\*$/, "Multi-match in same para");
}
#####################

done_testing();
