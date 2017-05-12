package NCustom;

use 5.008;
use strict qw(vars);
use warnings;

use vars qw(%Config  $Transaction $req);
use Carp;
use File::Basename;
use File::Compare;
use File::Copy;
use File::Find;
use File::Path;
use File::Spec;
use File::Temp qw(tempfile tempdir);
use FindBin qw($Bin);   #this finds the dir of the src of $0
use Text::ParseWords;
use Socket;
use Symbol qw(delete_package);

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 
  'all' => [ qw( &transaction &save_files &initialise &overwrite_file &append_file &prepend_file &edit_file &undo_files &required_packages $req &apt_fix &ncustom &blat_myconfig &config_edit) ] 
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.07';


# ///////////////////////////////////////////////////////////////////
#<< PP: POD Prefix      <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

=head1 NAME

NCustom - Perl extension for customising system configurations.

=head1 SYNOPSIS

  NCUSTOM_SCRIPT
  use NCustom;
  # do stuff in your script using NCustom routines

  KICKSTART POST SECTION
  # install package management tool that is used in NCUSTOM_SCRIPT
  rpm -i http://install/install/rpm/apt-0.5.5cnc6-fr1.i386.rpm ;
  echo 'rpm http://install/ install/rh90_apt os extras' > /etc/apt/sources.list;
  apt-get update ;

  # install and use NCustom
  apt-get -q -y install perl-NCustom ;
  ncustom -i ;
  ncustom -c src_fqdn=install.example.com ;
  ncustom -n NCUSTOM_SCRIPT
  ncustom -n smb_ldap_pdc-0.4-rh90.ncus ;

=head1 ABSTRACT

NCustom provides some file editting routines and some package management hooks to assit in system configuration.

File editting:
The file editing routines include features such as transactions, and undo by transaction. The original files are archived within a directory tree structure.

Package management:
You may specify packages (and minumum/maximum/exact versions) that you require to be installed, and a routine to be called if they are not installed. Your routine may use simple "rpm" commands (or whatever you want), or you may use the provided routine that uses "apt". In-built support for other package management tools is on the todo list.

System configuration:
A commandline interface provides for initialisation, configuration, and invocation (including invocation across the network). This enables NCustom to be used from the post section of Kickstart script. It may also be used stand alone on an already built system.

If system configuration tweaking is minor, then scripts (even in the post section of a kickstart configuration) may be more useful. If the system configuration tweaking is related to only one rpm, then re-rolling the rpm with a new post section may be more useful. If there are several packages that need inter-related configuration (eg building a Samba, PDC, LDAP server), then NCustom may improve the speed of development of automated system configuration.  

=head1 DESCRIPTION

File editting:
Files are saved into a directory structure within the users home directory. This location may be configured. A file will be saved within a directory structure named after the current transaction name, and also under the "all" directory. Because of this "all" changes, or only changes relating to a "transaciton" may be reversed.

Package management:
When a package requirement is not met, a routine that you may provide shall be called.

System configuration:


=head2 EXPORT

None by default.

=head2 API

=over

=cut


# ///////////////////////////////////////////////////////////////////
#<< FF: Functions  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

#====================================================================
# Inline testing setup and general tests

=begin testing

use Carp;
use File::Compare ;
use File::Copy ;
use File::Path ;
use File::Spec ;
use vars qw($output $input);

# test setup
$output = File::Spec->rel2abs("./t/embedded-NCustom.o");
$input  = File::Spec->rel2abs("./t/embedded-NCustom.i");
ok( -d $input) 
  || diag("TEST:<test setup> requires the data input directory be present");
-d $input || die; # as if we have that wrong we could clobber allsorts
rmtree  $output;
mkpath  $output;
$ENV{HOME} = $output ; # lets be non-intrusive

use_ok( "NCustom", qw(:all) ) 
  || diag("TEST:<NCustom> is a package");

sub test_reset {
  #Test::Inline doesnt execute test blocks in order
  #it does all basic tests first (seemingly in declaration order),
  #then examples tests (seemingly in declaration order).
  #hmmm.. test_rest can erase "why test failed" data
  rmtree  $output;
  mkpath  $output;
  &NCustom::constructor();
  transaction("tx1");
  system("cp -r $input/subject/* $output");

}
sub output {
  $_STDOUT_ && diag($_STDOUT_);
  $_STDERR_ && diag($_STDERR_);
}
output();

=end testing

=cut

#====================================================================
# load_config

=begin testing

NCustom::load_config();
is($NCustom::Config{'test_data1'}, "global_value")
  || diag("TEST:<load_config> sets variables from global conf file 1/3");
is($NCustom::Config{'test_data2'}, "global_value")
  || diag("TEST:<load_config> sets variables from global conf file 2/3");
is($NCustom::Config{'save_dir'}, "$output/.ncustom/save",)
  || diag("TEST:<load_config> sets variables from global conf file 3/3");

mkpath	"$output/.ncustom/NCustom" ;
copy("$input/MyConfig.pm", "$output/.ncustom/NCustom");
NCustom::load_config();
is($NCustom::Config{'test_data1'}, "global_value")
  || diag(<<'  EOF');
  TEST:<load_config>
  TEST:   - will use a local conf file if present
  TEST:   - will still inheirit settings from global conf file
  EOF
is($NCustom::Config{'test_data2'}, "local_value")
  || diag(<<'  EOF');
  TEST:<load_config>
  TEST:   - local conf file settings will override global conf file settings
  EOF

my $subref = $NCustom::Config{'get_url'};
my $target_url = "dummy_url";
my $target_dir = "dummy_dir";
&$subref($target_url, $target_dir);
open(STUBSLOG, "< $output/stubs.log");
my @lines = <STUBSLOG>;
close(STUBSLOG);
ok( grep( /get_url ${target_url} ${target_dir}/, @lines) > 0 )
  || diag("TEST:<load_config> override works for get_url handler");

TODO: {
  local $TODO = "Unload and reload modules, eg Symbol::delete_package.";

  #testing can reset / toggle 
  #Q: is this useful outside of testing context ?
  #A: no

  rmtree 	"$output/.ncustom/NCustom" ;
  NCustom::load_config();
  is($NCustom::Config{'test_data1'}, "global_value")
    || diag("TEST:<load_config> is re-runnable and resets configuration 1/2");
  is($NCustom::Config{'test_data2'}, "global_value")
    || diag("TEST:<load_config> is re-runnable and resets configuration 2/2");
}
output();

=end testing

=cut

#====================================================================
sub load_config{

  delete_package("NCustom::Config");#   if exists $NCustom::{'Config::'};
  delete_package("NCustom::MyConfig");# if exists $NCustom::{'MyConfig::'};
  
  require NCustom::Config ;
  unshift @INC, "$ENV{HOME}/.ncustom";
  eval {require NCustom::MyConfig;} ;
  shift @INC;
  return 1;
}

#====================================================================
# transaction

=item C<transaction>
  
  trasaction("tx1");

Set the current trasaction. If not set it defaults to basename($0). Using the default is normally good enough.

=cut

#====================================================================
sub transaction{
  my ($tx, @rest) = @_;
  $Transaction = ($tx || basename($0)); 
}

#====================================================================
# apply_config

=begin testing

test_reset();

&NCustom::apply_config();

ok( -d "$output/.ncustom/save/all")
  || diag("TEST:<NCustom> uses a save directory");
ok( -d "$output/.ncustom/tmp")
  || diag("TEST:<NCustom> uses a tmp directory");
-d "$output/.ncustom/save/all" || die; # as we could be way off course
output();

=end testing

=cut

#====================================================================
sub apply_config{
  if(! -d $Config{'save_dir'}){
    mkpath "$Config{'save_dir'}/all";
    mkpath "$Config{'save_dir'}/all.new";
  }
  -d $Config{'tmp_dir'}  || mkpath $Config{'tmp_dir'};

  #TODO# error checking
  #Q: whether should test src_fqdn (dns lookup/http get/ping) ?
  #A: no, as might'nt ever matter that it is (potentially) incorrect/offline

  transaction(basename($0)); #so easy to override in testing
  return 1;
}

#====================================================================
# crud_gaurantee

=begin testing

test_reset();
my $msg;
ok( &NCustom::crud_gaurantee("$output/dir1/file1","read",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can read a file.");
ok( &NCustom::crud_gaurantee("$output/dir1/file1","update",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can update a file.");
ok(!&NCustom::crud_gaurantee("$output/dir1/file9","update",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you cant update a file.");
# should do more cant't testing
# and test that get $msg 
#
ok( &NCustom::crud_gaurantee("$output/dir1/file1","delete",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can delete a file.");
ok( &NCustom::crud_gaurantee("$output/dir1/file9","create",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can create a file.");
ok( &NCustom::crud_gaurantee("$output/dir1/subdir1/file9","create",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can create a file and its dirs.");
#
ok( &NCustom::crud_gaurantee("$output/dir1/file1","r",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can r a file (short notation).");
ok(!&NCustom::crud_gaurantee("$output/dir1/file9","r",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you cant r a file (short notation).");
ok( &NCustom::crud_gaurantee("$output/dir1/file1","ru",\$msg) )
  || diag("TEST:<crud_gaurantee> says if you can ru a file (short notation).");
# should do other crud combos
#
output();

=end testing

=cut

#====================================================================
sub crud_gaurantee{
  my ($file, $check, $msgref) = @_ ;
  my $rc = 1;
  
  #TODO# fix so dont fall through to success on invalid checks

  #CRUD: Create guarantee
  # interpreting as create/clobber
  if($check =~ /create/i || ($check =~ /^[crud]+$/i && $check =~ /c/i )){
    if(! -e dirname($file)){
      $rc = mkpath(dirname($file));
      unless($rc){$$msgref = "Cant create dir for file: $file."; return 0; }
    }
    if(! -w dirname($file)){
      $$msgref = "Cant create in dir for file: $file."; return 0;
    }
    if(-e $file && ! -f $file){
      $$msgref = "Shant clobber existing non-plain-file: $file."; return 0;
    }
    if(-f $file && ! -w $file){
      $$msgref = "Cant clobber existing plain-file: $file."; return 0;
    }
  }

  #CRUD: Read guarantee
  if($check =~ /read/i || ($check =~ /^[crud]+$/i && $check =~ /r/i )){
    if(! -e $file){
      $$msgref = "Cant read non-existant file: $file."; return 0;
    }
    if(! -f $file){
      $$msgref = "Shant read from non-plain-file: $file."; return 0;
    }
    if(! -r $file){
      $$msgref = "Cant read file: $file."; return 0;
    }
  }

  #CRUD: Update guarantee
  if($check =~ /update/i || ($check =~ /^[crud]+$/i && $check =~ /u/i )){
    if(! -e $file){
      $$msgref = "Cant update non-existant file: $file."; return 0;
    }
    if(! -f $file){
      $$msgref = "Shant update non-plain-file: $file."; return 0;
    }
    if(! -r $file){
      $$msgref = "Cant read file: $file."; return 0;
    }
    if(! -w $file){
      $$msgref = "Cant write file: $file."; return 0;
    }
  }

  #CRUD: Delete guarantee
  if($check =~ /delete/i || ($check =~ /^[crud]+$/i && $check =~ /d/i )){
    #TODO# implement when we need it
    if(! -e $file){
      $$msgref = "Cant delete non-existant file: $file."; return 0;
    }
    if(! -f $file){
      $$msgref = "Shant delete non-plain-file: $file."; return 0;
    }
    if(! -w dirname($file)){
      $$msgref = "Cant delete from dir of file: $file."; return 0;
    }
  }

  return 1;
}

#====================================================================
# save_files, save_file, save_file2

=item C<save_files>

=begin example

test_reset();
ok(-f "$output/dir2/file1")
  || diag("TEST:<test setup> must copy over the subject dir");
can_ok("NCustom", qw(save_files)) 
  || diag("TEST:<save_files> is a public function of NCustom");

=end example

=for example begin
  
  save_files("~/dir2/file1");
  
  save_files(<<'    EOF');
    ~/dir2/file2
    ~/dir3/*
    EOF

=for example end

There is not much point to this - the customise works or not.
But it helps while developing the customisation.
Note: changes effected by using NCustom functions are saved automatically.

=for example_testing
ok(-f "$output/.ncustom/save/all/$output/dir2/file1")
  || diag(<<'  EOF');
  TEST:<save_files> 
  TEST:   - saves given file(s) to the overall archive
  TEST:   - performs filename expansion eg ~/
  EOF
ok(-f "$output/.ncustom/save/tx1/$output/dir2/file1")
  || diag(<<'  EOF');
  TEST:<save_files> 
  TEST:   - also saves given file(s) to the current tx archive
  EOF
ok(-f "$output/.ncustom/save/all/$output/dir2/file2")
  || diag(<<'  EOF');
  TEST:<save_files> multiple arguments:
  TEST:   - accepts multiple arguments in one newline delimited string
  TEST:   - are also saved to both the overall, and current tx, archives 1/2
  EOF
ok(-f "$output/.ncustom/save/tx1/$output/dir2/file2")
  || diag(<<'  EOF');
  TEST:<save_files> multiple arguments:
  TEST:   - are also saved to both the overall, and current tx, archives 2/2
  EOF
ok(-f "$output/.ncustom/save/all/$output/dir3/file1")
  || diag("TEST:<save_files> supports wildcarding 1/4");
ok(-f "$output/.ncustom/save/tx1/$output/dir3/file1")
  || diag("TEST:<save_files> supports wildcarding 2/4");
ok(-f "$output/.ncustom/save/all/$output/dir3/file2")
  || diag("TEST:<save_files> supports wildcarding 3/4");
ok(-f "$output/.ncustom/save/tx1/$output/dir3/file2")
  || diag("TEST:<save_files> supports wildcarding 4/4");
#
# extra tests
#
transaction("tx2");
save_files("~/dir4/file1");
ok(-f "$output/.ncustom/save/tx2/$output/dir4/file1")
  || diag(<<'  EOF');
  TEST:<save_files> 
  TEST:   - saves to a corresponding tx archive when the tx changes 1/2
  EOF
ok(! -f "$output/.ncustom/save/tx1/$output/dir4/file1")
  || diag(<<'  EOF');
  TEST:<save_files> 
  TEST:	  - saves to a corresponding tx archive when the tx changes 2/2
  EOF
copy("$input/dir4file1.v2", "$output/dir4/file1");
save_files("~/dir4/file1");
my @matches = glob("$output/.ncustom/save/tx2/$output/dir4/*");
is($#matches, 1)
  || diag(<<'  EOF');
  TEST:<save_files> if a file is saved to an archive, and it is already there:
  TEST:	  - the file will be saved with a suffix
  EOF
  #this better test didnt work because of filename mangling with samba
  #ok(-f "$output/.ncustom/save/tx2/$output/dir4/file1.AT*")
save_files("~/dir4/file1");
@matches = glob("$output/.ncustom/save/tx2/$output/dir4/*");
is($#matches, 1)
  || diag(<<'  EOF');
  TEST:<save_files> if a file is saved to an archive, and it is already there:
  TEST:   - if there is no change it wont be saved again
  EOF
output();

=cut

#====================================================================
sub save_file;
sub save_files {
  my ($files, @rest) = @_;
  my @lines = split(/\n/,$files);
  my $status = 1;
  my $line;

  foreach $line (@lines){
    my ($file, @rest) = ($line  =~ /\s*(.*)/);
    save_file($file) || ($status = 0);
  }
  return $status;
}

#====================================================================
sub save_file2;
sub expand_filenames;
sub save_file {
  #save_file reduces the problem to dealing with indivudual files
  #it then calls save_file2 to do the work
  my ($file, @rest) = @_;
  my ($msg, $rc, $f, $global_dest, $local_dest);
  my $status = 1;

  foreach my $f ( expand_filenames($file)){
    chomp $f;
    $global_dest = "$Config{'save_dir'}/all/$f";
    $local_dest  = "$Config{'save_dir'}/$Transaction/$f";
    save_file2($f, $global_dest) || ($status =0);
    save_file2($f, $local_dest)  || ($status =0);
    if(! -e $f){
      #So we must be dealing with a new file.
      #For consistencey:
      -d "$Config{'save_dir'}/${Transaction}" 
        || mkpath "$Config{'save_dir'}/${Transaction}";

      #We have a special place for noting new files:
      $global_dest = "$Config{'save_dir'}/all.new/$f";
      $rc = crud_gaurantee($global_dest,"create",\$msg);
      unless($rc){carp "save_file: $msg"; return 0; }
      open(TOUCH,"> $global_dest");
      close(TOUCH); 

      $local_dest  = "$Config{'save_dir'}/${Transaction}.new/$f";
      $rc = crud_gaurantee($local_dest,"create",\$msg);
      unless($rc){carp "save_file: $msg"; return 0; }
      open(TOUCH,"> $local_dest");
      close(TOUCH); 
    }
  }
  return $status;
}

#====================================================================
sub save_file2 {
  my ($file, $dest, @rest) = @_;
  my $rc = 1;
  my $msg;
  my ($sec, $min, $hr) = (localtime)[0..2];
  my $suffix = ".AT_$hr:$min:$sec" ;#also used in undo_file
  #TODO# $sec not fine grained enough, will get caught out one day

  if(! -e $file){
    #we dont save something that doesnt exist
    #but still relatively normal as we may be dealing with a new creation
    return 1;
  }
  if((-e $dest) && (compare($dest, $file) == 0)){
    #already saved and files are the same
    #TODO# add more checking here, -f, perms...
    #carp "save_file: not saving, as not changed since last save: $file";
    return 1;
  }
  if((-e $dest) && (compare($dest, $file) != 0)){
    #already saved but files are different
    #better get a new name
    $dest = "${dest}$suffix";
  }

  $rc = crud_gaurantee($dest,"create",\$msg);
  unless($rc){carp "save_file2: $msg"; return 0; }

  $rc = copy($file, $dest);
  unless($rc){carp "save_file2: copy failed: $file, $dest."; return 0; }

  return 1;
}
#====================================================================
sub expand_filenames {
  my ($file_list, @rest) = @_ ;
  my @result;

  #tag#
  my @lines = split(/\n/,$file_list);
  foreach my $line (@lines){
    $line =~ s/^\s+//;          #trim leading whitespace
    next if $line =~ /^#/;      #TODO# comments need much work
    #TODO# find the perl fn for the following kludge 
    #cant use builtin glob as in some instances we're dealing with a newfile 
    #(builtin glob matches existing)
    my @filename_expansion = split(/\s+/, `echo $line`); 
    foreach my $filename (@filename_expansion){
      push @result, $filename;
    }
  }
  return @result;
}

#====================================================================
# initialise

=item C<initialise>

=begin example

test_reset();
can_ok("NCustom", qw(initialise)) 
  || diag("TEST:<initialise> is a public function of NCustom");

=end example

=for example begin
  
  initialise();

=for example end

Initialise the archive of saved files. As this deletes files this is not done automatically.

=for example_testing
@matches = glob("$output/.ncustom/save/*");
is($#matches, 3) # ie 4 entries (all, all.new, tx1, tx1.new)
  || diag("TEST:<initialise> removes all save files");
ok(-d "$output/.ncustom/save/all")
  || diag("TEST:<initialise> creates an empty skeleton save dir");
output();

=cut

#====================================================================
sub initialise {
  rmtree($Config{'save_dir'}) || return 0;
  mkpath("$Config{'save_dir'}/all") || return 0;
  mkpath("$Config{'save_dir'}/all.new") || return 0;
  mkpath("$Config{'save_dir'}/$Transaction") || return 0;
  mkpath("$Config{'save_dir'}/${Transaction}.new") || return 0;
  rmtree($Config{'tmp_dir'}) || return 0;
  mkpath($Config{'tmp_dir'}) || return 0;
  return 1;
}

#====================================================================
# commit_file

=begin testing

test_reset();

my $tmp = "$NCustom::Config{'tmp_dir'}";
#use tmp for files that will be altered/moved (to keep input unaltered)

copy("$input/dir5file1", "$tmp/dir5file1");
&NCustom::commit_file("$tmp/dir5file1", "$output/dir5/file1");
ok(-f "$output/dir5/file1")
  || diag("TEST:<commit_file> checks in a new file");
ok(! -f "$output/.ncustom/save/tx1/$output/dir5/file1")
  || diag("TEST:<commit_file> doesnt archive files that didnt already exist");
  #TODO# that is interesting, that means that restore wont delete it
  #TODO# could handle by save archiving filename.new, the resore knows to rm

copy("$input/dir5file1.v2", "$tmp/dir5file1.v2");
&NCustom::commit_file("$tmp/dir5file1.v2", "$output/dir5/file1");
is(compare("$output/dir5/file1", "$input/dir5file1.v2"), 0)
  || diag("TEST:<commit_file> checks in over an existing file");
is(compare("$output/.ncustom/save/tx1/$output/dir5/file1","$input/dir5file1"), 0)
  || diag("TEST:<commit_file> saves things before it clobbers them");

copy("$input/dir5file1", "$tmp/dir5file1");
&NCustom::commit_file("$tmp/dir5file1", "$output/dir5/subdir1/file1");
ok(-f "$output/dir5/subdir1/file1")
  || diag("TEST:<commit_file> checks in a new file, creating subdirs required");
output();

=end testing

=cut

#====================================================================
sub commit_file{
  my($newfile, $file, @rest) = @_ ;
  my $rc = 1;
  my $msg;

  $rc = crud_gaurantee($newfile,"read delete",\$msg);
  unless($rc){carp "commit_file: $msg"; return 0; }

  $rc = crud_gaurantee($file,"create",\$msg);
  unless($rc){carp "commit_file: $msg"; return 0; }

  $rc = save_file($file);
  unless($rc){ carp "commit_file: save_file: $file failed\n"; return 0; }

  $rc = copy($newfile, $file);
  unless($rc){carp "commit_file: copy failed: $newfile, $file.\n"; return 0;}

  $rc = unlink($newfile);
  unless($rc){carp "commit_file: unlink failed: $newfile.\n"; return 0;}

  return 1;
}

#====================================================================
# overwrite_file

=item C<overwrite_file>

=begin example

test_reset();
can_ok("NCustom", qw(overwrite_file)) 
  || diag("TEST:<overwrite_file> is a public function of NCustom");

=end example

=for example begin
  
  overwrite_file(file => "~/dir6/file1", text => ' some content');
  
  overwrite_file(file => "~/dir6/file2",
                strip => '^\s{4}',
                text  => <<'    EOF');
    This will be line 1 of the new content of the file.
    This will be line 2 of the new content of the file.
      This, line3, will still be indented. As will line 4.
      I bet there will be a dollar sign and two single quotes on the next line.
    'I told you so ! Now you owe me $20', I would then say.
    This will be the last line.
    EOF

=for example end

Overwrite file overwrites $file with $text. 

So that you can have pretty indentation when using here documents, the pattern $strip is stripped out prior to processing.

More clearly, overwrite file is equivalent to:
    
    open(FILE,">$file"); 
    $text =~ s/$strip//;
    print FILE $text;

=for example_testing
is(compare("$output/dir6/file1", "$input/dir6file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<overwrite_file> 
  TEST:   - is logically equivalent to ">"
  TEST:   - will not strip anything by default
  TEST:   - performs filename expansion eg ~/
  TEST:   - will create new file if required
  EOF
is(compare("$output/dir6/file2", "$input/dir6file2.v2"), 0)
  || diag(<<'  EOF');
  TEST:<overwrite_file> 
  TEST:   - will strip a given pattern from the text
  EOF
overwrite_file(file => "~/dir6/subdir1/file1", text => ' some content');
is(compare("$output/dir6/subdir1/file1", "$input/dir6file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<overwrite_file>
  TEST:   - will create subdirs as needed for new files
  EOF
output();

=cut

#====================================================================
sub change_file {
  my %args      = @_ ;
  my $change    = ($args{'change'} || "");
  my $files     = ($args{'files'}  || "");
  my $body      = ($args{'body'}   || "");
  my $strip     = ($args{'strip'}  || "");
  my $status = 1;
  my $rc = 1;

  # input checks
  if($files eq ""){
    carp "change_file: file name is blank.\n"; return 0;
  }
  if($change !~ /^(overwrite|append|prepend|edit)$/){
    carp "change_file: Invalid type of change: $change."; return 0; 
  }

  # pre-process body (text / code)
  $body =~ s/$strip//mg unless $strip eq "";

  # pre-process filenames
  # then invoke processing on each one
  foreach my $file (expand_filenames($files)){
    chomp $file;
    $rc = change_file2(change => $change, file => $file, body => $body);
    unless($rc){$status = 0};
  }

  return $status;
}

#====================================================================
sub change_file2 {
  my %args      = @_ ;
  my $change    = ($args{'change'} || "");
  my $file      = ($args{'file'}   || "");
  my $body      = ($args{'body'}   || "");
  my $rc = 1;
  my $msg = "";

  #we use a tmp file
  my $newfile  = "$Config{'tmp_dir'}/" . basename($file);
  $rc = crud_gaurantee($newfile, "create", \$msg);
  unless($rc){carp "change_file2: $msg"; return 0; }

  if($change =~ /overwrite/ ){
    $rc = open(NEWFILE,  ">$newfile");
    print NEWFILE $body ;
    close(NEWFILE);
  }
  if($change =~ /append/ ){
    if( -e $file){
      $rc = crud_gaurantee($file, "read", \$msg);
      unless($rc){carp "change_file2: $msg"; return 0; }
      copy($file, $newfile);
    }
    open(NEWFILE,  ">>$newfile");
    print NEWFILE $body ;
    close(NEWFILE);
  }
  if($change =~ /prepend/ ){
    open(NEWFILE,  ">$newfile");
    print NEWFILE $body ;
    close(NEWFILE);
    -f $file && system("cat $file >>  $newfile"); #TODO# do in perl
  }
  if($change =~ /edit/ ){
    $rc = crud_gaurantee($file, "read", \$msg);
    unless($rc){carp "change_file2: $msg"; return 0; }
    open(FILE, "<$file");
    open(NEWFILE, ">$newfile");
    # select newfile, so prints in $body behave as expected
    my $old_fh = select(NEWFILE);
    # the action 
    no strict; no warnings ;
    while( <FILE> ){
      eval $body;
      if($@){carp "change_file2: code \n$body \nraised the error $@"; return 0;}
    } continue {
      print;
    }
    use strict; use warnings;
    close(NEWFILE);
    close(FILE);
    select($old_fh);
  }

  return commit_file($newfile, $file);
}

#====================================================================
sub overwrite_file {
  my %args      = @_ ;
  my $file      = ($args{'file'} || "");
  my $text      = ($args{'text'} || "");
  my $strip     = ($args{'strip'} || "");
    
  return change_file(change => "overwrite", files => $file, 
                     body => $text, strip => $strip);
}

#====================================================================
# append_file

=item C<append_file>

=begin example

test_reset();
can_ok("NCustom", qw(append_file)) 
  || diag("TEST:<append_file> is a public function of NCustom");

=end example

=for example begin
  
  append_file(file => "~/dir7/file1", text => 'an extra line');
  
  append_file(file => "~/dir7/file2",
             strip => '^\s{4}',
             text  => <<'    EOF');
    An extra line to add on to the file.
      This line, will be indented. 
    The last last line with some special chars *!@$%.'"
    EOF

=for example end

Append file is the same as overwrite file, except it behaves as ">>" instead of ">".

=for example_testing
is(compare("$output/dir7/file1", "$input/dir7file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<append_file> 
  TEST:   - is logically equivalent to ">>"
  TEST:   - will not strip anything by default
  TEST:   - performs filename expansion eg ~/
  TEST:   - will create new file if required
  EOF
is(compare("$output/dir7/file2", "$input/dir7file2.v2"), 0)
  || diag(<<'  EOF');
  TEST:<append_file> 
  TEST:   - will strip a given pattern from the text
  EOF
append_file(file => "~/dir7/subdir1/file1", text => 'an extra line');
is(compare("$output/dir7/subdir1/file1", "$input/dir7file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<append_file>
  TEST:   - will create subdirs as needed for new files
  EOF
output();

=cut

#====================================================================
sub append_file {
  my %args      = @_ ;
  my $file      = ($args{'file'} || "");
  my $text      = ($args{'text'} || "");
  my $strip     = ($args{'strip'} || "");
    
  return change_file(change => "append", files => $file, 
                     body => $text, strip => $strip);
}

#====================================================================
# prepend_file

=item C<prepend_file>

=begin example

test_reset();
can_ok("NCustom", qw(prepend_file)) 
  || diag("TEST:<prepend_file> is a public function of NCustom");

=end example

=for example begin
  
  prepend_file(file => "~/dir8/file1", text => 'an extra line');
  
  prepend_file(file => "~/dir8/file2",
             strip => '^\s{4}',
             text  => <<'    EOF');
    An extra line at the start of the file.
      This line, will be indented. 
    Some special chars *!@$%.'"
    The last extra line added to the start of the file.
    EOF

=for example end

Prepend behaves the same as append, except the text is added to the start instead of the end.

=for example_testing
is(compare("$output/dir8/file1", "$input/dir8file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<prepend_file> 
  TEST:   - is logically equivalent to ">>"
  TEST:   - will not strip anything by default
  TEST:   - performs filename expansion eg ~/
  TEST:   - will create new file if required
  EOF
is(compare("$output/dir8/file2", "$input/dir8file2.v2"), 0)
  || diag(<<'  EOF');
  TEST:<prepend_file> 
  TEST:   - will strip a given pattern from the text
  EOF
prepend_file(file => "~/dir8/subdir1/file1", text => 'an extra line');
is(compare("$output/dir8/subdir1/file1", "$input/dir8file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<prepend_file>
  TEST:   - will create subdirs as needed for new files
  EOF
output();

=cut

#====================================================================
sub prepend_file {
  my %args      = @_ ;
  my $file      = ($args{'file'} || "");
  my $text      = ($args{'text'} || "");
  my $strip     = ($args{'strip'} || "");
    
  return change_file(change => "prepend", files => $file, 
                     body => $text, strip => $strip);
}

#====================================================================
# edit_file

=item C<edit_file>

=begin example

test_reset();
can_ok("NCustom", qw(edit_file)) 
  || diag("TEST:<edit_file> is a public function of NCustom");

=end example

=for example begin
  
  edit_file(file => "~/dir9/file1", code => 's/file/FILE/g;');
  
  edit_file(file  => "~/dir9/file2",
            strip => '^\s{4}',
            code  => <<'    EOF');
    s/my\.example\.com/whatever\.com/g;
    s/^$/replace all blank lines with these three lines
        two of three, with 4 leading spaces
        and three of three/ ;
    s/might/WILL/g;
    EOF
  
  edit_file(file => <<'    EOF', strip => '^\s{6}', code => <<'    EOF');
      ~/dir9/file3
      ~/dir10/*
    EOF
      s/file/FILE/g;
      s/least/LEASTWAYS/g;
    EOF

=for example end

Edit file is similar to:
    
    perl -i -e "$code" $file

With edit file, $file must exist. 
As with the other routines, $code has the pattern $strip stripped out.

You can also provide multiple filenames to be editted. This holds true for the other routines too.

=for example_testing
is(compare("$output/dir9/file1", "$input/dir9file1.v2"), 0)
  || diag(<<'  EOF');
  TEST:<edit_file> 
  TEST:   - simple edit file
  EOF
#
is(compare("$output/dir9/file2", "$input/dir9file2.v2"), 0)
  || diag(<<'  EOF');
  TEST:<edit_file> 
  TEST:   - multi substitution edit
  EOF
is(compare("$output/dir9/file3", "$input/dir9file3.v2"), 0)
  || diag("TEST:<edit_file> - edits multiple files 1/3.");
is(compare("$output/dir10/file1", "$input/dir10file1.v2"), 0)
  || diag("TEST:<edit_file> - edits multiple files 2/3.");
is(compare("$output/dir10/file2", "$input/dir10file2.v2"), 0)
  || diag("TEST:<edit_file> - edits multiple files 3/3.");
#
output();

=cut

#====================================================================
sub edit_file {
  my %args      = @_ ;
  my $file      = ($args{'file'} || "");
  my $code      = ($args{'code'} || "");
  my $strip     = ($args{'strip'} || "");
    
  return change_file(change => "edit", files => $file, 
                     body => $code, strip => $strip);
}

#====================================================================
# undo_files

=item C<undo_files>

=begin example

test_reset();
can_ok("NCustom", qw(undo_files)) 
  || diag("TEST:<undo_files> is a public function of NCustom");
save_files("~/dir11/file1 ~/dir11/file2");
transaction("tx2");
save_files("~/dir11/file3");
transaction("tx3");
save_files("~/dir11/file4");
transaction("tx4");
save_files("~/dir11/file5");
transaction("tx5");
save_files("~/dir11/file6");
transaction("tx6");
save_files("~/dir11/file7");
transaction("tx7");
save_files("~/dir11/file8");
rmtree("$output/dir11");
mkpath("$output/dir11");

=end example

=for example begin
  
  undo_files("tx1");

  undo_files("~/.ncustom/save/tx2");

  undo_files("tx3 tx4");

  undo_files(<<'  EOF');
    tx5
    ~/.ncustom/save/tx6
  EOF

=for example end

Undo transaction will restore the files from a given transaction archive directory. That includes removing any new files that were created. For any directories that it cannot find, it will try looking in $Config{'save_dir'}.
Undo does not: restore files that were edited by non-NCustom function if they were not first saved using NCuston::save_files; delete new directories that were created (yet).
Again: this is only a development aid.

=for example_testing
ok(-f "$output/dir11/file1" && -f "$output/dir11/file2")
  || diag("TEST:<undo_files> restores files for a given customisation");
ok(-f "$output/dir11/file3")
  || diag("TEST:<undo_files> restores files for a given directory");
ok(-f "$output/dir11/file4" && -f "$output/dir11/file5")
  || diag("TEST:<undo_files> restores for multiple customisations at once");
ok(-f "$output/dir11/file6" && -f "$output/dir11/file7")
  || diag("TEST:<undo_files> handles mixed multi-line arguments");
ok(!-f "$output/dir11/file8")
  || diag("TEST:<undo_files> doesnt restore too much");
undo_files("all");
ok(-f "$output/dir11/file8")
  || diag("TEST:<undo_files> will restore all");
transaction("tx8");
mkpath("$output/dir12/subdir1");
overwrite_file(file => "~/dir12/file1", text => ' some content');
transaction("tx9");
overwrite_file(file => "~/dir12/file2", text => ' some content');
transaction("tx10");
overwrite_file(file => "~/dir12/file3", text => ' some content');
ok(  -f "$output/dir12/file1" 
  && -f "$output/dir12/file2" 
  && -f "$output/dir12/file3")
  || diag("TEST:<test setup> new files are setup ready for undo test");
undo_files("tx8");
ok(! -f "$output/dir12/file1")
  || diag("TEST:<undo_files> removes newly created files");
ok(-f "$output/dir12/file2" && -f "$output/dir12/file3")
  || diag("TEST:<undo_files> doesnt removes too much");
undo_files("all");
ok(  ! -f "$output/dir12/file1" 
  && ! -f "$output/dir12/file2" 
  && ! -f "$output/dir12/file3")
  || diag("TEST:<undo_files> removes all new files for \"all\" transaction");
#
output();

=cut

#====================================================================
sub undo_file ;
sub delete_file ;
sub undo_files{
  my ($names, @rest) = @_;
  my $status = 1;

  #tag#
  foreach my $dir ( expand_filenames($names)){
    if(! -e $dir){ 
      # if dir (ie tx) to undo isnt an absolute dir, assume relative to save_dir
      $dir = "$Config{'save_dir'}/$dir";
    }
    # now we need to expand again, as it may be wildcarded
    foreach my $d ( expand_filenames($dir)){
      if(! -e $d){ 
        carp "undo_files: dir doesnt exist: $d.";
        $status = 0;
	next;
      }
      #TODO# maybe dont need this restriction, makes it safer though...
      #restrict to existing archive dirs (transactions)
      if( $d !~  m|$Config{'save_dir'}/([^/]*)| ){
        carp "undo_files: dir isnt an archive dir: $d.";
        $status = 0;
	next;
      }
      #print "\nRestoring files from archive dir: $d \n\t";
      find(\&undo_file, "$d") || ($status = 0);

      #print "\nDeleting files that didnt exist before: $d \n\t";
      #dir undoing may be a subtree of a transaction's archive dir
      #so get the corresponding subtree of archive.new dir
      my $d_new = $d ;
      $d_new =~ s|($Config{'save_dir'}/[^/]*)|$1.new| ;
      if( -e $d_new){
        find(\&delete_file, $d_new) || ($status = 0);
      }
    }
  }
  return $status;
}

#====================================================================
sub undo_file {
  my $file      = $File::Find::name ;
  my ($dest, @rest) = ($file =~ m|$Config{'save_dir'}/[^/]*(.*)| );

  if($file =~ /\.AT_\d+:\d+:\d+$/ ){ #suffix set in save_file2
    return 1; # not restoring non-original saves
  }
  if(! -f $file ){return 1}
  copy($file, $dest); #TODO# too silent on errors, however justified
  return 1;
}

#====================================================================
sub delete_file {
  my $archive_filename      = $File::Find::name ;
  my ($real_filename, @rest) = 
     ($archive_filename =~ m|$Config{'save_dir'}/[^/]*(.*)| );

  if(! -f $archive_filename ){return 1}
  my $rc = unlink($real_filename); 
  #silent, as may fail unlink as may already have been deleted 
  #when undid a transaction, so cant unlink again when do undo all
  #unless($rc){carp "delete_file: unlink: $!";}
  return 1;
}

#====================================================================
# check_pkg

=begin testing

test_reset();
system('rpm -e perl-NCustomDummy > /dev/null 2>&1');

my $junk = "JUNK  gg";
ok(! &NCustom::check_pkg($junk))
  || diag("TEST:<check_pkg> checks input format");
# supress expected error message:
$_STDERR_ =~ s/check_pkg: invalid arguments. at lib\/NCustom.pm line \d+\n// ;
#
my $req = { match => "", version => "0.0.0", pkg => "", result => ""};
my $p = "perl-NCustomDummy";
#
$req = { match => "MINIMUM", version => "0.0.0", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "MISSING")
  || diag("TEST:<check_pkg> checks if package meets minimum version 1/4");
$req = { match => "MAXIMUM", version => "0.0.0", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "MISSING")
  || diag("TEST:<check_pkg> checks if package meets maximum version 1/4");
$req = { match => "EXACTLY", version => "0.0.0", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "MISSING")
  || diag("TEST:<check_pkg> checks if package meets exact version 1/4");
$req = { match => "NOTWANT", version => "0.0.0", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package present 1/4");
#  
system("rpm -i $input/perl-NCustomDummy-1.23-1.noarch.rpm");
#shouldnt assume this works
#
$req = { match => "MINIMUM", version => "1.09.1", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets minimum version 2/4");
$req = { match => "MINIMUM", version => "1.23", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets minimum version 3/4");
$req = { match => "MINIMUM", version => "1.99.9", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "BELOW")
  || diag("TEST:<check_pkg> checks if package meets minimum version 4/4");
#
$req = { match => "MAXIMUM", version => "1.09.1", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "ABOVE")
  || diag("TEST:<check_pkg> checks if package meets maximum version 2/4");
$req = { match => "MAXIMUM", version => "1.23", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets maximum version 3/4");
$req = { match => "MAXIMUM", version => "1.99.9", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets maximum version 4/4");
#
$req = { match => "EXACTLY", version => "1.09.1", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "ABOVE")
  || diag("TEST:<check_pkg> checks if package meets exact version 2/4");
$req = { match => "EXACTLY", version => "1.23", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "OK")
  || diag("TEST:<check_pkg> checks if package meets exact version 3/4");
$req = { match => "EXACTLY", version => "1.99.9", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "BELOW")
  || diag("TEST:<check_pkg> checks if package meets exact version 4/4");
#
$req = { match => "NOTWANT", version => "1.09.1", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "UNWELCOME")
  || diag("TEST:<check_pkg> checks if package present 2/4");
$req = { match => "NOTWANT", version => "1.23", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "UNWELCOME")
  || diag("TEST:<check_pkg> checks if package present 3/4");
$req = { match => "NOTWANT", version => "1.99.9", pkg => $p, result=>"" };
&NCustom::check_pkg($req); is($$req{'result'}, "UNWELCOME")
  || diag("TEST:<check_pkg> checks if package present 4/4");
#
output();

=end testing

=cut

#====================================================================
sub vcmp ;
sub check_pkg {
  my ($req, @rest) = @_ ;
  #$req = { match => "", version => "", pkg => "", result => ""};

  if(! defined $$req{'match'}){
    carp "check_pkg: invalid arguments.";
    return 0 ;
  }
  if($$req{'match'} !~ /(MINIMUM)|(MAXIMUM)|(EXACTLY)|(NOTWANT)/){
    carp "check_pkg: invalid argument values.";
    return 0 ;
  }

  my $rc = system("rpm -q $$req{'pkg'}");

  if(($rc == 0)and($$req{'match'} =~ /NOTWANT/)){ 
    $$req{'result'} = "UNWELCOME";
    return 1;
  }
  if(($rc != 0)and($$req{'match'} =~ /NOTWANT/)){ 
    $$req{'result'} = "OK";
    return 1;
  }
  if(($rc != 0)and($$req{'match'} !~ /NOTWANT/)){ 
    $$req{'result'} = "MISSING";
    return 1;
  }

  my $ver = `rpm -q $$req{'pkg'} --qf  \%{VERSION}` . "";
  my $reqver = "$$req{'version'}" . "";

  # vstring will be deprecated, by then we'll find a module for it
  if(($$req{'match'} =~ /EXACTLY/) and(vcmp($ver, "eq", $reqver))){
    $$req{'result'} = "OK";
    return 1;
  }
  if(($$req{'match'} =~ /MINIMUM|EXACTLY/) and(vcmp($ver, "lt", $reqver))){
    $$req{'result'} = "BELOW";
    return 1;
  }
  if(($$req{'match'} =~ /MAXIMUM|EXACTLY/) and(vcmp($ver, "gt", $reqver))){
    $$req{'result'} = "ABOVE";
    return 1;
  }
  # fall-through is brave ? check this logic
  $$req{'result'} = "OK";
  return 1;
}

#====================================================================
# required_packages

=item C<required_packages>

=begin example

test_reset();
can_ok("NCustom", qw(required_packages)) 
  || diag("TEST:<required_packages> is a public function of NCustom");
#that was test 93

=end example

=for example begin

  sub handler{
    my ($reqref, $url, $file) = @_;
    print "As $$reqref{'match'} version $$reqref{'version'} of ";
    print "$$reqref{'pkg'} was $$reqref{'result'} - ";
    print "we are going to fetch $file from $url and execute it.\n";
    print "This should set things right.\n";
    return 1;
  }

  required_packages(<<'  EOF');
    EXACTLY;   9.9.9;   acme;   handler($req, "URL", "FILE")
    NOTWANT;   0.0.0;   perl;   print "Dont be stupid\n"
    #MAXIMUM;  9.9.9;   perl;   carp("Warning: untested with this perl")
    #MINIMUM;  9.9.9;   perl;   apt_fix()
    NOTWANT;   0.0.0;   perl;	for($i = 0; $i < 10; $i++){$s="Hello"; print "${s}${i}\n"}
  EOF

=for example end

Required packages take a multi-line argument list, where each line is of the format: requirement, version, package, handler code.

Required packages will invoke the handler if the package is (or isnt) installed as per the requirement and version.

Valid requirements are: MINUMUM, MAXUMUM, EXACTLY, and NOTWANT.

Input lines will be ignored if the first non-whitespace character is the '#' character.

The handler code is eval'd, and it may make use of the hashref "req". The hash has the keys: match, version, and package; which correspond to the original arguments. The hash also contains result, which is the answer as to whether the requirements was met or not. Possible values of result (each referring to the package or it's version in relation to the requuirements) are: MISSING, ABOVE, BELOW, or UNWELCOME.

A handler "apt_fix" is provided that will simply attempt to remove UNWELCOME packages, and do an install for all other scenarios - so you might get the verion you want or not, depending upon your apt repository.

=for example_testing
my $o = $_STDOUT_;
my $e = $_STDERR_;
like($o, qr/As EXACTLY version .* fetch FILE from URL and execute it.\n/)
  || diag("TEST:<required_packages> calls a handler");
like($o, qr/Dont be stupid/)
  || diag("TEST:<required_packages> executes simple statements");
like($o, qr/Hello9/)
  || diag("TEST:<required_packages> executes compound statements");
#
# supress expected output
$_STDOUT_ =~ s/Hello\d+\n//gm ;
$_STDOUT_ =~ s/Dont be stupid\n//gm ;
$_STDOUT_ =~ s/As EXACTLY version .* fetch FILE from URL and execute it.\n//gm ;
$_STDOUT_ =~ s/This should set things right.\n//gm ;
#
output();


=cut

#====================================================================
sub required_packages {
  my ($requirements, @rest) = @_;
  my $status = 1;
  my $rc = 1;

  my @lines = split(/\n/,$requirements);
  foreach my $line (@lines){
    $line =~ s/^\s+//;          #trim leading whitespace
    next if $line =~ /^#/;      #TODO# comments need much work

    $req = { match => "", version => "0.0.0", pkg => "", result => ""};
    ($$req{'match'}, $$req{'version'}, $$req{'pkg'}, my @rest) 
      = parse_line('\s*;\s*',1, $line);
    my $code = join(';',@rest);

    $rc = check_pkg($req);
    unless($rc){$status = 0; next}

    if($$req{'result'} ne "OK"){
      #we invoke handler from caller's perspective
      package main ; 
      no strict; no warnings;
      eval $code ;
      if($@){
	carp("required_packages: code \n$code \nraised the error $@");
       	$NCustom::status = 0;
      }
      use strict; use warnings;
      #
      #back to normal
      package NCustom ;
      $rc = check_pkg($req);
      unless(($$req{'result'} eq "OK") && ($rc)){ $status = 0; }
    }
  }
  return $status;
}

#====================================================================
# apt_fix

=begin testing

test_reset();
SKIP: {
  skip "apt too intrusive", 6 unless (defined $ENV{'TEST_APT'} || defined $ENV{'TEST_ALL'});
#############
system('rpm -e perl-NCustomDummy > /dev/null 2>&1');
my ($version, $rc);
$version = `rpm -q perl-NCustomDummy --qf  \%{VERSION}`;
like($version, qr/package perl-NCustomDummy is not installed/)
  || diag("TEST:<test setup> must remove perl-NCustomDummy package");
#
#
can_ok("NCustom", qw(apt_fix)) 
  || diag("TEST:<apt_fix> is a public function of NCustom");
#
$rc = required_packages(<<'  EOF');
  EXACTLY;   9.9.9;   perl-NCustomDummy;   apt_fix()
  EOF
ok(! $rc)
  || diag("TEST:<required_packages> must return 0 if requirements arent met");
$version = `rpm -q perl-NCustomDummy --qf  \%{VERSION}`;
like($version, qr/1.23/)
  || diag("TEST:<apt_fix> must will install its version rather than nothing");
#
$rc = required_packages(<<'  EOF');
  NOTWANT;   9.9.9;   perl-NCustomDummy;   apt_fix()
  EOF
is($rc, 1)
  || diag("TEST:<required_packages> must return 1 if requirements are met");
$version = `rpm -q perl-NCustomDummy --qf  \%{VERSION}`;
like($version, qr/package perl-NCustomDummy is not installed/)
  || diag("TEST:<apt_fix> will remove unwanted packages");
############
}
output();

=end testing

=cut

#====================================================================
sub apt_fix {
  if($$req{'result'} =~ /UNWELCOME/){
    system("apt-get -q -y remove $$req{'pkg'}");
  }else{
    system("apt-get -q -y install $$req{'pkg'}");
  }
  return 1; #hmm
}

#====================================================================
# vcmp

=begin testing

#FALSE
ok(! &NCustom::vcmp(1,"gt",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(! &NCustom::vcmp(1,"eq",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(! &NCustom::vcmp(3,"gt",3) )
  || diag("TEST:<vcmp> compares version strings");
ok(! &NCustom::vcmp(3,"lt",3) )
  || diag("TEST:<vcmp> compares version strings");
ok(! &NCustom::vcmp(3,"ne",3) )
  || diag("TEST:<vcmp> compares version strings");
#
#TRUE";
ok(&NCustom::vcmp(1,"lt",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp(1,"ne",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp(3,"eq",3) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","lt",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","gt","1.1.99") )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","eq","1.2.3") )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp(1,"ne",0) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","lt",2) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","gt","1.1.99") )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","eq","1.2.3") )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp(1,"ne",0) )
  || diag("TEST:<vcmp> compares version strings");
ok(&NCustom::vcmp("1.2.3","lt","1.03") )
  || diag("TEST:<vcmp> compares version strings");
output();

=end testing

=cut


#====================================================================
sub vcmp {
  my ($vstring1, $cmp, $vstring2) = @_;
  my ($v1, $v2, $dummy, @rest);

  # check input ######################################
  if( $cmp !~ /(lt)|(gt)|(eq)|(ne)/ ){
    carp "vcmp: invalid comparision operator: $cmp.\n";
    return 0; #arbitrary
  }
  if( $vstring1 !~ /^(\d+\.)*\d*$/ ){
    carp "vcmp: invalid version string: $vstring1.\n";
    return 0; #arbitrary
  }
  if( $vstring2 !~ /^(\d+\.)*\d*$/ ){
    carp "vcmp: invalid version string: $vstring2.\n";
    return 0; #arbitrary
  }

  # reduce ###########################################
  $vstring1 =~ s/^\.*([^\.]+)\.*// ;
  $v1 = $1;
  #if($v1 eq ""){$v1 = 0}
  #if($vstring1 eq ""){$vstring1 = 0}
  #print "\n\t\tv1: $v1 vstring1: $vstring1 ";
  #
  $vstring2 =~ s/^\.*([^\.]+)\.*// ;
  $v2 = $1;
  #if($v2 eq ""){$v2 = 0}
  #if($vstring2 eq ""){$vstring2 = 0}
  #print "\n\t\tv2: $v2 vstring2: $vstring2 ";


  # result/recuse ###################################
  if( $cmp eq  "eq"){ 
    if((! defined $v1) and (! defined $v2)){
      return 1;
    }elsif((! defined $v1) or (! defined $v2)){
      return 0;
    }elsif( $v1 != $v2 ){
      return 0;
    }elsif( $v1 != $v2 ){
    }else{
      return vcmp($vstring1, $cmp, $vstring2) ;
    }
  }
  if( $cmp eq  "ne"){ 
    if((! defined $v1) and (! defined $v2)){
      return 0;
    }elsif((! defined $v1) or (! defined $v2)){
      return 1;
    }elsif( $v1 != $v2 ){
      return 1;
    }elsif($v1 eq "" && $v2 eq ""){
      return 0;
    }else{
      return vcmp($vstring1, $cmp, $vstring2) ;
    }
  }
  if( $cmp eq  "lt"){ 
    if((! defined $v1) and (! defined $v2)){
      return 0;
    }elsif((! defined $v1) and ( defined $v2)){
      return 1;
    }elsif(( defined $v1) and (!defined $v2)){
      return 0;
    }elsif( $v1 <  $v2 ){
      return 1;
    }elsif($v1 >  $v2 ){
      return 0;
    }elsif($v1 eq "" && $v2 eq ""){
      return 0;
    }else{
      return vcmp($vstring1, $cmp, $vstring2) ;
    }
  }
  if( $cmp eq  "gt"){ 
    if((! defined $v1) and (! defined $v2)){
      return 0;
    }elsif((! defined $v1) and ( defined $v2)){
      return 0;
    }elsif(( defined $v1) and (!defined $v2)){
      return 1;
    }elsif( $v1 >  $v2 ){
      return 1;
    }elsif($v1 <  $v2 ){
      return 0;
    }elsif($v1 eq "" && $v2 eq ""){
      #}elsif($v1 == 0 && $v2 == 0){
      return 0;
    }else{
      return vcmp($vstring1, $cmp, $vstring2) ;
    }
  }
}

#====================================================================
# blat_myconfig

=item C<blat_myconfig>

=begin example

test_reset();
can_ok("NCustom", qw(blat_myconfig)) 
  || diag("TEST:<blat_myconfig> is a public function of NCustom");

=end example

=for example begin

  blat_myconfig();


=for example end

Blat_myconfig overwrites the personal configuration profile with the global configuration profile. The personal configuration profile is "~/.ncustom/NCustom/MyConfig.pm".

=for example_testing
is(compare("$output/.ncustom/NCustom/MyConfig.pm", "$input/Global.pm"), 0)
  || diag(<<'  EOF');
  TEST:<blat_config>
  TEST:   - MyConfig.pm replaced by Config.pm
  TEST:   - This test will fail if you change Config.pm and 
  TEST:     dont update reference copies used in test comparision.
  EOF
#
output();


=cut

#====================================================================
sub blat_myconfig {
  my $rc ;
  my $myconfig_file_dir  = "$ENV{'HOME'}/.ncustom/NCustom";
  my $myconfig_file      = "$myconfig_file_dir/MyConfig.pm";
  my $global_config_file = "dummy" ;

  # ensure target directory exists
  if( ! -e $myconfig_file_dir){
    $rc = mkpath $myconfig_file_dir;
    unless($rc){
      carp "blat_myconfig: couldnt create $myconfig_file_dir: $!"; 
      return 0; 
    }
  }
  if( ! -d $myconfig_file_dir){
    carp "blat_myconfig: not at directory: $myconfig_file_dir";
    return 0;
  }

  # find source file
  foreach my $i (@INC){
    if(-e "$i/NCustom/Config.pm"){
      $global_config_file = "$i/NCustom/Config.pm";
      last;
    }
  }
  if( $global_config_file =~ /^dummy$/){
    carp "blat_myconfig: cant find global Config.pm file";
    return 0;
  }

  # copy file, without pod doco past end
  $rc = open(SRCFILE, "< $global_config_file");
  unless($rc){carp "blat_myconfig: open $global_config_file : $!"; return 0; }

  $rc = open(NEWFILE, "> ${myconfig_file}");
  unless($rc){carp "blat_myconfig: open ${myconfig_file}: $!"; return 0; }

  while(<SRCFILE>){
    /^__END__/ && last;
    print NEWFILE $_ ;
  }
  close(SRCFILE);
  close(NEWFILE);
  return 1;
}

#====================================================================
# config_edit

=item C<config_edit>

=begin example

test_reset();
can_ok("NCustom", qw(config_edit)) 
  || diag("TEST:<config_edit> is a public function of NCustom");

=end example

=for example begin

  config_edit((src_fqdn  => '"install.baneharbinger.com"',
               test_url1 => '"install.baneharbinger.com/index.html"'));



=for example end

Config_edit is followed by name vaule pairs. If there is a corresponding name in the personal configuration file, then its vaule shall be updated. If there is no corresponding name then the name value shall be added to the end of the file. If there is no file it shall be created. The personal configuration file is "~/.ncustom/NCustom/MyConfig.pm". 

If some configuration vlaues are defined in terms of other configuration values, then the order may be important.


=for example_testing
my @lines ; 
open(MYCFG, "< $output/.ncustom/NCustom/MyConfig.pm");
@lines = <MYCFG>;
close(MYCFG);
ok( grep( /src_fqdn.*install.baneharbinger.com/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(add) src_fqdn");
ok( grep( /test_url1.*install.baneharbinger.com/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(add) test_url1");
#
&NCustom::blat_myconfig(); #TODO# hmmm tests should be independent 
&NCustom::config_edit((test_data1 => "wow", test_data2 => "whoopee doo"));
open(MYCFG, "< $output/.ncustom/NCustom/MyConfig.pm");
@lines = <MYCFG>;
close(MYCFG);
ok( grep( /test_data1.*wow/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(change) test_data1");
ok( grep( /test_data2.*whoopee doo/, @lines) > 0 )
  || diag("TEST:<config_edit> can edit(change) test_data2");
#
output();


=cut

#====================================================================
sub config_edit {
  my (%config_edit) = @_;

  my ($rc, $name, $value) ;
  my $myconfig_file_dir  = "$ENV{'HOME'}/.ncustom/NCustom";
  my $myconfig_file      = "$myconfig_file_dir/MyConfig.pm";
  my $global_config_file = "dummy" ;

  # ensure target directory exists
  if( ! -e $myconfig_file_dir){
    $rc = mkpath $myconfig_file_dir;
    unless($rc){ carp "config_edit: mkpath $myconfig_file_dir: $!"; return 0; }
  }
  if( ! -d $myconfig_file_dir){
    carp "config_edit: not at directory: $myconfig_file_dir"; return 0;
  }

  # create blank personal config file if there isnt one
  if( ! -e $myconfig_file){
    $rc = open(NEWFILE, ">$myconfig_file");
    unless($rc){carp "config_edit: open $myconfig_file: $!"; return 0; }
    my $content = <<'    EOF' ;
      package NCustom ;
      no warnings;
      1;
    EOF
    print NEWFILE $content ;
    close(NEWFILE);
  }

  # open files for editting
  $rc = open(OLDFILE, "< ${myconfig_file}");
  unless($rc){carp "config_edit: open ${myconfig_file}: $!"; return 0; }

  $rc = open(NEWFILE, "> ${myconfig_file}.new");
  unless($rc){carp "config_edit: open ${myconfig_file}.new: $!"; return 0; }

  # do options that are already in the file
  while(<OLDFILE>){
    my $line =  $_ ;  
    my $line_replaced = 0;
    next if($line =~ /^\s*1;/) ; # we will add it back on later
    while(($name, $value) = each(%config_edit)) {
      if($line =~ /^\s*\$Config{.$name.}/ ){ #TODO#nasty pattern assumptions!!!
        #print NEWFILE "\$Config{\'$name\'} = \"$value\" ; \n";
        print NEWFILE "\$Config{\'$name\'} = $value ; \n";
	$line_replaced = 1;
        delete($config_edit{$name});
      }
    }
    print NEWFILE $line unless $line_replaced ;
  }
  close(OLDFILE);

  # do options that were not in the file 
  while(($name, $value) = each(%config_edit)) {
    #print NEWFILE "\$Config{\'$name\'} = \"$value\" ;\n";
    print NEWFILE "\$Config{\'$name\'} = $value ;\n";
  }
  print NEWFILE "1;\n"; # we said we would add it back later
  close(NEWFILE);

  # all done
  $rc = move("${myconfig_file}.new", "${myconfig_file}");
  unless($rc){carp "config_edit: move $!"; return 0; }

  return 1;
}

#====================================================================
# ncustom

=item C<ncustom>

=begin example

test_reset();
can_ok("NCustom", qw(ncustom))
  || diag("TEST:<ncustom> is a public function of NCustom");
copy("$input/test1.ncus", "$output");
chmod(0750,"$output/test1.ncus");
copy("$input/test2.ncus", "$output");
chmod(0750,"$output/test2.ncus");

=end example

=for example begin

  ncustom(<<'  EOF');
    ~/test1.ncus
    test2.ncus
  EOF

=for example end

Ncustom is passed one or more filenames, either local filenames or URLs.
The filenames are assumed to be NCustom scripts, are fetched, and executed.
If the filename is not an NCustom script, then transactions will not be journalled, and will not be able to be undone.
An unqualified NCustom script name will be searched for in pwd and the location(s) specified in NCustom::Config.
URLs will be fetched using the get_url subrouting in NCustom::Config.

=for example_testing
open(STUBSLOG, "< $output/stubs.log");
my @lines = <STUBSLOG>;
close(STUBSLOG);
ok( grep( /NCustom test1.ncus/, @lines) > 0 )
  || diag("TEST:<ncustom> fetches and executes file 1/2");
ok( grep( /NCustom test2.ncus/, @lines) > 0 )
  || diag("TEST:<ncustom> fetches and executes file 2/2");
#
output();

=cut

#====================================================================
sub ncustom {
  my ($file_list, @rest) = @_ ;
  my $status = 1;

  #tag#
  my @lines = split(/\n/,$file_list);
  foreach my $line (@lines){
    my $executed = 0;		#we must invoked something for a line
    chomp $line ;
    $line =~ s/^\s+//;          #trim leading whitespace
    next if $line =~ /^#/;      #TODO# comments need much work
    if(ncustom_try_dir($line, "")){$executed = 1}
    if($executed){next}
    if(ncustom_try_url($line, "")){$executed = 1}
    if($executed){next}
    my $src_arraryref = $NCustom::Config{'default_src'};
    foreach my $src (@$src_arraryref){
      my $dir = (glob($src))[0];
      if(-d $dir){
	if(ncustom_try_dir($line, $dir)){$executed = 1}
	if($executed){last};
      }else{
	if(ncustom_try_url($line, $src)){$executed = 1}
	if($executed){last};
      }
    }
    if($executed){next}
    carp "ncustom: cant find/execute \"$line\".\n";
    $status = 0;
  }
  return $status;
}

#====================================================================
sub ncustom_try_dir {
  my ($line, $prefix, @rest) = @_ ;
  my (@candidates, $candidate);
  my $executed = 0 ;
  my $rc ;

  @candidates = glob($line);
  foreach $candidate (@candidates){
    my $file = (glob("${prefix}${candidate}"))[0];
    if(-f $file && -x $file){
      if( basename($file) eq $file){
        $file = "./$file"; 
        # so system call ok in this scenario (regardless of pwd being in path)
      }
      $rc = system($file); 
      carp "ncustom_try_dir: system call=$file : error=$?\n" unless $rc == 0;
      $executed = 1;	 
      #for better or worse...
    }
  }
  return $executed;
}

#====================================================================
sub ncustom_try_url {
  my ($line, $prefix, @rest) = @_ ;
  my (@candidates, $candidate);
  my $executed = 0 ;
  my $rc ;

  my $stagedir = tempdir( DIR => $Config{'tmp_dir'});
  #TODO# add CLEANUP => 1
  my $subref = $NCustom::Config{'get_url'};
  &$subref("${prefix}${line}",$stagedir);
  opendir(DIR, $stagedir); 
  @candidates = grep { -f $_ && -x $_ } # executable files only
    		map  { "$stagedir/$_" }	# form: "path/filename"
    		readdir(DIR);           # all files
  foreach $candidate (@candidates){
    $rc = system($candidate);
    carp "ncustom_try_url: system call=${candidate}: error=$?\n" unless $rc ==0;
    $executed = 1;	 
    #for better or worse...
  }
  return $executed;
}
#====================================================================

# ///////////////////////////////////////////////////////////////////
#<< CC: Constructor     <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
constructor();

sub constructor {
  load_config();
  apply_config();
}

# ///////////////////////////////////////////////////////////////////
#<< DD: Destructor      <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Dont clean up on exit of tests, 
# or we would have nothing to diagnose upon failure of tests,
# instead we prevent polution by doing a cleanup prior to each test,
# this is also better as destructor isnt 100% reliable, depending upon death.

1;
__END__
# ///////////////////////////////////////////////////////////////////
#<< AA: Autoloaded fns  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Autoload methods are processed by the autosplit program.

# ///////////////////////////////////////////////////////////////////
#<< PP: POD Suffix  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#====================================================================

=back

=head1 SEE ALSO

NCustom
NCustom::Config
ncustom

http://baneharbinger.com/NCustom

=head1 AUTHOR

Bane Harbinger, E<lt>bane@baneharbinger.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Bane Harbinger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


