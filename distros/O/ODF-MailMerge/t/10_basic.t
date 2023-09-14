#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops btw btwN/; # strict, warnings, Carp
use t_TestCommon #':silent', # Test2::V0 etc.
                 qw/:DEFAULT $debug $savepath/;
warn ":silent temp disabled";

use LpodhTestUtils qw/append_para verif_normalized/;

use ODF::lpOD;
use ODF::lpOD_Helper;
use ODF::MailMerge;

use constant FRAME_FILTER => 'draw:frame';

my $token_re = $ODF::MailMerge::token_re;

sub escape($) { local $_ = shift; s/([:\{\}\\])/\\$1/g; $_ }

for my $tokname ("A", "a b", "A_B", "A:B", "A\\B", "A{B:", "AB\\") {
  for my $modlist ([], ["mod1"], ["mod1=xx\nyy"], ["mod1","mod{2=val2"],
                   ["M:od1","Mod2\\","Mod3}:=val3"]) {
    for my $prespace ("", " \t") {
      for my $postspace ("", "\t  ") {
        my $token = "{".$prespace.escape($tokname).$postspace
                    .join("", map{ ":".escape($_) } @$modlist)
                    ."}";
        my ($ptokname, $smods, $cmods)
          = eval{ ODF::MailMerge::_parse_token($token) };
        fail(dvisq '$token parse error: $@') if $@;
        unless ($ptokname eq $tokname) {
          fail(dvis '_parse_token $token : $ptokname ne $tokname');
        }
        unless (@$smods == 0
                && @$cmods == @$modlist
                && all { $cmods->[$_] eq $modlist->[$_] } 0..$#$cmods) {
          is($cmods, $modlist, "_parse_token bug with modifiers",
             dvis '$tokname $modlist $prespace $postspace\n$token\n$ptokname $smods $cmods'
          )
        }
      }
    }
  }
}
for my $bad_tokname ("A\tB", "a\nb", "A:\nfoo") {
  for my $modlist ([], ["mod1"], ["mod1","mod{2=val2"],
                   ["M:od1","Mod2\\","Mod3}:=val3"]) {
    for my $prespace ("", " \t") {
      for my $postspace ("", "\t  ") {
        my $token = "{".$prespace.escape($bad_tokname).$postspace
                    .join("", map{ ":".escape($_) } @$modlist)
                    ."}";
        () = eval{ ODF::MailMerge::_parse_token($token) };
        unless ($@ =~ /token/) {
          fail(dvis '$bad_tokname failed to provoke an error ($token)');
        }
      }
    }
  }
}
{ my ($tokname, $std_mods, $custom_mods) = ODF::MailMerge::_parse_token(
     "{Foo:nb:AA=a1\na2 :BB:unfold:breakmulti:die:delrow:delpara"
    .":del=MY DELTAG"
    .":rep_first:rep_mid:rep_last:rep=MYEXPR:CC:reptag=MYREPTAG}" );

  fail() unless $tokname eq "Foo";
  is($custom_mods, ["AA=a1\na2 ", "BB", "CC"], "Custom mods separated");
  is($std_mods, [qw/nb unfold breakmulti die delrow delpara/,
                 "del=MY DELTAG",
                 qw/rep_first rep_mid rep_last rep=MYEXPR reptag=MYREPTAG/],
     "Standard :modifier recognition"
  );
}
pass "Finished token-parse tests";

my $master_copy_path = "$Bin/../tlib/Basic.odt";
my $input_path = tmpcopy_if_writeable($master_copy_path);
note "> Reading (copy of) $master_copy_path" if $debug;
my $doc = odf_get_document($input_path, read_only => 1);
my $body = $doc->get_body;

#sub xxdebug() {
#  my ($file,$lno) = (caller(0))[1,2];
#  for my $para ($body->descendants('text:p')) {
#    my $d = $para->can("document") ? $para->document : "CANT-document";
#    #my $r = $para->can("root") ? $para->root : "CANT-root";
#    my $b = ref($d) ? $d->can("body") ? $d->body : "CANT-body" : '($d not ref)';
#    say "LINE $lno : para=",u($para)," d=",u($d)," b=",u($b),"   ", dvis '##ZZ $para $d $b';
#    oops if ref($b) && $b != $body;
#    oops if ref($d) && $d != $doc;
#  }
#}
#xxdebug();

# Basic replace_tokens
# These tests directly mess with a couple of tables (not using mail-merge)
{
  my $table1 = $body->Hsearch("BareTable1ProtoTag")->{para}->get_parent_table;

  # Note: Wildcard '*' hash entries are tested with Mail Merge
  my %hash = (
    "Address2" => "MULTI\nLINE", # token has ":unfold:die"
    "CITY" => "Lake Placid",     # token has ":suf=,:nb"
    "FIRST NAME" => "John",      # token has ":nb:pfx=, "
    "LAST NAME"  => "{Brown}",
    "ZIP" => "",                 # token has ":die,"
    "Non-existent Token Name" => "Should not be found",
    # N.B. "STATE" is not specified, so should not be replaced
  );
  my $subst_count = replace_tokens($table1, \%hash, debug => $debug);

  is ($subst_count, 5, "table1 replace_tokens return count");

  my $text1 = $table1->Hget_text;
  like($text1, qr/^\{Brown\}, John.*\{Address1.*\}BareTable1ProtoTagMULTI LINELake\N{NO-BREAK SPACE}Placid/,
       "Overall table content check",
       fmt_tree($table1));
}

#####################
# :die test
#####################
{
  my $table2 = $body->Hsearch("{Table2ProtoTag}")->{para}->get_parent_table;
  my %hash = (
    # Address1 omitted from hash, so should not be deleted
    "FIRST NAME" => "John",
    "LAST NAME"  => "Brown",
    "Address2"   => "",
    "CITY" => "", "STATE" => "", "ZIP" => "",
    "Non-existent Token Name" => "Should not be found",
  );
  my $subst_count = replace_tokens($table2, \%hash, debug => $debug);
  is ($subst_count, 6, "table2 replace_tokens return count");
  my $text2 = $table2->Hget_text;
  like($text2, qr/^Brown, John.*\{Address1.*\}\{Table2ProtoTag\}$/,
       ":die test", fmt_tree($table2));
}

{ # Callback with custom modifier
my $frame = $body->Hsearch("{Date:mymodif}")->{para}->parent(FRAME_FILTER);
my %hash = (
  "Date" => sub {
    my ($key, $token, $para, $custom_mods) = @_;
    is($key, 'Date', 'User callback $key arg');
    is($token, '{Date:mymodif}', 'User callback $match arg');
    is($custom_mods, ["mymodif"], 'User callback $mods arg');
    ok($para->Hsearch($token), "  para contains the token");
    return (Hr_SUBST, ["8/18/2023"]);
  },
);
replace_tokens($body, \%hash, debug => $debug) == 1 or fail();
my $ftext = $frame->Hget_text();
is($ftext, "BASIC TEST FILE8/18/2023", "User callback subst result ok");
}

sub test_rt($$$;$) {
  my ($tokname, $mods, $num_values, $failure_exp_regex) = @_;
  $num_values //= 1;
  $mods = [$mods] unless ref($mods);
  confess "bug" unless @$mods > 0;
  my $frame = $body->insert_element('draw:frame', position => LAST_CHILD);
  scope_guard { $frame->delete };
  my @texts = map{ "{$tokname${_}}" } @$mods;
  #my $desc = "{${tokname}".join("/", @$mods)."}";
  my $desc = join("/", @texts);
  $desc .= " [$num_values ".($num_values==1 ? "val]" : "values]");
  my @rops = map{ scalar append_para($frame, $_) } @texts;
  my $hash = {
    Abogon => "bogon-a",
    $tokname => ($num_values==1 && rand(1) >= 0.5)
                  ? "val" : [map{ "val$_" } 0..$num_values-1],
    Zbogon => "bogon-z"
  };
  my $exp_repl_count = $num_values;
  my $testname = "repl_count==$exp_repl_count with ".$desc;
  btwN 1,dvis 'TEST test_rt: @rops\nframe',fmt_tree($frame) if $debug;
  my $repl_count;
  if ($num_values == 1 && none{ /:rep/ } @$mods) {
    $repl_count = eval{ replace_tokens($rops[ int(rand(scalar @rops)) ],
                                       $hash, debug => $debug) };
  } else {
    $repl_count = eval{ replace_tokens($frame, $hash, debug => $debug) };
  }

  if ($failure_exp_regex) {
    like($@, $failure_exp_regex, "$desc (GOT EXPECTED FAILURE?)");
  } else {
    croak("Unexpected exception:\n$@\n") if $@;
    is($repl_count, $exp_repl_count, $testname);
  }
}

test_rt( "MyTok", [""], 1 ); # ($tokname, $mods, $num_values, $exception_re)
test_rt( "MyTok", [":bogus"], 1, qr/invalid.*mod.*:bogus/i );
test_rt( "MyTok", [":die"], 1 );
test_rt( "MyTok", [":die:"], 1, qr/':'.*:die:/); # extraneous ':'
test_rt( "MyTok", ["", ":rep_first", ":rep_last"], 1 );
test_rt( "MyTok", [":rep_first", ":rep_last"], 2 );
test_rt( "MyTok", [":rep_first", ":rep_last"], 1, qr/no.*match.*N==?1/i);

test_rt( "MyTok", [""], 2 );
test_rt( "MyTok", [""], 50 );

test_rt( 'MyTok', [':rep_first', ':rep=$i==0'], 2, qr/no .*matches/i );
test_rt( 'MyTok', [':rep=$i == 17', ':rep=$N > 999'], 1, qr/no .*matches/i );
test_rt( 'MyTok', ['', ':rep=$i == 17', ':rep=$N > 999'], 1);

sub test_multi($$$;$) {
  my ($rowtexts, $hash, $exp_text, $desc_pfx) = @_;
  $rowtexts = [$rowtexts] unless ref $rowtexts;

  my $frame = $body->insert_element('draw:frame', position => LAST_CHILD);
  scope_guard { $frame->delete };

  my $desc = ($desc_pfx//"")."[test_multi]".scalar(@$rowtexts)." para;";
  foreach my $tokname (sort keys %$hash) {
    my $v = $hash->{$tokname} // next;
    $desc .= " $tokname";
    $desc .= "(".scalar(@$v)." vals)" if ref($v) && @$v > 1;
  }

  my $exp_repl_count = 0;
  foreach (@$rowtexts) {
    append_para($frame, $_);
    my $maxN = 0;
    my $numtoks = 0;
    while (/\G.*?\{([^\s:\}]+).*?\}/gc) {
      my $tokname = $1;
      my $v = $hash->{$tokname};
      confess dvis 'No repl value for $tokname' unless defined $v;
      my $nv = ref($v) ? scalar(@$v) : 1;
      $maxN = max($maxN, $nv);
      ++$numtoks;
    }
    $exp_repl_count += $numtoks * $maxN;
  }
  my $repl_count = replace_tokens($frame, $hash, debug => $debug);
  if ((my $got=$frame->Hget_text) ne $exp_text ) {
    @_ = ($got, $exp_text, $desc);
    goto &is;
  }
  if ($repl_count != $exp_repl_count) {
    @_ = ($repl_count, $exp_repl_count, "WRONG repl_count for $desc");
    goto &is;
  }
  is($frame->Hget_text,$exp_text, $desc);
  #is($repl_count, $exp_repl_count, "  (repl_count=$repl_count)");
}

test_multi(["AAA {TokA} {TokB} BBB",
            "{TokA} {TokB}",
            "{TokA} {TokB}ZZZ"],
           { TokA => "aaa", TokB => "bbb" },
           "AAA aaa bbb BBBaaa bbbaaa bbbZZZ");

test_multi(["AAA {TokA} {TokB} BBB",
            "{TokA} {TokB}",
            "{TokA} {TokB}ZZZ"],
           { TokA => ["A1".."A3"], TokB => "bbb", },
           join("",
                "AAA A1 bbb BBB", "AAA A2  BBB", "AAA A3  BBB",
                "A1 bbb", "A2 ", "A3 ",
                "A1 bbbZZZ", "A2 ZZZ", "A3 ZZZ"
           ));

test_multi(["AAA {TokA} {TokB} BBB",
            "{TokA} {TokB}",
           ],
           { TokA => ["A1".."A3"], TokB => ["B1".."B4"] },
           join("",
                "AAA A1 B1 BBB", "AAA A2 B2 BBB", "AAA A3 B3 BBB", "AAA  B4 BBB",
                "A1 B1", "A2 B2", "A3 B3", " B4",
           ));

test_multi(["XXX[{TokA} {TokB:die}]",
            "YYY[{TokA:die} {TokB:die} {TokC}]",
            "ZZZ[{TokA} {TokB} {TokC}]",
           ],
           { TokA => ["A1".."A3"],
             TokB => ["B1".."B2"],
             TokC => "ccc",
           },
           join("",
                ("XXX[A1 B1]", "XXX[A2 B2]",
                 #"XXX A3 ", #should not appear bc TokB is empty
                ),
                ("YYY[A1 B1 ccc]",
                 "YYY[A2 B2 ]",
                 "YYY[A3  ]", # not deleted bc TokA is not empty
                ),
                ("ZZZ[A1 B1 ccc]",
                 "ZZZ[A2 B2 ]",
                 "ZZZ[A3  ]",
                ),
           ),
           ":die"
);

test_multi(["XXX[{TokA:die} {TokB:die}]",
           ],
           {
             TokA => "aaa",
             TokB => "",
           },
           "XXX[aaa ]", # not deleted because TokA is :die but isn't empty
           ":die#2"
);
test_multi(["XXX[{TokA:die} {TokB:die}]",
            "YYY[{TokA:die} {TokB:die} {TokC}]",
           ],
           {
             TokA => "",
             TokB => "",
             TokC => "ccc",
           },
           "", # all deleted because all tokens with :die are empty
           ":die-all-deleted"
);

###########################
# :rmbb and :span (not really tested)
###########################
test_rt( "MyTok", [':span'], 1 );
test_rt( "MyTok", [':rmsb'], 1 );

# TODO FUTURE: TEst :span and eliding borders

done_testing;
