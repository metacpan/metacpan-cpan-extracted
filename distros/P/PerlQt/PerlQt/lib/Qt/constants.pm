package Qt::constants;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    IO_Direct
    IO_Sequential
    IO_Combined 
    IO_TypeMask 
    IO_Raw 
    IO_Async
    IO_ReadOnly 
    IO_WriteOnly
    IO_ReadWrite 
    IO_Append
    IO_Truncate
    IO_Translate 
    IO_ModeMask  
    IO_Open      
    IO_StateMask 
    IO_Ok        
    IO_ReadError 
    IO_WriteError
    IO_FatalError
    IO_ResourceError
    IO_OpenError    
    IO_ConnectError 
    IO_AbortError   
    IO_TimeOutError 
    IO_UnspecifiedError
);

our %EXPORT_TAGS = ( 'IO' => [ @EXPORT ] );

sub IO_Direct     () { 0x0100 }
sub IO_Sequential () { 0x0200 }
sub IO_Combined   () { 0x0300 }
sub IO_TypeMask   () { 0x0f00 }
sub IO_Raw        () { 0x0040 }
sub IO_Async      () { 0x0080 }
sub IO_ReadOnly   () { 0x0001 }
sub IO_WriteOnly  () { 0x0002 }
sub IO_ReadWrite  () { 0x0003 }
sub IO_Append     () { 0x0004 }
sub IO_Truncate   () { 0x0008 }
sub IO_Translate  () { 0x0010 }
sub IO_ModeMask   () { 0x00ff }
sub IO_Open       () { 0x1000 }
sub IO_StateMask  () { 0xf000 }
sub IO_Ok              () { 0 }
sub IO_ReadError       () { 1 }
sub IO_WriteError      () { 2 }
sub IO_FatalError      () { 3 }
sub IO_ResourceError   () { 4 }       
sub IO_OpenError       () { 5 }
sub IO_ConnectError    () { 5 }
sub IO_AbortError      () { 6 }
sub IO_TimeOutError    () { 7 }
sub IO_UnspecifiedError() { 8 }

1;