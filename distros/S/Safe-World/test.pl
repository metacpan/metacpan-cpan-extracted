#########################

###use Data::Dumper ; print Dumper( $world ) ;

use Test;
BEGIN { plan tests => 89 } ;

use Safe::World ;

use strict ;
use warnings qw'all' ;

$|=1;

#########################
{

  my $tmp ;
  my $world_cache = Safe::World->new(
  is_cache  => 1 ,
  stdout    => \$tmp ,
  stderr    => \$tmp ,
  no_io     => 1 ,
  flush     => 1 ,
  sharepack => ['foo'] ,
  ) ;
  
  $world_cache->eval(q`
  $GLOBAL = 'cache' ;
  package foo ;
    sub test { print STDOUT "TEST>> @_ [ $main::GLOBAL ]" ; }
  `) ;
  
  my $val0 = $world_cache->eval(q`$GLOBAL`) ;
    
  ###########
  
  my ( $stdout , $stderr ) ;
  my $world = Safe::World->new(
  stdout       => \$stdout ,
  stderr       => \$stderr ,
  flush        => 1 ,  
  ) ;
  
  $world->link_world($world_cache) ;

  $world->eval(q`
    $GLOBAL = 'world1' ;
    foo::test(123) ;
  `) ;
  
  my $world_val = $world->eval(q`$GLOBAL`) ;
  
  $world->unlink_world($world_cache) ;
    
  $world->close ;
  $world = undef ;
  
  my $val = $world_cache->eval(q`$GLOBAL`) ;
  
  ok($val0 , 'cache') ;
  ok($world_val , 'world1') ;
  ok($val , 'cache') ;

  ok($stdout , 'TEST>> 123 [ world1 ]') ;
  ok($stderr , '') ;
  ok($tmp , undef) ;

}
#########################
{

  my $tmp ;
  my $world_cache = Safe::World->new(
  is_cache  => 1 ,
  stdout    => \$tmp ,
  stderr    => \$tmp ,
  no_io     => 1 ,
  flush     => 1 ,
  sharepack => ['foo'] ,
  ) ;
  
  $world_cache->eval(q`
  package bar ;
    $GLOBAL = 'cache' ;
  package foo ;
    sub test { print STDOUT "TEST>> @_ [ $bar::GLOBAL ]" ; }
  `) ;
  
  $world_cache->track_vars( qw($bar::GLOBAL) ) ;
  
  my $val0 = $world_cache->eval(q`$bar::GLOBAL`) ;
    
  ###########
  
  my ( $stdout , $stderr ) ;
  my $world = Safe::World->new(
  stdout       => \$stdout ,
  stderr       => \$stderr ,
  flush        => 1 ,  
  ) ;
  
  $world->link_world($world_cache) ;
  
  $world->eval(q`
    $bar::GLOBAL = 'world1' ;
    foo::test(123) ;
  `) ;
  
  my $world_val = $world->eval(q`$bar::GLOBAL`) ;
  
  $world->unlink_world($world_cache) ;
    
  $world->close ;
  $world = undef ;
  
  my $val = $world_cache->eval(q`$bar::GLOBAL`) ;
  
  ok($val0 , 'cache') ;
  ok($world_val , 'world1') ;
  ok($val , 'cache') ;

  ok($stdout , 'TEST>> 123 [ world1 ]') ;
  ok($stderr , '') ;
  ok($tmp , undef) ;

}
#########################
{

  my $tmp ;
  my $world_cache = Safe::World->new(
  is_cache  => 1 ,
  stdout    => \$tmp ,
  stderr    => \$tmp ,
  no_io     => 1 ,
  flush     => 1 ,
  sharepack => ['foo'] ,
  ) ;
  
  ###########
  
  my ( $stdout , $stderr ) ;
  my $world = Safe::World->new(
  stdout       => \$stdout ,
  stderr       => \$stderr ,
  flush        => 1 ,  
  ) ;
  
  $world->link_world($world_cache) ;
  
  $world_cache->track_vars( $world , qw($GLOBAL :defaults) ) ;
  
  $world->eval(q`
  package foo ;
    sub test { print "TEST>> @_ [ $main::GLOBAL ]" ; }
  `) ;
  
  $world->eval(q`
    $GLOBAL = 'world1' ;
    foo::test(123) ;
  `) ;
  
  $world->unlink_world($world_cache) ;
    
  $world->close ;
  $world = undef ;
  
  ###########
  
  my ( $stdout2 , $stderr2 ) = () ;
  $world = Safe::World->new(
  stdout       => \$stdout2 ,
  stderr       => \$stderr2 ,
  flush        => 1 ,  
  ) ;
  
  $world->link_world($world_cache) ;
  
  $world->eval(q`
    $GLOBAL = 'world2' ;
    foo::test(456) ;
  `) ;
  
  $world->unlink_world($world_cache) ;
  
  $world->close ;
  $world = undef ;
  
  ###########
  
  ok($stdout , 'TEST>> 123 [ world1 ]') ;
  ok($stderr , '') ;
  ok($stdout2 , 'TEST>> 456 [ world2 ]') ;
  ok($stderr2 , '') ;

}
#########################
{


  my $tmp ;
  my $world_cache = Safe::World->new(
  is_cache  => 1 ,
  stdout    => \$tmp ,
  stderr    => \$tmp ,
  flush     => 1 ,
  no_set_safeworld => 1 ,
  no_strict        => 1 ,
  ) ;

  my ( $stdout , $stderr , $headout ) ;

  my $world = Safe::World->new(
  stdout       => \$stdout ,
  stderr       => \$stderr ,
  headout      => \$headout ,
  no_strict    => 1,
  headsplitter => 'HTML' ,
  autohead     => 1 ,
  on_closeheaders => sub {
                       my ( $pack , $headers ) = @_ ;
                       $pack->print_stdout("[[$headers]]") ;
                       $pack->headers('') ;
                       return 1 ;
                     } ,
  ) ;
  
  $| = 0 ;

  use Safe::World::Scope ;

  my $SCOPE_Safe_World ;
  
  sub Safe::World::use_cached {
    my $this = shift ;
    my $module = shift ;
    $SCOPE_Safe_World->call_hole('_use_cached_call_hole',$world,$world_cache,$module) ;
  }
  
  sub Safe::World::_use_cached_call_hole {
    my $world = shift ;
    my $world_cache = shift ;
    my $module = shift ;
    
    my $pm = $module ;
    $pm =~ s/::/\//g ; $pm .= '.pm' ;
    
    my ( $link_pack , $inc ) = $world_cache->use_shared($module) ;
    
    if ( $link_pack && !ref($link_pack) ) {
      warn($link_pack) ;
      return ;
    }
    
    my $inside = $world->{INSIDE} ;
    $world->{INSIDE} = undef ;
    
    if ( ref($link_pack) eq 'ARRAY' ) {
      foreach my $link_pack_i ( @$link_pack ) {
        $world->link_pack($link_pack_i) ;
      }
    }
    
    if ( ref($inc) eq 'HASH' ) {
      foreach my $Key ( keys %$inc ) { $INC{$Key} = $$inc{$Key} ;}
    }
    
    $world->{INSIDE} = $inside ;  
    
    return 1 ;
  }
  
  $SCOPE_Safe_World = new Safe::World::Scope('Safe::World',1) ;
  
  $world->print_header("X-Powered-By: Safe::World\n") ;
  $world->print_header("Content-type: text/html\n\n") ;
  
  $world->eval(q`
     $SAFEWORLD->use_cached('Data::Dumper') ;
  `);
  
  $world->eval(q`
    my @inc = (
    'Carp.pm=' . ( $INC{'Carp.pm'} eq '#shared#' ? 1 : 0 ) ,
    'Exporter.pm=' . ( $INC{'Exporter.pm'} eq '#shared#' ? 1 : 0 ) ,
    'Data/Dumper.pm=' . ( $INC{'Data/Dumper.pm'} eq '#shared#' ? 1 : 0 ) ,
    'XSLoader.pm=' . ( $INC{'XSLoader.pm'} eq '#shared#' ? 1 : 0 ) ,
    'warnings/register.pm=' . ( $INC{'warnings/register.pm'} eq '#shared#' ? 1 : 0 ) ,
    'warnings.pm=' . ( $INC{'warnings.pm'} eq '#shared#' ? 1 : 0 ) ,
    'overload.pm=' . ( $INC{'overload.pm'} eq '#shared#' ? 1 : 0 ) ,
    ) ;

    print Data::Dumper::Dumper( \@inc ) ;
  `);
    
  $world->close ;

  $world = undef ;
 
  $stdout =~ s/\n[ \t]*/\n/gs ;
  
  ok ($stdout , q`[[X-Powered-By: Safe::World
Content-type: text/html

]]$VAR1 = [
'Carp.pm=1',
'Exporter.pm=1',
'Data/Dumper.pm=1',
'XSLoader.pm=1',
'warnings/register.pm=1',
'warnings.pm=1',
'overload.pm=1'
];
`) ;
 
  ok($stderr , '') ;
  ok($headout , '') ;

}

#########################
{

  my ( $stdout , $stderr , $headout ) ;

  my $world = Safe::World->new(
  stdout       => \$stdout ,
  stderr       => \$stderr ,
  headout      => \$headout ,
  no_strict    => 1,
  headsplitter => 'HTML' ,
  autohead     => 1 ,
  on_closeheaders => sub {
                       my ( $pack , $headers ) = @_ ;
                       $pack->print_stdout("[[$headers]]") ;
                       $pack->headers('') ;
                       return 1 ;
                     } ,
  ) ;
  
  $| = 0 ;
  
  $world->print_header("X-Powered-By: Safe::World\n") ;
  $world->print_header("Content-type: text/html\n\n") ;
  
  $world->eval(q`
     print "<pre>\n\n" ;

     $|=1;
     my $sel = select ;
     print "content2 $sel\n" ;
     
     my $sel = select ;
     print "</pre>\n" ;
  `);
  
  $world->close ;

  $world = undef ;
  
  $stdout =~ s/SAFEWORLD\d+::STDOUT/main::STDOUT/gs ;
  
  ok($stdout , q`[[X-Powered-By: Safe::World
Content-type: text/html

]]<pre>

content2 main::STDOUT
</pre>
`);

  ok($stderr , '') ;
  
  ok($headout , '') ;

}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  env    => {
              FOO => 'bar' ,
              BAZ => 'BRAS' ,
            } ,
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  $world->eval(q`
    print "Test1 "  ;
    print STDERR "ERROR!\n" ;
    warn("Alert!!!") ;
    foreach my $Key (sort keys %ENV ) {
      print "<$Key = $ENV{$Key}>" ;
    }
  `);

  $stderr =~ s/eval \d+/eval x/gi ;
  
  ok($stdout , "Test1 <BAZ = BRAS><FOO = bar>") ;
  ok($stderr , "ERROR!\nAlert!!! at (eval x) line 4.\n") ;
  
}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  $world->eval(q`
     $var = 'abcd' ;
     $var{k1} = 'v1' ;
  `);
  
  my $val = $world->get('$var') ;
  ok($val,'abcd');
  
  $val = $world->get('$var{k1}') ;
  ok($val,'v1');
  
  my $var_ref = $world->get_ref('$var') ;
  ok(ref($var_ref) , 'SCALAR');
  
  ${$var_ref} .= 'efgh' ;
  
  $val = $world->get('$var') ;
  ok($val,'abcdefgh');
  
  my $var_ref_copy = $world->get_ref_copy('$var') ;
  ok(ref($var_ref_copy) , 'SCALAR');
  
  ${$var_ref_copy} .= 'ijkl' ;
  ok(${$var_ref_copy} ,'abcdefghijkl') ;
    
  $val = $world->get('$var') ;
  ok($val,'abcdefgh');

  ok($stderr , '') ;

}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  $world->eval(q`
    use strict ;
    my @inc = sort keys %INC ;
    print "\@INC: $#INC\n" if @INC ;
    print "%INC: @inc\n" ;
  `);
  
  $stdout =~ s/\@INC: \d+/\@INC: x/ ;
  
  ok($stdout , "\@INC: x\n\%INC: strict.pm\n");
  ok($stderr , '') ;

}
#########################
{

  my ( $stdout0 , $stderr0 ) ;

  my $world = Safe::World->new(
  stdout => \$stdout0 ,
  stderr => \$stderr0 ,
  ) ;
  
  $world->eval(q`
    print "test0\n" ;
  `);

  $world->close ;
  
  my ( $stdout1 , $stderr1 ) ;
  
  $world->reset(
  stdout => \$stdout1 ,
  stderr => \$stderr1 ,
  ) ;
  
  $world->eval(q`
    print "test1\n" ;
  `);  
  
  $world->close ;
  
  ok($stdout0 , "test0\n");
  ok($stderr0 , '') ;
  
  ok($stdout1 , "test1\n");
  ok($stderr1 , '') ;
  
}
#########################
{

  my ( $stdout0 , $stderr0 ) ;

  my $world = Safe::World->new(
  stdout => \$stdout0 ,
  stderr => \$stderr0 ,
  flush  => 1,
  ) ;
  
  $world->eval(q`
    print "test0\n" ;
    warn("alert0");
  `);
  
  my ( $stdout1 , $stderr1 ) ;
  
  $world->reset_output(
  stdout => \$stdout1 ,
  stderr => \$stderr1 ,
  ) ;
  
  $world->eval(q`
    print "test1\n" ;
    warn("alert1");    
  `);  
  
  $world->close ;
  
  ok($stdout0 , "test0\n");
  ok($stderr0 =~ /^alert0[^\r\n]*$/) ;
  
  ok($stdout1 , "test1\n");
  ok($stderr1 =~ /^alert1[^\r\n]*$/s) ;

}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  $world->eval(q`
    sub test { print "SUBTEST <@_> " ; }
  `);
  
  $world->eval(q`
    &test ;
    test(123,456) ;
    test ;
  `);

  $world->call('test','outside');

  ok($stdout , "SUBTEST <> SUBTEST <123 456> SUBTEST <> SUBTEST <outside> ");
  ok($stderr , '') ;

}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  $world->eval(q`
    use test::shared ;
    my @incs = sort keys %INC ;
    print "incs> @incs\n" ;
  `);

  $world = undef ;
  
  ok($stdout , "incs> strict.pm test/shared.pm\n");

}
#########################
{

  my ( $stdout0 , $stderr0 ) ;

  my $world0 = Safe::World->new(
  stdout => \$stdout0 ,
  stderr => \$stderr0 ,
  flush  => 1 ,
  ) ;
  
  $world0->eval(q`
    use test::shared ;
    
    my @incs = sort keys %INC ;
    print "incs> @incs\n" ;
    
    $TEST = 'w0' ;
    print ">> $test::shared::VAR\n" ;
    test::shared::method(0) ;
  `);
  
  my ( $stdout1 , $stderr1 ) ;
  
  my $world1 = Safe::World->new(
  stdout => \$stdout1 ,
  stderr => \$stderr1 ,
  flush  => 1 ,
  ) ;
  
  $world1->link_pack("$world0->{ROOT}::test::shared") ;
  
  $world1->eval(q`
    my @incs = sort keys %INC ;
    print "incs> @incs\n" ;
    
    $TEST = 'w1' ;
    print ">> $test::shared::VAR\n" ;
    test::shared::method(1) ;
  `);
  
  my ( $stdout2 , $stderr2 ) ;
  
  my $world2 = Safe::World->new(
  stdout => \$stdout2 ,
  stderr => \$stderr2 ,
  flush  => 1 ,
  ) ;
  
  $world2->link_pack("$world0->{ROOT}::test::shared") ;
  
  $world2->eval(q`
    my @incs = sort keys %INC ;
    print "incs> @incs\n" ;
    
    $TEST = 'w2' ;
    print ">> $test::shared::VAR\n" ;
    test::shared::method(2) ;
  `);
  
  ok($stdout0 , "incs> strict.pm test/shared.pm\n>> foovar\nSHARED[1]! [w0][w0] <<0>>\n");
  ok($stderr0 , '') ;

  ok($stdout1 , "incs> strict.pm\n>> foovar\nSHARED[2]! [w0][w1] <<1>>\n");
  ok($stderr1 , '') ;

  ok($stdout2 , "incs> strict.pm\n>> foovar\nSHARED[3]! [w0][w2] <<2>>\n");
  ok($stderr2 , '') ;
  
  ok($INC{'test/shared.pm'} , undef) ;

}
#########################
{

  my ( $stdout0 , $stderr0 ) ;

  my $world0 = Safe::World->new(
  stdout => \$stdout0 ,
  stderr => \$stderr0 ,
  flush  => 1 ,
  ) ;
  
  $world0->eval(q`
    use test::shared ;
    my @incs = sort keys %INC ;
    print "incs> @incs\n" ;
    
    $TEST = 'w0' ;
    print ">> $test::shared::VAR\n" ;
    test::shared::method(0) ;
  `);
  
  $world0->set_sharedpack('test::shared') ;
  
  my ( $stdout1 , $stderr1 ) ;
  
  my $world1 = Safe::World->new(
  stdout => \$stdout1 ,
  stderr => \$stderr1 ,
  flush  => 1 ,
  ) ;
  
  my $lnk = $world1->link_world($world0) ;
  ok($lnk,1) ;
  ok($world0->{WORLD_SHARED}[0], $world1->{ROOT}) ;
  
  $world1->eval(q`
    my @incs = sort keys %INC ;
    print "incs> @incs >> $INC{'test/shared.pm'}\n" ;
    $TEST = 'w1' ;
    print ">> $test::shared::VAR\n" ;
    test::shared::method(1) ;
  `);
  
  $world1->unlink_world($world0) ;
  
  my ( $stdout2 , $stderr2 ) ;
  
  my $world2 = Safe::World->new(
  stdout => \$stdout2 ,
  stderr => \$stderr2 ,
  flush  => 1 ,
  ) ;
  
  $lnk = $world2->link_world($world0) ;
  ok($lnk,1) ;
  ok($world0->{WORLD_SHARED}[0], $world2->{ROOT}) ;
  
  $world2->eval(q`
    my @incs = sort keys %INC ;
    print "incs> @incs >> $INC{'test/shared.pm'}\n" ;
    $TEST = 'w2' ;
    print ">> $test::shared::VAR\n" ;
    test::shared::method(2) ;
  `);
  
  $world2->unlink_world($world0) ;  
  
  $world0->eval(q`
    my @incs = sort keys %INC ;
    print "incs> @incs\n" ;
    print ">> $test::shared::VAR\n" ;
    test::shared::method('0.1') ;
  `);
  
  ok($stdout0 , "incs> strict.pm test/shared.pm\n>> foovar\nSHARED[1]! [w0][w0] <<0>>\nincs> strict.pm test/shared.pm\n>> foovar\nSHARED[4]! [w0][w0] <<0.1>>\n");
  ok($stderr0 , '') ;

  ok($stdout1 , "incs> strict.pm test/shared.pm >> #shared#\n>> foovar\nSHARED[2]! [w1][w1] <<1>>\n");
  ok($stderr1 , '') ;

  ok($stdout2 , "incs> strict.pm test/shared.pm >> #shared#\n>> foovar\nSHARED[3]! [w2][w2] <<2>>\n");
  ok($stderr2 , '') ;

}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  on_select => sub { print "SELECT " ; } ,
  on_unselect => sub { print "UNSELECT " ; } ,
  ) ;
  
  $world->eval(q`
    print "Test1 " ;
  `);
  
  ok($stdout , "SELECT UNSELECT SELECT Test1 UNSELECT ") ;
  ok($stderr , '') ;

}
#########################
{

  my ( $stdout , $stderr , $headout ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr  => \$stderr ,
  headout => \$headout ,
  headspliter => 'HTML' ,
  autohead => 1 ,
  #flush => 1 ,
  
  on_closeheaders => sub {
                       my ( $world ) = @_ ;
                       my $headers = $world->headers ;

                       my $data = $world->stdout_data ;

                       $headers =~ s/[\r\n\012\015]+/\n/gs ;
                       $headers =~ s/^[ \t]+\n/\n/gs ;
                       $headers =~ s/^\n+//s ;
                       $headers =~ s/\n+$//s ;
                       $headers =~ s/\n+/\015\012/gs ;

                       $headers .= "\015\012\015\012" ;
  
                       $world->print( "HEADERS[[\n$headers]]\n" ) ;
                       $world->headers('') ;
                     } ,
  
  on_exit => sub {
               my ( $world ) = @_ ;
               $world->print("<<ON_EXIT_IN>>\n");
               return 0 ;
             } ,
  ) ;
  
  $world->print("headers init!\n") ;
  
  $world->eval(q`
     print "Content-type: text/html\n\n" ; 
     print "<html>\n" ;
     
     print "content1\n" ;
     
     $SAFEWORLD->print_header("1: more headers after close!\n");     
     
     $|=1;
     
     print "content2\n" ;
     
     $SAFEWORLD->print_header("2: more headers after flush!\n");     
     
     $|=0;

     print STDERR "error!\n" ;
     
     warn("warning!!!") ;
     
     print "content3\n" ;     
     
     exit ;
     
     print "end!\n" ;
  `);
  
  $world->close ; ## flush all and exit.
  
  ok($headout , "2: more headers after flush!\n") ;
  
  $stdout =~ s/\r\n?/\n/gs ;

ok($stdout , q`HEADERS[[
headers init!
Content-type: text/html
1: more headers after close!

]]
<html>
content1
content2
content3
<<ON_EXIT_IN>>
end!
`) ;

  $stderr =~ s/eval \d+/eval x/gi ;

  ok($stderr , "error!\nwarning!!! at (eval x) line 19.\n") ;
}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  ) ;
  
  ok(1);
  
  print "## Socket test at www.perl.com: to test bug at select() with IO::Socket.\n" ;
  
  $world->eval(q`
  
    use IO::Socket ;

    my $host = 'www.perl.com' ;

    my $sel = select ;
    
    print "SEL: $sel\n" ;

    my $sock = new IO::Socket::INET(
       PeerAddr => $host,
       PeerPort => 80,
       Proto    => 'tcp',
       Timeout  => 30) ;

    if ($sock) {
      $sock->autoflush(1) ;
      my $rn = "\015\012" ;
    
      print $sock "GET / HTTP/1.0$rn" ;
      print $sock "Host: $host$rn" ;
      print $sock "$rn$rn" ;
      
      my $data ;
      1 while( read($sock, $data , 1024*4, length($data) ) ) ;
      
      print "DATA: " ;
      if ( $data =~ /<html>.*?<\/html>/si ) { print "ok\n" ;}
      else { print "error\n" ;}
    }
    else { print "SOCKET ERROR!\n" ;}

    close($sock) ;
  `);
  
  $world->close ;
  
  if ( $stdout =~ /SOCKET ERROR/s ) {
    print "## ** Socket test skiped! Can't connect to www.perl.com!\n" ;
  }
  else {
    my $root = $world->root ;
    print " "; ok( $stdout =~ /SEL: (?:main|$root)::STDOUT/s ) ;
    print " "; ok( $stdout =~ /DATA: ok/s ) ;
    print "## End of Socket tests.\n" ;    
  }

  ## Can't have warnings for constant sub redefinition! Bug at Perl-5.8.x
  ok($stderr , '') ;
  
}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  $world->eval(q`
    sub test { print "sub_test[@_]" ; }
  
    print "A|" ;
    
    my $out ;
    $SAFEWORLD->redirect_stdout(\$out) ;
    test(123);
    $SAFEWORLD->restore_stdout ;
    
    print "B|" ;
    print "OUT: <$out>" ;
  `);

  ok($stdout , 'A|B|OUT: <sub_test[123]>') ;
  ok($stderr , '') ;
}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;

  $world->eval(q`
    &null ;
  `);
  
  $world->eval(q`
    sub test { print "sub_test[@_]" ; }
    print "A|" ;
    &test ;
    print "B|" ;
  `);
  
  ok($stdout , 'A|sub_test[]B|') ;
  ok($stderr =~ /Undefined subroutine &(?:main|SAFEWORLD\d+)::null/) ;

}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  $world->eval(q`
    print "A|" ;
    exit ;
    print "B|" ;
  `);
  
  $world->eval(q`
    print "C|" ;
  `);

  ok($stdout , 'A|') ;
  ok($stderr =~ /Can't evaluate after exit!/) ;

}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  $world->eval(q`
    print "A|" ;
    die ;
    print "B|" ;
  `);
  
  $world->eval(q`
    print "C|" ;
  `);
  
  ok($stdout , 'A|C|') ;
  ok($stderr =~ /Died at \(eval \d+\)/) ;

}
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  $world->eval(q` print "a> @_|" ; `);
  
  $world->eval_args(q` print "b> @_|" ;` , 123 , 456);
  
  ok($stdout , 'a> |b> 123 456|') ;
  ok($stderr , '') ;

}
#########################
{

package foo ;
  use vars qw($var);
  $var = 'foovar!' ;
  sub test { print "TEST! $var >> @_|" ; }
  
package main ;

  use Safe::World::Scope ;
  
  my $scope = new Safe::World::Scope('foo') ;
    
  my ( $stdout , $stderr ) ;
  
  my $world = new Safe::World(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
    
  $world->set('$scope' , $scope , 1) ; ## Set the object inside the World.
  
  $world->eval(q`
    $scope->call('test','argmunet') ;
    
    my $v = $scope->get('$var') ;
    print "var: $v|" ;
    
    $scope->set('$var', '123' ) ;
    
    $v = $scope->get('$var') ;
    print "var after set: $v|" ;
  `);
  
  ok($stdout , 'TEST! foovar! >> argmunet|var: foovar!|var after set: 123|') ;
  ok($stderr , '') ;

}
#########################
{

  my ( $stdout0 , $stderr0 ) ;

  my $world_cache = Safe::World->new(
  stdout => \$stdout0 ,
  stderr => \$stderr0 ,
  flush  => 1 ,
  ) ;
  
  my ( $link_pack , $inc ) = $world_cache->use_shared('test::useshared') ;
  
  ok( @$link_pack ) ;
  ok( (keys %$inc) ) ;
  
  $world_cache->eval(q`
    print test::useshared::test() . "#" ;
    print test::required::test() . "#" ;
  `);
    
  my ( $stdout1 , $stderr1 ) ;
  
  my $world = Safe::World->new(
  stdout => \$stdout1 ,
  stderr => \$stderr1 ,
  flush  => 1 ,
  ) ;
  
  $world->link_world($world_cache) ;
  
  $world->eval(q`
    print test::useshared::test() . "#" ;
    print test::required::test() . "#" ;
    print "$INC{'test/useshared.pm'}|$INC{'test/required.pm'}" ;
  `);
    
  ok($stdout0 , 'useshared_ok#required_ok#') ;
  ok($stderr0 , '') ;
  
  ok($stdout1 , 'useshared_ok#required_ok##shared#|#shared#') ;
  ok($stderr1 , '') ;

}

if (0) {
#########################
{

  my ( $stdout , $stderr ) ;

  my $world = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  flush  => 1 ,
  ) ;
  
  my $outvar ;
  
  $world->eval_args(q` $refout = $_[0] ;` , \$outvar ) ;
  
  $world->eval(q` print "REF: ". ref($refout) ; `) ;
  
  $world->eval(q` $$refout = 123 ;`) ;
  
  ok($outvar , 123) ;
  
  $world->eval(q`
    require test::endblk ;
  `) ;
  
  $world->close ;
  
  $world = undef ;
  
  ok($outvar , 'END BLOCK EXECUTED!') ;
  
  ok($stdout , 'REF: SCALAR') ;
  ok($stderr , '') ;
  

}
#########################
}

print "\nThe End! By!\n" ;

1 ;


