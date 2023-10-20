#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon #':silent', # Test2::V0 etc.
                 qw/:DEFAULT run_perlscript verif_no_internals_mentioned
                    $verbose $debug $savepath/;
use IO::Uncompress::Gunzip qw/gunzip $GunzipError/;
use Encode qw/decode/;

use Spreadsheet::Edit ();
use ODF::lpOD;
use ODF::lpOD_Helper;

use Capture::Tiny qw/capture/;

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
{ my ($out, $err, $wstat) = capture {
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
  note "script parser test\n$err" if $verbose;
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
  my ($out, $err, $wstat) = capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<EOF);
      skeleton '${\$Skelpath->canonpath()}'
      save '${\$odt_outpath->canonpath()}'
EOF
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
  my ($out, $err, $wstat) = capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<EOF);
      skeleton '${\$Skelpath->canonpath()}'
      _eval_perlcode 'foreach (\$body->cut_children) { \$_->delete }'
      _eval_perlcode 'die "BUGGO" if \$body->children_count != 0;'
      save '${\$odt_outpath->canonpath()}'
EOF
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
  my ($out, $err, $wstat) = capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<EOF);
      skeleton '${\$Skelpath->canonpath()}'
      _eval_perlcode 'foreach (\$body->cut_children) { \$_->delete }'
      _eval_perlcode 'die "BUGGO" if \$body->children_count != 0;'
      save -f '${\$odt_outpath->canonpath()}'
EOF
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
  my ($out, $err, $wstat) = capture {
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<EOF);
      skeleton '${\$Skelpath->canonpath()}'
      subst-value "DatabaseManager" "FAKE-DB-MGR" "LAST NAME" FAKE-LN
      save -f '${\$odt_outpath->canonpath()}'
EOF
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
    $as->apply(sub{
      $exp_re .= '.*'.$as->{LAST_NAME}.", ".$as->{FIRST_NAME}
                .'.*'.$as->{Address1}
                .'.*'.$as->{Address2}
                .'.*'.$as->{CITY}.', '.$as->{STATE}.' *'.$as->{ZIP};
      $ptext .= $as->{FIRST_NAME}.",".$as->{LAST_NAME}."\n";
    });
    $exp_re =~ s/ /[ \\N{NO-BREAK SPACE}]/g;
    $exp_re = qr/${exp_re}/;
    note dvis '$ptext';
    $primaryss->spew_utf8($ptext);
   }
  my ($out, $err, $wstat) = capture {
  };
    run_perlscript($scriptpath->canonpath, @dash_dv, "-e", <<EOF);
      skeleton '${\$Skelpath->canonpath()}'
      mail-merge 'PROTO-TAG' \\
        '${\$primaryss->canonpath()}' \\
                -a 'FIRST_NAME=/PRI.*FIRST.*NAME/' -a 'LAST_NAME=PRI-LAST-NAME' -a xyzzx=PRI-LAST-NAME \\
        'FIRST_NAME,PRI_LAST_NAME=ADDR_LN_ALIAS:${\$Addrspath->canonpath()}' \\
                -a 'ADDR_LN_ALIAS=LAST_NAME'
      save -f '${\$odt_outpath->canonpath()}'
EOF
  note "mail-merge test\n$err" if $verbose;
  is($wstat, 0, "out:$out\nerr:$err") if $wstat;
  is($out, "") if $out ne "";
  ok($odt_outpath->exists, "$odt_outpath exists");
  my $after_text = get_body_text($odt_outpath);
  if ($debug) { warn "SAVING RESULT AS /tmp/j.odt\n"; $odt_outpath->copy("/tmp/j.odt"); }
  like($after_text, $exp_re, "subst-value");
}

done_testing;
