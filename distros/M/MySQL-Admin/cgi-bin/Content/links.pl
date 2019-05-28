use utf8;
use warnings;
no warnings 'redefine';
use vars qw(@t $ff $ss $folderfirst $sortstate);
$folderfirst = param('folderfirst') ? 1 : 0;
$ss          = param('sort')        ? 1 : 0;
folderFirst($folderfirst);

#Style("admin");
#size(22);
sub ShowBookmarks {
    loadTree( $m_hrSettings->{tree}{links} );
    *t = \@{ $HTML::Menu::TreeView::TreeView[0] };
    applyRights( \@t );

    #     print '<div class="showTables">';
    _showBookmarksNavi();
    print
qq(<table  style="padding-top:1.65em;" align="center"  border="0" cellpadding="0" cellspacing="0"  width="95%" summary="linkLayout"><tr><td valign="top">);
    print Tree( \@t );
    print qq(</td></tr></table>);
} ## end sub ShowBookmarks

sub _showBookmarksNavi {
    $ff = $folderfirst;
    $ff = $ff ? 0 : 1;
    sortTree($ss);
    $sortstate = $ss;
    $ss = $ss ? 0 : 1;
    print '<div align="left">'
      . a(
        {
            class => 'link',
            href  => "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=links&sort=1','links','links')",
            title => translate('sort')
        },
        translate('sort')
      ) . ' ';
    print a(
        {
            class => $folderfirst ? 'currentLink' : 'link',
            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=links&sort=$sortstate&folderfirst=$ff','links','links')",
            title => translate('folderFirst')
        },
        translate('folderFirst')
    ) . ' ';
    print a(
        {
            class => 'link',
            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ExportOperaBookmarks','ExportOperaBookmarks','ExportOperaBookmarks')",
            title => translate('ExportOperaBookmarks')
        },
        translate('ExportOperaBookmarks')
    );
    print '<br/>'
      . a(
        {
            class => 'link',
            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=editTreeview&dump=links','editTreeview','editTreeview')",
            title => translate('edit')
        },
        translate('edit')
      ) if ( $m_nRight >= $m_oDatabase->getActionRight('editTreeview') );
    print ' '
      . a(
        {
            class => $m_sAction eq 'ImportOperaBookmarks'
            ? 'currentLink'
            : 'link',
            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ImportOperaBookmarks','ImportOperaBookmarks','ImportOperaBookmarks')",
            title => translate('ImportOperaBookmarks')
        },
        translate('ImportOperaBookmarks')
      ) if ( $m_nRight >= $m_oDatabase->getActionRight('ImportOperaBookmarks') );
    print ' '
      . a(
        {
            class => $m_sAction eq 'ImportFireFoxBookmarks'
            ? 'currentLink'
            : 'link',
            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ImportFireFoxBookmarks','ImportFireFoxBookmarks','ImportFireFoxBookmarks')",
            title => translate('importFireFox'),
            id    => 'ShareLink'
        },
        translate('importFireFox')
      ) if ( $m_nRight >= $m_oDatabase->getActionRight('ImportFireFoxBookmarks') );
    $msContent .= q|</div>| . br();
} ## end sub _showBookmarksNavi

sub ExportOperaBookmarks {
    loadTree( $m_hrSettings->{tree}{links} );
    *t = \@{ $HTML::Menu::TreeView::TreeView[0] };
    _showBookmarksNavi();
    print
      q(<table align="center"  border="0" cellpadding="0" cellspacing="0"  width="100%" summary="linkLayout"><tr><td align="center" valign="top">);
    print qq(<textarea style="width:98%;height:800px;">\nOpera Hotlist version 2.0\nOptions: encoding = utf-8, version=3\n);
    &_rec( \@t );
    print q(</textarea><br/></td></tr></table>);
} ## end sub ExportOperaBookmarks

sub _rec {
    my $tree = shift;
    for ( my $i = 0 ; $i < @$tree ; $i++ ) {
        if ( @$tree[$i] ) {
            my $text = defined @$tree[$i]->{text} ? @$tree[$i]->{text} : '';
            if ( ref @$tree[$i]->{subtree}[0] eq "HASH") {
                print "#FOLDER\n\tID=@$tree[$i]->{rid}\n\tNAME=$text\n\tUNIQUEID=@$tree[$i]->{rid}\n";
                _rec( \@{ @$tree[$i]->{subtree} } );
                print "-\n\n";
            } else {
                my $hrf = defined @$tree[$i]->{href} ? @$tree[$i]->{href} : '';
                print "#URL\n\tID=@$tree[$i]->{rid}\n\tNAME=$text\n\tURL=$hrf\n\tUNIQUEID=@$tree[$i]->{rid}\n";
            } ## end else [ if ( ref @{ @$tree[$i]...})]
        } ## end if ( defined @$tree[$i...])
    } ## end for ( my $i = 0 ; $i < ...)
} ## end sub _rec

sub ImportOperaBookmarks {
    my $save        = translate('save');
    my $choosefile  = translate('choosefile');
    my $newFolder   = translate('newFolder');
    my $b_NewFolder = param('newFolder') ? param('newFolder') : '';
    print qq|



<br/><div align="center">



<font size="+1">Upload Opera Bookmarks</font><br/><br/>



<form name="upload" method="post" accept-charset="utf-8" accept="text/*" enctype="multipart/form-data" onSubmit="submitForm(this,'ImportOperaBookmarks','ImportOperaBookmarks');return false;">



<input name="file" type="file" size ="30" title="$choosefile"/>



$newFolder<input type="checkbox" name="newFolder"/>



<input type="submit" value="$save"/>



<input  name="action" value="ImportOperaBookmarks" style="display:none;"/>



</form></div><br/>|;
    my $sra = 0;
    my $ufi = param('file');
    if ($ufi) {
        use vars qw(@adrFile $folderId $currentOpen @openFolders @operaTree $treeTempRef $up);
        $up = upload('file');
        while (<$up>) { push @adrFile, $_; }
        ( $folderId, $currentOpen ) = (0) x 2;
        if ( $b_NewFolder eq 'on' ) {
            loadTree( $m_hrSettings->{tree}{links} );
            unshift @fireFoxTree, @{ $HTML::Menu::TreeView::TreeView[0] };
        } ## end if ( $b_NewFolder eq 'on')
        $treeTempRef = \@operaTree;
        $openFolders[0][0] = $treeTempRef;
        for ( my $line = 0 ; $line < $#adrFile ; $line++ ) {
            chomp $adrFile[$line];
            if ( $adrFile[$line] =~ /^#FOLDER/ ) {    #neuer Folder
                $folderId++;
                my $text = $1 if ( $adrFile[ $line + 1 ] =~ /NAME=(.*)$/ );
                $text = $1 if ( $adrFile[ $line + 2 ] =~ /NAME=(.*)$/ );
                push @{$treeTempRef},
                  {
                    text => $text =~ /(.{50}).+/ ? "$1..." : $text,
                    subtree => []
                  };
                my $l = @$treeTempRef;
                $treeTempRef               = \@{ @{$treeTempRef}[ $l - 1 ]->{subtree} };
                $openFolders[$folderId][0] = $treeTempRef;
                $openFolders[$folderId][1] = $currentOpen;
                $currentOpen               = $folderId;
            } ## end if ( $adrFile[$line] =~...)
            if ( $adrFile[$line] =~ /^-/ ) {
                $treeTempRef = $openFolders[ $openFolders[$currentOpen][1] ][0];
                $currentOpen = $openFolders[$currentOpen][1];
            } ## end if ( $adrFile[$line] =~...)
            if ( $adrFile[$line] =~ /^#URL/ ) {
                my $text = $1 if ( $adrFile[ $line + 2 ] =~ /NAME=(.*)$/ );
                $text = $1 if ( $adrFile[ $line + 1 ] =~ /NAME=(.*)$/ );
                my $href = $1 if ( $adrFile[ $line + 3 ] =~ /URL=(.*)$/ );
                $href = $1 if ( $adrFile[ $line + 2 ] =~ /URL=(.*)$/ );
                if ( defined $text && defined $href ) {
                    push @{$treeTempRef},
                      {
                        text   => $text =~ /(.{75}).+/ ? "$1..." : $text,
                        href   => $href,
                        target => "_blank",
                      };
                } ## end if ( defined $text && ...)
            } ## end if ( $adrFile[$line] =~...)
        } ## end for ( my $line = 0 ; $line...)
        saveTree( $m_hrSettings->{tree}{links}, \@operaTree );
    } ## end if ($ufi)
    ShowBookmarks();
} ## end sub ImportOperaBookmarks

sub ImportFireFoxBookmarks {
    my $save        = translate('save');
    my $choosefile  = translate('choosefile');
    my $newFolder   = translate('newFolder');
    my $b_NewFolder = param('newFolder') ? param('newFolder') : '';
    print qq|



<br/><div align="center">



<font size="+1">Upload Firefox Bookmarks</font><br/><br/>



<form name="upload" action="$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}" method="post" accept-charset="utf-8" accept="text/*" enctype="multipart/form-data" onSubmit="submitForm(this,'ImportFireFoxBookmarks','ImportFireFoxBookmarks');return false;">



<input name="file" type="file" size ="30" title="$choosefile"/>



$newFolder<input type="checkbox"  name="newFolder"/>



<input type="submit" value="$save"/>



<input  name="action" value="ImportFireFoxBookmarks" style="display:none;"/>



</form></div><br/>|;
    my $sra = 0;
    my $ufi = param('file');
    if ($ufi) {
        use vars qw(@adrFile $folderId $currentOpen @openFolders @fireFoxTree $treeTempRef $up);
        $up = upload('file');
        while (<$up>) { push @adrFile, $_; }
        ( $folderId, $currentOpen ) = (0) x 2;
        if ( $b_NewFolder eq 'on' ) {
            loadTree( $m_hrSettings->{tree}{links} );
            unshift @fireFoxTree, @{ $HTML::Menu::TreeView::TreeView[0] };
        } ## end if ( $b_NewFolder eq 'on')
        $treeTempRef       = \@fireFoxTree;
        $openFolders[0][0] = $treeTempRef;
        $openFolders[0][1] = 0;
        for ( my $line = 0 ; $line < $#adrFile ; $line++ ) {
            chomp $adrFile[$line];
            if ( $adrFile[$line] =~ /<DL>/ ) {    #neuer Folder
                $folderId++;
                if ( $adrFile[ $line - 1 ] =~ /<H3[^>]+>(.*)<\/H3>/ ) {
                    my $text = $1;
                    push @{$treeTempRef},
                      {
                        text => $text =~ /(.{50}).+/ ? "$1..." : $text,
                        subtree => []
                      };
                    my $l = @$treeTempRef;
                    $treeTempRef =
                      \@{ @{$treeTempRef}[ $l - 1 ]->{subtree} };    #aktuelle referenz setzen.
                    $openFolders[$folderId][0] = $treeTempRef;       #referenz auf den parent Tree speichern
                    $openFolders[$folderId][1] = $currentOpen;       #rücksprung speichern
                    $currentOpen               = $folderId;
                } ## end if ( $adrFile[ $line -...])
            } ## end if ( $adrFile[$line] =~...)
            if ( $adrFile[$line] =~ /<\/DL>/ ) {                     #wenn folder geschlossen wird
                $treeTempRef = $openFolders[ $openFolders[$currentOpen][1] ][0];    #aktuelle referenz auf parent referenz setzen
                $currentOpen = $openFolders[$currentOpen][1];                       #rücksprung zu parent
            } ## end if ( $adrFile[$line] =~...)
            if ( $adrFile[$line] =~ /<A HREF="([^"]+)"[^>]+>(.*)<\/A>/ ) {
                my $text = $2;
                my $href = $1;
                if ( defined $text && defined $href ) {
                    push @{$treeTempRef},
                      {
                        text   => $text =~ /(.{75}).+/ ? "$1..." : $text,
                        href   => $href,
                        target => "_blank",
                      };
                } ## end if ( defined $text && ...)
            } ## end if ( $adrFile[$line] =~...)
        } ## end for ( my $line = 0 ; $line...)
        saveTree( $m_hrSettings->{tree}{links}, \@fireFoxTree );
    } ## end if ($ufi)
    ShowBookmarks();
} ## end sub ImportFireFoxBookmarks
