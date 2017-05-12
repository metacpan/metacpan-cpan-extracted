unit PLDelphi_dll ;

interface

uses
  ShareMem , SysUtils , Windows ;

type DWORD = Longword;

{******************************************************************************}

type
   SV = class(TObject)
   private
     ID : Integer ;
   public
     function call( method : String ) : String; overload ;
     function call( method , args : String ) : String; overload ;
     function call_sv( method : String ) : SV; overload ;
     function call_sv( method , args : String ) : SV; overload ;

     constructor Create( newid : String );
     destructor Destroy(); override;
end;

{******************************************************************************}

type
   Perl = class(TObject)
   private
     ID : Integer ;
   public

     class function error() : String; overload ;

     class function eval( code : String ) : String; overload ;
     class function eval_sv( code : String ) : SV; overload ;
     class function eval_int( code : String ) : Integer; overload ;

     class function call( code : String ) : String; overload ;
     class function call_args( code , args : String ) : String; overload ;

     class function quoteit( s : String ) : String; overload ;

     class function NEW( pkg : String ) : SV; overload ;
     class function NEW( pkg , args : String ) : SV; overload ;

     class function use( pkg : String ) : Boolean; overload ;
     class function use( pkg , args : String ) : Boolean; overload ;
end;

{******************************************************************************}

  function PLDelphi_start: Integer; cdecl;
  function PLDelphi_eval( code : Pchar ) : Pchar; cdecl;
  function PLDelphi_eval_sv( code : Pchar ) : Pchar; cdecl;

  function PLDelphi_call( code : Pchar ) : Pchar; cdecl;
  function PLDelphi_call_args( code , args : Pchar ) : Pchar; cdecl;

  function PLDelphi_error : Pchar; cdecl;
  procedure PLDelphi_stop ; cdecl;

  procedure PatchINT3 ;

implementation

{******************************************************************************}

class function Perl.error() : String;
begin
  Result := PLDelphi_error() ;
end;

class function Perl.eval( code : String ) : String;
begin
  Result := PLDelphi_eval( PChar(code) ) ;
end;

class function Perl.eval_sv( code : String ) : SV ;
begin
  Result := SV.Create( PLDelphi_eval_sv( PChar(code) ) ) ;
end;

class function Perl.eval_int( code : String ) : Integer;
begin
  Result := StrtoInt( PLDelphi_eval( PChar(code) ) ) ;
end;

class function Perl.call( code : String ) : String;
begin
  Result := PLDelphi_call( PChar(code) ) ;
end;

class function Perl.call_args( code , args : String ) : String;
begin
  Result := PLDelphi_call_args( PChar(code) , PChar(args) ) ;
end;

class function Perl.NEW( pkg : String ) : SV;
begin
  Result := eval_sv( PChar('new ' + pkg + '()') ) ;
end;

class function Perl.NEW( pkg , args : String ) : SV;
begin
  Result := eval_sv( PChar('new ' + pkg + '('+ args +')') ) ;
end;

class function Perl.use( pkg : String ) : Boolean;
begin
  eval( PChar('use ' + pkg) ) ;
end;

class function Perl.use( pkg , args : String ) : Boolean;
begin
  eval( PChar('use ' + pkg + '('+ args +')') ) ;
end;

class function Perl.quoteit( s : String ) : String;
var
  str , t : String ;
  i : Integer ;
begin
  str := '''' ;

  for i := 1 to Length(s) do
  begin
    t := Copy( s , i , 1 ) ;

    if (t = '\') or (t = '''') then
    begin
      str := str + '\' + t ;
    end
    else
    begin
      str := str + t ;
    end;
  end;

  str := str + '''' ;

  Result := str ;
end;

{******************************************************************************}

constructor SV.Create( newid : String );
begin
  ID := StrtoInt(newid) ;
end;

destructor SV.Destroy;
begin
  Perl.call_args('PLDelphi::SV_destroy' , InttoStr(ID) ) ;
  inherited Destroy() ;
end;

function SV.call( method : String ) : String;
begin
  //Result := Perl.eval('PLDelphi::SV_call('+ InttoStr(ID) +' , '+ Perl.quoteit(method) +')') ;
  Result := Perl.call_args('PLDelphi::SV_call' , InttoStr(ID) +' , '+ Perl.quoteit(method) ) ;
end;

function SV.call( method , args : String ) : String;
begin
  //Result := Perl.eval('PLDelphi::SV_call('+ InttoStr(ID) +' , '+ Perl.quoteit(method) +' , '+ args +')' ) ;
  Result := Perl.call_args('PLDelphi::SV_call' , InttoStr(ID) +' , '+ Perl.quoteit(method) +' , '+ args ) ;
end;

function SV.call_sv( method : String ) : SV;
begin
  Result := Perl.eval_sv('PLDelphi::SV_call('+ InttoStr(ID) +' , '+ Perl.quoteit(method) +')') ;
end;

function SV.call_sv( method , args : String ) : SV;
begin
  Result := Perl.eval_sv('PLDelphi::SV_call('+ InttoStr(ID) +' , '+ Perl.quoteit(method) +' , '+ args +')' ) ;
end;

{******************************************************************************}

const
  PLDELPHI_DLL_NAME = 'PLDelphi.dll' ;

function PLDelphi_start; external PLDELPHI_DLL_NAME name 'PLDelphi_start';

function PLDelphi_eval; external PLDELPHI_DLL_NAME name 'PLDelphi_eval' ;
function PLDelphi_eval_sv; external PLDELPHI_DLL_NAME name 'PLDelphi_eval_sv' ;

function PLDelphi_call; external PLDELPHI_DLL_NAME name 'PLDelphi_call' ;
function PLDelphi_call_args; external PLDELPHI_DLL_NAME name 'PLDelphi_call_args' ;

function PLDelphi_error; external PLDELPHI_DLL_NAME name 'PLDelphi_error' ;

procedure PLDelphi_stop; external PLDELPHI_DLL_NAME name 'PLDelphi_stop';

procedure PatchINT3 ;
var
  NOP : Byte;
  NTDLL: THandle;
  BytesWritten: DWORD;
  Address: Pointer;
begin
  //if Win32Platform <> VER_PLATFORM_WIN32_NT then Exit;

  NTDLL := GetModuleHandle('NTDLL.DLL');
  if NTDLL = 0 then Exit;

  Address := GetProcAddress(NTDLL, 'DbgBreakPoint');

  if Address = nil then Exit;

  try
    if Char(Address^) <> #$CC then Exit;
    NOP := $90;
    if WriteProcessMemory(GetCurrentProcess, Address, @NOP, 1, BytesWritten) and (BytesWritten = 1) then
      FlushInstructionCache(GetCurrentProcess, Address, 1);
  except
    //Do not panic if you see an EAccessViolation here, it is perfectly harmless!
    on EAccessViolation do
    else raise;
  end;
end;

{******************************************************************************}

begin
  PatchINT3() ;
  PLDelphi_start() ;
end.

{******************************************************************************}
