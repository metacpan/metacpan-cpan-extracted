use strict;
use warnings;
use SOOT ':all';

# FIXME port charset issues

sub _pstable {
  
  # program to display all possible types of ROOT/Postscript characters

  my $rsymbol1 = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N",
                  "O","P","Q","R","S","T","U","V","W","X","Y","Z",
                  "0","1","2","3","4","5","6","7","8","9",
                  ".",",","+","-","*","/","=","(",")","{","}","END"];

  my $rsymbol2 = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n",
                  "o","p","q","r","s","t","u","v","w","x","y","z",
                  ":","\;","\@","\\","\_","\|","\%",
                  "\@'","<",">","[","]","\42","\@\43","\@\136",
                  "\@\77","\@\41","\@&","\$","\@\176"," ","END"];

  my $rsymbol3 = ["\241","\242","\243","\244","\245","\246","\247","\250",
                  "\251","\252","\253","\254","\255","\256","\257","\260",
                  "\261","\262","\263","\264","\265","\266","\267","\270",
                  "\271","\272","\273","\274","\275","\276","\277","\300",
                  "\301","\302","\303","\304","\305","\306","\307","\310",
                  "\311","\312","\313","\314","\315","\316","\317","END"];

  my $rsymbol4 = ["\321","\322","\323","\324","\325","\326","\327","\330",
                  "\331","\332","\333","\334","\335","\336","\337","\340",
                  "\341","\342","\343","\344","\345","\346","\347","\340",
                  "\351","\352","\353","\354","\355","\356","\357","\360",
                  "\361","\362","\363","\364","\365","\366","\367","\370",
                  "\371","\372","\373","\374","\375","\376","\377","END"];

  my $xrange = 18;
  my $yrange = 25;
  my $w = 650;
  my $h = int($w*$yrange/$xrange);
  my $c1 = TCanvas->new("c1","c1",200,10,$w,$h);
  $c1->Range(0,0,$xrange,$yrange);

  my $t = TText->new(0,0,"a");
  $t->SetTextSize(0.02);
  $t->SetTextFont(62);
  $t->SetTextAlign(22);

  table(0.5,0.5*$xrange-0.5,$yrange,$t,$rsymbol1,0);
  table(0.5*$xrange+0.5,$xrange-0.5,$yrange,$t,$rsymbol2,0);

  my $tlabel = TText->new(0,0,"a");
  $tlabel->SetTextFont(72);
  $tlabel->SetTextSize(0.018);
  $tlabel->SetTextAlign(22);
  $tlabel->DrawText(0.5*$xrange,1.3,"Input characters are standard keyboard characters");
  $c1->Modified();
  $c1->Update();
  $c1->Print("pstable1.ps");

  my $c2 = TCanvas->new("c2","c2",220,20,$w,$h);
  $c2->Range(0,0,$xrange,$yrange);

  table(0.5,0.5*$xrange-0.5,$yrange,$t,$rsymbol3,1);
  table(0.5*$xrange+0.5,$xrange-0.5,$yrange,$t,$rsymbol4,1);

  $tlabel->DrawText(0.5*$xrange,1.3,"Input characters using backslash and octal numbers");
  $c2->Modified();
  $c2->Update();
  $c2->Print("pstable2.ps");

sub table {
  my ($x1, $x2, $yrange, $t, $rsymbol, $isoctal) = @_;
  my $n = scalar @$rsymbol;
  my $y1  = 2.5;
  my $y2  = $yrange - 0.5;
  my $dx  = ($x2-$x1)/5;
  my $dy  = ($y2 - 1 - $y1)/($n+1);
  my $y   = $y2 - 1 - 0.7*$dy;
  my $xc0 = $x1  + 0.5*$dx;
  my $xc1 = $xc0 + $dx;
  my $xc2 = $xc1 + $dx;
  my $xc3 = $xc2 + $dx;
  my $xc4 = $xc3 + $dx;

  my $line = TLine->new();
  $line->DrawLine($x1,$y1,$x1,$y2);
  $line->DrawLine($x1,$y1,$x2,$y1);
  $line->DrawLine($x1,$y2,$x2,$y2);
  $line->DrawLine($x2,$y1,$x2,$y2);
  $line->DrawLine($x1,$y2-1,$x2,$y2-1);
  $line->DrawLine($x1+  $dx,$y1,$x1+  $dx,$y2);
  $line->DrawLine($x1+2*$dx,$y1,$x1+2*$dx,$y2);
  $line->DrawLine($x1+3*$dx,$y1,$x1+3*$dx,$y2);
  $line->DrawLine($x1+4*$dx,$y1,$x1+4*$dx,$y2);

  my $tit = TText->new(0,0,"a");
  $tit->SetTextSize(0.015);
  $tit->SetTextFont(72);
  $tit->SetTextAlign(22);
  $tit->DrawText($xc0,$y2-0.6,"Input");
  $tit->DrawText($xc1,$y2-0.6,"Roman");
  $tit->DrawText($xc2,$y2-0.6,"Greek");
  $tit->DrawText($xc3,$y2-0.6,"Special");
  $tit->DrawText($xc4,$y2-0.6,"Zapf");

  for (my $i=0; $i<$n; $i++) {
    my $text;
    if ($isoctal) {
      $text = sprintf("\@\\ %3o", $rsymbol->[$i]);
    } 
    else {
      $text = $rsymbol->[$i];
    }
    $t->DrawText($xc0,$y,$text);
    $text = sprintf("%s",$rsymbol->[$i]);
    $t->DrawText($xc1,$y,$text);
    $text = sprintf("`%s", $rsymbol->[$i]);
    $t->DrawText($xc2,$y,$text);
    $text = sprintf("'%s",$rsymbol->[$i]);
    $t->DrawText($xc3,$y,$text);
    $text = sprintf("~%s",$rsymbol->[$i]);
    $t->DrawText($xc4,$y,$text);
    $y -= $dy;
  }
}

_pstable;

$gApplication->Run;
