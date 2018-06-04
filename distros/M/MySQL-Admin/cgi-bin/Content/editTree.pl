use utf8;
use warnings;
no warnings 'redefine';
#no warnings;

use vars qw(
    $m_sDump 
    $m_sPdmp 
    %m_hTempNode 
    $m_hrTempNode 
    $m_nRid  
    $m_nPrid 
    @m_aTree 
    %disallowedKeys
    %params
    $deleteTempIndex
    $tempDeleteRef
);
$m_sPdmp = param('dump') ? param('dump') : 'navigation';
$m_sDump = $m_hrSettings->{tree}{$m_sPdmp};
$m_nPrid = param('rid') ? param('rid') :0;
undef @m_aTree;
$m_nPrid =~ s/^a(.*)/$1/ if $m_nPrid;
$m_hrTempNode = \%m_hTempNode;
$m_nSize      = 16;
%disallowedKeys = (
                   action   => 1,
                   folder   => 1,
                   subtree  => 1,
                   class    => 1,
                   dump     => 1,
                   sid      => 1,
                   m_bLogin => 1
                  );
%params = Vars();

sub linkseditTreeview {
    $m_sPdmp = 'links';
    $m_sDump = $m_hrSettings->{tree}{'links'};
    editTreeview();
}

sub newTreeviewEntry {
    $m_sPdmp = param('dump') ? param('dump') : 'navigation';
    $m_sDump = $m_hrSettings->{tree}{$m_sPdmp};
    &newEntry();
}

sub saveTreeviewEntry {
    &load();
    &saveEntry(\@m_aTree, $m_nPrid);
    _Tree();
}

sub addTreeviewEntry {
    &load();
    &addEntry(\@m_aTree, $m_nPrid);
    _Tree();
}

sub editTreeview {
    &load();
    &rid();
    saveTree($m_sDump, \@m_aTree);
    _Tree();
}

sub _Tree {
    &updateTree(\@m_aTree);
    TrOver(1);

    print
      qq(<div align="center"><form action="$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}" method="POST" enctype="multipart/form-data" onsubmit="submitForm(this,'deleteTreeviewEntrys','deleteTreeviewEntrys');return false;"  accept-charset="UTF-8"><input type="hidden" name="action" value="deleteTreeviewEntrys"/><input type="hidden" name="dump" value="$m_sPdmp"/><table class="marginTop"><tr><td>);

    print table(
                {
                 align => 'center',
                 width => '100%'
                },
                Tr(td(Tree(\@m_aTree)))
               );
    my $delete   = translate('delete');
    my $mmark    = translate('selected');
    my $markAll  = translate('select_all');
    my $umarkAll = translate('unselect_all');
    my $rebuild  = translate('rebuild');
    print
      qq{</td></tr><tr><td><script language="Javascript">m_sDump = '$m_sPdmp';</script><table align="center" border="0" cellpadding="0"  cellspacing="0" summary="layout" width="100%" ><tr><td style="padding-left:18px;text-align:left;"><a id="markAll" href="javascript:markInput(true);" class="links">$markAll</a><a class="links" id="umarkAll" style="display:none;" href="javascript:markInput(false);">$umarkAll</a></td><td align="right"><select  name="MultipleRebuild"  onchange="if(this.value != '$mmark' )submitForm(this.form,'links','links')"><option  value="$mmark" selected="selected">$mmark</option><option value="delete">$delete</option></select></td></tr></table></td></tr></table></div>};
    TrOver(0);
    undef @m_aTree;
}

sub editTreeviewEntry {
    &load();
    &editEntry(\@m_aTree, $m_nPrid);
}

sub deleteTreeviewEntry {
    &load();
    &deleteEntry(\@m_aTree, $m_nPrid);
    _Tree();
}

sub upEntry {
    &load();
    &sortUp(\@m_aTree, $m_nPrid);
    _Tree();
}

sub MoveTreeViewEntry {
    &load();
    my $from = param('from');
    $from =~ s/^a(\d+)/$1/;
    my $to = param('to');
    $to =~ s/^a(\d+)/$1/;
    &getEntry(\@m_aTree, $from, $to);
    &rid();
    saveTree($m_sDump, \@m_aTree);
    _Tree();
}

sub moveEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i <= @$t ; $i++) {
        next if ref @$t[$i] ne 'HASH';
        if (@$t[$i]) {
            if (@$t[$i]->{rid} eq $find) {
                splice @$tempDeleteRef, $deleteTempIndex, 1;
                splice @$t, $i, 0, $m_hrTempNode;
                return 1;
            }
            if (ref @$t[$i]->{subtree}[0] eq "HASH") {
               moveEntry(\@{@$t[$i]->{subtree}}, $find);
            }
        }
    }
}

sub getEntry {
    my $t    = shift;
    my $find = shift;
    my $goto = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        next if ref @$t[$i] ne 'HASH';
        if (@$t[$i]->{rid} eq $find) {
            undef $m_hrTempNode;
            foreach (keys %{@$t[$i]}) {
                $m_hrTempNode->{$_} = @$t[$i]->{$_};
            }
            $tempDeleteRef = $t;
            $deleteTempIndex = $i;
            moveEntry(\@m_aTree, $goto);
            
        } elsif (ref @$t[$i]->{subtree}[0] eq "HASH") {
            getEntry(\@{@$t[$i]->{subtree}}, $find, $goto);
        }
    }
}

sub downEntry {
    &load();
    $down = 1;
    &sortUp(\@m_aTree, $m_nPrid);
    &updateTree(\@m_aTree);
    _Tree();
}

sub newEntry {
    my $value = param('title') ? param('title') : '';
    my $push = '';

    if (param('addBookMark')) {
        &load();
        &rid();
        saveTree($m_sDump, \@m_aTree);
        $m_nPrid = $m_nRid;
        $push    = '<input type="hidden" name="addBookMark" value="addBookMark"/>';
    }
    my $new = translate('newEntry');
    print qq(
<div align="center" class="marginTop">
<b>$new</b>
<form action="$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}" onsubmit="submitForm(this,'addTreeviewEntry','addTreeviewEntry');return false;">
<input type="hidden" name="rid" value="a$m_nPrid"/>$push<br/>
<table align="center" class="mainborder" cellpadding="2"  cellspacing="2" summary="mainLayolut">
<tr><td>) . translate('txt') . qq(</td><td><input type="text" value="$value" name="text"/></td></tr>
<tr><td>) . translate('folder') . qq(</td><td><input type="checkbox" name="folder"/></td></tr>);
    print qq(<tr><td>)
      . translate('right')
      . qq(</td><td><input type="text" value="$node->{right}" name="right" /></td></tr>);
    language('de') if $ACCEPT_LANGUAGE eq 'de';
    my $node = help();

    foreach my $key (sort keys %{$node}) {
        $value = "";
        $value = param('addBookMark') if ($key eq 'href' && param('addBookMark'));
        $value = param('title') if ($key eq 'title' && param('title'));
        $value = 'a' . $m_nPrid if ($key eq 'id' && param('addBookMark'));
        print
          qq(<tr><td></td><td>$node->{$key}</td></tr><tr><td>$key :</td><td><input type="text" value="$value" name="$key" id="$key"/><br/></td></tr>)
          unless $disallowedKeys{$key};
    }
    print
      qq|<tr><td><input type="hidden" name="action" value="addTreeviewEntry"/><input type="hidden" name="dump" value="$m_sPdmp"/></td><td><input type="submit"/></td></tr></table></form></div>|;
}

sub addEntry {
    my $t    = shift;
    my $find = shift;
    $find = $find ? $find : 1;
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (@$t[$i]->{rid} eq $find) {
            my %params = Vars();
            my $node   = {};
            foreach my $key (sort(keys %params)) {
                $node->{$key} = $params{$key} unless $disallowedKeys{$key};
                $node->{$key} =
                  "javascript:requestUri('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=$1','$1','$1');"
                  if ($key eq 'href' && $params{$key} =~ /^action:\/\/(.*)$/);
            }
            if (param('folder')) {
                $node->{'subtree'} = [
                                      {
                                       text => 'Empty Folder',
                                      }
                                     ];
            }
            if (param('addBookMark')) {
                unless ($node->{'text'} eq $m_aTree[$#m_aTree]->{'text'}) {
                    push @$t, $node;
                    &rid();
                    saveTree($m_sDump, \@m_aTree);
                    return;
                }
            }
            splice @$t, $i, 0, $node;
            &rid();
            saveTree($m_sDump, \@m_aTree);
            return;
        } elsif (ref @$t[$i]->{subtree}[0] eq "HASH") {
            &addEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub saveEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (@$t[$i]->{rid} eq $find) {
            my %params = Vars();
            foreach my $key (keys %params) {
                @$t[$i]->{$key} = $params{$key} unless $disallowedKeys{$key};
                @$t[$i]->{$key} =
                  "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=$1','$1','$1')"
                  if ($key eq 'href' && $params{$key} =~ /^action:\/\/(.*)$/);
            }
            &saveTree($m_sDump, \@m_aTree);
            return;
        } elsif (ref @$t[$i]->{subtree}[0] eq "HASH") {
            &saveEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub editEntry {
    my $t    = shift;
    my $find = shift;
    my $href = "submitForm(this ,'editTreeviewEntry','editTreeviewEntry');return false;";
    language('de') if $ACCEPT_LANGUAGE eq 'de';
    my $node = help();
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (@$t[$i]->{rid} eq $find) {
            print '<div align="center" class="marginTop"><b>'
              . @$t[$i]->{text}
              . '</b><form onsubmit="'
              . $href
              . '"><table align=" center " class=" mainborder " cellpadding="0"  cellspacing="0" summary="mainLayolut">';
            print qq(<tr><td>)
              . translate('txt')
              . qq(</td><td><input type="text" value="@$t[$i]->{text}" name="text" /></td></tr>);
            print qq(<tr><td>)
              . translate('right')
              . qq(</td><td><input type="text" value="@$t[$i]->{right}" name="right" /></td></tr>);
            foreach my $key2 (
                sort {
                    return $a cmp $b if @$t[$i]->{$a} && @$t[$i]->{$b};
                    return -1        if @$t[$i]->{$a};
                    return +1        if @$t[$i]->{$b};
                    return $a cmp $b;
                } keys %{$node}
              ) {
                unless ($disallowedKeys{$key2}) {
                    print
                      qq(<tr><td></td><td>$node->{$key2}</td></tr><tr><td>$key2 :</td><td><input type="text" value="@$t[$i]->{$key2}" name="$key2"/><br/></td></tr>);
                }
            }
            print
              qq(<tr><td><input type="hidden" name="action" value="saveTreeviewEntry"/><input type="hidden" name="rid" value="@$t[$i]->{rid}"/><input type="hidden" name="dump" value="$m_sPdmp"/></td><td><input type="submit" value="save"/></td></tr></table></form></div>);
            saveTree($m_sDump, \@m_aTree);
            return;
        } elsif (ref @$t[$i]->{subtree}[0] eq "HASH") {
            &editEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub sortUp {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i <= @$t ; $i++) {
        if (defined @$t[$i]) {
            if (@$t[$i]->{rid} eq $find) {
                $i++ if ($down);
                return if (($down && $i eq @$t) or (!$down && $i eq 0));
                splice @$t, $i - 1, 2, (@$t[$i], @$t[$i - 1]);
                saveTree($m_sDump, \@m_aTree);
            }
            if (ref @$t[$i]->{subtree}[0] eq "HASH") {
                sortUp(\@{@$t[$i]->{subtree}}, $find);
                saveTree($m_sDump, \@m_aTree);
            }
        }
    }
}

sub deleteEntry {
    my $t    = shift;
    my $find = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (@$t[$i]->{rid} eq $find) {
            splice @$t, $i, 1;
            saveTree($m_sDump, \@m_aTree);
        } elsif (ref @$t[$i]->{subtree}[0] eq "HASH") {
            deleteEntry(\@{@$t[$i]->{subtree}}, $find);
        }
    }
}

sub updateTree {
    my $t = shift;
    for (my $i = 0 ; $i < @$t ; $i++) {
        if (defined @$t[$i]) {
            @$t[$i]->{onmouseup} = 'confirmMove()';

            #@$t[$i]->{id}          = @$t[$i]->{id};
            @$t[$i]->{name}        = @$t[$i]->{id};
            @$t[$i]->{onmousedown} = "prepareMove('" . @$t[$i]->{id} . "')";
            @$t[$i]->{onmousemove} = "enableDropZone('" . @$t[$i]->{id} . "')";
            @$t[$i]->{onmouseout}  = "disableDropZone('" . @$t[$i]->{id} . "')";
            my $nPrevId = 'a' . (@$t[$i]->{rid} - 1);
            @$t[$i]->{addition} =
              qq|<table border="0" cellpadding="0" cellspacing="0" align="right" summary="layout"><tr>
<td><a class="treeviewLink$m_nSize" target="_blank" title="@$t[$i]->{text}" href="@$t[$i]->{href}"><img src="style/$m_sStyle/$m_nSize/mimetypes/www.png" border="0" alt=""></a></td>
<td><a class="treeviewLink$m_nSize" href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=editTreeviewEntry&dump=$m_sPdmp&rid=@$t[$i]->{rid}','editTreeviewEntry','editTreeviewEntry')"><img src="style/$m_sStyle/$m_nSize/mimetypes/edit.png" border="0" alt="edit"></a></td><td><a class="treeviewLink$m_nSize" onclick="confirm2('Delete ?',function(){requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=deleteTreeviewEntry&dump=$m_sPdmp&rid=@$t[$i]->{rid}','deleteTreeviewEntry','deleteTreeviewEntry')});"><img src="style/$m_sStyle/$m_nSize/mimetypes/editdelete.png" border="0" alt="delete"></a></td><td><a class="treeviewLink$m_nSize" href="javascript:requestURI('$ENV{SCRIPT_NAME}?action=upEntry&dump=$m_sPdmp&rid=@$t[$i]->{rid}#@$t[$i]->{id}','upEntry','upEntry')"><img src="style/$m_sStyle/$m_nSize/mimetypes/up.png" border="0" alt="up"></a></td><td><a class="treeviewLink$m_nSize" href="javascript:requestURI('$ENV{SCRIPT_NAME}?action=downEntry&dump=$m_sPdmp&rid=@$t[$i]->{rid}','downEntry','downEntry')"><img src="style/$m_sStyle/$m_nSize/mimetypes/down.png" border="0" alt="down"></a></td><td><a class="treeviewLink$m_nSize" href="javascript:requestURI('$ENV{SCRIPT_NAME}?action=newTreeviewEntry&dump=$m_sPdmp&rid=@$t[$i]->{rid}','newTreeviewEntry','newTreeviewEntry')"><img src="style/$m_sStyle/$m_nSize/mimetypes/filenew.png" border="0" alt="new"></a></td><td><input type="checkbox" name="markBox$i" class="markBox" value="@$t[$i]->{rid}" /></td></tr></table>|;
            @$t[$i]->{href} = '';
            updateTree(\@{@$t[$i]->{subtree}}) if (ref @$t[$i]->{subtree}[0] eq "HASH");
        }
    }
}

sub rid {
    $m_nRid = 0;
    &getRid(\@m_aTree);

    sub getRid {
        my $t = shift;
        for (my $i = 0 ; $i < @$t ; $i++) {
            $m_nRid++;
            next unless ref @$t[$i] eq 'HASH';
            @$t[$i]->{rid} = $m_nRid;
            @$t[$i]->{id}  = "a$m_nRid";
            getRid(\@{@$t[$i]->{subtree}}) if (ref @$t[$i]->{subtree}[0] eq "HASH");
        }
    }
}

sub load {
    if (-e $m_sDump) {
        loadTree($m_sDump);
        *m_aTree = \@{$HTML::Menu::TreeView::TreeView[0]};
    }
}

sub deleteTreeviewEntrys {
    &load();
    my @params = param();

    for (my $i = 0 ; $i <= $#params ; $i++) {
        if ($params[$i] =~ /markBox\d?/) {

            my $id = param($params[$i]);
            &deleteEntry(\@m_aTree, $id);

        }
    }
    editTreeview();
}
1;
