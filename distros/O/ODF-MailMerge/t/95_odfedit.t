#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops btw btwN/; # strict, warnings, Carp
use t_TestCommon #':silent', # Test2::V0 etc.
                 qw/:DEFAULT run_perlscript my_capture verif_no_internals_mentioned
                    $verbose $debug $savepath/;
use IO::Uncompress::Gunzip qw/gunzip $GunzipError/;
use Encode qw/decode/;

use Spreadsheet::Edit 1000.011 (); # In 1000.011 btw writes to stderr
use ODF::lpOD;
use ODF::lpOD_Helper;

# 7/7/2024: perl 5.20.x *hangs* while compiling certain uses of lexical subs,
# including 'my sub mydie...' used below.  It was too difficult to figure out how
# work around this, but 5.20 is really old...
use 5.22.0;

#diag "WARNING: :silent temp disabled";

my @dash_dv = ($debug ? ("-v","-d") : $verbose ? ("-v") : ());

sub get_body_text($) {
  my $path = shift;
  my $doc = odf_new_document_from_template(path($path)->canonpath);
  $doc->get_body->Hget_text;
}

my $scriptpath = path($Bin)->child("../bin/odfedit");

# Embed speces in tempdir path to check quoting
my $tdir = Path::Tiny->tempdir(TEMPLATE => "test dir XXXXX");
my $odt_outpath = path($tdir)->child("output.odt");

my $Skelpath  = path($Bin)->child("../tlib/Skeleton.odt");
my $Addrspath = path($Bin)->child("../tlib/Addrlist.csv");


my $skel_text = get_body_text($Skelpath);

################################## TEST COMMAND PARSER ################
{ my ($out, $err, $wstat) = my_capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<'EOF');
      print
      print 	;
      print ; ;
      print    ;;
      print "d q"	" B#B "; print    C \# 's q' \\ \n \e \bozo; print E
      print FF \
         'GG'#; print IGNORED
      print HH "II"#; print IGNORED
      print \
        JJ KK#; print IGNORED
      print #IGNORED
      #print "F F" ' G G '#; print C DDD; print E
EOF
  };
  $out =~ s/\R/\n/sg;  # change Windows CRLF to LF
  $err =~ s/\R/\n/sg;  # change Windows CRLF to LF
  note "script parser test\n$err" if $verbose;
  # On Windows, the 'print' command shows a lone backslash unquoted
  #   (because Data::Dumper::Interp::qsh('\\') tries to quote for cmd.com
  #    on Windows)
  #diag dvisq '$out';
  like ($out, qr/\A\n
                 \n
                 \n
                 \n
                 "d\ q"\ "\ B\x{23}B\ "\n
                 C\ "\x{23}"\ "s\ q"\ '\\'\ n\ e\ bozo\n
                 E\n
                 FF\ GG\n
                 HH\ II\n
                 JJ\ KK\n
                 \n
                 \z
                /xs, "script parser test",
                ivis 'OUT:$out\nERR:$err');
}

####################### null edit ################
{
  my ($out, $err, $wstat) = my_capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<QQEOF);
      skeleton '${\$Skelpath->canonpath()}'
      save '${\$odt_outpath->canonpath()}'
QQEOF
  };
  note "null edit test\n$err" if $verbose;
  is($out, "") if $out ne "";
  is($wstat, 0, "out:$out\nerr:$err") if $wstat;
  fail("$odt_outpath exists") unless $odt_outpath->exists;
  ok($odt_outpath->exists, "$odt_outpath exists");
  my $after_text = get_body_text($odt_outpath);
  is($after_text, $skel_text, "null edit");
}
####################### save overwrite without -f ################
{
  my ($out, $err, $wstat) = my_capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<QQEOF);
      skeleton '${\$Skelpath->canonpath()}'
      _eval_perlcode 'foreach (\$body->cut_children) { \$_->delete }'
      _eval_perlcode 'die "BUGGO" if \$body->children_count != 0;'
      save '${\$odt_outpath->canonpath()}'
QQEOF
  };
  note "save overwrite without -f\n$err" if $verbose;
  is($out, "") if $out ne "";
  isnt($wstat, 0, "out:$out\nerr:$err") if $wstat == 0;
  like($err, qr/already exists/i, "save overwrite without -f");
  fail("$odt_outpath exists") unless $odt_outpath->exists;
  my $after_text = get_body_text($odt_outpath);
  is($after_text, $skel_text);
}
####################### save overwrite with -f ################
{
  my ($out, $err, $wstat) = my_capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<QQEOF);
      skeleton '${\$Skelpath->canonpath()}'
      _eval_perlcode 'foreach (\$body->cut_children) { \$_->delete }'
      _eval_perlcode 'die "BUGGO" if \$body->children_count != 0;'
      save -f '${\$odt_outpath->canonpath()}'
QQEOF
  };
  note "save overwrite with -f\n$err" if $verbose;
  is($out, "") if $out ne "";
  is($wstat, 0, "out:$out\nerr:$err") if $wstat;
  my $after_text = get_body_text($odt_outpath);
  is($after_text, "");
  unlike($err, qr/\A(?=.*exists)/is);
}

####################### subst-value ################
{
  my ($out, $err, $wstat) = my_capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<QQEOF);
      skeleton '${\$Skelpath->canonpath()}'
      subst-value "DatabaseManager" "FAKE-DB-MGR" "LAST NAME" FAKE-LN
      save -f '${\$odt_outpath->canonpath()}'
QQEOF
  };
  note "subst-value test\n$err" if $verbose;
  is($wstat, 0, "out:$out\nerr:$err") if $wstat;
  is($out, "") if $out ne "";
  ok($odt_outpath->exists, "$odt_outpath exists");
  my $exp = $skel_text;
  $exp =~ s/\{DatabaseManager[^{}]*\}/FAKE-DB-MGR/gs or oops dvis '$exp';
  $exp =~ s/\{LAST NAME[^{}]*\}/FAKE-LN/gs or die;
  my $after_text = get_body_text($odt_outpath);
  is ($after_text, $exp, "subst-value");
}

##################### mail-merge ################
{
  # Make a "primary" spreadsheet which only contains names, which will be used
  # with the full Addrlist sheet as a secondary to find other data.
  my $primaryss = $tdir->child("Primary.csv");
  my $exp_re = "";
  { my $ptext = "PRI-FIRST-NAME,PRI-LAST-NAME\n";
    my $as = Spreadsheet::Edit->new()->read_spreadsheet($Addrspath->canonpath);
    # In the combined Virtual Text, the row texts are concatenated without
    # nothing inbetween (not even a newline).
    # N.B. After {LAST_NAME},{FIRST_NAME} there is a tab and then *** in
    # in the Skeleton.
    $as->apply(sub{
      $exp_re .= $as->{LAST_NAME}.", ".$as->{FIRST_NAME}."\t\\*\\*\\*"
                .$as->{Address1}
                .$as->{Address2}
                .$as->{CITY}.', '.$as->{STATE}.' *'.$as->{ZIP};
      $ptext .= $as->{FIRST_NAME}.",".$as->{LAST_NAME}."\n";
    });
    $exp_re = qr/${exp_re}/;
    note dvis '$ptext\n$exp_re' if $debug;
    $primaryss->spew_utf8($ptext);
  }

  my $script = <<QQEOF;
    skeleton ${\visq($Skelpath->canonpath())}

    mail-merge 'PROTO-TAG' \\
      -a 'FIRST_NAME=/PRI.*FIRST.*NAME/' -a 'LAST_NAME=PRI-LAST-NAME' \\
        ${\visq($primaryss->canonpath())} \\
      -k FIRST_NAME -k LAST_NAME \\
        ${\visq($Addrspath->canonpath())} \\

    save -f ${\visq($odt_outpath->canonpath())}
QQEOF

  my ($out, $err, $wstat) = my_capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", $script);
  };

  is($out, "") if $out ne "";
  if ($verbose || $debug) {
    diag dvis 'stderr:$err';
  } else {
    is($err,"",$err);
  }
  ok($odt_outpath->exists, "$odt_outpath exists");
  my $after_text = get_body_text($odt_outpath);
  #if ($debug) { warn "SAVING RESULT AS /tmp/j.odt\n"; $odt_outpath->copy("/tmp/j.odt"); }
  $after_text =~ s/\N{NO-BREAK SPACE}/ /g; # Be insensitive to :nb modifiers
btw dvis '$after_text' if $debug;
  like($after_text, $exp_re, "text after mail-merge");
}

done_testing;
