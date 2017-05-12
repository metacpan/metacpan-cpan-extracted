#!/usr/local/bin/perl

## Copyright(c) 1998-1999 by John C. Siracusa.  All rights reserved.  This
## program is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.

##
## hlftp.pl - A simple FTP-like hotline client by John Siracusa, created to
##            demonstrate the Net::Hotline::Client module's blocking task mode.
##
## Created:  July      10th, 1998
## Modified: September 21st, 1999
##

use strict;

use Cwd;
use Text::Wrap;
use Getopt::Std;
use Term::ReadLine;
use Time::localtime;
use Net::Hotline::Client;
use Net::Hotline::Constants
  qw(HTXF_PARTIAL_TYPE HTXF_PARTIAL_CREATOR HTLC_MACOS_TO_UNIX_TIME
     HTLC_FOLDER_TYPE HTLC_INFO_FOLDER_TYPE HTLC_INFO_FALIAS_TYPE);

my $VERSION = '1.07';

my(%OPT, $LPWD, $RPWD, $NICK, $TERM);

getopts('bchn:pquvx', \%OPT);

if($OPT{'v'})
{
  print "hlftp version $VERSION by John Siracusa\n";
  exit(0);
}

Usage()  if($OPT{'h'});

my $DEF_LOGIN    = 'guest';
my $DEF_PASSWORD = '';
my $DEF_SERVER   = undef;
my $DEF_PORT     = undef;
my $DEF_ICON     = 410;

my $ICON         = $DEF_ICON;
my $LOGIN        = $DEF_LOGIN;

my $MACOS        = ($^O eq 'MacOS');

my $LOCAL_SEP    = ($MACOS) ? ':' : '/';
my $REMOTE_SEP   = ':';

my $MACBIN_MODE  = ($OPT{'b'} || !$MACOS) ? 1 : 0;
my $CLOBBER_MODE = ($OPT{'c'}) ? 1 : 0;
my $PROMPTING    = 1;

my $COLS = $ENV{'COLUMNS'} || $ENV{'COLS'} || 80;
$Text::Wrap::columns = $COLS;

my $OUT = *STDOUT;

$Net::Hotline::Client::DEBUG = 0;

my $FOLDER_REGEX = join ('|', HTLC_FOLDER_TYPE, HTLC_INFO_FOLDER_TYPE, HTLC_INFO_FALIAS_TYPE);

my %HELP = (
'cd'      => 'cd <dir>        Change remote working directory to <dir>',
'clobber' => 'clobber         Toggle overwrite-when-downloading behavior.',
'close'   => 'close           Disconnect from the server.',
'del'     => 'del <file>      Delete <file> from the server.',
'dir'     => 'dir <dir>       Does an "ls -l" on <dir> in the server.',
'get'     => 'get <file>      Get <file> from the remote server.',
'help'    => 'help <cmd>      Get general help or help for <cmd>',
'icon'    => 'icon <num>      Set your icon to <num>',
'info'    => 'info <file>     Get information about <file>',
'lcd'     => 'lcd <dir>       Change local working directory to <dir>',
'ldir'    => 'ldir <dir>      Does an "ls -l" on the local directory <dir>',
'lls'     => 'lls [-l] <dir>  List files in the local directory <dir>',
'lpwd'    => 'lpwd            Show the current local working directory.',
'ls'      => 'ls [-l] <dir>   List files in <dir> on the server.',
'macbin'  => 'macbin          Toggle MacBinary download mode.',
'mget'    => 'mget <regex>    Get files matching <regex> from the server.',
'mput'    => 'mput <regex>    Put files matching <regex> on server.',
'nick'    => 'nick <nick>     Set your nickname to <nick>',
'open'    => 'open <server>   Open connection to <server>',
'prompt'  => 'prompt          Toggle cautionary prompting.',
'pwd'     => 'pwd             Show the current remote working directory.',
'quiet'   => 'quiet           Quiet mode: less verbose output.',
'quit'    => 'quit            Exit hlftp.',
'status'  => 'status          Show current status.',
'version' => 'version         Show the hlftp version number.',
'wd'      => 'wd              Show local and remote working directories.');

sub print_wrap; # Forward declaration

MAIN:
{
  my($login, $pass, $server, $port, $path) = Parse_Command_Line();

  my($hlc) = Start_Up($login, $pass, $server, $port, $path);

  Converse($hlc, $server);
}

sub Parse_Command_Line
{
  if(@ARGV == 0)
  {
    return($DEF_LOGIN, $DEF_PASSWORD, $DEF_SERVER, $DEF_PORT, undef);
  }
  elsif(@ARGV > 1)
  {
    Usage();
  }
  else
  {
    $_ = $ARGV[0];

    s#^ho?t?li?n?e?://##i;

    if(m{^([^:]+):([^@]+)@([^:/]*)  # Login, pass, server 
          (?::(\d+))?               # Port
          (/.*)?$                   # Path
        }ix)
    {
      return($1, $2, $3, $4, $5);
    }
    elsif(m{^([^:@]+):?@([^:/]*)    # Login, server 
             (?::(\d+))?            # Port
             (/.*)?$                # Path
           }ix)
    {
      return($1, $DEF_PASSWORD, $2, $3, $4);
    }
    elsif(m{^([^:/]*)(?::(\d+))?    # Server, port
             (/.*)?$                # Path
           }ix)
    {
      return($DEF_LOGIN, $DEF_PASSWORD, $1, $2, $3);
    }
    else
    {
      Usage();
    }
  }
}

sub Usage
{
  print STDERR<<'EOF';
Usage: hlftp [-bchpquvx] [-n nick] [hotline://user:pass@host.com:port/path/]
-b    MacBinary mode (on by default on non-Mac OS systems).
-c    Clobber mode: overwrite existing files.
-h    Show this help screen.
-p    Use shorter prompt.
-q    Quiet mode: less verbose output.
-u    Prompt for username and password.
-v    Show the hlftp version number.
-x    Exit after failed command line connections.
EOF

  exit(1);
}

sub Help
{
  my($cmd) = shift;

  my($printed);

  if($cmd =~ /\S/)
  {
    $cmd = Shell_RE_To_Perl_RE($cmd);

    if(Safe_Regex(\$cmd))
    {
      foreach my $hcmd (sort(keys(%HELP)))
      {
        if($hcmd =~ /^$cmd$/i)
        {
          print $OUT "\n"  unless($printed);
          print_wrap $HELP{$hcmd}, "\n";
          $printed = 1;
        }
      }

      if($printed) { print $OUT "\n" }
      else
      {
        print_wrap "No commands matching \"$cmd\" were found.\n";
      }
    }
    else
    {
      print_wrap "Bad regex: $cmd\n";
    }    
  }
  else
  {
    my(@cmds, $i, $j, $cols);

    @cmds = sort(keys(%HELP));
    $cols = int($COLS/10);

    print_wrap "'help <command>' gives a brief description of <command>\n\n";

    for($i = 0; $i <= $#cmds;)
    {
      for($j = 0; $j < $cols && $i <= $#cmds; $j++)
      {
        print $OUT sprintf("%-10s", $cmds[$i]);
        $i++;
      }
      print $OUT "\n";
    }
    print $OUT "\n";
  }
}

sub Start_Up
{
  my($login, $pass, $server, $port, $path) = @_;

  my($server_arg) = $server;

  if($MACBIN_MODE && $MACOS)
  {
    print_wrap "Sorry, MacBinary mode is disabled on Mac OS.\n";
    MacBinary_Mode('off');
  }

  ($login, $pass) = Login_Pass()  if($OPT{'u'});

  my($hlc) = new Net::Hotline::Client;

  $LPWD = cwd();
  $hlc->downloads_dir($LPWD);
  $hlc->blocking_tasks(1);

  return($hlc)  unless($server);

  $path = Convert_Path($path);

  $server_arg .= ":$port"  if($port =~ /^\d+$/);

  print_wrap "Connecting to $server_arg...\n"  unless($OPT{'q'});

  unless($hlc->connect($server_arg))
  {
    print_wrap $hlc->last_error(), "\n";
    exit(1)  if($OPT{'x'});
    return($hlc);
  }

  unless(length($NICK))
  {
    if($OPT{'n'}) { $NICK  = $OPT{'n'} }
    else          { $NICK  = $login    }
  }

  print_wrap "Logging in as \"$login\"...\n"  unless($OPT{'q'});

  unless($hlc->login(Login    => $login,
                     Password => $pass,
                     Nickname => $NICK,
                     Icon     => $DEF_ICON,
                     News     => 'no',
                     UserList => 'no'))
  {
    print_wrap "Login to $server_arg failed: ", $hlc->last_error(), "\n";
    exit(1)  if($OPT{'x'});
    return($hlc);
  }

  $LOGIN = $login;

  unless(length($NICK))
  {
    if($OPT{'n'}) { $NICK  = $OPT{'n'} }
    else          { $NICK  = $login    }
  }

  if($path =~ m#:|/#)
  {
    print_wrap "Changing directory to <root>...\n"  unless($OPT{'q'});
    Change_Dir_Remote($hlc, $path);
  }
  elsif(length($path))
  {
    # Check that path is a directory
    my($info) = $hlc->get_fileinfo($path);

    unless($info)
    {
      print_wrap "No such file or directory: $path\n";

      if($OPT{'x'})
      {
        $hlc->disconnect();
        exit(1);
      }

      return($hlc);
    }

    if($info->type() =~ /^($FOLDER_REGEX)$/i)
    {
      print_wrap "Changing directory to $path...\n"  unless($OPT{'q'});
      Change_Dir_Remote($hlc, $path);
    }
    else
    {
      if(Get_File($hlc, $path))
      {
        $hlc->disconnect();
        exit;
      }
    }
  }
  else
  {
    $RPWD = '';
  }

  return($hlc);
}

sub Disconnect
{
  my($hlc, $prompt_ref) = @_;

  if($hlc->connected())
  {
    $hlc->disconnect();
    print_wrap "Connection closed.\n"  unless($OPT{'q'});
    Set_Prompt($hlc, $prompt_ref);
  }
  else
  {
    print_wrap "Not connected.\n"  unless($OPT{'q'});
  }
}

sub Reconnect
{
  my($hlc, $user_pass, $server) = @_;

  my($login, $pass);

  if($hlc->connected())
  {
    print_wrap "Closing connection to ", $hlc->server(), "...\n";
    $hlc->disconnect();
  }

  if($user_pass)
  {
    ($login, $pass) = Login_Pass();
  }
  else
  {
    ($login, $pass) = ($DEF_LOGIN, $DEF_PASSWORD);
  }

  unless(length($NICK))
  {
    if($OPT{'n'}) { $NICK  = $OPT{'n'} }
    else          { $NICK  = $login    }
  }

  $LOGIN = $login;
  $RPWD = '';

  print_wrap "Connecting to $server...\n"  unless($OPT{'q'});

  unless($hlc->connect($server))
  {
    print_wrap "Connection failed.\n";
    return;
  }

  print_wrap "Logging in as \"$login\"...\n"  unless($OPT{'q'});

  unless($hlc->login(Login      => $login,
                     Password   => $pass,
                     Nickname   => $NICK,
                     Icon       => $ICON,
                     NoNews     => 1,
                     NoUserList => 1))
  {
    print_wrap "Login to $server failed: ", $hlc->last_error(), "\n";
    return;
  }

  return(1);
}

sub Login_Pass
{
  my($login, $pass, $def);

  if($NICK)        { $def = $NICK      }
  elsif($OPT{'n'}) { $def = $OPT{'n'}  }
  else             { $def = $DEF_LOGIN }

  print_wrap "Login ($def): ";
  chomp($login = <STDIN>);

  system 'stty', '-echo'  unless($MACOS);
  print_wrap 'Password: ';
  chomp($pass = <STDIN>);

  unless($MACOS)
  {
    system 'stty', 'echo';
    print $OUT "\n";
  }

  $login = $def           unless(length($login));
  $pass  = $DEF_PASSWORD  unless(length($pass));

  return($login, $pass);
}

sub Converse
{
  my($hlc, $server) = @_;

  my($cmd, $prompt);

  $TERM = new Term::ReadLine 'Hotline FTP';
  $OUT  = $TERM->OUT || *STDOUT;

  print $OUT "Welcome to hlftp version $VERSION by John Siracusa\n"
    unless($OPT{'q'} || @ARGV);

  Set_Prompt($hlc, \$prompt);

  while(defined($cmd = $TERM->readline($prompt)))
  {
    Process_Command($hlc, $cmd, \$prompt);
    $TERM->addhistory($cmd)  if($cmd =~ /\S/);
  }
}

sub Process_Command
{
  my($hlc, $cmd, $prompt_ref) = @_;

  return unless($cmd =~ /\S/);

  for($cmd)
  {
    s/^\s*//;
    s/\s*$//;
  }

  return unless(length($cmd));

  $_ = $cmd;

  if(/^ls(?:\s+(?:(-l)(?:\s+|$))?(.*))?/)
  {
    List($hlc, $1, $2);
  }
  elsif(/^lls(?:\s+(?:(-l)(?:\s+|$))?(.*))?/)
  {
    List_Local($hlc, $1, $2);
  }
  elsif(/^(?:dir|ll)(?:\s+(\S.*))?$/)
  {
    List($hlc, '-l', $1);
  }
  elsif(/^(?:lll|ldir)(?:\s+(\S.*))?$/)
  {
    List_Local($hlc, '-l', $1);
  }
  elsif(/^cd\s+(\S.*)/)
  {
    Change_Dir_Remote($hlc, $1);
  }
  elsif(/^\.\.$/)
  {
    Change_Dir_Remote($hlc, '..');
  }
  elsif(/^lcd\s+(\S.*)/)
  {
    Change_Dir_Local($hlc, $1);
  }
  elsif(/^get\s+(\S.*)/)
  {
    Get_File($hlc, $1);
  }
  elsif(/^mget\s+(\S.*)/)
  {
    Get_Files($hlc, $1);
  }
  elsif(/^put\s+(\S.*)/)
  {
    Put_File($hlc, $1);
  }
  elsif(/^mput\s+(\S.*)/)
  {
    Put_Files($hlc, $1);
  }
  elsif(/^(?:del(?:ete)?|rm)\s+(\S.*)/)
  {
    Delete_File($hlc, $1);
  }
  elsif(/^mkdir\s+(\S.*)/)
  {
    Make_Dir($hlc, $1);
  }
  elsif(/^clobber(?:\s+(on|yes|off|no))?$/)
  {
    Clobber_Mode($hlc, $1);
  }
  elsif(/^(?:mac)?bin(?:ary)?(?:\s+(on|yes|off|no))?$/)
  {
    MacBinary_Mode($1);
  }
  elsif(/^info(?:rmation)?\s+(\S.*)/)
  {
    Get_Info($hlc, $1);
  }
  elsif(/^(?:\?+|help)(?:\s+(\S.*))?$/i)
  {
    Help($1);
  }
  elsif(/^close$/)
  {
    Disconnect($hlc, $prompt_ref);
  }
  elsif(/^open\s+(?:(-u)\s+)?(\S.*)/)
  {
    Reconnect($hlc, $1, $2);
    Set_Prompt($hlc, $prompt_ref);
  }
  elsif(/^prompt$/)
  {
    $PROMPTING = ($PROMPTING) ? 0 : 1;
    print $OUT "Interactive mode ", ($PROMPTING) ? 'on' : 'off', ".\n";
  }
  elsif(/^long\s*prompt$/)
  {
    $OPT{'p'} = 0;
    Set_Prompt($hlc, $prompt_ref);
  }
  elsif(/^short\s*prompt$/)
  {
    $OPT{'p'} = 1;
    Set_Prompt($hlc, $prompt_ref);
  }
  elsif(/^ver(s(ion)?)?$/)
  {
    print $OUT "hlftp version $VERSION by John Siracusa\n";
  }
  elsif(/^[cp]wd$/)
  {
    print_wrap "Remote dir: ", (length($RPWD)) ? $RPWD : '<root>', "\n";
  }
  elsif(/^l[cp]?wd$/)
  {
    print_wrap "Local dir: $LPWD\n";
  }
  elsif(/^wd$/)
  {
    print_wrap "Local  dir: $LPWD\n",
               "Remote dir: ", (length($RPWD)) ? $RPWD : '<root>', "\n";
  }
  elsif(/^(?:q(?:uit)?|bye|exit|x)$/)
  {
    $hlc->disconnect();
    exit;
  }
  elsif(/^nick\s+("?)(\S.*?)\1$/) #"
  {
    if(Nick($hlc, $2))
    {
      Set_Prompt($hlc, $prompt_ref);
    }
  }
  elsif(/^icon\s+(\d+)/)
  {
    Icon($hlc, $1);
    Set_Prompt($hlc, $prompt_ref);
  }
  elsif(/^stat(s|us)?/)
  {
    Status($hlc);
  }
  elsif(/^quiet|shh+$/)
  {
    $OPT{'q'} = !$OPT{'q'};
    print_wrap "Quiet mode OFF.\n"  unless($OPT{'q'});
  }
  else
  {
    print_wrap "Invalid command: $cmd\n";
  }
}

sub Status
{
  my($hlc) = shift;

  if($hlc->connected())
  {
    print_wrap "Nick:   $NICK\n",
               "Login:  $LOGIN\n",
               "Icon:   $ICON\n",
               "Server: ", $hlc->server(), "\n",
               "Local:  $LPWD\n",
               "Remote: ", (length($RPWD)) ? $RPWD : '<root>', "\n",
  }
  else
  {
    print_wrap "Nick:   $NICK\n",
               "Login:  $LOGIN\n",
               "Icon:   $ICON\n",
               "Server: (Not connected)\n",
               "Local:  $LPWD\n",
               "Remote: (Not connected)\n";
  }
}

sub MacBinary_Mode
{
  my($onoff) = shift;

  if($MACOS)
  {
    print_wrap "Sorry, MacBinary mode is disabled on Mac OS.\n";
    return;  
  }

  if(defined($onoff))
  {
    if($onoff =~ /^(on|yes)$/i)
    {
      $MACBIN_MODE = 1;
      print_wrap "MacBinary mode ON.\n";
    }
    else
    {
      $MACBIN_MODE = 0;
      print_wrap "MacBinary mode OFF.\n";
    }
  }
  else
  {
    $MACBIN_MODE = !$MACBIN_MODE;
    print_wrap "MacBinary mode ", ($MACBIN_MODE) ? 'ON' : 'OFF', "\n";
  }
}

sub Clobber_Mode
{
  my($hlc, $onoff) = @_;

  if(defined($onoff))
  {
    if($onoff =~ /^(on|yes)$/i)
    {
      $CLOBBER_MODE = 1;
      print_wrap "Clobber mode ON.\n";
    }
    else
    {
      $CLOBBER_MODE = 0;
      print_wrap "Clobber mode OFF.\n";
    }
  }
  else
  {
    $CLOBBER_MODE = !$CLOBBER_MODE;
    print_wrap "Clobber mode ", ($CLOBBER_MODE) ? 'ON' : 'OFF', "\n";
  }
}

sub Get_File
{
  my($hlc, $path, $absolute) = @_;

  unless($hlc->connected())
  {
    print_wrap "Not connected.\n";
    return;
  }

  my($file, $task, $ref, $size, $data_file, $rsrc_file,
     $finished_file, $resume, $ret, $clobber, @path);

  if($absolute)
  {
    @path = split($REMOTE_SEP, $path);
  }
  else
  {
    @path = Rel_To_Abs_Path_Remote(Convert_Path(Clean_Path($path)))
  }

  $path = join($REMOTE_SEP, @path);
  $file = $path[$#path];

  if(length($path))
  {
    # Check that path exists and is a file
    my($info) = $hlc->get_fileinfo($path);

    unless($info && $info->type() !~ /^($FOLDER_REGEX)$/)
    {
      print_wrap "No such file: $path\n";
      return;
    }
  }
  else
  {
    print_wrap "No such file: $path\n";
    return;
  }

  $finished_file = Rel_To_Abs_Path_Local($file);
  $data_file = $finished_file . $hlc->data_fork_extension();
  $rsrc_file = $finished_file . $hlc->rsrc_fork_extension();

  if(-e $finished_file)
  {
    $clobber = 1;

    if($MACOS)
    {
      my($creator, $type) = MacPerl::GetFileInfo($finished_file);

      if($type eq Net::Hotline::Constants::HTXF_PARTIAL_TYPE &&
         $creator eq Net::Hotline::Constants::HTXF_PARTIAL_CREATOR)
      {
        $resume = 1;
        $clobber = 0;
      }
    }
  }

  if($clobber)
  {
    if($CLOBBER_MODE)
    {
      unless(unlink($finished_file))
      {
        print_wrap "Could not delete $file: $!\n";
        return;
      }
    }
    else
    {
      print_wrap "\"$file\" already exists. Set \"clobber\" to overwrite.\n";
      return;
    }
  }

  if(!$MACOS)
  {
    $resume = (-e $rsrc_file || -e $data_file);
  }

  if(-e "$finished_file.bin" && $MACBIN_MODE)
  {
    if($CLOBBER_MODE)
    {
      unless(unlink("$finished_file.bin"))
      {
        print_wrap "Could not delete  $file.bin: $!\n";
        return;
      }
    }
    else
    {
      print_wrap "\"$file.bin\" already exists.  Set \"clobber\" to overwrite.\n";
      return;
    }
  }

  if($resume)
  {
    ($task, $ref, $size) = $hlc->get_file_resume($path);
  }
  else
  {
    ($task, $ref, $size) = $hlc->get_file($path);
  }

  unless($task)
  {
    print_wrap $hlc->last_error(), "\n";
    return;
  }

  if($resume)
  {
    print_wrap "Resuming file download: \"$file\" ($size bytes)...\n"  unless($OPT{'q'});
  }
  else
  {
    print_wrap "Getting file \"$file\" ($size bytes)...\n"  unless($OPT{'q'});
  }

  $ret = $hlc->recv_file($task, $ref, $size);

  unless($ret)
  {
    print_wrap "Download failed: ", $hlc->last_error(), "\n";
    return;
  }

  if($MACBIN_MODE && ref($ret))
  {
    print_wrap "Creating MacBinary file \"$file.bin\"...\n"  unless($OPT{'q'});

    unless($hlc->macbinary(undef, $ret))
    {
      print_wrap "Could not create MacBinary file: ", $hlc->last_error(), "\n";
      return;
    }

    # Delete the separate data and resource fork files
    unlink($data_file)  if(-e $data_file);
    unlink($rsrc_file)  if(-e $rsrc_file);
  }

  return(1);
}

sub Put_File
{
  my($hlc, $path) = @_;

  unless($hlc->connected())
  {
    print_wrap "Not connected.\n";
    return;
  }

  my($file, $task, $ref, $size, $remote_path, $check_file, $files, 
     $resume, $replace, $rflt, @path);

  @path = Rel_To_Abs_Path_Local($path);
  $file = $path[$#path];
  $remote_path = "$RPWD:$file";

  unless(-e $path)
  {
    print_wrap "File not found: $path\n";
    return;
  }

  if(-d $path)
  {
    print_wrap "Cannot put a directory.  Use \"mput\" instead.\n";
    return;
  }

  $files = $hlc->get_filelist($RPWD);

  unless($files)
  {
    print_wrap "Could not get file list for folder $RPWD: ", $hlc->last_error(), "\n";
    return;
  }

  foreach my $check_file (@{$files})
  {
    next unless($check_file->name() eq $file);

    if($check_file->type() eq HTXF_PARTIAL_TYPE &&
       $check_file->creator() eq HTXF_PARTIAL_CREATOR)
    {
      $resume = 1;
    }
    else
    {
      $replace = 1;
    }
  }

  if($replace)
  {
    print_wrap "A file named \"$file\" already exists.\n";
    return;
  }

  if($resume)
  {
    ($task, $ref, $size, $rflt) = $hlc->put_file_resume($path, $RPWD);
  }
  else
  {
    ($task, $ref, $size) = $hlc->put_file($path, $RPWD);
  }

  unless($task)
  {
    print_wrap $hlc->last_error(), "\n";
    return;
  }

  if($resume)
  {
    print_wrap "Resuming upload of file \"$file\" ($size bytes)...\n"  unless($OPT{'q'});
  }
  else
  {
    print_wrap "Putting file \"$file\" ($size bytes)...\n"  unless($OPT{'q'});
  }

  unless($hlc->send_file($task, $ref, $size, $rflt))
  {
    print_wrap "Upload failed: ", $hlc->last_error(), "\n";
    return;
  }

  return(1);
}

sub Put_Files
{
  my($hlc, $path) = @_;
  unless($hlc->connected())
  {
    print_wrap "Not connected.\n";
    return;
  }

  my(@path, $save_path, $dir, $check_path, $file, $regex, $found,
     $cd_backone, $res);

  $save_path = $path;

  @path = Rel_To_Abs_Path_Local($path);
  $check_path = Rel_To_Abs_Path_Local($path);

  if(-d $check_path)
  {
    print_wrap "Put the entire directory \"$save_path\"? (y/n) [n]: ";
    chomp($res = <STDIN>);
    unless($res =~ /^\s*y(es|up|eah)?\s*$/i)
    {
      print_wrap "mput aborted.\n";
      return(0);
    }
    $dir = $check_path;
    $regex = '*';

    unless(Make_Dir($hlc, $path[$#path]))
    {
      print_wrap "mput aborted.\n";
      return(0);
    }

    unless(Change_Dir_Remote($hlc, $path[$#path]))
    {
      print_wrap "mput aborted.\n";
      return(0);
    }
    $cd_backone = 1;
  }
  else
  {
    $dir = (($MACOS) ? '' : $LOCAL_SEP) .
           join($LOCAL_SEP, @path[0 .. $#path - 1]);
    $regex = $path[$#path];
  }

  $regex = Shell_RE_To_Perl_RE($regex);

  unless(Safe_Regex(\$regex))
  {
    $regex = quotemeta($regex);
  }

  unless(opendir(DIR, $dir))
  {
    print_wrap "Could not read directory \"$dir\" - $!\n";
    return(0);
  }

  while($file = readdir(DIR))
  {
    next if($file !~ /^$regex$/);

    if(-d "$dir$LOCAL_SEP$file")
    {
      print_wrap "Skipping directory \"$dir$LOCAL_SEP$file\"\n"
        unless($OPT{'q'} || ($file =~ /^\.\.?$/ && !$MACOS));
      next;
    }

    $found = 1;

    if($PROMPTING)
    {
      print_wrap "Put \"$file\"? (ynq) [n]: ";
      chomp($res = <STDIN>);

      if($res =~ /^\s*q(uit)?\s*$/i)
      {
        print_wrap "mput aborted.\n";
        return(0);
      }
      elsif($res !~ /^\s*y(es|up|eah)?\s*/i)
      {
        next;
      }
    }

    unless(Put_File($hlc, "$dir$LOCAL_SEP$file"))
    {
      if($PROMPTING)
      {  
        my($res);
        print_wrap "Continue with mput? (y/n) [n]: ";
        chomp($res = <STDIN>);
        return(1)  unless($res =~ /^\s*y(es|up|eah)?\s*/i);
      }
    }
  }

  if($cd_backone)
  {
    Change_Dir_Remote($hlc, '..');
  }

  unless($found)
  {
    print $OUT "mput: No match.\n";
  }

  return(1);
}

sub Get_Files
{
  my($hlc, $path) = @_;

  unless($hlc->connected())
  {
    print_wrap "Not connected.\n";
    return;
  }

  my(@path, $files, $name, $info, $regex, $save_path, $res,
     $file_path, $file_dir);

  $save_path = $path;

  @path = Rel_To_Abs_Path_Remote(Convert_Path(Clean_Path($path)));
  $path = join($REMOTE_SEP, @path);

  if(length($path))
  {
    $info = $hlc->get_fileinfo($path);

    # Last part of the path could have been a regex
    unless(ref($info))
    {
      $regex = pop(@path);
      $path = join($REMOTE_SEP, @path);

      if(length($path))
      {
        $info = $hlc->get_fileinfo($path);

        unless(ref($info) && $info->type() =~ /^($FOLDER_REGEX)$/i)
        {
          print_wrap "No such file or directory: $save_path\n";
          return;
        }
      }
    }
    elsif($info->type() =~ /^($FOLDER_REGEX)$/i)
    {
      print_wrap "Get the entire contents of the folder \"$path\"? (y/n) [n]: ";
      chomp($res = <STDIN>);
      unless($res =~ /^\s*y(es|up|eah)?\s*$/i)
      {
        print_wrap "mget aborted.\n";
        return(0);
      }
    }
  }

  if(defined($regex))
  {
    $regex = Shell_RE_To_Perl_RE($regex);

    unless(Safe_Regex(\$regex))
    {
      $regex = quotemeta($regex);
    }
  }

  $files = $hlc->get_filelist($path);

  $file_dir = $path;
  $path = '<root>'  unless(length($path));

  unless($files)
  {
    print_wrap "Could not get file list for folder $path: ", $hlc->last_error(), "\n";
    return;
  }

  foreach my $file (@{$files})
  {
    $name    = $file->name();

    next if(defined($regex) && $name !~ /^$regex$/);

    if($PROMPTING)
    {
      print_wrap "Get \"$name\"? (ynq) [n]: ";
      chomp($res = <STDIN>);

      if($res =~ /^\s*q(uit)?\s*$/i)
      {
        print_wrap "mget aborted.\n";
        return(0);
      }
      elsif($res !~ /^\s*y(es|up|eah)?\s*/i)
      {
        next;
      }
    }

    $file_path = Rel_To_Abs_Path_Remote($name, $file_dir);

    unless(Get_File($hlc, $file_path, 'absolute'))
    {
      if($PROMPTING)
      {  
        my($res);
        print_wrap "Continue with mget? (y/n) [n]: ";
        chomp($res = <STDIN>);
        return(1)  unless($res =~ /^\s*y(es|up|eah)?\s*/i);
      }
    }
  }
  return(1);
}

sub Nick
{
  my($hlc, $nick) = @_;

  $nick =~ s/(^|^[^\\]|[^\\]{2})"/$1"/g;
  $nick =~ s/^(.{,31}).*/$1/;

  if(length($nick))
  {
    $hlc->nick($nick)  if($hlc->connected());
    $NICK = $nick;

    return(1);
  }
  return;
}

sub Icon
{
  my($hlc, $icon) = @_;

  $hlc->icon($icon)  if($hlc->connected());
  $ICON = $icon;
}

sub Get_Info
{
  my($hlc, $path) = @_;

  unless($hlc->connected())
  {
    print_wrap "Not connected.\n";
    return;
  }

  my($name, @path, $info);

  @path = Rel_To_Abs_Path_Remote(Convert_Path(Clean_Path($path)));
  $path = join($REMOTE_SEP, @path);
  $name = $path[$#path];

  $info = $hlc->get_fileinfo($path);

  unless(ref($info))
  {
    print_wrap($hlc->last_error(), "\n");
    return;
  }

  my($size, $units, $comments);

  ($size, $units) = Size_Units($info->size());

  print_wrap "\n",
             "Name:     ", $info->name(), "\n",
             "Size:     $size $units\n",
             "Type:     ", $info->type(), "\n",
             "Creator:  ", $info->creator(), "\n",
             "Created:  ", Date_Text($info->ctime()), "\n",
             "Modified: ", Date_Text($info->mtime()), "\n";

  $comments = $info->comment();

  if(length($comments))
  {
    print_wrap "Comments: $comments\n";
  }

  print $OUT "\n";             

  return(1);
}

sub Make_Dir
{
  my($hlc, $path) = @_;

  unless($hlc->connected())
  {
    print_wrap "Not connected.\n";
    return;
  }

  my($name, @path);

  @path = Rel_To_Abs_Path_Remote(Convert_Path(Clean_Path($path)));
  $path = join($REMOTE_SEP, @path);
  $name = $path[$#path];

  unless($hlc->new_folder($path))
  {
    print_wrap($hlc->last_error(), "\n");
    return;
  }

  print_wrap "Folder created: $name\n"  unless($OPT{'q'});

  return(1);
}

sub Delete_File
{
  my($hlc, $path) = @_;

  unless($hlc->connected())
  {
    print_wrap "Not connected.\n";
    return;
  }

  my($folder, $name, @path, $res, $info, $regex, $save_path,
     $file_path, $file_dir, $found, $files);

  @path = Rel_To_Abs_Path_Remote(Convert_Path(Clean_Path($path)));
  $path = join($REMOTE_SEP, @path);
  $name = $path[$#path];

  $save_path = $path;

  $info = $hlc->get_fileinfo($path);

  # Last part of the path could have been a regex
  unless(ref($info))
  {
    $regex = pop(@path);
    $path = join($REMOTE_SEP, @path);

    if(length($path))
    {
      $info = $hlc->get_fileinfo($path);

      unless(ref($info) && $info->type() =~ /^($FOLDER_REGEX)$/i)
      {
        print_wrap "No such file or directory: $save_path\n";
        return;
      }
    }
  }
  else
  {
    if($info->type() =~ /^($FOLDER_REGEX)$/i && $PROMPTING)
    {
      $folder = 1;
      print_wrap "Really delete the folder \"$name\" and all its contents? (y/n) [n]: ";
      chomp($res = <STDIN>);
      return(0)  unless($res =~ /^\s*y(es|up|eah)?\s*$/i);
    }

    unless($hlc->delete_file($path))
    {
      print_wrap $hlc->last_error(), "\n";
      return;
    }

    print_wrap +($folder) ? "Folder" : "File", " deleted: $name\n"  unless($OPT{'q'});

    return(1);
  }

  if(defined($regex))
  {
    $regex = Shell_RE_To_Perl_RE($regex);

    unless(Safe_Regex(\$regex))
    {
      $regex = quotemeta($regex);
    }
  }

  $files = $hlc->get_filelist($path);

  $file_dir = $path;
  $path = '<root>'  unless(length($path));

  unless($files)
  {
    print_wrap $hlc->last_error(), "\n";
    return;
  }

  foreach my $file (@{$files})
  {
    $name = $file->name();

    next if(defined($regex) && $name !~ /^$regex$/);

    $found = 1;

    $folder = ($file->type() eq HTLC_FOLDER_TYPE);

    if($PROMPTING)
    {
      if($folder)
      {
        print_wrap "Really delete the folder \"$name\" and all its contents? (ynq) [n]: ";
      }
      else
      {
        print_wrap "Really delete \"$name\"? (ynq) [n]: ";
      }

      chomp($res = <STDIN>);

      if($res =~ /^\s*q(uit)?\s*/i)
      {
        return(0);
      }
      elsif($res !~ /^\s*y(es|up|eah)?\s*$/i)
      {
        next;
      }
    }

    $file_path = Rel_To_Abs_Path_Remote($name, $file_dir);

    unless($hlc->delete_file($file_path))
    {
      print_wrap $hlc->last_error(), "\n";
      next;
    }

    print_wrap +($folder) ? "Folder" : "File", " deleted: $name\n"  unless($OPT{'q'});
  }

  if(!$found && !$OPT{'q'})
  {
    print_wrap "del: No match.\n";
  }

  return(1);
}

sub Rel_To_Abs_Path_Local
{
  my($path, $start_dir) = @_;

  unless(length($path))
  {
    return (split(/$LOCAL_SEP/, $LPWD))  if(wantarray);
    return $LPWD;
  }

  my($tmp, $dir, @dirs, @path, $ret);

  $start_dir = $LPWD  unless(defined($start_dir));

  if($path !~ /^$LOCAL_SEP/)
  {
    $tmp = "$start_dir$LOCAL_SEP$path";
  }
  else
  {
    $tmp = $path;
  }

  $tmp =~ s/$LOCAL_SEP+/$LOCAL_SEP/g;

  @dirs = split(/$LOCAL_SEP/, $tmp);

  foreach my $dir (@dirs)
  {
    if($dir eq '..')    { pop(@path)        }
    elsif($dir eq '.')  { next              }
    elsif(length($dir)) { push(@path, $dir) }
  }

  # MacPerl's chdir() likes a trailing ':'
  if($MACOS)
  {
    $ret = join($LOCAL_SEP, @path) . $LOCAL_SEP;
  }
  # Other OSes have leading path separators on their absolute paths
  else
  {
    $ret = $LOCAL_SEP . join($LOCAL_SEP, @path);
  }

  return @path  if(wantarray);
  return $ret;
}

sub Rel_To_Abs_Path_Remote
{
  my($path, $start_dir) = @_;

  my($tmp, $dir, @dirs, @path);

  $start_dir = $RPWD  unless(defined($start_dir));

  if($path !~ /^$REMOTE_SEP/)
  {
    $tmp = "$start_dir$REMOTE_SEP$path";
  }
  else
  {
    ($tmp = $path) =~ s/^$REMOTE_SEP//o;
  }

  $tmp =~ s/$REMOTE_SEP+/$REMOTE_SEP/g;

  @dirs = split(/$REMOTE_SEP/, $tmp);

  foreach my $dir (@dirs)
  {
    if($dir eq '..')    { pop(@path)        }
    elsif($dir eq '.')  { next              }
    elsif(length($dir)) { push(@path, $dir) }
  }

  return @path  if(wantarray);
  return join($REMOTE_SEP, @path);
}

sub Change_Dir_Local
{
  my($hlc, $path) = @_;

  $path = Rel_To_Abs_Path_Local($path);

  unless(chdir($path))
  {
    print_wrap "Could not change directory to $path: $!\n";
    return;
  }

  $LPWD = cwd();
  $hlc->downloads_dir($LPWD);

  print_wrap "lcwd: $LPWD\n"  unless($OPT{'q'});
}

sub Change_Dir_Remote
{
  my($hlc, $path) = @_;

  unless($hlc->connected())
  {
    print_wrap "Not connected.\n";
    return;
  }

  if($path =~ m#^(?:|/)$#)
  {
    $RPWD = '';
  }
  else
  {
    my($abs) = ($path =~ m{^[:/]});

    $path = Convert_Path(Clean_Path($path));
    $path = Rel_To_Abs_Path_Remote($path)  unless($abs);

    if(length($path))
    {
      # Check that path exists and is a folder
      my($info) = $hlc->get_fileinfo($path);

      unless($info && $info->type() =~ /^(?:$FOLDER_REGEX)$/)
      {
        print_wrap "No such directory: $path\n";
        return;
      }
    }

    $RPWD = $path;
  }

  unless($OPT{'q'} || $OPT{'p'})
  {
    print_wrap "cwd: ", (length($RPWD)) ? $RPWD : '<root>', "\n";
  }
}

sub List
{
  my($hlc, $long, $path) = @_;

  unless($hlc->connected())
  {
    print $OUT "Not connected.\n";
    return;
  }

  my(@path, $files, $info, $regex, $save_path);

  $save_path = $path;

  @path = Rel_To_Abs_Path_Remote(Convert_Path(Clean_Path($path)));
  $path = join($REMOTE_SEP, @path);

  if(length($path))
  {
    $info = $hlc->get_fileinfo($path);

    # Last part of the path could have been a regex
    unless(ref($info))
    {
      $regex = pop(@path);
      $path = join($REMOTE_SEP, @path);

      if(length($path))
      {
        $info = $hlc->get_fileinfo($path);

        unless(ref($info) && $info->type() =~ /^($FOLDER_REGEX)$/i)
        {
          print_wrap "No such file or directory: $save_path\n";
          return;
        }
      }
    }
    elsif($info->type() !~ /^($FOLDER_REGEX)$/i)
    {
      $regex = pop(@path);
      $path = join($REMOTE_SEP, @path);
    }
  }

  if(defined($regex))
  {
    $regex = Shell_RE_To_Perl_RE($regex);

    unless(Safe_Regex(\$regex))
    {
      $regex = quotemeta($regex);
    }
  }

  $files = $hlc->get_filelist($path);

  $path = '<root>'  unless(length($path));

  unless($files)
  {
    print_wrap "Could not get file list for folder $path: ", $hlc->last_error(), "\n";
    return;
  }

  unless(@{$files} > 0)
  {
    print_wrap "<empty folder>\n";
    return;
  }

  if($long)
  {
    my($msg, $name, $size, $bytes, $type, $creator, $units);

    foreach my $file (@{$files})
    {
      $name    = $file->name();

      next if(defined($regex) && $name !~ /^$regex$/);

      $size    = $file->size();
      $type    = $file->type();
      $creator = $file->creator();

      $bytes = $size;

      $name .= ':'  if($type eq HTLC_FOLDER_TYPE);

      if($type eq 'fldr')
      {
        $units = 'Items';
        print $OUT sprintf("%-32s           %10d %-5s    Folder", $name, $size, $units);
      }
      else
      {
        if($size < 1024)
        {
          $units = 'bytes';
        }
        elsif($size > 1024 && $size < (1024 * 1024))
        {
          $units = 'KB';
          $size = (int($size/1024));
        }
        elsif($size > (1024 * 1024))
        {
          $units = 'MB';
          $size =  $size/(1024 * 1024);
        }
        elsif($size > (1024 * 1024 *1024))
        {
          $units = 'GB';
          $size =  $size/(1024 * 1024 *1024);
        }

        print $OUT sprintf("%-32s  %10d    %5.1f %-5s    %4s    %4s",
                           $name, $bytes, $size, $units, $type, $creator);
      }

      print $OUT "\n";
    }
  }
  else
  {
    my($max_length, $col_width, $cols, $name, @names, $i, $j);

    $max_length = 0;

    foreach my $file (@{$files})
    {
      $name = $file->name();

      next if(defined($regex) && $name !~ /^$regex$/);

      $name .= ':'  if($file->type() eq HTLC_FOLDER_TYPE);
      push(@names, $name);
      $max_length = length($name)  if(length($name) > $max_length);
    }

    $col_width = $max_length + 3;
    $col_width = 10 if($col_width < 10);
    $cols = int($COLS/$col_width);

    for($i = 0; $i <= $#names; $i += $cols)
    {
      for($j = 0; $j < $cols && defined($names[$i + $j]); $j++)
      {
        print $OUT $names[$i + $j],
                   ' ' x ($col_width - length($names[$i + $j]));
      }
      print $OUT "\n";
    }
  }
}

sub List_Local
{
  my($hlc, $long, $path) = @_;

  my(@path, $files, $info, $regex, $save_path, $abs_path, $printed,
     $save_file, $save_abs_path);

  $save_path = $path;

  @path = Rel_To_Abs_Path_Local($path);
  $path = join($LOCAL_SEP, @path);

  $path .= $LOCAL_SEP  if($MACOS);

  if(length($path))
  {
    unless(-e $path)
    {
      $regex = pop(@path);
      $path = join($LOCAL_SEP, @path);
      $path .= $LOCAL_SEP  if($MACOS);

      if(length($path))
      {
        unless(-d $path)
        {
          print_wrap "No such file or directory: $save_path\n";
          return;
        }
      }
    }
  }

  if(defined($regex))
  {
    $regex = Shell_RE_To_Perl_RE($regex);

    unless(Safe_Regex(\$regex))
    {
      $regex = quotemeta($regex);
    }
  }

  unless(opendir(DIR, $path))
  {
    print_wrap "Could not read directory $path: $!\n";
    return;
  }

  if($long)
  {
    my($file, $size, $is_dir, $bytes, $units, $type, $creator);

    foreach my $file (sort(readdir(DIR)))
    {
      $save_file = $file;
      $file =~ s/\015//g  if($MACOS);

      next if(defined($regex) && $file !~ /^$regex$/);

      ($abs_path = "$path$LOCAL_SEP$file") =~ s/$LOCAL_SEP+/$LOCAL_SEP/og;
      ($save_abs_path = "$path$LOCAL_SEP$save_file") =~
        s/$LOCAL_SEP+/$LOCAL_SEP/og;

      $bytes = $size = (stat($abs_path))[7];

      $is_dir = (-d $abs_path) ? 1 : 0;

      if($is_dir)
      {
        $file .= $LOCAL_SEP;

        if($MACOS)
        {
          print $OUT sprintf("%-32s           -      Folder          -       -", $file);
        }
        else
        {
          print $OUT sprintf("%-40s  %10d    %-s", $file, $size, "(directory)");
        }
      }
      else
      {
        ($size, $units) = Size_Units($size);

        if($MACOS)
        {
          ($type, $creator) = MacPerl::GetFileInfo($save_abs_path);
          print $OUT sprintf("%-32s  %10d    %5.1f %-5s    %4s    %4s",
                             $file, $bytes, $size, $units, $type, $creator);
        }
        else
        {
          print $OUT sprintf("%-40s  %10d    %6.1f %-5s",
                             $file, $bytes, $size, $units);
        }
      }
      print_wrap "\n";
      $printed = 1;
    }
  }
  else
  {
    my($max_length, $col_width, $cols, $name, @names, $i, $j);

    foreach my $file (sort(readdir(DIR)))
    {
      $file =~ s/\015//g  if($MACOS);

      next if(defined($regex) && $file !~ /^$regex$/);

      ($abs_path = "$path$LOCAL_SEP$file") =~ s/$LOCAL_SEP+/$LOCAL_SEP/og;

      $file .= $LOCAL_SEP  if(-d $abs_path);
      push(@names, $file);
      $max_length = length($file)  if(length($file) > $max_length);
    }

    $col_width = $max_length + 3;
    $col_width = 10 if($col_width < 10);
    $cols = int($COLS/$col_width);

    for($i = 0; $i <= $#names; $i += $cols)
    {
      for($j = 0; $j < $cols && defined($names[$i + $j]); $j++)
      {
        print $OUT $names[$i + $j],
                   ' ' x ($col_width - length($names[$i + $j]));
      }
      print $OUT "\n";
    }

    $printed = 1;
  }

  closedir(DIR);

  unless($printed)
  {
    if(defined($regex))
    {
      print $OUT "No match.\n";
    }
    else
    {
      print $OUT "<empty directory>\n";
    }
  }
}

sub Set_Prompt
{
  my($hlc, $prompt_ref) = @_;

  if(!$hlc->connected())
  {
    $$prompt_ref = 'hlftp> ';
  }
  else
  {
    if($OPT{'p'}) { $$prompt_ref = '' }
    else          { $$prompt_ref = "[$NICK:$ICON] " }
    $$prompt_ref .= $hlc->server() . '> ';
  }
}

sub Clean_Path
{
  my($path) = shift;

  for($path)
  {
    s/^"(.*?)"$/$1/;
    s/^\\"/"/g;
  }

  $path;
}

sub Convert_Path
{
  my($path) = shift;

  for($path)
  {
    s/\\\\/\\/g;
    s#(^|[^\\])/#$1:#g;
    s/^://;
    s/:$//;
  }

  $path;
}

sub Safe_Regex
{
  my($re) = shift;

  while($$re =~ s/\(\?([^)]*)e([^)]*)\)/(?$1$2)/g){}

  eval { m/$$re/ };

  if($@) { return undef }
  else   { return 1     }
}

sub Shell_RE_To_Perl_RE
{
  my($pre, $ignore_case) = @_;

  for($pre)
  {
    s/\\/\\\\/g;
    s/\./\\./g;
    s/\*/.*/g;
    s/\?/./g;
  }

  $pre .= '(?i)'  if($ignore_case);

  return $pre;
}

sub Size_Units
{
  my($size) = shift;

  return('n/a', undef)  unless($size =~ /^\d+$/);

  my($units);

  if($size < 1024)
  {
    $units = 'bytes';
  }
  elsif($size > 1024 && $size < (1024 * 1024))
  {
    $units = 'KB';
    $size = int($size/1024);
  }
  elsif($size > (1024 * 1024))
  {
    $units = 'MB';
    $size =  $size/(1024 * 1024);
  }
  elsif($size > (1024 * 1024 *1024))
  {
    $units = 'GB';
    $size =  $size/(1024 * 1024 *1024);
  }

  return($size, $units);
}

sub Date_Text
{
  my($date) = shift;

  $date += HTLC_MACOS_TO_UNIX_TIME  unless($MACOS);

  return ctime($date);
}

sub print_wrap
{
  my($text) = join('', @_);

  print $OUT wrap("", "", $text);
}
