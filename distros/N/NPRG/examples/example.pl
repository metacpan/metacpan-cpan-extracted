use ExtUtils::testlib;
use Win32::Wingraph;
use NPRG qw(drawmatrix);

$dc=new Win32::Wingraph( device=>"\\\\LUCENT\\HP LaserJet 1100",  desc=>'test', metafile=>'tsta.emf') or die; #orientation=>'Landscape',
print "Start\n";
%st1=(font=>'Times New Roman Bold', size=>12, opt=>'C', border=>'TBLR', pen=>2);

$rp=new NPRG(dc=>$dc);
$rp->{'atbreak'}=sub{
                  $rp->pushq({font=>'Times, 6', opt=>'R', border=>'B', value=>'Very wisdom report about something '.$rp->pagenum(), width=>980}
                            );
                  $rp->pushq({height=>20, value=>' ', width=>100}
                            );
                  $rp->pushq({font=>'Arial italic, 16', opt=>'-L', border=>'TBLR', value=>'Some header', width=>300, brush=>220},
                             {font=>'Courier Bold, 12', opt=>'-C', border=>'TBLR', value=>'Another header', width=>250, brush=>220},
                             {value=>\&NPRG::drawmatrix, width=>400,
                                matrix=>[
                                  [ {font=>'Arial Bold Italic, 12', value=>'Month', border=>'TBLR', opt=>'C'}],
                                  [
                                      {font=>'Times New Roman,8', value=>'I', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,8', value=>'II', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,8', value=>'III', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,8', value=>'IV', border=>'TBLR', opt=>'-C'},
                                  ],
                                  [
                                      {font=>'Times New Roman,7', value=>'I', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'II', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'III', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'IV', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'V', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'VI', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'VII', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'VIII', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'IX', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'X', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'XI', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'XII', border=>'TBLR', opt=>'-C'},
                                   ]
                                ],
                             }
                            );
                  $rp->pushq({width=>950, height=>3, brush=>0});
#                  $rp->flushq();
                  print "Here\n";
               };

$rp->{'beforebreak'}=sub{
                  $rp->pushq({height=>20, value=>' ', width=>100}
                            );
                  $rp->pushq({font=>'Times New Roman, 12', opt=>'R', border=>'T', value=>'Report about something, page '.$rp->pagenum(), width=>980}
                            );
                  $rp->flushq();
               };

%st=(font=>'Courier New Bold, 10', opt=>'-LB', border=>'TBLR');
for(1..2){
   $rp->pushq({height=>20, value=>' ', width=>100}) if $rp->pagenum == $oldpagenum;
   $oldpagenum=$rp->pagenum;
   for(1..4){
     $rp->pushq( {font=>'Times New Roman, 12', opt=>'JL', border=>'TBLR', value=>($_ % 2? 'The prison wall was round us both':'How dow the little crocodile improve his shinig tail'),
                  width=>300},
                 {font=>'Courier Bold Italic, 12', opt=>'-C', border=>'TBLR', value=>"$_ Labuda", width=>250},
                 {width=>400, value=>\&drawmatrix,
                   matrix=>[
                            [
                             {width=>50, value=>'Price', %st, opt=>'-R', brush=>240},
                             {width=>350, value=>'$100.00', %st}
                            ],
                           ]
                 }
          );
   }
   $rp->pushq();
   $rp->flushq();
}
$rp->flushq();
print "End\n";
