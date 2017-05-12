program ConsoleTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  PLDelphi_dll ;

var
  browser , response : SV ;
    
begin

  writeln('***********') ;

  Perl.use('WWW::Mechanize');

  browser := Perl.NEW('WWW::Mechanize');

  response := browser.call_sv('get',' "http://www.perl.com/" ') ;

  writeln( response.call('content') ) ;

  FreeAndNil(response) ;
  FreeAndNil(browser) ;

  writeln('***********') ;

end.
