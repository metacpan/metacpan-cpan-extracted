use utf8;

use warnings;

no warnings 'redefine';

use vars qw($r);

use File::stat;

use Fcntl qw(:flock);

use Symbol;

use Search::Tools::UTF8;

use POSIX qw(sysconf _PC_CHOWN_RESTRICTED);

use POSIX 'floor';

sub EditFile {

    my $name = defined param('name') ? param('name') : $m_sAction;

    my @n = $m_oDatabase->fetch_array("select file from `actions` where action=?", $name);

    FileOpen("$m_hrSettings->{cgi}{bin}/Content/$n[0]");

}



sub round {

    my $x = shift;

    floor($x + 0.5);

}



sub showDir {

    my $sSubfolder = param('subfolder') ? param('subfolder') : shift;

    $sSubfolder = defined $sSubfolder ? $sSubfolder : $m_hrSettings->{cgi}{DocumentRoot};

    $sSubfolder =~ s?/$??g;

    my $links = $sSubfolder =~ m?^(.*/)[^/]+$? ? $1 : $sSubfolder;

    my $fname =

      $sSubfolder =~ m?^.*/([^/]+)$? ? qq(<b>$1</b>) : $sSubfolder;

    $links =~ s?//?/?g;

    my $elinks     = uri_escape($links);

    my $esubfolder = uri_escape($sSubfolder);

    $r = 0;

    my $orderby  = defined param('orderBy')  ? param('orderBy')  : 'NULL';

    my $byColumn = defined param('byColumn') ? param('byColumn') : 'a';

    my $state = defined param('desc') ? param('desc') == 1 ? 1 : 0 : 0;

    my $newstate = $state ? 0 : 1;

    my @t = readFiles($sSubfolder, 0);

    my $fileview = new HTML::Menu::TreeView();



    SWITCH: {

        if (defined param('sort')) {

            $fileview->sortTree(1);

            $fileview->desc($state ? 1 : 0);

            last SWITCH;

        }

        if ($byColumn eq 0 or $byColumn eq 1 or $byColumn eq 2){

            $fileview->orderByColumn($byColumn);

            $fileview->desc($state ? 1 : 0);

            last SWITCH;

        }

        if ($orderby eq 'mTime') {

            @t = sort { lc($a->{mtime}) cmp lc($b->{mtime}) } @t;

            @t = reverse @t if $state;

            last SWITCH;

        }

        if ($orderby eq 'Size') {

            @t = sort { $a->{size} <=> $b->{size} } @t;

            @t = reverse @t if $state eq 1;

            last SWITCH;

        }

        $fileview->folderFirst(1);

    }

    $fileview->TrOver(1);



    $fileview->columns(

        a(

           {

            href =>

              "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=FileOpen&file=$esubfolder&sort=1&desc=$newstate','FileOpen','FileOpen');",

            class => "treeviewLink$m_hrSettings->{size}",

            align => 'left',

           },

           'Name'

         )

          . (

            param('sort')

            ? (

               $state

               ? qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/up.png" border="0" alt="" title="up" width="16" height="16" />|

               : qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/down.png" border="0" alt="" title="down"/>|

              )

            : ''

          )

          . ' ',

        a(

           {

            href =>

              "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=FileOpen&file=$esubfolder&orderBy=Size&desc=$newstate','FileOpen','FileOpen')",

            class => "treeviewLink$m_hrSettings->{size}",

            align => "left"

           },

           'Size'

         )

          . (

            $orderby eq 'Size'

            ? (

               $state

               ? qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/up.png" border="0" alt="" title="up" width="16" height="16" />|

               : qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/down.png" border="0" alt="" title="down"/>|

              )

            : ''

          )

          . ' ',

        a(

           {

            href =>

              "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=FileOpen&file=$esubfolder&byColumn=1&desc=$newstate','FileOpen','FileOpen')",

            class => "treeviewLink$m_hrSettings->{size}",

            align => "left"

           },

           'Permission'

         )

          . (

            $byColumn == 0 && !param('sort')

            ? (

               $state

               ? qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/up.png" border="0" alt="" title="up" width="16" height="16" />|

               : qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/down.png" border="0" alt="" title="down" />|

              )

            : ''

          )

          . ' ',

        a(

           {

            href =>

              "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=FileOpen&file=$esubfolder&byColumn=2&desc=$newstate','FileOpen','FileOpen')",

            class => "treeviewLink$m_hrSettings->{size}",

            align => "left"

           },

           'UID'

         )

          . (

            $byColumn == 2

            ? (

               $state

               ? qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/up.png" border="0" alt="" title="up" width="16" height="16" />|

               : qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/down.png" border="0" alt="" title="down"/>|

              )

            : ''

          )

          . ' ',

        a(

           {

            href =>

              "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=FileOpen&file=$esubfolder&byColumn=3&desc=$newstate','FileOpen','FileOpen')",

            class => "treeviewLink$m_hrSettings->{size}",

            align => "left"

           },

           'GID'

         )

          . (

            $byColumn eq 3

            ? (

               $state

               ? qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/up.png" border="0" alt="" title="up" width="16" height="16"/>|

               : qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/down.png" border="0" alt="" title="down" />|

              )

            : ''

          )

          . ' ',

        a(

           {

            href =>

              "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=FileOpen&file=$esubfolder&orderBy=mTime&desc=$newstate','FileOpen','FileOpen')",

            class => "treeviewLink$m_hrSettings->{size}",

            align => "left"

           },

           'Last Modified'

         )

          . (

            $orderby eq 'mTime'

            ? (

               $state

               ? qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/up.png" border="0" alt="" title="up" width="16" height="16"/>|

               : qq| <img src="/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/down.png" border="0" alt="" title="down"/>|

              )

            : ''

          )

          . ' ',

        '',

      )

      if $#t >= 0;

    my $hf =

      "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=FileOpen&file=$elinks','FileOpen','FileOpen')";



    my $toolbar = div(

        {align => 'left'},

        a(

           {

            onclick =>

              "prompt('Enter File Name',function(a){if(a != null )requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=newFile&file='+encodeURIComponent(a)+'&dir=$esubfolder','newFile','newFile')});",

            class => 'toolbarButton'

           },

           'New File'

         )

          . ' '

          . a(

            {

             onclick =>

               "prompt('Neues Verzeichnis',function(a){if(a != null )requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=makeDir&file=$esubfolder&d='+encodeURIComponent(a),'makeDir','makeDir')});",

             class => 'toolbarButton'

            },

            'New Directory'

          )

          . ' '

          . ( $^O ne 'MSWin32' ? a(

            {

             onclick =>

               "prompt('Enter Chmod: 0755',function(a){if(a != null ) requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=chmodFile&file=$esubfolder&chmod='+encodeURIComponent(a),'chmodFile','chmodFile')});",

             class => 'toolbarButton'

            },

            'Chmod',

          ) : '')

          . ' '

          . ($^O ne 'MSWin32' ? a(

            {

             onclick =>

               "var a;prompt('Enter User:',function(argv){a= argv;prompt('Enter Group:',function(b){if(a != null  && b != null)requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=chownFile&file=$esubfolder&user='+encodeURIComponent(a)+'&gid='+encodeURIComponent(b),'chownFile','chownFile')});});",

             class => 'toolbarButton'

            },

            'Chown',

          ): '')

    );

    print

      qq(<table class="ShowTables marginTop"><tr class="captionRadius"><td class="captionRadius" colspan="7"><a href="$hf" class="treeviewLink$m_hrSettings->{size}">$links $fname</a></td></tr><tr><td colspan="7" class="toolbar"><div id="toolbarcontent" class="toolbarcontent">$toolbar</div></td></tr><tr><td colspan="7" style="padding:0px;padding-bottom:1em;vertical-align:top;">)

      . ($#t >= 0 ? $fileview->Tree(\@t, $m_sStyle) : '')

      . q(</td></tr></table>);



}



sub readFiles {

    my @TREEVIEW;

    my $dir  = shift;

    my $edir = uri_escape($dir);

    my $rk   = shift;

    $r++ if ($rk);

    if (-d "$dir" && -r "$dir") {

        opendir DIR, $dir or warn "files.pl sub readFiles: $dir $!";

        foreach my $d (readdir(DIR)) {

            my $fl = "$dir/$d";

            my $sb = stat($fl);

          TYPE: {

                last TYPE if ($d =~ /^\.+$/);

                my $efl = uri_escape($fl);

                my $href =

                  "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=FileOpen&file=$efl','FileOpen','FileOpen')";

                my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =

                  localtime($sb->mtime);

                $year += 1900;

                $mon  = sprintf("%02d", $mon);

                $mday = sprintf("%02d", $mday);

                $min  = sprintf("%02d", $min);

                $hour = sprintf("%02d", $hour);

                $sec  = sprintf("%02d", $sec);

                my $trdelete = translate('delete');

                my $trnew    = translate('new');

                my $trrename = translate('rename');



                if (-d $fl) {

                    push @TREEVIEW, {

                        text    => $d,

                        href    => "$href",

                        empty   => 1,

                        subtree => [{}, {}],

                        mtime   => $sb->mtime,

                        size    => $sb->size,

                        columns => [

                            sprintf("%s",   $sb->size),

                            ($^O ne 'MSWin32' ?  sprintf("%04o", $sb->mode & 07777) :''),

                            ($^O ne 'MSWin32' ? getpwuid($sb->uid)->name:''),

                            ($^O ne 'MSWin32' ?  $sb->gid : ''),

                            "$year-$mon-$mday $hour:$min:$sec",

                            qq|<table cellpading="0" cellspacing="0">
                            <tr><td class="batch">&#xe906;<a class="treeviewLink16" href="javascript:prompt('Enter Filename:',function(a){if(a != null )requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=renameFile&file=$efl&newName='+encodeURIComponent(a),'renameFile','renameFile')});" title="$trrename">$trrename</a></td>|
                            .($^O ne 'MSWin32' ? qq|<td class="batch">&#xe971;<a class="treeviewLink16" href="javascript:prompt('Enter User:',function(c){ a = c; prompt('Enter Group:',function(b){ if(a != null  && b != null)requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=chownFile&file=$efl&user='+encodeURIComponent(a)+'&gid='+encodeURIComponent(b),'chownFile','chownFile')});});" title="Chown">Chown</a></td>| :'')
                            .($^O ne 'MSWin32' ? qq|<td class="batch">&#xe972;<a class="treeviewLink16" href="javascript:prompt('Enter Chmod: 0755',function(a){if(a != null )requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=chmodFile&file=$efl&chmod='+encodeURIComponent(a),'chmodFile','chmodFile')});" title="Chmod">Chmod</a></td>| :'')
                            .qq|<td class="batch">&#xe9ac;<a class="treeviewLink16" href="javascript:confirm2('$trdelete ?',function(a){requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=deleteFile&file=$efl','deleteFile','deleteFile')});" title="$trdelete">$trdelete</a></td>

                            </td></tr></table>|

                                   ],

                    };

                    last TYPE;

                }



                if (-f $fl) {

                    my $suffix = $d =~ /\.([^\.]+)$/ ? $1 : '';

                    push @TREEVIEW, {

                        text    => "$d",

                        href    => "$href",

                        mtime   => $sb->mtime,

                        size    => $sb->size,

                        columns => [

                            sprintf("%s",   $sb->size),

                            sprintf("%04o", $sb->mode & 07777),

                            ($^O ne 'MSWin32' ? getpwuid($sb->uid)->name:''),

                            $sb->gid,

                            "$year-$mon-$mday $hour:$min:$sec",

                            qq|

				  <table cellpading="0" cellspacing="0"><tr>

				  <td class="batch" style="font-size:14px;">&#xe906;<a class="treeviewLink16" href="javascript:prompt('Enter Filename:',function(a){if(a != null )requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=renameFile&file=$efl&newName='+encodeURIComponent(a),'renameFile','renameFile');});" title="$trrename">$trrename</a></td>

				  |.( $^O ne 'MSWin32' ? qq|<td class="batch" style="font-size:14px;">&#xe971;<a class="treeviewLink16" href="javascript:prompt('Enter User:',function(c){a=c;prompt('Enter Group:',function(b){if(a != null  && b != null)requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=chownFile&file=$efl&user='+encodeURIComponent(a)+'&gid='+encodeURIComponent(b),'chownFile','chownFile');});});" title="Chown">Chown</a></td>| :'').

				  ( $^O ne 'MSWin32' ?

				  qq|<td class="batch" style="font-size:14px;">&#xe972;<a class="treeviewLink16" href="javascript:prompt('Enter Chmod: 0755',function(a){;if(a != null )requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=chmodFile&file=$efl&chmod='+encodeURIComponent(a),'chmodFile','chmodFile');});" title="Chmod">Chmod</a></td>| :'').

				  qq|<td class="batch" style="font-size:14px;">&#xe9ac;<a class="treeviewLink16" href="javascript:confirm2('$trdelete ?',function(a){requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=deleteFile&file=$efl','deleteFile','deleteFile');});" title="$trdelete">$trdelete</a></td>

				  </tr></table>|,

                        ],

                        image => (

                            -e "$m_hrSettings->{cgi}{DocumentRoot}/style/$m_sStyle/$m_hrSettings->{size}/mimetypes/$suffix.png"

                          )

                        ? "$suffix.png"

                        : 'link_overlay.png',

                    };

                }

            }

        }

        $r = 0;

        return @TREEVIEW;

    }

}



sub FileOpen {

    my $f = defined param('file') ? param('file') : shift;

    return unless defined $f;

	SWITCH: {

        if (-d $f) {

            &showDir($f);

            last SWITCH;

        }

        if (-T $f) {

            my $content = openFile($f);
            &showEditor($f, $content, 'saveFile', $f);

            last SWITCH;

        } else {

            print br(). qq(<div align="center">).translate('no_ascii_file') . "</div>";

        }

        if ($f =~ /png|jpg|jpeg|gif$/ && $f =~ m~/var/www/htdocs/(.*)$~) {

            print br()

              . qq(<div align="center"><img alt="" src="/$1" align="center"/>)

              . br()

              . "</div>";

            last SWITCH;

        }

        print br()

          . translate("UnsopportedFileType")

          . br();

    }

}



sub saveFile {

    my $txt = param('txt');
    my $sFile = param('file');
    $txt =~ s/\r\n/\n/g;
    my $fh = gensym();

    unless (-d $sFile) {

        open $fh, ">:encoding(UTF-8)", "$sFile.bak" or warn "files.pl::saveFile $/ $! $/ $sFile $/";

        flock $fh, 2;

        seek $fh, 0, 0;

        truncate $fh, 0;

        print $fh $txt;

        close $fh;

        rename "$sFile.bak", $sFile or warn "files.pl::saveFile $/ $! $/" if (-e "$sFile.bak");

        chmod(0755, $sFile) if ($sFile =~ m?\.pl? && $^O ne 'MSWin32');

        FileOpen($sFile);

    } elsif (defined param('title') && defined param('file')) {

        my $sf = param('file') . '/' . param('title');

        open $fh, ">$sf.bak" or warn "files.pl::saveFile $/ $! $/ $sf $/";

        flock $fh, 2;

        seek $fh, 0, 0;

        truncate $fh, 0;

        print $fh $txt;

        close $fh;

        rename "$sf.bak", $sf or warn "files.pl::saveFile $/ $! $/" if (-e "$sf.bak");

        FileOpen($sf);

    }

}



sub showEditor {

    my $h = shift;

    my $t = shift;



	unless (is_valid_utf8($t)) {

		utf8::decode($t);

	}



    my $a       = shift;

    my $fi      = shift;

    my $efl     = $h;

    $efl =~s?^(.+)/([^/]+)$?$1?;

    my $linkText = $h;

    $linkText =~s?^(.+)/([^/]+)$?$1/<b>$2</b>?;

	  $m_sJson->{m_sFile} = $t;



    my $link = qq|<a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=FileOpen&file=$efl','FileOpen','FileOpen')">$linkText</a>|;

    print qq|<div class="ShowTables marginTop">

    <form accept-charset="utf-8" action ="$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}" onsubmit="document.getElementById('txt').value = GetEditorLines();submitForm(this,'$a','$a');return false;" method="post">

    <table cellspacing="5" cellpadding="0" border="0" align="center" summary="files.pl" width="95%">
      <tbody>
      <tr>
	  <td>$link</td>
	</tr>
	<tr>

	<td>

	<pre id="editor"></pre>

	<textarea name="txt" id="txt" style="display:none;"></textarea>

	</td>

	</tr>

	<tr>

	  <td align="right"><input type="submit" name="save" value="Save"/>

	  <input type="hidden" value="$a" name="action"/>

	  <input type="hidden" value="$fi" name="file"/>

	  </td>

	</tr>

      </tbody>

    </table>

    </form></div><script>html =1;</script>|;

}



sub newFile {

    my $d = defined param('dir') ? param('dir') : '';

    my $sFile = param('file');

    unless (-e $sFile) {

        open(IN, ">$d/$sFile") or die $!;

        close IN;

        print translate('newfileadded') if -e $sFile;

    } else {

        print translate('fileExists ') if -e $sFile;

    }

    &showDir($d);

}



sub makeDir {

    my $d     = param('d');

    my $sFile = param('file');

    unless (-d "$sFile/$d") {

        mkdir "$sFile/$d";

        print translate('newfileadded') if -d $sFile;

    } else {

        print translate('fileExists');

    }

    &showDir($sFile);

}



sub renameFile {

    my $file    = param('file');

    my $newName = param('newName');

    my $dir     = $file =~ /(.*\/)[^\/]+$/ ? $1 : '/';

    rename $file, "$dir$newName";

    &showDir($dir);

}



sub chownFile {

    my $user  = param('user');

    my $uid   = getpwnam($user);

    my $gid   = param('gid');

    my $g     = getgrnam($gid);

    my $sFile = param('file');



    $can_chown_giveaway = not sysconf(_PC_CHOWN_RESTRICTED);

    print 'Not allowed' unless $can_chown_giveaway;

    my $cnt = chown $uid, $g, $sFile;

    print 'Ok' if $cnt > 0;

    my $d = $sFile =~ m?^(.*)/[^/]+$? ? $1 : $m_hrSettings->{cgi}{bin};

    &showDir($d);

}



sub chmodFile {

    my $chmod = param('chmod');

    my $sFile = param('file');

    chmod oct($chmod), $sFile if $chmod =~ /\d\d\d\d/ && -e $sFile;

    my $d = $sFile =~ m?^(.*)/[^/]+$? ? $1 : $m_hrSettings->{cgi}{bin};

    &showDir($d);

}



sub deleteFile {

    my $sFile = param('file');

    unlink $sFile if -e $sFile;

    rmdir $sFile  if -d $sFile;

    my $d = $sFile =~ m?^(.*)/[^/]+$? ? $1 : $m_hrSettings->{cgi}{bin};

    &showDir($d);

}



