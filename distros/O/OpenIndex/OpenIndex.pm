#$Id: OpenIndex.pm,v 1.04b 2001/10/17 13:33:42 perler@xorgate.com Exp $
package Apache::OpenIndex;
use strict;

$Apache::OpenIndex::VERSION = '1.04b';

use Apache::Constants qw(:common OPT_INDEXES DECLINE_CMD REDIRECT DIR_MAGIC_TYPE);
use DynaLoader ();
use Fcntl qw/:flock/;
use Apache::Util qw(ht_time size_string escape_html);
use Apache::ModuleConfig;
use Apache::Icon;
use Apache::Language;
use Apache::Request;
use Apache::Log;

#Configuration constants
use constant FANCY_INDEXING 	=> 1;
use constant ICONS_ARE_LINKS 	=> 2;
use constant SCAN_HTML_TITLES 	=> 4;
use constant SUPPRESS_LAST_MOD	=> 8;
use constant SUPPRESS_SIZE  	=> 16;
use constant SUPPRESS_DESC	=> 32;
use constant SUPPRESS_PREAMBLE 	=> 64;
use constant SUPPRESS_COLSORT 	=> 128;
use constant THUMBNAILS 	=> 256;
use constant SHOW_PERMS         => 512;
use constant HIDE_EXT		=> 1024;
use constant FOLDERS_FIRST	=> 2048;
use constant NO_OPTIONS		=> 4096;
use constant SKIP_INDEX		=> -1;
use constant ERROR		=> -2;
use constant URI_FILE		=> 1;
use constant URI_DIR		=> 2;
use constant URI_ROOT		=> 4;
use constant URI_MARK		=> 8;

use vars qw(%GenericDirectives);
%GenericDirectives = 
(      
    fancyindexing		=> FANCY_INDEXING,
    iconsarelinks		=> ICONS_ARE_LINKS,
    scanhtmltitles		=> SCAN_HTML_TITLES,
    suppresslastmodified	=> SUPPRESS_LAST_MOD,
    suppresssize		=> SUPPRESS_SIZE,
    suppressdescription		=> SUPPRESS_DESC,
    suppresshtmlpreamble	=> SUPPRESS_PREAMBLE,
    suppresscolumnsorting	=> SUPPRESS_COLSORT,
    thumbnails			=> THUMBNAILS,
    showpermissions		=> SHOW_PERMS,
    hideext			=> HIDE_EXT,
    foldersfirst		=> FOLDERS_FIRST,
);

#Default values
use constant DEFAULT_ICON_WIDTH => 20;
use constant DEFAULT_ICON_HEIGHT=> 22;
use constant DEFAULT_NAME_WIDTH => 23;
use constant DEFAULT_ORDER	=> 'ND';
use constant DEFAULT_FAKE_DIR 	=> '.XOI';
use constant DEFAULT_MARK_DIR 	=> '.MARK';
use constant DEFAULT_TEXT_LEN 	=> 49;
use constant DEFAULT_MENU	=> ['Upload','Unzip','Delete','MkDir','MkFile','Copy','Move','Edit','Rename','Help',];
use constant DEFAULT_ADMN_MENU	=> ['SetGID','Revoke','Debug',];
use constant DEFAULT_POST_MAX 	=> 4194304;
use constant DEFAULT_EDIT_MAX 	=>  131072;
use constant DEFAULT_HELP_URL 	=> 'http://www.xorgate.com/help/OpenIndex';
use constant DEFAULT_DIR_MOD 	=> 0770;
use constant DEFAULT_FILE_MOD 	=> 0460;
use constant REVOKE_DIR		=> '/revoke';
use constant REVOKE_FILE	=> '/revoked';

use vars qw(%sortname);
%sortname =
( 	
'N'=>'Name',
'M'=>'LastModified',
'S'=>'Size',
'D'=>'Description',
);

#Statistics variables
use vars qw($nDir $nRedir $nIndex $nThumb);
$nDir=0;
$nRedir=0;
$nIndex=0;
$nThumb=0;

# global arguments
use vars qw($debug $dodump $errmsg $chgid $users $iconfig %commands);
%commands = (
    Menu => {
	back=>\&procform,
    },
    Upload => {			# name of the menu button selected
	cmd=>\&Upload,		# routine to call when selected
	req=>'browse',		# have to have browse form field
	src=>'browse',
    },
    Unzip => {
	cmd=>\&Unzip,
	min=>1,			# at least 1 item has to be selected
    },
    Delete => {
	cmd=>\&Delete,
	min=>1,			# at least 1 item has to be selected
    },
    MkDir => {
	cmd=>\&MkDir,
	req=>'dst',		# has to have a destination
    },
    MkFile => {
	cmd=>\&Edit,
	req=>'dst',
	src=>'dst',
	back=>\&EditSave,	# routine called back after MkFile submit
    },
    Copy => {
	cmd=>\&Copy,
	req=>'dst',		# has to have a destination
	min=>1,
    },
    Move => {
	cmd=>\&Move,
	req=>'dst',
	min=>1,
    },
    Edit => {
	cmd=>\&Edit,
	min=>1,
	max=>1,			# can only operate on one item
	back=>\&EditSave,	# routine called back after Edit submit
    },
    Rename => {
	cmd=>\&Rename,
	req=>'dst',
	min=>1,
	max=>1,			# can only operate on one item
    },
    Help => {
	cmd=>\&Help,
    },
    SetGID => {
	cmd=>\&SetGID,
	min=>1,
	req=>'group',
	dst=>'group',
	admin=>1,
    },
    Revoke => {
	cmd=>\&Revoke,
	back=>\&Revokem,
	admin=>1,
    },
    Debug => {
	cmd=>\&Debug,
	admin=>1,
    },
    SelectAll => {
	cmd=>\&SelectAll,
    },
);

if ($ENV{MOD_PERL}){
    no strict;
    @ISA=qw(DynaLoader);
    __PACKAGE__->bootstrap($Apache::OpenIndex::VERSION);
    if (Apache->module('Apache::Status')) {
	Apache::Status->menu_item('OpenIndex'=>'Apache::OpenIndex status',\&status);
    }
}

sub oindex {
 my ($r,$args,$filename,$mode,$cfg) = @_;
 my $uri = $r->uri;
 my $fakedir=$cfg->{fakedir};
 my $markdir=$cfg->{markdir};
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $isroot;
 my $retval=1;
    $r->filename($filename);
    return 0 unless opendir HDH, $filename;
 my $msg=$lang->{IndexOf} || 'Index of';
    chomp($msg);
 my $ref=$args->{dir};
    if($mode) {
	if($mode & URI_MARK) {
	    if($cfg->{markroot}) {
		$isroot=$filename=~m:^$cfg->{markroot}$:;
	    } else {
		$isroot=$filename=~m:$fakedir/$markdir/$:;
	    }
	} elsif($mode & URI_ROOT) {
	    $isroot=$uri=~m:^$args->{root}$fakedir/$:;
	    $ref=~s:/$fakedir/:/:;
	}
    } else {
	$isroot=$uri=~m:^$args->{root}$:;
    }
    print STDERR "oindex() open $filename\n" if $debug;
    thumb_conf($r) if $cfg->{options} & THUMBNAILS;
    tagout('h2',$cfg,'', qq~<a name="main">$msg $ref</a></h2>~);
    if($mode) {
	tagout('form',$cfg,qq~method="post" action="$uri" enctype="multipart/form-data"~);
	cmd_form($r,$args,$cfg);
    }
    $nDir++;
    if($cfg->{options} & FANCY_INDEXING) {
	$retval=fancy_page($r,$args,\*HDH,$mode,$isroot); 
    } else {
	$retval=plain_page($r,$args,\*HDH,$mode,$isroot);
    }
    print "</form>\n" if($mode);
    closedir HDH;
    $retval;
}

sub procform {
 my ($r,$args,$cfg,$docroot) = @_;
 my $fakedir = $cfg->{fakedir};
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $mode=$args->{mode};
 my $msg;
 my $dir;
 my $formsrc;
 my $formdst;
 my $userdir;
 my $count;
 my $retval=0;
 my $items=$args->{items};	# Items array selected
 my $icnt=@$items;		# The number selected
 my $cmd = getcmd($cfg->{menu},$args);
    $cmd||=getcmd($cfg->{admnmenu},$args);
 my $cmdname=$lang->{$cmd} || $cmd;
    chomp $cmdname;
 my $req=$commands{$cmd}{req};
    if($mode & URI_MARK) {
	if($args->{dst}=~m:^/:o) {
	    $formdst=$args->{dst};
	} else {
	    $formdst="$args->{dir}$args->{dst}";
	}
	$dir=$args->{dir};
    } elsif($mode & URI_ROOT) {
	if($args->{dst}=~m:^/:o) {
	    $formdst=$args->{dst};
	} else {
	    ($formdst="$args->{dir}$args->{dst}")=~s:/$fakedir/:/:;
	}
	($dir=$args->{dir})=~s:/$fakedir/:/:;
    } else {
	$msg=$lang->{mode} || 'UNKNOWN: mode';
	errmsg($msg);
	return 0;
    }
 my $dst=$commands{$cmd}{dst};
    if($dst) {
	if($dst eq 'src') {
	    $formdst=$formsrc;
	} else {
	    $formdst=$args->{$dst};
	}
    }
    print STDERR "procform($cmd)\n" if $debug;
# check if cmd
    unless($cmd) {
	$msg=$lang->{command} || 'UNKNOWN: command';
	errmsg($msg);
	$r->log->error(__PACKAGE__." internal error: NULL command");
	return ERROR;
    }
# check min select
    $count=$commands{$cmd}{min};
    if($count && $icnt<$count) {
	$msg=$lang->{min} || 'Select more items!';
	errmsg("$cmdname: $msg");
	$r->log->warn(__PACKAGE__." $cmd ERROR: $args->{user}: $msg");
	return ERROR;
    }
# check max select
    $count=$commands{$cmd}{max};
    if($count && $icnt>$count) {
	$msg=$lang->{max} || 'Too many items selected!';
	errmsg("$cmdname: $msg");
	$r->log->warn(__PACKAGE__." $cmd ERROR: $args->{user}: $msg");
	return ERROR;
    }
# check req
    if($req) {
	unless($args->{$req}) {
	    $msg=$lang->{$req} || "$req";
	    chomp($msg);
	    $msg.=' ';
	    $msg.=$lang->{required} || "required!";
	    errmsg("$cmdname: $msg");
	    $r->log->warn(__PACKAGE__." $cmd ERROR: $args->{user}: $msg");
	    return ERROR;
	}
	unless($args->{isadmin}) {
# do not allow hidden files names to be used.
	 my $ignore_regex;
	    if($cfg->{ignore}) {
		if($args->{$req}=~m:[/\\]:o) {
		    $ignore_regex = '.*[/\\\\]'.join('$|.*[/\\\\]',@{$cfg->{ignore}}).'$';
		} else {
		    $ignore_regex = '^'.join('$|^',@{$cfg->{ignore}}).'$';
		}
	    }
	    if($args->{$req}=~m:$ignore_regex:) {
		$msg=$lang->{forbid} || 'Forbidden: ';
		$msg.=$lang->{$req} || $args->{$req};
		errmsg($msg);
		$r->log->error(__PACKAGE__." FORBIDDEN: $req=$args->{$req}");
		return ERROR;
	    }
	}
    }
    $docroot='' if $mode & URI_MARK && $cfg->{markroot};
    $userdir=$cfg->{userdir};
    $docroot='' if $formdst=~m:/~:o && $userdir=~m:^/:o;
    $formdst=xuserdir($formdst,$userdir) if $userdir;
    $dir    =~tr{ :.a-zA-Z0-9~!@#$^&+i_\\\-/}{}cd; #strip unusual characters
    $formdst=~tr{ :.a-zA-Z0-9~!@#$^&+i_\\\-/}{}cd;
    unless(dirbound($formdst,$args->{root})) { # Don't allow $formdst below root
	$msg=$lang->{ProcDstRoot} || 'Destination goes below the root directory';
	errmsg($msg);
	return ERROR;
    } 
 my $oldmask=umask $cfg->{umask} if $args->{gid} && $cfg->{umask};
# process any before command
    if($commands{$cmd}{before}) {
	unless($commands{$cmd}{before}->($r,$args,$cfg,$docroot,$items,$formdst)) {
	    $r->log->error(__PACKAGE__." $cmd before");
	    return ERROR;
	}
    }
    do {
     my $src=$commands{$cmd}{src};
	if($src) {
	    if($src eq 'dst') {
		$formsrc=$formdst;
	    } else {
		$formsrc=$args->{$src};
	    }
	} else {
	    $formsrc="$dir$items->[--$icnt]";
	}
	$formsrc=xuserdir($formsrc,$userdir) if $userdir;
	$formsrc=~tr{ :.a-zA-Z0-9~!@#$^&+i_\\\-/}{}cd;
	unless(dirbound($formsrc,$args->{root})) { # Don't allow $formsrc below root
	    $msg=$lang->{SourcePath} || 'Bad source path';
	    errmsg($msg);
	    umask($oldmask) if $args->{gid} && $cfg->{umask};
	    $retval=ERROR;
	} else {
	    $retval=$commands{$cmd}{cmd}->($r,$args,$cfg,$docroot,$formsrc,$formdst);
	    unless($retval) {
		$r->log->warn(__PACKAGE__." $cmd ERROR: $args->{user}: $docroot: src=$formsrc dst=$formdst");
		$retval=ERROR;
	    } else {
		$retval=0 unless $retval<0 || $retval>99;
	    }
	}
    } until $icnt<1 || $retval;
# process any after command
    if($commands{$cmd}{after}) {
	$retval=$commands{$cmd}{after}->($r,$args,$cfg,$docroot,$formdst);
	unless($retval) {
	    $r->log->error(__PACKAGE__." $cmd after");
	    $retval=ERROR;
	}
    }
    umask($oldmask) if $args->{gid} && $cfg->{umask};
    $retval;
}

# Returns the translated UserDir $path according to the $pattern
sub xuserdir {
 my($path,$pattern)=@_;
    print STDERR "xuserdir() path=$path pattern=$pattern" if $debug;
    return $path unless $pattern;
 my($head,$user,$tail)=$path=~m:^(.*)/~(.+)/(.*):o;
 my $userdir=$pattern;
    if($pattern=~m:/\*/:o) {
	$userdir=~s:/\*:/$user: if $user;
	$path=~s:/~$user:$userdir:;
    } elsif($pattern=~m:^/:o) {
	$path=$pattern;
	$path.='/' unless $path=~m:/$:o;
	$path.="$user/$tail";
    } else {
	$path="$head/$user/$pattern";
	$path.="/$tail" if $tail;
    }
print STDERR "->$path\n" if $debug;
    $path;
}

sub frames {
 my($r,$args,$cfg) = @_;
 my $uri = $r->uri;
 my $footer=gotfooter($r,$cfg);
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $ac = $uri=~m:\?:o ? '&amp;':'?';
 my $msg=qq~src="$uri${ac}frame=main"~;
    print STDERR "frames() uri=$uri src=$msg footer=$footer\n" if $debug;
    if($cfg->{frameset}) {
	tagout('frameset',$cfg);
    } else {
	print qq~<frameset rows="15%,*~,$footer?',15%':'',qq~">\n~;
    }
    if($cfg->{htmltext}{frame}) {
	my $frametext=$lang->{$cfg->{htmltext}{frame}} || $cfg->{htmltext}{frame};
	if($cfg->{frame}) {
	    $frametext=~s:<mainframe>:<frame $msg $cfg->{frame} />:i;
	} else {
	    $frametext=~s:<mainframe>:<frame $msg id="main" />:i;
	}
	print "$frametext\n";
    } else {
	print qq~<frame src="$uri${ac}frame=head" id="head" />\n~;
    	etagout('frame',$cfg,qq~src="$uri${ac}frame=main"~.$cfg->{frame}?'':'id="main"');
	print qq~<frame src="$uri${ac}frame=foot" id="foot" />\n~ if $footer;
    }
    if($cfg->{htmltext}{noframes}) {
	$msg=$lang->{$cfg->{htmltext}{noframe}} || $cfg->{htmltext}{noframe};
    } else {
	$msg=$lang->{NoFrames} || 'Sorry, your browser can not display frames.  Select the following:';
	chomp $msg;
    }
    tagout('noframes',$cfg);
    print qq~$msg <a href="$uri${ac}frame=none">\n</noframes>\n</frameset>\n~;
    1;
}

sub header {
 my ($r,$args,$cfg,$notitle)=@_;
    print STDERR "header() $cfg->{headuri}\n" if $debug;
    if($cfg->{headuri}) {
     my $subr = $r->lookup_uri($cfg->{headuri});
	$subr->run;
    }
    place_doc($r,$cfg,'header') if $cfg->{header};
    unless($notitle || $cfg->{notitle}) {
	tagout('h1',$cfg,'','OpenIndex');
	if($args->{gid}) {
	 my $lang = new Apache::Language($r) if $cfg->{language};
	 my $msg=$lang->{user} || 'User';
	    print " $msg=$args->{user}" if $args->{user};
	 my $cnt=@{$args->{gid}}-1;
	    $msg=$lang->{access} || 'Access';
	    print " $msg=$args->{gidname}[$cnt]";
	    for($cnt--;$cnt>=0;$cnt--) {
		print ",$args->{gidname}[$cnt]";
	    }
	}
	print "</h1>\n";
    }
    1;
}

sub httphead {
 my ($r,$title)=@_;
 my $cfg = Apache::ModuleConfig->get($r);
 my $lang = new Apache::Language($r) if $cfg->{language};
    $r->no_cache(1) if $cfg->{nocache};
    $r->send_http_header('text/html');
    return 0 if $r->header_only;
    print STDERR "httpdhead()\n" if $debug;
# print qq~<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN""http://www.w3.org/TR/REC-html40/loose.dtd">\n~;
    print qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 ~,
	$cfg->{frames}?'FrameSet':'Transitional',qq~//EN\n"~,
	qq~"http://www.w3.org/TR/2000/REC-xhtml1-20000126/DTD/-~,
	$cfg->{frames}?'xhtml1-frameset.dtd':'xhtml1-transitional.dtd',qq~">\n~;
    print '<html>';
    tagout('head',$cfg);
    print $lang->{$cfg->{htmltext}{head}} || $cfg->{htmltext}{head} if $cfg->{htmltext}{head};
    tagout('title',$cfg);
    print "$title</title>\n";
    if($cfg->{htmltext}{style}) {
	tagout('style',$cfg);
	print "$cfg->{htmltext}{style}\n</style>\n";
    }
    print "</head>\n";
    tagout('body',$cfg) unless $cfg->{frames};
    1;
}


sub footer {
 my ($r,$cfg)=@_;
    print STDERR "footer() $cfg->{footuri}\n" if $debug;
    if($cfg->{readme}) {
	etagout('hr',$cfg) unless $cfg->{frames};
	place_doc($r,$cfg,'readme');
    }
    if($cfg->{footuri}) {
     my $subr = $r->lookup_uri($cfg->{footuri});
	$subr->run;
    }
    1;
}

sub gotfooter {
 my ($r,$cfg)=@_;
    return 1 if $cfg->{footuri} || $cfg->{readme};
    0;
}

sub cmd_form {
 my ($r,$args,$cfg)=@_;
 my $uri=$r->uri;
 my $dst;
 my $setgid;
 my $docroot=$r->document_root;
 my $fakedir=$cfg->{fakedir};
 my $textlen=$cfg->{textlen} || DEFAULT_TEXT_LEN;
 my $menu=$cfg->{menu}||DEFAULT_MENU;
    if($args->{error}) {
	tagout('h3',$cfg);
	if($cfg->{font}) {
	    tagout('font',$cfg,'',"ERROR: $errmsg</font></h3>");
	} else {
	    print qq~<font color=#FF0000> ERROR: $errmsg</font></h3>~;
	}
	$args->{error}=0;
    }
    if(!$args->{src}) {
	if(!$args->{file} && $args->{child}) {
	    $args->{src}=$args->{child};
	} else {
	    $args->{src}=$args->{file};
	}
    }
    $dst=$args->{dst};
    $setgid=$args->{gid};
 my $didit;
 my $msg='';
 my $lang = new Apache::Language($r) if $cfg->{language};
    tagout('div',$cfg);
    foreach (@$menu) {
	if($_ eq 'Upload') {
	    $msg=$lang->{$_} || $_;
	    chomp $msg;
	    chomp $msg;
	    textout($r,$cfg,'browse');
	    print "$cfg->{browse}" if $cfg->{browse};
	    etagout('input',$cfg,qq~type="file" name="browse" size=$textlen maxlength=255~);
	    textout($r,$cfg,'upload');
	    etagout('input',$cfg,qq~type="submit" name="$_" value="$msg"~);
	    etagout('br',$cfg);
	}
    }
    foreach (@$menu) {
	unless($_ eq 'Upload') {
	    $msg=$lang->{$_} || $_;
	    chomp $msg;
	    chomp $msg;
	    textout($r,$cfg,$_);
	    etagout('input',$cfg,qq~type="submit" name="$_" value="$msg"~);
	}
    }
    unless($cfg->{options} & FANCY_INDEXING) {  # enter the source item if not FANCY
	$msg=$lang->{src} || 'Select Item';
	chomp $msg;
	textout($r,$cfg,'src');
	etagout('br',$cfg);
	etagout('input',$cfg,
	    qq~TYPE="text" name="src" size=$textlen maxlength=255 value="$args->{src}"~,$msg);
    }
    $msg=$lang->{dst} || 'Destination';
    chomp $msg;
    textout($r,$cfg,'dst');
    etagout('br',$cfg);
    etagout('input',$cfg,qq~type="text" name="dst" size=$textlen maxlength=255 value="$dst"~,$msg);
    tagout('p',$cfg);
    if($args->{isadmin}) {
     my $halflen=($textlen+($textlen%2))/2;
	$menu=$cfg->{admnmenu}||DEFAULT_ADMN_MENU;
	foreach (@$menu) {
	    $msg=$lang->{$_} || $_;
	    chomp $msg;
	    chomp $msg;
	    next if $_ eq 'Revoke' && !$cfg->{revoke};
	    next if $_ eq 'Debug'  && !$cfg->{debug};
	    textout($r,$cfg,$_);
	    etagout('input',$cfg,qq~type="text" name="group" size=$halflen maxlength=255~) if $_ eq 'SetGID';
	    etagout('input',$cfg,qq~type="submit" name="$_" value="$msg"~);
	}
    }
    print qq~<input type="hidden" name="proc" value="Menu" />\n~;
    print qq~<input type="hidden" name="all" value="$args->{all}" />\n~ if $args->{all};
    print qq~<input type="hidden" name="frame" value="$args->{frame}" />\n~ if $args->{frame};
    print "</p></div>\n";
    1;
}

sub textout {
 my ($r,$cfg,$cmd)=@_;
    return unless $cfg->{htmltext}{$cmd};
 my $lang = new Apache::Language($r) if $cfg->{language};
    print $lang->{$cfg->{htmltext}{$cmd}} || $cfg->{htmltext}{$cmd};
}

sub plain_page {
 my ($r,$args,$dirhandle,$mode,$isroot)=@_;
 my $cfg = Apache::ModuleConfig->get($r);
 my $hide=!($args->{isadmin} && $dodump);
 my $ignore_regex;
    $ignore_regex = join('$|^',@{$cfg->{ignore}}) if $cfg->{ignore};
    print "<ul>\n";
    while (my $file = readdir $dirhandle) {
     my $stub;
	next if $file=~m/^\.$/o; # Never display '.' directory
	next if $hide && $file=~m/^$ignore_regex$/;
	next if $file eq ".." and $isroot;
     my $subr = $r->lookup_file($file);
	stat $subr->finfo;
	print '    <li><a href="',$args->{dir},$file;
	print '/' if -d _;
	if($mode) {
	    if($file eq '..') {
		$stub=$args->{dir};
		$stub=~s:/$::;
		$stub=~s:.*/::;
	    }
	    print "?child=$stub" if $stub;
	    print $stub?'&amp;':'?',"frame=$args->{frame}" if $args->{frame};
	    print '#main';
	}
	$file=~s:\..*::o if $cfg->{options} & HIDE_EXT;
    	if($file eq $args->{file}) { # selected file goes BOLD
	    print qq~"><b>$file</b></a></li>\n~;
    	} else {
	    print qq~">$file</a></li>\n~;
    	}
    }
    print "</ul>\n";
    1;
}

sub fancy_page {
 my ($r,$args,$dirhandle,$mode,$isroot)=@_;
 my $msg='';
 my $cfg  = Apache::ModuleConfig->get($r);
 my $subr;
 my $uri = $r->uri;
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $list = read_dir($r,$args,$dirhandle);
    tagout('table',$cfg,qq~summary="OpenIndex"~);
    tagout('tr',$cfg);
    if($cfg->{options} & SUPPRESS_COLSORT) {
	foreach('N','M','S','D') {
	    delete $args->{@_};
	}
    }
 my $listing=do_sort($list,$args,$cfg->{default_order},$cfg->{options} & FOLDERS_FIRST);
#Permission header
    tagout('th',$cfg,'align="left"','Permission</th>') if $cfg->{options} & SHOW_PERMS;
#Owner header
    tagout('th',$cfg,'align="left"','Owner</th>') if $args->{isadmin};
#Group header
    if($args->{gid}) {
	$msg=$args->{isadmin}?"Group":"Access";
	tagout('th',$cfg,'align="left"',"$msg</th>");
    }
#Select header
    tagout('th',$cfg,'align="center"','Select</th>') if $mode;
#Icon header
    tagout('th',$cfg,'align="left"','Icon</th>');
#Name, Last Modified, Size, and Description headers
    foreach ('N', 'M', 'S', 'D') {
	next if $cfg->{options} & SUPPRESS_LAST_MOD && $_ eq 'M';
	next if $cfg->{options} & SUPPRESS_SIZE     && $_ eq 'S';
	next if $cfg->{options} & SUPPRESS_DESC     && $_ eq 'D';
	tagout('th',$cfg,'align="left"');
	$msg=$lang->{$sortname{$_}} || $sortname{$_};
	chomp($msg);
	chomp($msg);
	if(not $cfg->{options} & SUPPRESS_COLSORT) {
	 my $query;
	    if($args->{$_}) {
		if($_ eq 'N') {		# Name, can sort on extention
		    $query=($args->{$_} eq 'D')?'A':($args->{$_} eq 'A')?'E':'D';
		} else {
		    $query = ($args->{$_} eq 'D')?'A':'D';
		}
	    } else {
		$query = 'A';
	    }
	    print qq~<a href="?$_=$query~,$args->{frame}?"&amp;frame=$args->{frame}":'',qq~">~;
	    tagout('i',$cfg,'',"$msg</i></a>");
	} else {
	    print $msg;
    	}
        print "</th>\n";
    }
    print '</tr>';
#End of header
    for my $entry (@$listing) {
     my $stub;
     my $label='';
     my $isdir;
	if($entry eq '..') {
	    next if $isroot;
	    $label=$lang->{Parent} || 'Parent&nbsp;Directory';
	    $isdir=1;
	} else {
	    $label = $entry;
	    $label=~s:\..*::o if $cfg->{options} & HIDE_EXT;
	}
     my $img = $list->{$entry}{icon};
	tagout('tr',$cfg,'align="left"');
#Permission data
	tagout('td',$cfg,'',"$list->{$entry}{mode}</td>") if $cfg->{options} & SHOW_PERMS;
#Owner data
	if($args->{isadmin}) {
	 my $pname=getpwuid($list->{$entry}{uid})||"$list->{$entry}{uid}";
	    tagout('td',$cfg,'',"${pname}</td>");
	}
#Group data
	if($args->{gid}) {
	 my $pname=getgrgid($list->{$entry}{gid})||"$list->{$entry}{gid}";
	    tagout('td',$cfg,'',"${pname}</td>");
	}
	if($mode && $entry eq '..') {
	    $stub=$args->{dir};
	    $stub=~s:/$::;
	    $stub=~s:.*/::;
	}
	$isdir=1 if $list->{$entry}{sizenice} eq '-';
#Select checkbox
	if($mode) {
	    if($entry eq '..') {
		print "<td></td>\n";
	    } else {
		tagout('td',$cfg,'align="center"');
		$msg=qq~TYPE="checkbox" name="${entry}"~;
		$msg.=' checked' if $args->{all};
		etagout('input',$cfg,$msg,'</td>');
	    }
	}
#Icon
	tagout('td',$cfg);
	if($cfg->{options} & ICONS_ARE_LINKS) {
	    $msg=$args->{dir};
	    $msg=~s:/$cfg->{fakedir}/:/: if $mode & URI_ROOT && !$isdir;
	    $msg.=$entry;
	    $msg.='/' if $isdir;
	    $msg.="?frame=$args->{frame}" if $args->{frame};
	    if($mode) {
	     my $ac=$args->{frame}?'&amp;':'?';
		$msg.="${ac}child=$stub" if $stub;
		$msg.='#main';
	    }
	    tagout('a',$cfg,qq~a href="$msg"~);
	}
	print 
qq~<img width="$list->{$entry}{width}" height="$list->{$entry}{height}" src="$img" alt="[$list->{$entry}{alt}]" border="0" />~;
	print "</a>" if ($cfg->{options} & ICONS_ARE_LINKS);
	print "</td>\n";
#Name data
	$msg=$args->{dir};
	$msg=~s:/$cfg->{fakedir}/:/: if $mode & URI_ROOT && !$isdir;
	tagout('td',$cfg);
	$msg.=$entry;
	$msg.='/' if $isdir;
	$msg.="?frame=$args->{frame}" if $args->{frame};
	if($mode) {
	 my $ac=$args->{frame}?'&amp;':'?';
	    $msg.="${ac}child=$stub" if $stub;
	    $msg.='#main';
	}
	tagout('a',$cfg,qq~a href="$msg"~);
	if($entry eq $args->{file}) {  # selected file goes BOLD
	    print qq~<b>$label</b>\n~;
	} else {
	    print qq~$label~;
	}
	print qq~</a></td>\n~;
#Last Modified data
	unless($cfg->{options} & SUPPRESS_LAST_MOD) {
	    tagout('td',$cfg);
	    print qq~$list->{$entry}{modnice}</td>~;
	}
#Size data
	unless($cfg->{options} & SUPPRESS_SIZE ) {
	    tagout('td',$cfg,qq~align="center"~);
	    print $list->{$entry}{sizenice},"</td>\n";
	}
#Description data
	unless($cfg->{options} & SUPPRESS_DESC) {
	    tagout('td',$cfg);
	    print $list->{$entry}{desc},'</td>';
	}
	print "</tr>\n";
    }
    if($mode && $args->{bytes} && !($cfg->{options} & SUPPRESS_SIZE)) {
	print '<tr>';
	print '<td></td>' if $cfg->{options} & SHOW_PERMS;
	print '<td></td>' if $args->{isadmin};
	print '<td></td>' if $args->{gid};
	print '<td></td>';
	print '<td></td>' if $cfg->{options} & ICONS_ARE_LINKS;
	print '<td></td>';
	print '<td></td>' unless ( $cfg->{options} & SUPPRESS_LAST_MOD );
	tagout('td',$cfg,qq~align="center"~);
	print '<b>',size_string($args->{bytes}),"</b></td></tr>\n";
    }
    print "</table>\n";
    if($debug && $dodump) {
	use Data::Dumper;
	print "<hr /><pre>\%list\n";
	print Dumper \%$list;
	print "</pre>";
    }
    1;
}

# Start of internal menu command routines
sub SelectAll {
 my ($r,$args,$cfg) = @_;
 my $uri = $r->uri;
 my $c='?';
    unless($args->{all}) {
	$uri.='?all=1';
	$c='&amp;';
    }
    if($args->{frame}) {
	$uri.="${c}frame=$args->{frame}";
	$c='&amp;';
    }
    $uri.="${c}dst=$args->{dst}" if $args->{dst};
    print STDERR "SelectAll() uri=$uri\n" if $debug;
    $r->header_out(Location=>$uri);
    REDIRECT;
}

sub Help {
 my ($r,$args,$cfg) = @_;
 my $uri=$cfg->{help}||DEFAULT_HELP_URL;
    $uri.="?version=$Apache::OpenIndex::VERSION&amp;postmax=$cfg->{postmax}";
    $uri.="&amp;mark=1"  if $cfg->{mark};
    $uri.="&amp;perms=1" if $args->{gid};
    $uri.="&amp;admin=1" if $args->{isadmin};
    $uri.="&amp;frame=$args->{frame}" if $args->{frame};
    $r->header_out(Location=>$uri);
    $r->log->notice(__PACKAGE__." $args->{user}: Help: $uri");
    REDIRECT;
}

sub Debug {
 my ($r,$args,$cfg) = @_;
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg='';
 my $cmdname=$lang->{Debug} || 'Debug';
    $dodump = !$dodump if $debug;
    print STDERR "Debug=$dodump\n" if $debug;
    $r->log->notice(__PACKAGE__." $args->{user}: Debug: $dodump");
    1;
}

sub SetGID {	# Set the item (file or dir) GID 
 my ($r,$args,$cfg,$root,$src,$igid) = @_;
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg='';
 my $cmdname=$lang->{SetGID} || 'SetGID';
 my $name;
    $src="$root$src";
    chomp $cmdname;
    if($igid=~m:[^0-9]:o) {		# if not a number look-up the group
	$name=$igid;
	unless(($igid=getgrnam $name)) {
	    $msg=$lang->{GIDbad} || 'GID name not found';
	    errmsg(qq~${cmdname}: "$name" $msg~);
	    return 0;
	}
    } else {
	unless(($name=getgrgid $igid)) {
	    $msg=$lang->{GIDbad} || 'GID name not found';
	    errmsg(qq~${cmdname}: "$igid" $msg~);
	    return 0;
	}
    }
    unless($igid && chown(-1,$igid,$src)) {
	$msg=$lang->{GIDset} || 'GID not set';
	errmsg(qq~${cmdname}: "$name" $msg~);
	return 0;
    }
    $r->log->notice(__PACKAGE__." $args->{user}: SetGID: $igid $src");
    1;
}

sub Revoke {
 my ($r,$args,$cfg) = @_;
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg='';
 my $cmdname=$lang->{Revoke} || 'Revoke';
 my $uri = $r->uri;
 my $textlen=$cfg->{textlen} || DEFAULT_TEXT_LEN;
 my $halflen=($textlen+($textlen%2))/2;
    chomp $cmdname;
    $r->no_cache(1);	# Always make sure that the data is not cached
    return SKIP_INDEX unless httphead($r,"OpenIndex $cmdname");
    header($r,$args,$cfg) unless $args->{frame}; 
    tagout('h3',$cfg,'',"OpenIndex $cmdname</h3>");
 my $gotdata;
 my $type;
 my $name;
    foreach (keys %$users) {
	if($users->{$_} eq '-') {
	 my($ruser,$rgid)=m:^(.*?)#(.*?)#:;
	    unless($gotdata) {
		$msg=$lang->{Revoked} || 'The following have been revoked:';
		tagout('p',$cfg,'',"$msg</p>");
		tagout('table',$cfg,qq~summary="$msg" cols="2"~);
		tagout('tr',$cfg);
		tagout('th',$cfg,'',' Type </th>');
		tagout('th',$cfg,'',' Name </th></tr>');
		$gotdata=1;
	    }
	    if($ruser) {
		$type='user';
		$name=$ruser;
	    }
	    if($rgid) {
		$type='gid';
		$name=getgrgid $rgid || $rgid;
	    }
	    tagout('tr',$cfg);
	    tagout('td',$cfg,''," $type </td>");
	    tagout('td',$cfg,''," $name </td></tr>");
	}
    }
    print "</table>\n" if $gotdata;
    unless($gotdata) {
	$msg=$lang->{NoUsers} || 'No user or group revoke information available';
	tagout('p',$cfg,'',"$msg</p>");
    }
    tagout('form',$cfg,qq~method="post" action="$uri" enctype="multipart/form-data"~);
    etagout('input',$cfg,qq~type="text" name="id" size=$halflen maxlength=255~);
	$msg=$lang->{EnableUID} || 'Enable User';
	chomp $msg;
    etagout('input',$cfg,qq~type="submit" name="enauid" value="$msg"~);
	$msg=$lang->{DisableUID} || 'Disable User';
	chomp $msg;
    etagout('input',$cfg,qq~type="submit" name="disuid" value="$msg"~);
	$msg=$lang->{EnableGID} || 'Enable GID';
	chomp $msg;
    etagout('input',$cfg,qq~type="submit" name="enagid" value="$msg"~);
	$msg=$lang->{DisableGID} || 'Disable GID';
	chomp $msg;
    etagout('input',$cfg,qq~type="submit" name="disgid" value="$msg"~);
    tagout('p',$cfg);
	$msg=$lang->{Return} || 'Return';
	chomp $msg;
    etagout('input',$cfg,qq~type="submit" name="return" value="$msg"~);
    etagout('input',$cfg,qq~type="hidden" name="proc" value="Revoke"~);
    hidenargs($args);
    print '</p></form>';
    etagout('hr',$cfg);
    $r->log->notice(__PACKAGE__." $args->{user}: Revoke:");
    SKIP_INDEX;
}

sub Edit {
 my ($r,$args,$cfg,$root,$src) = @_;
 my $relsrc=$src;
    $src="$root$src";
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg;
 my %info;
 my $inifile;
 my $opened;
 my $uri = $r->uri;
 my $fgid=(stat $src)[5];
 my $cmdname=$lang->{Edit} || 'Edit';
    chomp $cmdname;
    if(-e _) {
	unless(isagid($args->{gid},$fgid) || $args->{isadmin}) {
	    $msg=$lang->{SourceAccess} || 'Source access denied';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
	unless(-f _) {
	    $msg=$lang->{NotText} || 'Item is not a text file';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
	unless(-T _) {
	    $msg=$lang->{NotText} || 'Item is not a text file';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
     my $editmax=$cfg->{editmax} | DEFAULT_EDIT_MAX;
	unless(-s _ <= $editmax) {
	    $msg=$lang->{FileTooBig} || 'File size is larger than';
	    errmsg("${cmdname}: $msg $editmax");
	    return 0;
	}
	unless(open ITEM, "<$src") {
	    $msg=$lang->{FileOpen} || 'File open';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
	$opened=1;
    } else {
	return 0 unless parentok($src,$args,$cfg,$cmdname,$lang);
    }
    ($inifile=$src)=~s:^(.*/)(.+):$1\.$2\.ini:;
    if(open INIFILE,"<$inifile") {
	$info{open}=1;
	while(<INIFILE>) {
	    chomp;
	 my($key,$value)=m:(\w+)\s*=\s*(.+):;
	    $info{$key}=$value;
	}
	close INIFILE;
    }
    $r->no_cache(1);	# Always make sure that the data is not cached
    return SKIP_INDEX unless httphead($r,"OpenIndex $relsrc");
    header($r,$args,$cfg) unless $args->{frame}; 
    tagout('h3',$cfg,'',qq~$cmdname "$relsrc"</h3>~);
    if($info{status} eq 'out' && $args->{user} ne $info{user}) {
	$msg=$lang->{warning} || 'WARNING';
	$errmsg="${msg}:";
	if($args->{user}) {
	    $msg=$lang->{User} || 'User';
	    $errmsg.=qq~ $msg "$info{user}"~;
	}
	$msg=$lang->{CheckedOut} || 'Currently has checked out';
	$errmsg.=qq~ $msg "$relsrc"~;
	$r->log->warn(__PACKAGE__." Edit: $errmsg");
	tagout('h3',$cfg);
	if($cfg->{font}) {
	    tagout('font',$cfg,'',"ERROR: $errmsg</font></h3>");
	} else {
	    print qq~<font color=#FF0000> ERROR: $errmsg</font></h3>~;
	}
    }
    unless(open INIFILE, ">$inifile") {
	print STDERR "Edit() File open: $inifile\n" if $debug;
    } elsif(flock INIFILE, LOCK_EX|LOCK_NB) {
	print INIFILE "edited=$info{editedby}\ngid=$info{gid}\ntime=$info{time}\nuser=$args->{user}\nstatus=out\n";
	flock INIFILE, LOCK_UN;
	close INIFILE;
    } else {
	print STDERR "Edit() File lock: $inifile\n" if $debug;
    }
    if($info{open}) {
	$msg=$lang->{EditLast} || 'Last edit information:';
	chomp $msg;
     my $phrase=$msg;
	$msg=$lang->{User} || 'User';
	chomp $msg;
	$phrase.=" $msg";
	$phrase.="=$info{editedby}" if $info{editedby};
	$msg=$lang->{Access} || 'Access';
	chomp $msg;
	$phrase.=" $msg";
	$phrase.="=$info{gid}" if $info{gid};
	$msg=$lang->{Time} || 'Time';
	chomp $msg;
	$phrase.=" ${msg}=$info{time}";
	tagout('p',$cfg,'',"$phrase</p>");
    }
    tagout('form',$cfg,qq~method="post" action="$uri" enctype="multipart/form-data"~);
	$msg=$lang->{Undo} || 'Undo';
	chomp $msg;
    etagout('input',$cfg,qq~type="reset" name="undo" value="$msg"~);;
	$msg=$lang->{Quit} || 'Quit';
	chomp $msg;
    etagout('input',$cfg,qq~type="submiT" name="quit" value="$msg"~);
	$msg=$lang->{Save} || 'Save';
	chomp $msg;
    etagout('input',$cfg,qq~type="submIt" name="save" value="$msg"~);
    tagout('p',$cfg);
    tagout('textarea',$cfg,qq~name="text" rows="24" cols="80"~);
    if($opened) {
	while(<ITEM>) {
	    chomp;
	    print(escape_html($_));
	}
	close ITEM;
    }
    ($inifile=$relsrc)=~s:^(.*/)(.+):$1\.$2\.ini:;
    print '</textarea></p>';
    tagout('p',$cfg);
    print qq~<input type="hidden" name="proc" value="Edit" />\n~,
	qq~<input type="hidden" name="edit" value="$relsrc" />\n~,
	qq~<input type="hidden" name="saver" value="$info{user}" />\n~,
	qq~<input type="hidden" name="info" value="$inifile" />\n~;
    hidenargs($args);
    print qq~</p></form>\n~;
    if($debug && $dodump) {
	use Data::Dumper;
	print "<hr /><pre>\%info\n";
	print Dumper \%info;
	print '</pre>';
	etagout('hr',$cfg);
    }
    $r->log->notice(__PACKAGE__." $args->{user}: Edit: $src");
    SKIP_INDEX;
}

sub MkDir {
 my ($r,$args,$cfg,$root,$src,$dst) = @_;
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg;
 my $cmdname=$lang->{MkDir} || 'MkDir';
    chomp $cmdname;
    unless($dst) {
	$msg=$lang->{DestPath} || 'Bad destination path';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    $dst="$root$dst";
    if(-e $dst) {
	$msg=$lang->{DestExists} || 'Destination exists';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    if($args->{gid}) {
	my $fgid=parentok($dst,$args,$cfg,$cmdname,$lang);
	return 0 unless $fgid; 
	unless(mkdir $dst,0755) {
	    errmsg("${cmdname}: $!");
	    return 0;
	}
	chown(-1,$fgid,$dst);
    } else {
	unless(mkdir $dst,0755) {
	    errmsg("${cmdname}: $!");
	    return 0;
	}
    }
    $r->log->notice(__PACKAGE__." $args->{user}: MkDir: $dst");
    1;
}

sub Unzip {
 my ($r,$args,$cfg,$root,$src,$dst) = @_;
    $dst=~s:/$::;		# strip any trailing '/'
    use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
    use Archive::Zip::Tree;
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg;
 my $cmdname=$lang->{Unzip} || 'Unzip';
    chomp $cmdname;
    unless($dst) {
	$msg=$lang->{DestPath} || 'Bad destination path';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    $src="$root$src";
    $dst="$root$dst";
 my $fgid=(stat $src)[5];
    unless(isagid($args->{gid},$fgid) || $args->{isadmin}) {
	$msg=$lang->{SourceAccess} || 'Source access denied';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    $fgid=(stat $dst)[5];
    if(! -d _) {
	$msg=$lang->{DestDir} || 'Destination is not a directory';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    unless(isagid($args->{gid},$fgid) || $args->{isadmin}) {
	$msg=$lang->{DestAccess} || 'Destination access denied';
	errmsg("${cmdname}: $msg");
	return 0;
    }
 my $zip=Archive::Zip->new($src);
    unless ($zip) {
	$msg=$lang->{FileRead} || 'file read';
	errmsg("${cmdname}: $msg");
	return 0;
    }
 my $files=0;
 my $name;
    $dst.='/';
    for my $member ($zip->members()) {
	($name=$dst).=$member->fileName();
	if($member->isDirectory()) {
	    mkdir $name,0775;
	    chown(-1,$fgid,$name);
            next;
	}
	unless($member->extractToFileNamed($name)==AZ_OK) {
	    errmsg("$cmdname: $name");
	    return 0;
	}
	chown(-1,$fgid,$name);
	++$files;
    }
    $r->log->notice(__PACKAGE__." $args->{user}: Unzip: $src files=$files");
    1;
}

sub Move {
 my ($r,$args,$cfg,$root,$src,$dst) = @_;
 my $target=$src;
    $src="$root$src";
    $dst="$root$dst";
    use File::Copy qw(move);
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg;
 my $cmdname=$lang->{Move} || 'Move';
    chomp $cmdname;
    unless($target) {
	$msg=$lang->{DestPath} || 'Bad destination path';
	errmsg("${cmdname}: $msg");
	return 0;
    }
 my $srcgid=(stat $src)[5];
 my $src_is_dir=1 if -d _;
    unless(isagid($args->{gid},$srcgid) || $args->{isadmin}) {
	$msg=$lang->{SourceAccess} || 'Source access denied';
	errmsg("${cmdname}: $msg");
	return 0;
    }
 my $dstgid=(stat $dst)[5];
    unless(isagid($args->{gid},$dstgid) || $args->{isadmin}) {
	$msg=$lang->{DestAccess} || 'Destination access denied';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    $target=~s:^.*/(.*):$1:;
    $dst="$dst/$target" if $src_is_dir;
    unless(File::Copy::move($src, $dst)) {
	errmsg("${cmdname}: $!");
	return 0;
    }
    chown(-1,$dstgid,$dst) unless $args->{isadmin}; # admin can move others
    $r->log->notice(__PACKAGE__." $args->{user}: Move: $src->$dst");
    1;
}

sub Rename {
 my ($r,$args,$cfg,$root,$src,$dst) = @_;
 my $target=$dst;
    $src="$root$src";
    $dst="$root$dst";
    use File::Copy qw(move);
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg;
 my $fgid=(stat $src)[5];
 my $cmdname=$lang->{Rename} || 'Rename';
    chomp $cmdname;
    unless(isagid($args->{gid},$fgid) || $args->{isadmin}) {
	$msg=$lang->{SourceAccess} || 'source access denied';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    unless($target) {
	$msg=$lang->{DestPath} || 'Bad destination path';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    if(-e $dst) {
	$msg=$lang->{DestExists} || 'Destination';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    unless(File::Copy::move($src, $dst)) {
	errmsg("${cmdname}: $!");
	return 0;
    }
    $r->log->notice(__PACKAGE__." $args->{user}: Rename: $src->$dst");
    1;
}

###################################################################
# The following override is requried because File::NCopy uses glob
# which can not deal with spaces in the file names.
###################################################################
package File::NCopy;
use subs qw(glob);
sub glob {@_};
package Apache::OpenIndex;
###################################################################
sub Copy {
 my ($r,$args,$cfg,$root,$src,$dst) = @_;
 my $target=$src;
    $src="$root$src";
    $dst="$root$dst";
    use File::NCopy qw(copy);
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg;
 my $cmdname=$lang->{Copy} || 'Copy';
    chomp $cmdname;
    unless($target) {
	$msg=$lang->{DestPath} || 'Bad destination path';
	errmsg("${cmdname}: $msg");
	return 0;
    }
 my $file;
 my $isdir;
 my $fgid=(stat $dst)[5];
    $chgid=0;
    if(-e _) {
	$isdir=1 if -d _;
	unless(isagid($args->{gid},$fgid) || $args->{isadmin}) {
	    $msg=$lang->{DestAccess} || 'Destination access denied';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
	$chgid=$fgid if $args->{gid}; # global used by chgid() to set GID
    } else {
	$msg=$lang->{SourcePath} || 'Bad source path';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    unless(isagid($args->{gid},$fgid) || $args->{isadmin}) {
	$msg=$lang->{SourceAccess} || 'Source access denied';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    if(-d _) {
	unless($isdir) {
	    $msg=$lang->{DirConflict} || 'Source directory but a destination file';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
	if($dst=~m:^$src:) {
	    $msg=$lang->{CopyRecusive} || 'Recursive copy detected';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
	$file=File::NCopy->new(recursive=>1,force_write=>1,set_permission=>\&chgid);
    } else {
	$file=File::NCopy->new(force_write=>1,set_permission=>\&chgid);
    }
    unless($file->copy($src, $dst)) {
	$msg=$lang->{DestCheck} || 'Check destination path';
	errmsg("${cmdname}: $msg: $!");
	return 0;
    }
    $r->log->notice(__PACKAGE__." $args->{user}: Copy: $src->$dst");
    1;
}

sub Delete {
 my ($r,$args,$cfg,$root,$src) = @_;
    $src="$root$src";
    use File::Path qw(rmtree);
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg;
 my $fgid=(stat $src)[5];
 my $cmdname=$lang->{Delete} || 'Delete';
    chomp $cmdname;
    unless(-e _) {
	$msg=$lang->{SourcePath} || 'Bad source path';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    unless(isagid($args->{gid},$fgid) || $args->{isadmin}) {
	$msg=$lang->{SourceAccess} || 'Source access denied';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    if(-d _) {
	unless(File::Path::rmtree($src)) {
	    errmsg("${cmdname}: $!");
	    return 0;
	}
    } else {
	unless(unlink($src)) {
	    errmsg("${cmdname}: $!");
	    return 0;
	}
    }
    $r->log->notice(__PACKAGE__." $args->{user}: Delete: $src");
    1;
}

sub Upload {
 my ($r,$args,$cfg,$root,$src,$dst) = @_;
 my $upload=$r->upload;
 my $sfh=$upload->fh;
 my $bytes=0;
 my $size=0;
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg;
 my $cmdname=$lang->{Upload} || 'Upload';
    chomp $cmdname;
    $src=~s:.*[\\/]::o; # strip off the UNIX or DOS filename
    $dst="$root$dst$src";
    unless($sfh) {
	$msg=$lang->{internal} || 'internal';
	errmsg("${cmdname}: $msg");
	return 0;
    }
 my $fgid=parentok($dst,$args,$cfg,$cmdname,$lang);
    return 0 unless $fgid; 
    unless(open DFH, ">$dst") {
	$msg=$lang->{DestOpen} || 'Destination open';
	errmsg("${cmdname}: $msg");
	return 0;
    }
 my $buf;
    while(($size=read($sfh, $buf, 4096))) {
	unless(print DFH $buf) {
	    close DFH;
	    $msg=$lang->{write} || 'write';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
	$bytes+=$size;
    }
    $args->{bytes}+=$bytes;
    close DFH;
    chown(-1,$fgid,$dst);
    $r->log->notice(__PACKAGE__." $args->{user}: Upload: $bytes: $src->$dst");
    1;
}

sub View {
 my ($r,$args,$cfg,$root,$src,$dst) = @_;
    $src.="?frame=$args->{frame}" if($args->{frame});
    $r->log->notice(__PACKAGE__." View: $args->{user}: $src");
    $r->header_out(Location=>$src);
    return REDIRECT;
}
# End of internal menu command routines

# Start of internal proc call back routines
sub EditSave {
 my ($r,$args,$cfg,$docroot)=@_;
 my $file="$docroot$args->{edit}";
    if($args->{save}) {
     my $lang = new Apache::Language($r) if $cfg->{language};
     my $msg;
     my $exists=1 if -e $file;
     my $cmdname=$lang->{EditSave} || 'EditSave';
	chomp $cmdname;
	unless(open FILE, ">$file") {
	    $msg=$lang->{FileOpen} || 'File Open';
	    errmsg("${cmdname}: $msg");
	    return ERROR;
	} else {
	    print FILE $args->{text};
	    close FILE;
	    unless($exists) {
	     my ($parent)=$file=~m:(^.*)/.+:o;
	     my $fgid=(stat $parent)[5];
		chown(-1,$fgid,$file);
	    }
	    $r->log->notice(__PACKAGE__." $args->{user}: EditSave: $file");
	}
    }
    editini($r,$args,$file,"$docroot$args->{info}");
}

sub editini {
 my ($r,$args,$file,$inifile)=@_;
    if($args->{save} || $args->{user} eq $args->{saver}) {
	if($args->{save}) {
	    unless(open INIFILE, ">$inifile") {
		errmsg("Edit: Lock File write open");
		$args->{error}=1;
	    } else {
		unless(flock INIFILE, LOCK_EX|LOCK_NB) {
		    errmsg("Edit: Couldn't lock file.  Try again");
		    $args->{error}=1;
		} else {
		 my $fgid=(stat $file)[5];
		    $fgid=getgrgid $fgid || $fgid;
		    print INIFILE "editedby=$args->{user}\ngid=$fgid\ntime=",scalar localtime,"\nstatus=in\n";
		}
	    }
	} else {
	    unless(open INIFILE, ">>$inifile") {
		errmsg("Edit: Lock File append open");
		$args->{error}=1;
	    } else {
		unless(flock INIFILE, LOCK_EX|LOCK_NB) {
		    errmsg("Edit: Couldn't lock file.  Try again");
		    $args->{error}=1;
		} else {
		    print INIFILE "status=in\n";
		}
	    }
	}
	flock INIFILE,LOCK_UN;
	close INIFILE;
	delete $args->{text};
    }
    1;
}

sub Revokem {
 my ($r,$args,$cfg,$docroot) = @_;
    return 0 if $args->{return};
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg='';
 my $cmdname=$lang->{Revoke} || 'Revoke';
 my $revgid=$args->{id} if $args->{enagid} || $args->{disgid};
 my $revuser=$args->{id} if $args->{enauid} || $args->{disuid};
 my $file="$docroot$args->{root}$cfg->{fakedir}".REVOKE_DIR;
       $file.=REVOKE_FILE;
    if($revgid=~m:[A-Za-z]:o) {
	$revgid=getgrnam $revgid;
    }
    if($revuser eq $args->{user} || $revgid==$cfg->{admin}) {
	$r->warn(__PACKAGE__ . " revoke self not allowed");
	errmsg("admin IDs can not be revoked");
	return 0;
    } else {
     my $result=1;
	$result=revoker($r,$args,$cfg,'user','+',$args->{id}) if $args->{enauid};
	$result=revoker($r,$args,$cfg,'user','-',$args->{id}) if $args->{disuid};
	$result=revoker($r,$args,$cfg,'gid', '+',$args->{id}) if $args->{enagid};
	$result=revoker($r,$args,$cfg,'gid', '-',$args->{id}) if $args->{disgid};
	unless($result) {
	    $r->warn(__PACKAGE__ . " Revoke: $args->{user}: $args->{id}");
	    return 0;
	} else {
	    $r->log->notice(__PACKAGE__." Revoke: $args->{user}: $args->{id}");
	}
    }
    1;
}

sub revoker {
 my ($r,$args,$cfg,$type,$action,$name)=@_;
 my $lang = new Apache::Language($r) if $cfg->{language};
 my $msg;
 my $cmdname=$lang->{Revoke} || 'Revoke';
    chomp $cmdname;
    print STDERR "revoker() type=$type action=$action name=$name\n" if $debug;
    unless($name) {
	$msg=$lang->{RevokeName} || 'No ID number or name provided';
	errmsg("${cmdname}: $msg");
	return 0;
    }
    $name= lc $name;
 my $docroot=$r->document_root;
 my $path="$docroot$args->{root}$cfg->{fakedir}".REVOKE_DIR;
    unless(-e $path) {
	chmod 0750,$path;	# Attempt to create revoke dir
	unless(mkdir $path,0750) {		# If it does not exist
	    $msg=$lang->{create} || 'Can\'t create path';
	    $msg.=" $args->{root}$cfg->{fakedir}".REVOKE_DIR;
	    $msg.=" $!";
	    errmsg($msg);
	    chmod 0550,$path;
	    return 0;
	}
	chmod 0550,$path;
    }
 my $file=$path.REVOKE_FILE;
    if(-e "$file.new") {	# gross file locking, should never happen
	$r->warn(__PACKAGE__ . " revoke file locked: ${file}.new exists");
	$msg=$lang->{FileLocked} || 'File locked';
	errmsg("${cmdname}: $msg");
	return 0;
    }
 my $server=$r->get_server_name;
 my $key;
 my $val;
    if($name=~m:[^0-9]:o) { # if not a number get the GID for the name
	$key=getgrnam $name || $name;
    }
    $key="#${key}#${server}#$args->{root}" if $type eq 'gid';
    $key="${key}##${server}#$args->{root}" if $type eq 'user';
    if($action eq '-') {	# '-' implies disable user/group
	return 1 if $users->{$key} eq '-';	# return if already disabled
	$users->{$key}='-';
	if(open REVOKE, ">>$file") {	# append name to the revoke file
	    print REVOKE "$type=$name\n";
	    close REVOKE;
	} else {
	    $r->warn(__PACKAGE__ . " revoke file append open");
	    $msg=$lang->{FileOpen} || 'File open';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
    } elsif($action eq '+') {		# '+' implies enable user/group
	return 1 if $users->{$key} eq '+'; # return if already enabled
	$users->{$key}='+';
	if(open REVOKE, "<$file") {	# remove name from revoke file 
	    if(open NEWREVOKE, ">$file.new") {
		while(<REVOKE>) {	# copy all but current enabled record
		    ($key,$val)=m:(\w+)\s*=\s*(\w+):;
		    print NEWREVOKE "$key=$val\n" if $key && !($key eq $type && $val eq $name);
		}
		close NEWREVOKE;
		close REVOKE;
		unlink $file;
		rename "$file.new", $file;
	    } else {
		$r->warn(__PACKAGE__ . " revoke file write open");
		$msg=$lang->{FileOpen} || 'File open';
		errmsg("${cmdname}: $msg");
		close REVOKE;
		return 0;
	    }
	} else {
	    $r->warn(__PACKAGE__ . " revoke file read open");
	    $msg=$lang->{FileOpen} || 'File open';
	    errmsg("${cmdname}: $msg");
	    return 0;
	}
    }
    1;
}
# End of internal call back routines

sub tagout {
 my ($tag,$cfg,$prefix,$suffix,$empty)=@_;
 my $conf=$cfg->{htmltags}{$tag};
    print "<$tag";
    print " $prefix" if $prefix;
    print " $conf" if $conf;
    print $empty?' />':'>';
    print "$suffix" if $suffix;
    print "\n";
}

sub etagout {
 my ($tag,$cfg,$prefix,$suffix)=@_;
 tagout($tag,$cfg,$prefix,$suffix,1);
}

sub hidenargs {
 my ($args) =@_;
    print qq~<input type="hidden" name="dst" value="$args->{dst}" />\n~ if $args->{dst};
    print qq~<input type="hidden" name="src" value="$args->{src}" />\n~ if $args->{src};
    print qq~<input type="hidden" name="group" value="$args->{group}" />\n~ if $args->{group};
    print qq~<input type="hidden" name="frame" value="$args->{frame}" />\n~ if $args->{frame};
}

sub substrcnt {
 my ($str,$substr,$offset) =@_;
 my ($cnt,$ndx);
 my $sublen=length $substr;
    for($cnt=0; ($ndx=index($str,$substr,$offset))>=0; $cnt++) {
	$offset=$ndx+$sublen;
    }
    $cnt;
}

sub parentok {
 my ($str,$args,$cfg,$cmd,$lang)=@_;
 my ($parent)=$str=~m:(^.*)/.+:o;
 my $fgid=(stat $parent)[5];
    unless(isagid($args->{gid},$fgid) || $args->{isadmin}) {
	my $msg=$lang->{ParentAccess} || 'Parent access denied';
	errmsg("${cmd}: $msg");
	return 0;	# root(0) gid is always not allowed
    }
    $fgid;
}


sub dirbound {
 my ($dir, $root)=@_;
 my $level=substrcnt($root,'/');
 my $cnt=0;
    while($dir=~m:/:go) {
	$cnt++;
	if($dir=~m:\G\.\.(/|$):o) {
	    return 0 if --$cnt<$level;
	    $cnt-- if m:\G\.\./:o;
	}
    }
    1;
}

sub getcmd {
 my ($c, $a)=@_;
    foreach (@$c) {
	return $_ if $a->{$_};
    }
    '';
}

sub isagid {
 my ($gid,$check)=@_;
    return 0 unless $check;		# never allow a root(0) gid
    return 1 unless $gid && @$gid;	# always a member if no gid 
    for(my $cnt=@$gid-1;$cnt>=0;$cnt--) {
	return 1 if $gid->[$cnt]==$check;
    }
    0;
}

sub chgid {
    chown(-1,$chgid,$_[1]) if $chgid;
    1;
}

sub outfile {
 my ($file,$suppress) = @_;
 my $buf;
    return 0 unless(open OFILE, "<$file");
    while(<OFILE>) {
	if($suppress) {
	    s:</?html.*>\s*::oi if m:</?html[\s>]:oi;
	    s:</?body.*>\s*::oi if m:</?body[\s>]:oi;
	    if(m:<head[\s>]:oi) {
		do {
		    if(m:</head>:oi) {
			s:.*</head>\s*::oi;
			goto SHOW;
		    }
		} while(<OFILE>);
	    }
	}
    SHOW: print;
    }
    close OFILE;
    1;
}

sub errmsg {
    return $errmsg unless defined $_[0];
    ($errmsg)=shift;
    chomp $errmsg;
}

sub getrevoked {
 my ($r,$args,$file)=@_;
 my $server=$r->get_server_name;
 my $key;
    print STDERR "getrevoked() file=$file\n" if $debug;
    if(open REVOKED, $file) {
	while(<REVOKED>) {
	 my ($type,$val)=m:(\w+)=(\w+):;
	    if($type eq 'gid' && $val=~m:[^0-9]:o) {
		$val=getgrnam $val || $val;
	    }
	    $val = lc $val;
	    $key=$type eq 'user'?"$val#":'#';
	    $key.=$type eq 'gid' ?"$val#":'#';
	    $key.="${server}#$args->{root}";
	    print STDERR "getrevoked() found $type=$val key=$key\n" if $debug;
	    $users->{"$key"}='-';
	}
	close REVOKED;
    } else {
	print STDERR "getrevoked() open FAILED: $file\n" if $debug;
    }
}

sub place_doc {
 my ($r,$cfg,$docs) = @_;
 my $uri = $r->uri;
 my $ofile;
 my $subr;
 my $ishtml;
    $uri=~s:/$cfg->{fakedir}/:/: if $cfg->{dir};
    foreach my $doc (@{$cfg->{$docs}}) {
	print STDERR "place_doc() $docs: doc=$doc " if $debug;
	$ishtml=0;
	if($doc=~m:^/:o) {
	    $subr = $r->lookup_uri("$doc");
	    if(stat $subr->finfo) {
		$ofile=$subr->filename();
		$ishtml=1 if $subr->content_type() eq 'text/html';
		print '<pre>' unless $ishtml;
		print STDERR "$ofile\n" if $debug;
		outfile($ofile,$cfg->{options} & SUPPRESS_PREAMBLE);
		unless($ishtml) {
		    print '</pre>';
		    etagout('hr',$cfg);
		}
		next;
	    }
	} else {
	    $subr = $r->lookup_uri("${uri}${doc}");
	    if(stat $subr->finfo) {
		$ofile=$subr->filename();
		$ishtml=1 if $subr->content_type() eq 'text/html';
		print '<pre>' unless $ishtml;
		print STDERR "$ofile\n" if $debug;
		outfile($ofile,$cfg->{options} & SUPPRESS_PREAMBLE);
		unless($ishtml) {
		    print '</pre>';
		    etagout('hr',$cfg);
		}
		next;
	    }
	}
	print STDERR "<MISSING> $doc\n" if $debug;
    }
}

sub userinfo {
 my ($r,$args,$cfg) = @_;
    $cfg = Apache::ModuleConfig->get($r) unless $cfg;
 my $gidenv = $cfg->{gidenv};
    if($r->auth_type eq 'Basic') {
	$args->{user}=$r->user;
    } elsif($cfg->{userenv}) {
	$args->{user}=$r->subprocess_env($cfg->{userenv});
    }
    $args->{gid}=[split /[,:;]|$;/,$r->subprocess_env($gidenv)];
    if($debug) {
	print STDERR "userinfo() user=$args->{user} admin=$cfg->{admin} gidenv=$gidenv\n";
	if($args->{gid}) {
	    print STDERR " gid=";
	    for(my $cnt=@{$args->{gid}}-1;$cnt>=0;$cnt--) {
		print STDERR "$args->{gid}[$cnt],";
	    }
	    print STDERR "\n";
	}
    }
    if($args->{gid}) {
	for(my $cnt=@{$args->{gid}}-1;$cnt>=0; $cnt--) {
	    if($args->{gid}[$cnt]=~m:[^0-9]:o) {	# if not a number, look-up the group name
		$args->{gidname}[$cnt]=$args->{gid}[$cnt];
		$args->{gid}[$cnt]=getgrnam $args->{gidname}[$cnt];
	    } else {
		$args->{gidname}[$cnt]=getgrgid $args->{gid}[$cnt] || $args->{gid}[$cnt];
	    }
	}
    }
    $args->{isadmin}=$args->{gid} && isagid($args->{gid},$cfg->{admin});
}

sub usercheck {
 my ($r,$args,$cfg) = @_;
#
# A lite duty $users hash cache is used in order to reduce file IO
# The cache is not shared between children, so each has initialize it.
# A '-' indicated a revoke and a '+' indicated not revoked.
# This way admin users can revoke users from within the browser.
#
    if($cfg->{revoke} && $args->{gid}) {  # Only check if there is a revoke option and a gid
     my $server=$r->get_server_name;
     my $docroot=$r->document_root;
	unless($users->{"##${server}#$args->{root}"} eq '~') {	# Check if initialized
	    getrevoked($r,$args,"$docroot$args->{root}$cfg->{fakedir}".REVOKE_DIR.REVOKE_FILE);
	    $users->{"##${server}#$args->{root}"}='~';		# mark cache as initialized
	}
	if($users->{"$args->{user}##$server#$args->{root}"} eq '-') {
	    return 0;	# user has been revoked in the past
	} else {
	    for(my $cnt=@{$args->{gid}}-1;$cnt>=0;$cnt--) {  # check each user's gid
	     my $key="#$args->{gid}[$cnt]#$server#$args->{root}";
		if($users->{$key} eq '-') {
		    splice @{$args->{gid}},$cnt,1;	# remove each revoked gid
		    splice @{$args->{gidname}},$cnt,1;	# remove each revoked gid
		    return 0 unless @{$args->{gid}};	# if all gids are revoked
		}
	    }
	}
    }
    1;
}

sub handler {
 my($r)=shift;
 my %args;
 my @items;
 my $filename = $r->filename . $r->path_info;
 my $file;
 my $retval;
 my $oipath;
 my $uri = $r->uri;
 my $subr;
 my $tail;
 my $mode=0;
 my $cfg = Apache::ModuleConfig->get($r);
 my $docroot=$r->document_root;
 my $postmax=$cfg->{postmax}|DEFAULT_POST_MAX;
    $r = Apache::Request->new($r, POST_MAX=>$postmax);
    $cfg->{fakedir}=DEFAULT_FAKE_DIR unless $cfg->{fakedir};
 my $fakedir=$cfg->{fakedir};
    $cfg->{markdir}=DEFAULT_MARK_DIR unless $cfg->{markdir};
 my $markdir=$cfg->{markdir};
    ($args{root})=$uri=~m:(^.*/)$fakedir/:;
    $args{root}=$cfg->{root} unless $args{root};
    $debug=$cfg->{debug};
    print STDERR "===== ", __PACKAGE__, " DEBUG START =====\nuri=$uri " if $debug;
    $filename .= '/' unless $filename =~ m:/$:o;
    if($filename=~m:/$fakedir/:) {	# could be fakedir or markdir
	($oipath)=$filename=~m:(^.*)/$fakedir/:;	# path before fakedir
	unless(-d "$oipath/$fakedir") {			# make sure that the fakedir exists
	    $r->log_reason( __PACKAGE__ . " Path not found: $oipath/$fakedir");
	    print STDERR "FORBIDDEN\n===== ", __PACKAGE__, " DEBUG STOP  =====\n" if $debug;
	    return FORBIDDEN;
	}
	if($filename=~m:/$fakedir/$markdir/:) {		# ckeck for a URI_MARK
	    ($tail)=$filename=~m:$fakedir/$markdir/(.*/?)$:;
	    if($cfg->{markroot}) {
		$oipath=$cfg->{markroot};
		$filename=~s:^.*/$fakedir/$markdir/:$oipath:;
		($args{dir})=$filename=~m:(.*/).*$:o;	# strip any filename
	    } else {
		($args{dir})=$uri=~m:(.*/).*$:o;	# strip any filename
	    }
	    $mode|=URI_MARK;
	} else {
	    ($tail)=$filename=~m:$fakedir/(.*/?)$:;
	    $mode|=URI_ROOT;
	    $filename="$oipath/$tail";	# the actural filename
	    ($args{dir})=$uri=~m:(.*/).*$:o;	# strip any filename
	}
	print STDERR "filename=$filename oipath=$oipath fake=$fakedir mark=$markdir\n" if $debug;
    }
    $filename=~s:/$::;							# Remove any trailing '/'
    $subr = $r->lookup_file("$filename");
    stat $subr->finfo;
    unless(-e _) {
	$r->log_reason( __PACKAGE__ . " Path not found: ");
	print STDERR "FORBIDDEN $filename\n===== ", __PACKAGE__, " DEBUG STOP  =====\n" if $debug;
	return FORBIDDEN;
    } elsif(-d _) {
	unless ($r->path_info || $tail) { #Issue an external redirect if the dir isn't tailed with a '/'
	    $r->header_out(Location=>"$uri/");
	    $nRedir++;
	    print STDERR "REDIRECT\n===== ", __PACKAGE__, " DEBUG STOP  =====\n" if $debug;
	    return REDIRECT;
	}
	$filename .= '/' unless $filename =~ m:/$:o;
	$mode|=URI_DIR if $mode;
	$args{dir}=$uri unless $mode;
    } else {
	($file)=$filename =~ m:.*/(.+)$:o;	# filename clicked
	if($mode) {
	    $mode|=URI_FILE;			# not a directory, but a file
	    $filename =~ s:(.+/).*:$1:;		# the directory clicked
	} else {
	    ($args{dir})=$uri=~m:(.*/):o  unless $mode;
	}
    }
    print STDERR "type=$mode\n" if $debug;
    $r->filename("$filename");
    unless($oipath || ($r->content_type && $r->content_type eq DIR_MAGIC_TYPE)) {
	print STDERR "DECLINED\n===== ", __PACKAGE__, " DEBUG STOP  =====\n" if $debug;
	return DECLINED;
    }
    $args{mode}=$mode;
    if($r->allow_options & OPT_INDEXES || $mode) {
	$args{frame}='';
     my @params = $r->param;
	foreach my $arg (@params) {
	 my @values=$r->param($arg);	# The name params space will not clash.
	    foreach my $value (@values) {
		if($value eq 'on') {	# All select item checkboxes are set to on.
		    push @items, $arg;
		} else {
		    $args{$arg}=$value;
		}
	    }
	}
	$args{items}=\@items;
	if($mode) {	# Set if managing files.
	    if($args{src}) {
		$args{src}=~tr{ .a-zA-Z0-9~!@#$^&+i_\-/}{}cd; # scrub names
		push @items,$args{src};
	    }
	    $args{child}='' if $mode & URI_FILE;
	    $args{file}=$file;
	    $dodump=$debug unless $mode;	# Turn on debug dump for AutoIndex mode
	    userinfo($r,\%args,$cfg);
	    unless(usercheck($r,\%args,$cfg)) {
		$r->log_reason( __PACKAGE__ . " REVOKED: user=$args{user}");
		return FORBIDDEN;
	    }
	    if($cfg->{usersite} && "$cfg->{usersite}/$args{user}/" ne $args{root}) {
		$r->log_reason( __PACKAGE__ . " USERSITE: user=$args{user} site=$cfg->{usersite} root=$args{root}");
		return FORBIDDEN;
	    }
	    if($cfg->{always}) {
		$retval=$cfg->{always}->($r,\%args,$cfg,$uri);
		if($retval>99) {
		    $nRedir++;
		    print STDERR "ALWAYS $retval\n===== ", __PACKAGE__, " DEBUG STOP  =====\n" if $debug;
		    return $retval;
		} 
	    }
	    if($args{proc}) {
		$retval=0;
	     my $lang = new Apache::Language($r) if $cfg->{language};
		unless($args{dir}) {	# Fixup dir if missing
		    $args{dir}="$args{root}$cfg->{fakedir}/";
		    $args{dir}.="$cfg->{markdir}/" if $mode & URI_MARK;
		}
# check if call back routine exists
		unless($commands{$args{proc}}{back}) {
		 my $msg=$lang->{command} || 'UNKNOWN: command';
		    errmsg("$args{proc}: $msg");
		    $retval=ERROR;
		    $r->log->error(__PACKAGE__." internal error: NULL back routine");
		}
# check if admin is required
		if($commands{$args{proc}}{admin} && !$args{isadmin}) {
		 my $msg=$lang->{AdminAccess} || 'Admin access denied';
		    errmsg("$args{proc}: $msg");
		    $r->log->error(__PACKAGE__." Admin access denied");
		    $retval=ERROR;
		}
		$retval=$commands{$args{proc}}{back}->($r,\%args,$cfg,$docroot) unless $retval;
		if($retval>99) {
		    $nRedir++;
		    print STDERR "proc($args{proc}) $retval\n===== ", __PACKAGE__, " DEBUG STOP  =====\n" if $debug;
		    return  $retval;
		} 
		$args{error}=1 if $retval==ERROR;
	    }
	}
	unless($retval==SKIP_INDEX) {
	 my $frames=$cfg->{frames};
	 my $frame=$args{frame};
	 my $oidir;
	    if($mode) {
		$args{dir}=~m:(.*)$cfg->{fakedir}/(.*):;
		$oidir="$1$2";		# snip out the fakedir
	    } else {
		$oidir=$r->uri;
	    }
	    $retval=httphead($r,"OpenIndex $oidir");
	    if($frames && $frame ne 'none') {
		unless($frame) {
		    $retval=frames($r,\%args,$cfg);
		} else {
		    $retval=header($r,\%args,$cfg) if $retval && $frame eq 'head';
		    $retval=oindex($r,\%args,$filename,$mode,$cfg)
			if $retval && $frame eq 'main' && ($mode & URI_MARK);
		    $retval=oindex($r,\%args,$filename,$mode,$cfg)
			if $retval && $frame eq 'main' && !($mode & URI_MARK);
		    $retval=footer($r,$cfg) if $retval && $frame eq 'foot';
		}
		if($retval) {
		    $retval=OK;
		} else {
		    $retval=FORBIDDEN;
		}
	    } else {
		$retval=header($r,\%args,$cfg,!$mode) if $retval;
		$retval=oindex($r,\%args,$filename,$mode,$cfg) if $retval && ($mode & URI_MARK);
		$retval=oindex($r,\%args,$filename,$mode,$cfg) if $retval && !($mode & URI_MARK);
		$retval=footer($r,$cfg) if $retval;
		if($retval) {
		    $retval=OK;
		} else {
		    $retval=FORBIDDEN;
		}
	    }
	} else {
	    $retval=OK;
	}
	if($debug && $dodump) {
	    use Data::Dumper;
	    print "<hr /><pre>\n\$cfg\n";
	    print Dumper $cfg;
	    print "</pre><hr /><pre>\%args\n";
	    print Dumper \%args;
	    print "</pre><hr /><pre>Global variables\n";
	    if($cfg->{revoke}) {
		print "\$users\n";
		print Dumper $users;
	    }
	    print "\$commands\n";
	    print Dumper %commands;
	    print "\$iconfig\n";
	    print Dumper $iconfig;
	    print "</pre><hr /><pre>Environment variables\n";
	    print Dumper $r->subprocess_env();
	    print "</pre><hr />\n";
	}
	print "</body>" unless $args{frame};
	print "</html>\n";
	print STDERR "retval=$retval\n===== ", __PACKAGE__, " DEBUG STOP  =====\n" if $debug;
    } else {
	$retval=FORBIDDEN;
	$r->log_reason( __PACKAGE__ . " Directory index forbidden by rule", $r->uri . " (" . $r->filename . ")");
	print STDERR "FORBIDDEN\n===== ", __PACKAGE__, " DEBUG STOP  =====\n" if $debug;
    }
    $retval;
}

#Configuration Stuff
sub rmarray {
 my ($array, $element) = @_;
    for(my $ndx; $ndx<@$array; $ndx++) {
	return splice @$array,$ndx,1 if lc @$array[$ndx] eq lc $element;
    }
}

sub OpenIndexOptions($$$;*) {
 my ($cfg, $parms, $directive, $cfg_fh) = @_;
 my @args=split /[\s=>,]+/, $directive;
    warn "OpenIndexOptions $directive: No argument" unless $args[0];
 my $lcarg = lc shift @args;
 my ($action)=$args[0]=~m:^([+-]):o;
    $args[0]=~s:^[+-]::o if $action;
 my $arg=$args[0];
    if($lcarg eq 'menu') {
	splice @{$cfg->{menu}} unless $action; # removes all items
	foreach(@args) {
	    if($action eq '-') {
		rmarray \@{$cfg->{menu}},$_;
	    } else {
		if($commands{$_}) { # only add commands that exist
		    unshift @{$cfg->{menu}},$_;
		} else {
		    warn "OpenIndexOptions: MENU:  $_ does not exist! ";
		}
	    }
	}
    } elsif($lcarg eq 'admnmenu') {
	splice @{$cfg->{admnmenu}} unless $action; # to removes all items
	foreach(@args) {
	    if($action eq '-') {
		rmarray \@{$cfg->{admnmenu}},$_;
	    } else {
		if($commands{$_}) {
		    unshift @{$cfg->{admnmenu}},$_;
		} else {
		    warn "OpenIndexOptions: ADMNMENU:  $_ does not exist! ";
		}
	    }
	}
    } elsif($lcarg eq 'import') {
	required($arg); # 1st arg is the module name
     my $r=$args[1]; # 2nd arg is menu command
	if($r) {
	    for(my $ndx=2;$ndx<@args;$ndx=$ndx+2) {
		$commands{$r}{$args[$ndx]}=$args[$ndx+1]; 
	    }
	    no strict 'refs';
	    $commands{$r}{cmd}=\&$arg; # The menu command name and subroutine
	    $commands{$r}{before}=\&{$commands{$r}{before}} if $commands{$r}{before};
	    $commands{$r}{after}=\&{$commands{$r}{after}} if $commands{$r}{after};
	    $commands{$r}{back}=\&{$commands{$r}{back}} if $commands{$r}{back};
	    use strict 'refs';
# A lot can go wrong, but we do check that the routines are defined.
	 my $nodef='before' unless defined &{$commands{$r}{before}};
	       $nodef='after'  unless defined &{$commands{$r}{after}};
	       $nodef='back'   unless defined &{$commands{$r}{back}};
	       $nodef='cmd'    unless defined &{$commands{$r}{cmd}};
	    if($nodef) {
		delete $commands{$r}; # This is bad, so throw it away!
		warn "OpenIndexOptions: IMPORT: routine $nodef not defined! ";
	    }
	} else {
	    warn "OpenIndexOptions: IMPORT: no command! ";
	}
    } elsif($lcarg eq 'always') { # a command always called before all pages
	required($arg); # 1st arg is the module name
     my $r=$args[1]; # 2nd arg is the always command
	if($r) {
	    no strict 'refs';
	    $cfg->{always}=\&$r;
	    use strict 'refs';
	    for(my $ndx=2;$ndx<@args;$ndx=$ndx+2) {
		$commands{always}{$args[$ndx]}=$args[$ndx+1]; 
	    }
	    unless(defined &{$cfg->{always}}) {
		delete $commands{always}; # This is bad, so throw it all away!
		delete $cfg->{always};
		warn "OpenIndexOptions: ALWAYS: routine not defined! ";
	    }
	} else {
	    warn "OpenIndexOptions: ALWAYS: no command! ";
	}
    } elsif ($lcarg eq 'userdir') {
	($cfg->{userdir})=$directive=~m:\w+\s+(.*):o;
    } elsif ($lcarg eq 'textlen') {
	if($arg<8) {
	    warn "Bad OpenIndexOptions $directive directive<8";
	    $cfg->{textlen} = DEFAULT_TEXT_LEN;
	} else {
	    $cfg->{textlen} = $arg;
	}
    } elsif ($lcarg eq 'postmax') {
	if($arg<128000) {
	    warn "Bad OpenIndexOptions $directive directive<128000";
	    $cfg->{postmax} = DEFAULT_POST_MAX;
	} else {
	    $cfg->{postmax} = $arg;
	}
    } elsif ($lcarg eq 'editmax') {
	if($arg<1024) {
	    warn "Bad OpenIndexOptions $directive directive<1024";
	    $cfg->{postmax} = DEFAULT_EDIT_MAX;
	} else {
	    $cfg->{postmax} = $arg;
	}
    } elsif ($lcarg eq 'admin') {
	if($arg=~m:[^0-9]:o) {
	    $arg=getgrnam $arg;
	}
	$cfg->{admin}=$arg;
    } elsif ($lcarg eq 'umask') {
	if($arg>0777 || $arg<0001) {
	    warn "Bad OpenIndexOptions $directive directive";
	} else {
	    $cfg->{umask} = $arg;
	}
    } elsif ($lcarg eq 'help') {
	$cfg->{help} = $arg;
    } elsif ($lcarg eq 'debug') {
	$arg = lc $arg;
	if($arg eq '1' || $arg eq 'yes' || $arg eq 'on') {
	    $cfg->{debug} = 1;
	} else {
	    $cfg->{debug} = 0;
	}
    } elsif ($lcarg eq 'language') {
	$arg = lc $arg;
	if($arg eq '1' || $arg eq 'yes' || $arg eq 'on') {
	    $cfg->{language} = 1;
	} else {
	    $cfg->{language} = 0;
	}
    } elsif ($lcarg eq 'frames') {
	$arg = lc $arg;
	if($arg eq '1' || $arg eq 'yes' || $arg eq 'on') {
	    $cfg->{frames} = 1;
	} else {
	    $cfg->{frames} = 0;
	}
    } elsif ($lcarg eq 'mark') {		# Force mark directory
	$arg = lc $arg;
	if($arg eq '1' || $arg eq 'yes' || $arg eq 'on') {
	    $cfg->{mark} = 1;
	} else {
	    $cfg->{mark} = 0;
	}
    } elsif ($lcarg eq 'revoke') {
	$arg = lc $arg;
	if($arg eq '1' || $arg eq 'yes' || $arg eq 'on') {
	    $cfg->{revoke} = 1;
	} else {
	    $cfg->{revoke} = 0;
	}
    } elsif ($lcarg eq 'nocache') {
	$arg = lc $arg;
	if($arg eq '1' || $arg eq 'yes' || $arg eq 'on') {
	    $cfg->{nocache} = 1;
	} else {
	    $cfg->{nocache} = 0;
	}
    } elsif ($lcarg eq 'notitle') {
	$arg = lc $arg;
	if($arg eq '1' || $arg eq 'yes' || $arg eq 'on') {
	    $cfg->{notitle} = 1;
	} else {
	    $cfg->{notitle} = 0;
	}
    } elsif ($lcarg eq 'userenv') {
	$cfg->{userenv} = $arg;
    } elsif ($lcarg eq 'gidenv') {
	$cfg->{gidenv} = $arg;
    } elsif ($lcarg eq 'root') {
	$cfg->{root} = $arg;
    } else {
	$arg=~s:/$::o; # Remove any trailing '/'
	if($lcarg eq 'fakedir') {
	    $cfg->{fakedir}=$arg;
	} elsif ($lcarg eq 'markdir') {
	    $cfg->{markdir} = $arg;
	} elsif ($lcarg eq 'markroot') {
	    $arg.='/' unless $arg =~ m:/$:o;
	    unless($arg=~m:^/:o) {
		warn "Missing initial '/' in MarkRoot";
	    } else {
		$cfg->{markroot} = $arg;
	    }
	} elsif ($lcarg eq 'usersite') {
	    ($cfg->{usersite})=$directive=~m:\w+\s+(.*):o;
	} else {
	    warn "Unknown OpenIndexOptions $directive directive";
	}
    }
}

sub required {
 my ($module)=@_;
 my ($p,$m)=$module=~m/(.*)::(.*)/o;
    unless($p && $m) {
	$p=__PACKAGE__;
	$m=$module;
    }
    eval "require ${p}::${m}";
    return $m;
}

sub IndexOptions($$$;*) {
 my ($cfg, $parms, $directives, $cfg_fh) = @_;
    foreach (split /[\s,]+/, $directives) {
     my $option;
    (my $action, $_) = (lc $_) =~ /(\+|-)?(.*)/;
	if (/^none$/) {
	    die "Cannot combine '+' or '-' with 'None' keyword" if $action;
	    $cfg->{options} = NO_OPTIONS;
	    $cfg->{options_add} = 0;
	    $cfg->{options_del} = 0;
	} elsif (/^iconheight(=(\d*$|\*$)?)?(.*)$/) {
	    warn "Bad IndexOption $_ directive syntax" if ($3 || ($1 && !$2));
	    if ($2) {
		die "Cannot combine '+' or '-' with IconHeight" if $action;
		$cfg->{icon_height} = $2;
	    } else 	{
		if ($action eq '-') {
		    $cfg->{icon_height} = DEFAULT_ICON_HEIGHT;
		} else {
		    $cfg->{icon_height} = 0;
		}
	    }
	} elsif (/^iconwidth(=(\d*$|\*$)?)?(.*)$/) {
	    warn "Bad IndexOption $_ directive syntax" if ($3 || ($1 && !$2));
	    if ($2) {
		die "Cannot combine '+' or '-' with IconWidth" if $action;
		$cfg->{icon_width} = $2;
	    } else {
		if ($action eq '-') {
		    $cfg->{icon_width} = DEFAULT_ICON_WIDTH;
		} else {
		    $cfg->{icon_width} = 0;
		}
	    }
	} elsif (/^namewidth(=(\d*$|\*$)?)?(.*)$/) {
	    warn "Bad IndexOption $_ directive syntax" if ($3 || ($1 && !$2));
	    if ($2) {
		die "Cannot combine '+' or '-' with NameWidth" if $action;
		$cfg->{name_width} = $2;
	    } else {
		die "NameWidth with no value can't be used with '+'" if ($action ne '-');
		$cfg->{name_width} = 0;
	    }
	} else {
	    foreach my $directive (keys %GenericDirectives) {
		if(/^$directive$/) {
		    $option = $GenericDirectives{$directive};
		    last;                
		}
	    }
	    warn "IndexOptions unknown/unsupported directive $_" unless $option;
	}
	if(!$action) {
	    $cfg->{options} |= $option;
	    $cfg->{options_add} = 0;
	    $cfg->{options_del} = 0;
	} elsif($action eq '+') {
	    $cfg->{options_add} |= $option;
	    $cfg->{options_del} &= ~$option;
	} elsif($action eq '-') {
	    $cfg->{options_del} |= $option;
	    $cfg->{options_add} &= ~$option;
	}
	if(($cfg->{options} & NO_OPTIONS) && ($cfg->{options} & ~NO_OPTIONS)) {
	    die "Cannot combine other IndexOptions keywords with 'None'";
	}
    }
    return DECLINE_CMD if Apache->module('mod_autoindex.c');
}

sub DIR_CREATE {
 my $class=shift;
 my $self=$class->new;
 my $menu=DEFAULT_MENU;
    $self->{menu}=[@$menu];
    $menu=DEFAULT_ADMN_MENU;
    $self->{admnmenu}=[@$menu];
    $self->{userdir}='';
    $self->{usersite}='';
    $self->{icon_width}=DEFAULT_ICON_WIDTH;
    $self->{icon_height}=DEFAULT_ICON_HEIGHT;
    $self->{name_width}=DEFAULT_NAME_WIDTH;
    $self->{default_order}=DEFAULT_ORDER;
    $self->{fakedir}=DEFAULT_FAKE_DIR;
    $self->{markdir}=DEFAULT_MARK_DIR;
    $self->{markroot}='';
    $self->{root}="";
    $self->{admin}=0;
    $self->{umask}=0;
    $self->{frames}=0;
    $self->{mark}=0;
    $self->{revoke}=0;
    $self->{notitle}=0;
    $self->{nocache}=0;
    $self->{debug}=0;
    $self->{textlen}=DEFAULT_TEXT_LEN;
    $self->{postmax}=DEFAULT_POST_MAX;
    $self->{help}=DEFAULT_HELP_URL;
    $self->{language}=0;
    $self->{gidenv}= "";
    $self->{userenv}= "";
    $self->{headuri}="";
    $self->{footuri}="";
    $self->{ignore}=[];
    $self->{header}=[];
    $self->{readme}=[];
    $self->{indexfile}=[];
    $self->{desc}={};
    $self->{htmltags}={};
    $self->{htmltext}={};
    $self->{options}=0;
    $self->{options_add}=0;
    $self->{options_del}=0;
    return $self;
}

sub DIR_MERGE {
 my ($parent, $current) = @_;
 my %new;
    $new{default_order} = $current->{default_order} || $parent->{default_order};
    $new{options_add} = 0;
    $new{options_del} = 0;
    if($current->{options} & NO_OPTIONS) { # None=override all
	$new{options} = NO_OPTIONS;
    } else {
	if ($current->{options} == 0) { # all incremental, so combine them with parent
	    $new{options_add} = ($parent->{options_add} | $current->{options_add}) & ~$current->{options_del};
	    $new{options_del} = ($parent->{options_del} | $current->{options_del}) ;
	    $new{options} = $parent->{options} & ~NO_OPTIONS;
	} else {			# not all incremental, so no inheritance
	    $new{options} = $current->{options};
	}
# Collect cascaded options
	$new{options} |= $new{options_add};
	$new{options} &= ~ $new{options_del};
    }
    $new{userdir}     = $current->{userdir}     || $parent->{userdir};
    $new{usersite}    = $current->{usersite}    || $parent->{usersite};
    $new{icon_height} = $current->{icon_height} || $parent->{icon_height};
    $new{icon_width}  = $current->{icon_width}  || $parent->{icon_width};
    $new{name_width}  = $current->{name_width}  || $parent->{name_width};
    $new{fakedir}     = $current->{fakedir}     || $parent->{fakedir};
    $new{markdir}     = $current->{markdir}     || $parent->{markdir};
    $new{markroot}    = $current->{markroot}    || $parent->{markroot};
    $new{frames}      = $current->{frames}      || $parent->{frames};
    $new{root}        = $current->{root}        || $parent->{root};
    $new{admin}       = $current->{admin}       || $parent->{admin};
    $new{umask}       = $current->{umask}       || $parent->{umask};
    $new{textlen}     = $current->{textlen}     || $parent->{textlen};
    $new{postmax}     = $current->{postmax}     || $parent->{postmax};
    $new{help}        = $current->{help}        || $parent->{help};
    $new{language}    = $current->{language}    || $parent->{language};
    $new{userenv}     = $current->{userenv}     || $parent->{userenv};
    $new{gidenv}      = $current->{gidenv}      || $parent->{gidenv};
    $new{mark}        = $current->{mark}        || $parent->{mark};
    $new{revoke}      = $current->{revoke}      || $parent->{revoke};
    $new{nocache}     = $current->{nocache}     || $parent->{nocache};
    $new{notitle}     = $current->{notitle}     || $parent->{notitle};
    $new{debug}       = $current->{debug}       || $parent->{debug};
    $new{menu}        = $current->{menu}        || $parent->{menu};
    $new{admnmenu}    = $current->{admnmenu}    || $parent->{admnmenu};
    $new{always}      = $current->{always}      || $parent->{always};
    $new{headuri}     = $current->{headuri}     || $parent->{headuri};
    $new{footuri}     = $current->{footuri}     || $parent->{footuri};
    $new{readme}      = [ @{$current->{readme}},   @{$parent->{readme}} ];
    $new{header}      = [ @{$current->{header}},   @{$parent->{header}} ];
    $new{readme}      = [ @{$current->{readme}},   @{$parent->{readme}} ];
    $new{ignore}      = [ @{$current->{ignore}},   @{$parent->{ignore}} ];
    $new{indexfile}   = [ @{$current->{indexfile}},@{$parent->{indexfile}} ];
    $new{desc} = {% {$current->{desc}}};
    foreach ( keys %{$parent->{desc}}) { $new{desc}->{$_}=$parent->{desc}{$_}; }
    $new{htmltags} = {% {$current->{htmltags}}};
    foreach ( keys %{$parent->{htmltags}}) { $new{htmltags}->{$_}=$parent->{htmltags}{$_}; }
    $new{htmltext} = {% {$current->{htmltext}}};
    foreach ( keys %{$parent->{htmltext}}) { $new{htmltext}->{$_}=$parent->{htmltext}{$_}; }
    return bless \%new, ref($parent);
}

sub DirectoryIndex($$$;*) {
 my ($cfg, $parms, $files, $cfg_fh) = @_;
    for my $file (split /\s+/, $files) {
	push @{$cfg->{indexfile}}, $file;
    }
    return DECLINE_CMD if Apache->module('mod_dir.c');
}

sub AddDescription($$$;*) {
#this is not completely supported.  
#Since I didn't take the time to fully check mod_autoindex.c behavior,
#I just implemented this as simplt as I could.
 my ($cfg, $parms, $args, $cfg_fh) = @_;
 my ($desc, $files) = ( $args =~ /^\s*"([^"]*)"\s+(.*)$/);
 my $file = join "|", split /\s+/, $files;
    $file = patternize($file);
    $cfg->{desc}{$file} = $desc; 
    return DECLINE_CMD if Apache->module('mod_autoindex.c');
}

sub IndexOrderDefault($$$$) {
 my ($cfg, $parms, $order, $key) = @_;
    die "First keyword must be Ascending, Desending, or Extension" unless ( $order =~ /^(descending|ascending|extension)$/i);
    die "Second keyword must be Name, Date, Size or Description" unless ( $key =~ /^(date|name|size|description)$/i);
    die "Only the Name column can be sorted by Extension" if $order eq 'extension' && $key ne 'name';
    if ($key =~ /date/i) {
	$key = 'M';
    } else {
	$key =~ s/(.).*$/$1/;
    }
    $order =~ s/(.).*$/$1/;
    $cfg->{default_order} = $key . $order;
    return DECLINE_CMD if Apache->module('mod_autoindex.c');
}

sub FancyIndexing ($$$) {
 my ($cfg, $parms, $opt) = @_;
    die "FancyIndexing directive conflicts with existing IndexOptions None" if ($cfg->{options} & NO_OPTIONS);
    $cfg->{options} = ($opt ? ( $cfg->{options} | FANCY_INDEXING ) : ($cfg->{options} & ~FANCY_INDEXING));
    return DECLINE_CMD if Apache->module('mod_autoindex.c');
}
	
sub patternize {
 my $pattern = shift;
    $pattern =~ s/\./\\./g;
    $pattern =~ s/\*/.*/g;
    $pattern =~ s/\?/./g;
    return $pattern;
}

sub push_config {
 my ($cfg, $parms, $value) = @_;
 my $key = $parms->info;
    if ($key eq 'ignore'){
	$value = patternize($value);
    }
    push @ {$cfg->{$key}}, $value;
    return DECLINE_CMD if Apache->module('mod_autoindex.c');
}

sub set_config ($$$) {
 my ($cfg, $parms, $value) = @_;
    $cfg->{$parms->info}=$value;
}

sub IndexHtmlTag($$$;*) {
 my ($cfg,$parms,$directive,$cfg_fh) = @_;
 my ($key,$action,$value)=$directive=~m:(\w+)\s+([+-])?(.+):o;
    unless($key) {
	warn "IndexHtmlTag $directive: No argument";
	return;
    }
    $key=lc($key);
    if($action eq '+') { # '+' action provides multiple lines
	$cfg->{htmltags}{$key}.="\n$value";
    } else {
	$cfg->{htmltags}{$key}="$value";
    }
}

sub IndexHtmlText($$$;*) {
 my ($cfg,$parms,$directive,$cfg_fh) = @_;
 my ($key,$action,$value)=$directive=~m:(\w+)\s+([+-])?(.*):o;
    unless($key) {
	warn "IndexHtmlText $directive: No argument";
	return;
    }
    $key=lc($key);
    if($action eq '+') { # '+' action provides multiple lines
	$cfg->{htmltext}{$key}.="\n$value";
    } else {
	$cfg->{htmltext}{$key}="$value";
    }
}
# End of Configuration Stuff

sub status {
 my ($r, $q) = @_;
 my @s;
 my $cfg = Apache::ModuleConfig->get($r);
    push (@s,"<b>" , __PACKAGE__ , " (ver $Apache::OpenIndex::VERSION) statistics</b><br />");
    push (@s,"Done ".$nDir.   " listings so far<br />");
    push (@s,"Done ".$nRedir. " redirects so far<br />");
    push (@s,"Done ".$nIndex. " indexes so far<br />");
    push (@s,"Done ".$nThumb. " thumbnails so far<br />");
    use Data::Dumper;
    my $string = Dumper $cfg;
    push (@s, $string);
    return \@s;
}

sub thumb_conf {
 my($r) = @_;
    use Storable;
    $iconfig->{cache_dir} = $r->dir_config("IndexCacheDir") || ".thumbnails";
    $iconfig->{dir_create} = $r->dir_config("IndexCreateDir") || 1;
 my $cachedir = $r->filename .  $iconfig->{cache_dir} ;          
    stat $cachedir;
    $iconfig->{cache_ok} = (-e _ && ( -r _ && -w _)) || ((not -e _) && 
	$iconfig->{dir_create} && mkdir $cachedir,0755);
 my $oldopts;
    if ($iconfig->{cache_ok} && -e "$cachedir/.config" && -r _){
	$oldopts = retrieve ("$cachedir/.config");
    }
    $iconfig->{thumb_max_width} = $r->dir_config("ThumbMaxWidth") || DEFAULT_ICON_WIDTH*4;
    $iconfig->{thumb_max_height} = $r->dir_config("ThumbMaxHeight")|| DEFAULT_ICON_HEIGHT*4;
    $iconfig->{thumb_max_size} = $r->dir_config("ThumbMaxSize") || 500000;
    $iconfig->{thumb_min_size} = $r->dir_config("ThumbMinSize") || 5000;
    $iconfig->{thumb_width} = $r->dir_config("ThumbWidth");
    $iconfig->{thumb_height} = $r->dir_config("ThumbHeight");
    $iconfig->{thumb_height} = $r->dir_config("ThumbHeight");
    $iconfig->{thumb_scale_width} = $r->dir_config("ThumbScaleWidth");
    $iconfig->{thumb_scale_height} = $r->dir_config("ThumbScaleHeight");
    $iconfig->{changed} = 0;
    foreach (keys %$iconfig){
	next unless /^thumb/;
	if ($iconfig->{$_} != $oldopts->{$_}) {
	    $iconfig->{changed} = 1;
	    last;
	}
    }
    unless ($iconfig->{cache_ok} && ((not -e "$cachedir/.config") || -w _) && store $iconfig, "$cachedir/.config") {
	$iconfig->{changed} = 0;
    }
}

sub read_dir {
 my ($r,$args,$dirhandle) = @_;
 my $cfg = Apache::ModuleConfig->get($r);
 my @listing;
 my %list;
 my @accept;
 my $size;
 my $hide=!($args->{isadmin} && $dodump);
 my $ignore_regex;
    $ignore_regex = join('$|^',@{$cfg->{ignore}}) if $cfg->{ignore};
    if($cfg->{options} & THUMBNAILS) {
        #Decode the content-encoding accept field of the client
        foreach (split(',\s*',$r->header_in('Accept'))) {
           push @accept, $_ if m:^image/:o;
    	}
    }
    $args->{bytes}=0;
    while(my $file = readdir $dirhandle) {
	next if $file=~m/^\.$/o; # Never display '.' directory
	next if $hide && $file=~m/^$ignore_regex$/;
	push @listing, $file;
     my $subr = $r->lookup_file($file);
	$list{$file}{uid}=(stat $subr->finfo)[4];
	$list{$file}{gid}=(stat _)[5];
	$size = -s _;
	$list{$file}{size} = $size;
	$args->{bytes}+=$size;
	if (-d _) {
	    $list{$file}{size} = -1;
	    $list{$file}{sizenice} = '-';
	} else {
	    $list{$file}{sizenice} = size_string($list{$file}{size});
            $list{$file}{sizenice} =~ s/\s*//;    
        }
        $list{$file}{mod}  = (stat _)[9];
        $list{$file}{modnice} = ht_time($list{$file}{mod}, "%d-%b-%Y %H:%M", 0);
        $list{$file}{modnice} =~ s/\s/&nbsp;/g;
        $list{$file}{mode} = write_mod((stat _)[2]);
        $list{$file}{type}  = $subr->content_type;
        if(($list{$file}{type} =~ m:^image/:o) && 
	   ($cfg->{options} & THUMBNAILS ) && 
	   Apache->module("Image::Magick")) {
            if ($iconfig->{cache_ok}) {
                ($list{$file}{icon},$list{$file}{width},$list{$file}{height}) = get_thumbnail($r, $file, $list{$file}{mod}, $list{$file}{type}, @accept);
	    }
	}
        $list{$file}{height} ||= $cfg->{icon_height};
        $list{$file}{width} ||= $cfg->{icon_width};
# icons size might be calculated on the fly and cached...
     my $icon = Apache::Icon->new($subr);
	$list{$file}{icon} ||= $icon->find;           
	if (-d _) {	
	    $list{$file}{icon} ||= $icon->default('^^DIRECTORY^^');	
	    $list{$file}{alt} = "DIR";
	}	    
	$list{$file}{icon} ||= $icon->default;
        $list{$file}{alt} ||= $icon->alt; 
	$list{$file}{alt} ||= "???"; 
        foreach (keys %{$cfg->{desc}}) {
            $list{$file}{desc} = $cfg->{desc}{$_} if $subr->filename =~ /$_/;
	}
        if($list{$file}{type} eq "text/html" and 
	  ($cfg->{options} & SCAN_HTML_TITLES) and 
	  not $list{$file}{desc}) {
            use HTML::HeadParser;
         my $parser = HTML::HeadParser->new;
            open FILE, $subr->filename;
            while (<FILE>) {
                last unless $parser->parse($_);
	    }
            $list{$file}{desc} = $parser->header('Title');
            close FILE;
	}
        $list{$file}{desc} ||= "&nbsp;";
    }
    return \%list;
}

sub do_sort {
 my ($list,$query,$default,$foldersfirst) = @_;
 my @names = sort keys %$list;
    shift @names;                   #removes '..'
#handle default sorting
    unless ($query->{N} || $query->{S} || $query->{D} || $query->{M}) {
	$default =~ /(.)(.)/;
	$query->{$1} = $2;
    }
    if($query->{N}) {
	@names = sort file_ext @names if $query->{N} eq 'E';
	@names = sort @names if $query->{N} eq 'D';
	@names = reverse sort @names if $query->{N} eq "A";
    } elsif($query->{S}) {
	@names = sort { $list->{$b}{size} <=> $list->{$a}{size} } @names if $query->{S} eq "D";
	@names = sort { $list->{$a}{size} <=> $list->{$b}{size} } @names if $query->{S} eq "A";
    } elsif($query->{M}) {
	@names = sort { $list->{$b}{mod} <=> $list->{$a}{mod} } @names if $query->{M} eq "D";
	@names = sort { $list->{$a}{mod} <=> $list->{$b}{mod} } @names if $query->{M} eq "A";		
    } elsif($query->{D}) {
	@names = sort { $list->{$b}{desc} cmp $list->{$a}{desc} } @names if $query->{D} eq "D";
	@names = sort { $list->{$a}{desc} cmp $list->{$b}{desc} } @names if $query->{D} eq "A";		
    }
    unshift @names, '..';           #puts back '..' on top of the pile
    if($foldersfirst) {
     my @folders;
	for(my $n=0; $n<@names; ) {
	    if($list->{$names[$n]}{sizenice} eq '-') {
		push @folders,$names[$n];# Add dir to @folders
		splice(@names,$n,1);	 # Remove dir from @names
	    } else {
		$n++;
	    }
	}
   	splice(@names,0,0,@folders);
    }
    return \@names;
}

sub file_ext {
 my @aa=split /\./,$a;
 my @ba=split /\./,$b;
 my $an=$#aa;
 my $bn=$#ba;
 my $retval=0;
    while($an>=1 && $bn>=1) {
	return $retval if($retval=$aa[$an--] cmp $ba[$bn--]); 
    }
    return $aa[$an] cmp $ba[$bn] if $an==$bn;
    return 1  if $bn<1;
    return -1 if $an<1;
    0;
}

sub get_thumbnail {
 my ($r, $filename, $mod, $content, @accept) = @_; 
 my $accept = join('|', @accept);
 my $dir = $r->filename;
#these should sound better.
 my $cachedir = $iconfig->{cache_dir};
 my $xresize;
 my $yresize;
 my $img = Image::Magick->new;
 my($imgx, $imgy, $img_size, $img_type) = split(',', $img->Ping($dir . $filename));
#Is the image OK?
    return "/icons/broken.gif" unless ($imgx && $imgy);
    if (($content =~ /$content/) && ($img_type =~ /JPE?G|GIF|PNG/i)) {
	if ($dir =~ /$cachedir\/$/) {	#We know that what we'll generate will be seen.
	    return $filename, $imgx, $imgy #Avoiding recursive thumbnails from Hell
	}
	return undef if $img_size > $iconfig->{thumb_max_size}; #The image is way too big to try to process...
	if(defined $iconfig->{thumb_scale_width} || 
           defined $iconfig->{thumb_scale_height}) {
            #Factor scaling
            $xresize = $iconfig->{thumb_scale_width} * $imgx if defined $iconfig->{thumb_scale_width};
            $yresize = $iconfig->{thumb_scale_height} * $imgy if defined $iconfig->{thumb_scale_height};           
	} elsif(defined $iconfig->{thumb_width} || 
	    defined $iconfig->{thumb_height}) {
#Absolute scaling
	    $xresize = $iconfig->{thumb_width}  
		if defined $iconfig->{thumb_width};
	    $yresize = $iconfig->{thumb_height} 
		if defined $iconfig->{thumb_height};           
	}
#preserve ratio if we can
	$xresize ||= $yresize * ($imgx/$imgy);
	$yresize ||= $xresize * ($imgy/$imgx);   
#default if values are missing.
	$xresize ||= DEFAULT_ICON_WIDTH;
	$yresize ||= DEFAULT_ICON_HEIGHT;
#round off for picky browsers
	$xresize = int($xresize);
	$yresize = int($yresize);
#Image is too small to actually resize.  Simply resize with the WIDTH and HEIGHT attributes of the IMG tag
	return ($filename, $xresize , $yresize) if $img_size < $iconfig->{thumb_min_size};
	if ($iconfig->{changed} || $mod > (stat "$dir$cachedir/$filename")[9]) {
#We should actually resize the image
	if ($img->Read($dir . $filename)) { #Image is broken
	    return "/icons/broken.gif";
	}
	$nThumb++;
	$img->Sample(width=>$xresize, height=>$yresize);
	$img->Write("$dir$cachedir/$filename");       
    }
    return "$cachedir/$filename", $xresize , $yresize;
    }   
    return undef;
}

sub write_mod {
 my $mod = shift ;
    $mod = $mod & 4095;
 my $letters;
 my %modes = (
	1   =>  'x',
	2   =>  'w',
	4   =>  'r',
    );
    foreach my $f (64,8,1){
        foreach my $key (4,2,1) {
	    if ($mod & ($key * $f)){
                $letters .= $modes{$key};
	    } else {
		$letters .= '-';
	    }
	}
    }
    return $letters;
}

sub new{bless{},shift;}
1;

__END__
=head1 NAME

Apache::OpenIndex - Perl Open Index manager for a Apache Web server

=head1 SYNOPSIS

  PerlModule Apache::Icon
  PerlModule Apache::OpenIndex
  (PerlModule Apache::Language) optional
  (PerlModule Image::Magick)    optional

=head1 DESCRIPTION

OpenIndex provides a file manager for a web sites through a web
browser. It is a extensive rewrite of the Apache::AutoIndex.pm
module which in turn was a remake of the autoindex Apache
module. OpenIndex can provide the same functionality as
AutoIndex.pm and can be used to both navigate and manage the web
site.

OpenIndex has dropped the mod_dir support provided by AutoIndex.

In order to activate the file manager functionality, two things
have to happen. First, the proper http.conf directives need to
be placed into a <Location area> section. Second, there has to
be a directory stub (.XOI) created off of the directory where
the file manager is to be provided.

Within the ROOT directory stub (.XOI), a MARK sub-directory
(.XOI/.MARK) can also be provided to present a MARK directory
tree by the file manager. The MARK (.XOI/.MARK) directory
provides a physical directory where files can be managed,
unzipped, moved, copied, deleted, and renamed. New directories
can be created with the mkdir command. The MARK directory can
be mapped to any path location on the Apache server or to any
site path location.  To activate the MARK directory access  
the "mark" directive needs to be set to '1'.  The ROOT (.XOI) 
directory is actually a fake path of the site's root directory. 
For example to access "http://www.site.com/bob/" the following 
URL would be required:

	"http://www.site.com/bob/.XOI/"

This would in turn would display the file manager for bob. To
Bob, the ROOT directory appears to be his actual web root
directory.

If the above description does not make sense, just follow the
examples provided, and perhaps it will become clearer once you
see some results.

Since a URL fake path (.XOI) is provided, authentication and
authorization can be used to only allow authorized users to
have access to the OpenIndex module.

In short, you will no longer need to use ftp to upload and
manage the web site files. Since OpenIndex is web based, you can
use all of your other Apache functionality, such as SSL,
proxies, and etc.
  
The best procedure to get OpenIndex loaded and working is to first
have the Apache mod_perl and autoindex modules loaded and
working properly. Then remove the httpd.conf 
"AddModule autoindex" 
directive and add the Apache::Icon and Apache::OpenIndex module 
directives.
  
=head1 DIRECTIVES

=head2 Loading the Modules

The following describes what httpd.conf directives you need in
your httpd.conf file to load OpenIndex and it's companion modules.

First or all you must have mod_perl loaded, with the following:

AddModule mod_perl.c

You will also need to load the following mod_perl modules, with:

  PerlModule Apache::Icon
  PerlModule Apache::OpenIndex

in your httpd.conf file or with:

   use Apache::Icon();
   use Apache::OpenIndex();
 
in your startup.pl file.

=head2 Configuration Guidelines

It is best to put the OpenIndex directives is in a <Location area>
section of your httpd.conf file, because it is the highest
priority Apache httpd.conf section. This way, other directives
will not get in the way of (ahead of) OpenIndex during the Apache
request processing. Apache 1.3.x the directive section priorities
are (in increasing order):

    <Directory>
    <Files>
    <Location>

Here is an example of a <Location area> directive:

    <LocationMatch /.*/\.XOI>
	SetHandler perl-script
	PerlHandler Apache::OpenIndex
    </LocationMatch> 

Notice that a regular expression Location form was used. This
will provide a file manager for each 1-level deep
sub-directory of the site's document root which have a
.XOI stub directory in them.  For example:
    
http:://www.site.com/friends/bob/

If a browser in turn accesses:

    http:://www.site.com/friends/bob/.XOI/

The OpenIndex file manager would be activated for "/friends/bob".

Even though the .XOI directory is a fake reference for the real
directory tree, it must exist in order to activate the file
manager. If a ".XOI/.MARK" directory is also present, and the
"mark" directive is set to '1', access to any location on the
Apache server can be managed.

You will probably want to provide authentication and
authorization for the .XOI fake location. For example, I have
used Apache::AuthenDBI and Apache::AuthzDBI with the following
additions to the same <Location> as above:

 PerlAuthenHandler Apache::AuthenDBI
 PerlAuthzHandler  Apache::AuthzDBI
 AuthName DBI
 AuthType Basic
 PerlSetVar Auth_DBI_data_source  dbi:Pg:dbname=webdb
 PerlSetVar Auth_DBI_username     webuser
 PerlSetVar Auth_DBI_password     webpass
 PerlSetVar Auth_DBI_pwd_table    users
 PerlSetVar Auth_DBI_uid_field    username
 PerlSetVar Auth_DBI_grp_field    GID
 PerlSetVar Auth_DBI_pwd_field    password
 PerlSetVar Auth_DBI_encrypted    on
 require group webgroup friends propellers

If you only want to provide the AutoIndex functionality, just place the
following into either a <Directory area>, or <Location area>
directive and don't bother to create the .XOI directory.

 SetHandler perl-script
 PerlHandler Apache::OpenIndex

Mod_perl does not provide configuration merging for Apache
virtual hosts. Therefore, you have to maintain a complete set of
OpenIndex directives for each virtual host, if any of the virtual
host configurations are different.
 
=head2 File Permissions

When using OpenIndex as a file manager, understanding and
implementing the file permissions is the hardest concept. First,
you need to have a good understanding of your operating system's
(OS) file permissions.

OpenIndex can allow groups of users to share the same web server
file space (tree), such that individuals can be prevented from
changing each others files and directories. An "admin" group can
also be specified, which allows certain users to be able to
modify all the files and directories within the tree, as well
as, assign GID access to the files and directories.
 
File permissions are controlled by a group ID (GID) provided by
an authorization module for the user. It is assigned to the
files and directories that that user creates. 

An Apache environment variable must be set prior to each OpenIndex
request. This environment variable would normally be set by an
authorization module.

For example, the Apache::AuthzDBI module (presented above) can
provide an environment variable "REMOTE_GROUP" which contains
the group ID of the authorized user. The following OpenIndex
directive tells it which environment variable contains the
user's GID for the request:

    OpenIndexOptions GIDEnv=REMOTE_GROUP

For example, if the authorization module sets the environment
variable:

	REMOTE_GROUP=1000

OpenIndex would set the GID for that user to 1000. If the GID is
valid (for Apache and it's OS), all files and directories created by
that user will have their GID set to 1000.

HINT:  If you set the "OpenIndexOptions Debug 1" directive, the
environment variables will be listed along with other debugging
information.  You can then spot your GID environment variable
set by your authorization module in order to verify it's
existence and OpenIndex operation. 

An admin directive can also be specified which enables a user
with the specified admin GID to access and control all files and
directories within the current file manager directory (.XOI)
tree.

In summary, if the following directives are provided:

  OpenIndexOptions GIDEnv=REMOTE_GROUP
  OpenIndexOptions Admin=1000
 
The GIDEnv directive tells OpenIndex which environment variable
contains the GID (REMOTE_GROUP in this example). [This variable
would have been set by an authorization module.] If the GID for
the user happens to be 1000, then that user will have "admin"
privileges and it's commands (SetGID).

The operating system (OS) rules still apply to all of the GID
operations. For example (OS=UNIX), if Apache's program ID (PID)
is 100 and a file is owned by user 200, Apache can not change
the GID of file unless the Apache process is also a member of
the GID 200 group.

If a "group name" (instead of a number) is provided, the GID
name is looked-up in the /etc/group file in order to obtain the
numeric GID. This is very UNIX like and my not work for other
operating systems.

HINT: Any environment variable can be used to contain the
GID. Therefore, you can trick the authorization module into
coughing up a GID by using the REMOTE_USER (user) environment
variable and then simply create a group with the same name. 
Don't forget to make the Apache's process user ID (PUID) a
member of the group (in /etc/group). 

=head2 AutoIndex Functionality

When a .XOI directory is not present in the URL, OpenIndex will
function like AutoIndex. Note that the .XOI directory name can
be changed with a directive. This is explain later on in the
text.

=head1 DIRECTIVES

The display options (directives) are a composite of autoindex,
AutoIndex, and OpenIndex's own module directives.

The original module directives are maintained by OpenIndex, so
that any existing directives that you may have, can be used to
maintain the status quo.

=head2 autoindex DIRECTIVES

Apache normally comes with mod_autoindex C module. A number of
it's httpd.conf directives are provided when Apache is
installed.

Documentation for autoindex can be found at:

    http://www.apache.org/docs/mod/mod_autoindex.html

An incomplete (no Alt directives) and a very brief description
of the autoindex (used by Apache::Icon) directives is
provided below.

These directives are processed by Apache::Icon.pm which
provides icons to Apache::AutoIndex and Apache::OpenIndex.

=over

=item * FancyIndexing boolean

    The FancyIndexing directive tells OpenIndex to present a
    robust display which can include permissions, an icon, name,
    date, size, and description for each file and directory. All
    of the following autoindex and AutoIndex directives require
    FancyIndexing.
    
=item * HeaderName file file ...

    Inserts a list of files displayed at the top of the document
    After Apache 1.3.5 the filename can be a relative URI.  If 
    the file name extention is '.html' it will be sent as is.

=item * IndexIgnore file file

    A list of files not to be displayed. The files can specify
    extensions, partial names, wild card expressions, or full
    filenames.  Multiple IndexIgnore directives add to the list.

=item * IndexOptions [+|-]option [+|-]option ... 
    
    There are several options. Please refer to the above URL:
	http://www.apache.org/docs/mod/mod_autoindex.html 
    for the complete list.

=item * IndexOrderDefault Ascending|Descending|Extension Name|Date|Size|Description

    IndexOrderDefault takes two arguments. The first must be
    either Ascending, Descending, or Extension indicating the
    direction of the sort. Only Name can have the Extension
    specified, which will sort on the file extension.  The 
    second argument must be one of the keywords: Name, Date,
    Size, or Description. It identifies the primary sort key.

=item * ReadmeName file file ...

    A list of text files that will be displayed to the end of the
    document.  If the file mime type is text/html it will be sent
    as is.
    
=item * AddDescription "string" file file...

    The file description displayed for the given file (file name
    wild cards).

=item * AddIconByEncoding (alttext, url) MIME-encoding MIME-encoding ...
    
    The file icon (alttext, url) to be displayed according to
    the MIME-encoding (mime-encoding).
    
=item * AddIconByType (alttext, url) MIME-type MIME-type ...

    The file icon (alttext, url) to be displayed according to
    the MIME-type (mime-type).

=item * AddIcon (alttext, url) name name ...

    The file icon (alttext, url) to be displayed according to
    file name extension.

=item * DefaultIcon icon

    The file icon to be displayed if no other icon can be found.
    (default icon)

=back

=head2 AutoIndex DIRECTIVES

=over

=item * IndexOptions Thumbnails

    The listing will include thumbnails for pictures. Defaults to
    false.

=item * IndexOptions ShowPermissions
    
    Print file permissions. Defaults to false.

=item * IndexOptions SuppressHtmlPreamble

    When a header or footer file is included with the 
       HeaderName file file ...
       ReadmeName file file ...
    directives, the <HTML> <HEAD> and <BODY> tags are striped.
    
=item * IndexOptions FoldersFirst

    The folders will be presented first in the index listings.
    
=item * IndexOptions HideExt

    The HideExt directive tells OpenIndex to not display the
    file extention within the index display.
    
=item * IndexHtmlTag tag attributes

    This directive specifies the tag's attributes that will be
    inserted into the tag.  For example: <TAG attributes>

    If the first character of attributes is a '+', it will 
    append the following attributes to the current tag's
    attributes.  If the first character of attributes is a '-'
    or not a '+', the current tag's attributes will be set to
    the following attributes string.  Note that an initial '+'
    or '-' character is always striped.

    HINT: If you need to have the first line start with a '+' or a
    '-' character, use "-+ . . ." or "-- . . .".

=item * IndexHtmlText tag [+|-]text

    This directive specifies the tag text that will be inserted 
    within the tag.  For example: <TAG> text </TAG>

    If the first character of text is a '+', it will append 
    the following text to the current tag's text.  If the first
    character of text is a '-' or not a '+', the current tag's
    text will be set to the following text.  Note that an initial
    '+' or '-' character is always striped.

    HINT: If you need to have the first line start with a '+' or a
    '-' character, use "-+ . . ." or "-- . . .".

    The frameset tag is special in that you will need to place
    <mainframe> in the position where the index (main) frame is to
    be placed  In this way any arbitrary frameset can be supported.

    HTML text can also be inserted just before each of the form text
    and submit buttons by appending 'insert' before it's name.  For
    example to insert "Hello World" just before 'Browse' text field
    specify:

        IndexHtmlText InsertBrowse Hello World

    HINT: If the language option is enabled, the text will be looked
    up in order to support multiple languages.

=item * IndexURIHead value

    Value should be the uri (absolute or relative) of a resource
    that would be inserted right after the <BODY> tag and just
    before anything else.

=item * IndexHtmlFoot value

    Value should be the uri (absolute or relative) of a resource
    that would be inserted right before the ending </BODY> tag
    and after everything else.

=item * IndexFrameTail value

    Value is a string that will be inserted after the main frame.
    The Frame option has to activated in order for this to work.
    The main frame contains the index table and is always inserted 
    into the frameset.  A NOFRAME tag is also always included.

=item * IndexHtmlStyle value

    Value is a string that will be inserted inside the <Style>
    tag.
    
    
=back

=head2 OpenIndex DIRECTIVES

=over

=item * OpenIndexOptions Admin n

    Sets the admin GID to n. If the user's GID equals the admin
    GID, the "SetGID" command will be provided and file access
    control will be provided for all files and directories in
    both the MARK and ROOT directory trees.
    
=item * OpenIndexOptions Debug [0|1]

    If set to 1, the listing displayed will print debugging
    information if the user is set to Admin. The default is 0.

=item * OpenIndexOptions Frames [0|1]

    If set to 1, the output will use HTLM horizontal frames.
    The default is 0.

=item * OpenIndexOptions Menu command1 command2 . . .

    Allows you to add and remove commands from the menu.
    The default menu is: "Browse", "Upload", "Unzip", "Delete",
    "MkDir", "MkFile","Copy", "Move","Edit","Rename","Help". 
    If the first command is preceded by '+' the following 
    commands will be added to the existing list of the menu.
    If it is preceded by '-' they well be removed from the list. 
    The  sign can only be used as the first argument, while the 
    remaining arguments are a list of the items to either add 
    or remove.   If no sign is provided the menu list is replaced 
    by the list provided.

=item * OpenIndexOptions AdmnMenu command1 command2 . . .

    AdmnMenu allows you to modify the admin command menu. When
    a user is an admin, as defined by the:
    "OpenIndexOptions Admin" directive, the AdmnMenu is provided.
    The default menu is: "SetGID", "Revoke", and "Debug".  Note 
    that the "Debug" command only is displayed if the: 
    "OpenIndexOptions Debug 1" directive is also provided.
    If the first command is preceded by '+' the following 
    commands will be added to the existing list of the menu.
    If it is preceded by '-' they well be removed from the list. 
    The  sign can only be used as the first argument, while the 
    remaining arguments are a list of the items to either add 
    or remove.   If no sign is provided the menu list is replaced 
    by the list provided.

=item * OpenIndexOptions Root Directory
    
    When operating in the AutoIndex mode, this option allows 
    you to specify the root directory where OpenIndex will not
    display the "Parent directory" item (the root).  The 
    string is compared with Perl regular expressions.

=item * OpenIndexOptions FakeDir Directory
    
    Sets the FakeDir directory stub name from which the files
    can be managed. The default is ".XOI". You should probably
    consider changing this value to something else if you do not
    want people probing your web site. You may want to prefix
    the name with a '.' in order to hide it from view.
    
=item * OpenIndexOptions MarkDir SubDirectory
    
    Set the mark subdirectory stub name of the where OpenIndex
    stores the Mark directory files. The default is ".MARK".
    Note that this is the fake name used to reference the MARK
    directory.  The MARK directory can be designated to be 
    anywhere on the web server.
    
=item * OpenIndexOptions MarkRoot syspath
    
    Set the rooted MARK path location to "syspath".  The path is
    from the Apache server's root path, that is it must contain
    the initial '/'.  It can allow the client to get to any file
    on the web server.  The browser client will not be able to 
    go below this directory.
    
=item * OpenIndexOptions UserDir pattern

    If you use the userdir_module and you want OpenIndex to
    manage the files accessed there, then you will need to
    duplicate it's UserDir translation directive using this 
    directive.  For example:

    OpenIndexOptions UserDir /home/*/htdocs

    will translate /~bob to /home/bob/htdocs

=item * OpenIndexOptions UserSite rootpath

    This directive restricts a user to a particular site
    path.  This is useful because it allow one group id
    to be used for a group of users by restricting which
    path particular each use can access.  For example, if
    you have two user sites which use the following URLs:

        http://www.thesite.com/friends/ed
        http://www.thesite.com/friends/steve

    You could create a group, named 'friends' for both
    users and restrict each user to their own site, by 
    specifying:

        OpenIndexOptions UserSite /friends

    Then when 'ed' tries to access any URL outside
    of '/friends/ed', OpenIndex will deny the request.

=item * OpenIndexOptions TextLen n
    
    Sets the text entry field of the command form to length n.
    The default value is 49.  The "SetGID" text length is
    almost one-half this value (default 25).
     
=item * OpenIndexOptions EditMax n
    
    Sets the maximum edit file byte size to n.  This is the
    maximum file size that can be edited.  The default value
    is 131072 bytes.
    
=item * OpenIndexOptions PostMax n
    
    Sets the http maximum post byte size to n.  This is also
    the maximum file size that can be uploaded.  The default
    value is 4,194,304 bytes.
    
=item * OpenIndexOptions umask n
    
    Allows you to set the umask for the files and directories
    created.  Generally n is an octal number starting with a '0'.

=item * OpenIndexOptions Help URL
    
    Sets the URL of the user help command.  The default URL is:
    http://www.xorgate.com/help/OpenIndex
    
=item * OpenIndexOptions language [0|no|off]
    
    Tells OpenIndex not to use the Apache::Language module to
    translate messages. ('0', 'no', or 'off')  Defaults 'off'.
    When enabled the Apache::Language module must be loaded.
    Make sure if you set language on that you load the 
    negotiation module and either use the Multiviews option
    or the *.var method. 
    
=item * OpenIndexOptions GIDEnv name    
        
    If an authorization module provides an environment variable
    (name) with the user's GID, the GIDEnv directive tells
    OpenIndex which variable contains the GID for the current
    request. The GID is then retrieved from the environment
    variable and is applied to the user's commands. For each
    command the source GID is checked to make sure that the GID
    matches each file and directory created. If a name (not a
    number) is provided, it is looked up in the /etc/group file
    to obtain the GID number.
    
=item * OpenIndexOptions UserEnv name    
        
    An environment variable can be specified which holds the
    user name of the request.  If 'Basic' authorization is being
    used, the user name will be recovered from Apache, regardless
    of what ever is specified for 'UserEnv name'.

=item * OpenIndexOptions Revoke [1|0]
    
    A boolean value which tells OpenIndex to check the file
    "revoked" in the root fake directory (FakeDir) for users and
    groups that will not be allowed to execute commands. This
    file is maintained by OpenIndex for the admin user through
    "Enable" and "Disable" commands provide in the Revoke form.
    Note that Apache will need to have read and write access in
    this file ("revoked") and root fake directory (.XOI).

=item * OpenIndexOptions Mark [1|0]
    
    A boolean value which tells OpenIndex to use and process the
    MARK (mark) directory (tree), if it exists. ('1', 'yes', or
    'on') Default 0. If the MARK directory does not exist, it
    will not use it :-).

=item * OpenIndexOptions NoTitle [1|0]

    If set to 1, the header title will not be displayed.
    The default is 0.

=item * OpenIndexOptions NoCache [1|0]
    
    A boolean value which tells OpenIndex to have the expire time
    of the http header to zero so that browsers will not cache 
    OpenIndex's output. Default 0.

=item * OpenIndexOptions Import package subroutine limit_arguments

    "This is are real cool directive!"  It allows you to add
    new commands and routines to OpenIndex.   Look in the 
    OpenIndex/OpenIndex directory and you will find an external
    command "MD5.pm".  This command calculates and displays
    the MD5 hash of the files selected, stores them in the
    file entered into the "Destination" form text field, and
    displays the results.  This directive can provide the
    full subroutine name including the '::'s.  For example,
    for the MD5 command the following directive is used:
      OpenIndexOptions \
	import MD5 MD5 before=>MD5before after=>MD5after \
        back=>MD5back min=>1 max=>0

    NOTE: that the escape character '\' is used to indicate
    that the the line continues.  Do not use the '/' character
    in your conf file.
 
    The interesting arguments are as follows:
    The first argument is the package name that contains the
    subroutines.  If it is not fully specified with '::' it
    is preappended with "Apache::OpenIndex::".

    The second argument is the menu command name of the 
    routine.  The command is added to the menu  by using 
    either the 'Menu' or the 'AdmnMenu' directive.

    before=>subroutine
        Is the name of the subroutine to run just before the
        menu command subroutine (Apache::OpenIndex::MD5before in 
        the example).  This command allows any initialization
        work to be done before the main command.  The main
        command (Apache::OpenIndex::MD5 in the example) is called
        once for each file/directory item selected from the
        directory index listing within the browser window.
    after=>subroutine
        This is the subroutine executed just after the last
        item is processed.  This routine will normally do
        cleanup of anything required from the before routine.
    back=>subroutine
        This subroutine is executed after a SUBMIT from the
        menu command.  It is a call back routine that depends
        on the 'proc' HIDDEN field from your HTML form.  The
        'proc' should contain the cmd name.
    min=>number
        Is the minimum number of items that must be selected 
        by the OpenIndex user.
    max=>number
        Is the maximum number of items that must be selected 
        by the OpenIndex user.  A value of 0, means there is no
        maximum number.
    src=>arg
        This tells OpenIndex which argument contains the source 
        string for the command.  Normally this is the list of
        items from the directory index listing.  However, you
        can use any input you like by perhaps setting an @args
        string in the before=>routine.
    dst=>arg
        This tells OpenIndex which argument contains the destination
        string for the command.  Normally this is the text in
        "Destination" text form field.  However, you can use 
        any input you like by perhaps setting an @args string 
        in the before=>routine.
    req=>arg
        This tells OpenIndex to check and make sure that a value
        is contained in the argument.  The default is to have
        an item selected from the directory index listing.
    admin=>1
        Requires that user is the admin user in order to execute
        the commands submitted. 

=item * OpenIndexOptions Always package subroutine arguments

    "This is another real cool directive!"  It allows you to 
    specify an external command to run before each OpenIndex
    managed page is processed.  This is where you would hook
    in a quota check routine and so forth.  The arguments
    are only for use by the command specified.

=back

=head1 THUMBNAILS

Generation of thumbnails is possible. This means that listing a
directory that contains images can be listed with little reduced
thumbnails beside each image name instead of the standard
'image' icon.

To enable this you simply need to preload Image::Macick in
Apache. The IndexOption option Thumbnails controls thumbnails
generation for specific directories like any other IndexOption
directive.

=head2 USAGE

The way thumbnails are generated/produced can be configured in
many ways.  A general overview of the procedure follows.

For each directory containing pictures, there will be a
.thumbnails directory created in it that will hold the thumbnails.
Each time the directory is accessed, and if thumbnail generation
is active, small thumbnails will be produced, shown beside each
image name, instead of the normal , generic, image icon.

That can be done in 2 ways. In the case the image is pretty
small, no actual thumbnail will be created. Instead the image
will resize the HEIGHT and WIDTH attributes of the IMG tag.

If the image is big enough, Image::Magick will resize it and
save (cache) it in the .thumbnails directory for the next
requests.

Changing configuration options will correctly refresh the cached
thumbnails. Also, if the original image is modified, the
thumbnail will be updated accordingly. Still, the browser might
screw things up if it preserves the cached images.  

=head2 Thumbnail DIRECTIVES

=over

=item * IndexCacheDir dir

This is the name of the directory where the generated thumbnails
will be created.  Make sure the user under which the web server
runs has read and write permissions. Defaults to .thumbnails

=item * IndexCreateDir 0|1

Specifies that when a cache directory isn't found, should an
attempt to be made to create it. Defaults to 1(true), meaning if
possible, a missing cache directories will be created. 

=item * ThumbMaxFilesize bytes

This value fixes the maximum size of an image at which thumbnail
processing isn't even attempted.  Trying to process a few
very big images could bring a server down to it's knees.
Defaults to 500,000

=item * ThumbMinFilesize bytes

This value fixes the minimum size of an image at which thumbnail
processing isn't actually done. Since trying to process already
very small images could be an overkill, the image is simply
resized with the size attributes of the IMG tag. Defaults to
5,000.

=item * ThumbMaxWidth pixels

This value fixes the maximum x-size of an image at which
thumbnail processing isn't actually done. Since trying to
process already very small images would be an overkill, the
image is simply resized with the size attributes of the IMG tag.
Defaults to 4 times the default icon width.

=item * ThumbMaxHeight pixels

This value fixes the maximum y-size of an image at which
thumbnail processing isn't actually done. Since trying to
process already very small images would be an overkill, the
image is simply resized with the size attributes of the IMG tag.
Defaults to 4 times the default icon height

=item * ThumbScaleWidth scaling-factor

Preserved only if there is no scaling factor for the other axis
of the image. 

=item * ThumbScaleHeight scaling-factor

This value fixes an y-scaling factor between 0 and 1 to resize
the images. The image ratio will be preserved only if there is
no scaling factor for the other axis of the image. 

=item * ThumbWidth pixels

This value fixes a fixed x-dimension to resize the image. The
image ratio will be preserved only if there is no fixed scaling
factor for the other axis of the image. This has no effect if a
scaling factor is defined.

=item * ThumbHeight pixels

This value fixes a fixed x-dimension to resize the image. The
image ratio will be preserved only if there is no fixed scaling
factor for the other axis of the image. This has no effect if a
scaling factor is defined.

=back

=head1 TODO

The thumbnail support needs to be tested. It was provide with
Apache:: AutoIndex, but I have not tested it yet.
    
Some minor changes to the thumbnails options will still have the
thumbnails regenerated. This should be avoided by checking the
attributes of the already existing thumbnail.

Some form of garbage collection should be performed on thumbnail
cache or the directories will fill up.

=head1 SEE ALSO

perl(1), L<Apache>(3), L<Apache::Icon>(3), L<Image::Magick>(3) .
L<Apache::AutoIndex>(3)
    
=head1 SUPPORT

Please send any questions or comments to the Apache modperl 
mailing list <modperl@apache.org> or to me at <perler@xorgate.com>

=head1 NOTES

This code was made possible by :

=over

=item Philippe M. Chiasson

<gozer@ectoplasm.dyndns.com> Creator of Apache::AutoIndex.

=item Doug MacEachern 

<dougm@pobox.com>  Creator of Apache::Icon, and of course, mod_perl.

=item Rob McCool

Who produced the final mod_autoindex.c I copied, hrm.., well,
translated to perl.

=item The mod_perl mailing-list 

at <modperl@apache.org> for all your mod_perl related problems.

=back

=head1 AUTHOR

George Sanderson <george@xorgate.com>

=head1 COPYRIGHT

Copyright (c) 2000-2001 George Sanderson All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. 

Copyright (c) 1999 Philippe M. Chiasson. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. 

=cut
