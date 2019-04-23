use vars qw/$RIBBONCONTENT $PAGES $SQL %m_hUserRights $set $typId/;
use utf8;
no warnings 'redefine';
no warnings 'uninitialized';
use Search::Tools::UTF8;
use Symbol;
use POSIX 'floor';
ChangeDb(
    {
        name     => $m_sCurrentDb,
        host     => $m_sCurrentHost,
        user     => $m_sCurrentUser,
        password => $m_sCurrentPass,
    }
);
$PAGES         = '';
$SQL           = '';
$RIBBONCONTENT = '';

=head2 styleguide

Action: means the sub is called from GUI.pm via do('tables.pl'); eval('sub()');

Sometimes it is possible that parameters will be used instead of param('table') values. 

For example SaveNewTable() calls ShowNewTable( 'table', 'column count' ).

again  if CREATE TABLE  failed.

=head2 ShowNewTable(table, count)

Action:

Shows a form to create a new table.

=cut

sub ShowNewTable {
    my $tbl = defined $_[0] ? shift : param('table');
    if ( $m_oDatabase->tableExists($tbl) ) {
        EditTable($tbl);
        return;
    } ## end if ( $m_oDatabase->tableExists...)
    my $count    = defined $_[0] ? shift : param('count');
    my $newentry = translate('CreateNewTable');
    my $save     = translate('save');
    print br();
    ShowDbHeader( $m_sCurrentDb, 0, 'none' );
    print qq(
    <form onsubmit="setAll();submitForm(this,'SaveNewTable','SaveNewTable');return false;" method="get" enctype="multipart/form-data">
    <input type="hidden" name="action" value="SaveNewTable"/>
    <table class="ShowTables">
    <tr><td class="captionRadius borderBottom" colspan="11">$tbl</td></tr>
    <tr class="caption">
    <td class="caption3">) . translate('Field') . q(</td>
    <td class="caption3">) . translate('Type') . q(</td>
    <td class="caption3">) . translate('LENGTH') . q(</td>
    <td class="caption3">) . translate('Null') . q(</td>
    <td class="caption3">) . translate('Default') . q(</td>
    <td class="caption3">) . translate('Extra') . q(</td>
    <td class="caption3">) . translate('Attribute') . qq(</td>
    <td class="caption3 "><img src="style/$m_sStyle/buttons/primary.png" title=")
      . translate('AddPrimaryKey') . qq(" /></td>
    <td class="caption3"><img src="style/$m_sStyle/buttons/fulltext.png" title="Fulltext"  align="left" /></td>
    <td class="caption3"><img src="style/$m_sStyle/buttons/index.png" title="Index"  align="left" /></td>
    <td class="caption3"><img src="style/$m_sStyle/buttons/unique.png" title="Unique"  align="left" /></td>
    </tr>);
    my %vars = (
        user   => $m_sUser,
        action => 'SaveNewTable',
        table  => $tbl,
        count  => $count,
        rows   => []
    );
    sessionValidity( 60 * 60 );
    my $session = param('create_table_session_new_table');

    if ( defined $tbl and defined $session ) {
        session( $session, $m_sUser );
        for ( my $row = 0 ; $row <= $#{ $m_hrParams->{rows} } ; $row++ ) {
            my $type      = param( $m_hrParams->{rows}[$row]{Type} );
            my $length    = param( $m_hrParams->{rows}[$row]{Length} );
            my $fie1d     = param( $m_hrParams->{rows}[$row]{Field} );
            my $null      = param( $m_hrParams->{rows}[$row]{Null} );
            my $extra     = param( $m_hrParams->{rows}[$row]{Extra} );
            my $default   = param( $m_hrParams->{rows}[$row]{Default} );
            my $attr      = param( $m_hrParams->{rows}[$row]{Attrs} );
            my $atrrs     = $m_oDatabase->GetAttrs( 0, $attr, $m_hrParams->{rows}[$row]{Attrs} );
            my $fieldid   = $m_hrParams->{rows}[$row]{Field};
            my $prim      = param( $m_hrParams->{rows}[$row]{Primary} ) eq 'on' ? 1 : 0;
            my $bFulltext = param( $m_hrParams->{rows}[$row]{Fulltext} ) eq 'on' ? 1 : 0;
            my $bIndex    = param( $m_hrParams->{rows}[$row]{Index} ) eq 'on' ? 1 : 0;
            my $bUnique   = param( $m_hrParams->{rows}[$row]{Unique} ) eq 'on' ? 1 : 0;
            print qq|<tr>
        <td class="forms"><input id="$m_hrParams->{rows}[$row]{Field}" type="text" value="$fie1d" name="$m_hrParams->{rows}[$row]{Field}"/></td>
        <td class="forms">|
              . GetTypes( $type, $m_hrParams->{rows}[$row]{Type}, $tbl, $fie1d, \$set ) . qq{</td>
        <td class="forms"><input type="text" value="$length" name="$m_hrParams->{rows}[$row]{Length}"/></td>
        <td class="forms">
        <select name="$m_hrParams->{rows}[$row]{Null}">
        <option value="not NULL" }
              . ( $null eq 'not NULL' ? 'selected="selected"' : '' ) . q{>not NULL</option>
        <option value="NULL" } . ( $null eq 'NULL' ? 'selected="selected"' : '' ) . qq{>NULL</option>
        </select>
        </td>
        <td class="forms"><input type="text" value="$default" name="$m_hrParams->{rows}[$row]{Default}"/></td>
        <td class="forms">
        <select name="$m_hrParams->{rows}[$row]{Extra}">
        <option value=''></option>
        <option value="auto_increment" }
              . ( $extra eq 'auto_increment' ? 'selected="selected"' : '' ) . qq{>auto_increment</option>
        </select>
        </td>
        <td class="forms">$atrrs</td>
        <td class="forms">
        <input type="checkbox" class="checkbox" }
              . ( $prim ? 'checked="checked"' : '' ) . qq { name="$m_hrParams->{rows}[$row]{Primary}"/>
        </td><td class="forms">
        }
              . (
                $bFulltext ? qq|<input type="checkbox" name="$m_hrParams->{rows}[$row]{Fulltext}" title="Fulltext" checked="checked"/>|
                : qq|<input type="checkbox" name="$m_hrParams->{rows}[$row]{Fulltext}" title="Fulltext" /> |
              )
              . '</td><td class="forms">'
              . (
                $bIndex ? qq|<input type="checkbox" name="$m_hrParams->{rows}[$row]{Index}" title="Index" checked="checked"/>|
                : qq|<input type="checkbox" name="$m_hrParams->{rows}[$row]{Index}" title="Index"/> |
              )
              . '</td><td class="forms right">'
              . (
                $bUnique ? qq|<input type="checkbox" name="$m_hrParams->{rows}[$row]{Unique}" title="Unique" checked="checked"/>|
                : qq|<input type="checkbox" name="$m_hrParams->{rows}[$row]{Unique}" title="Unique"/> |
              ) . q{</td></tr>};
            $vars{rows}[$row] = {
                Field    => $m_hrParams->{rows}[$row]{Field},
                Type     => $m_hrParams->{rows}[$row]{Type},
                Length   => $m_hrParams->{rows}[$row]{Length},
                Null     => $m_hrParams->{rows}[$row]{Null},
                Key      => $m_hrParams->{rows}[$row]{Key},
                Default  => $m_hrParams->{rows}[$row]{Default},
                Extra    => $m_hrParams->{rows}[$row]{Extra},
                Comment  => $m_hrParams->{rows}[$row]{Comment},
                Attrs    => $m_hrParams->{rows}[$row]{Attrs},
                Primary  => $m_hrParams->{rows}[$row]{Primary},
                Fulltext => $m_hrParams->{rows}[$row]{Fulltext},
                Index    => $m_hrParams->{rows}[$row]{Index},
                Unique   => $m_hrParams->{rows}[$row]{Unique},
            };
        } ## end for ( my $row = 0 ; $row...)
    } else {
        for ( my $j = 0 ; $j < $count ; $j++ ) {
            my $sUniqueField    = Unique();
            my $sUniqueType     = Unique();
            my $sUniqueLength   = Unique();
            my $sUniqueNull     = Unique();
            my $sUniqueKey      = Unique();
            my $sUniqueDefault  = Unique();
            my $sUniqueExtra    = Unique();
            my $sUniqueComment  = Unique();
            my $sUniqueAttrs    = Unique();
            my $sUniquePrimary  = Unique();
            my $sUniqueFulltext = Unique();
            my $sUniqueIndex    = Unique();
            my $sUniqueUnique   = Unique();
            my $atrrs           = $m_oDatabase->GetAttrs( 0, 'none', $sUniqueAttrs );
            print qq|
      <tr>
      <td class="forms"><input id="$sUniqueField" type="text" value='' name="$sUniqueField"/></td>
      <td class="forms">| . GetTypes( 'INT', $sUniqueType, $tbl, $sUniqueField ) . qq{</td>
      <td class="forms"><input type="text" value='' name="$sUniqueLength"/></td>
      <td class="forms">
      <select class="editTable" name="$sUniqueNull">
      <option  value="not NULL">not NULL</option>
      <option value="NULL">NULL</option>
      </select>
      </td>
      <td class="forms"><input type="text" value='' name="$sUniqueDefault"/></td>
      <td class="forms">
      <select class="editTable" name="$sUniqueExtra">
      <option value=''></option>
      <option value="auto_increment">auto_increment</option>
      </select>
      </td>
      <td class="forms">$atrrs</td>
      <td class="forms"><input type="checkbox" name="$sUniquePrimary" title="Primary Key" /></td>
      <td class="forms"><input type="checkbox" name="$sUniqueFulltext" title="Fulltext" /></td>
      <td class="forms"><input type="checkbox" name="$sUniqueIndex" title="Index"/></td>
      <td class="forms right"><input type="checkbox" name="$sUniqueUnique" title="Unique"/></td></tr>};
            push @{ $vars{rows} },
              {
                Field    => $sUniqueField,
                Type     => $sUniqueType,
                Length   => $sUniqueLength,
                Null     => $sUniqueNull,
                Key      => $sUniqueKey,
                Default  => $sUniqueDefault,
                Extra    => $sUniqueExtra,
                Comment  => $sUniqueComment,
                Attrs    => $sUniqueAttrs,
                Primary  => $sUniquePrimary,
                Fulltext => $sUniqueFulltext,
                Index    => $sUniqueIndex,
                Unique   => $sUniqueUnique
              };
        } ## end for ( my $j = 0 ; $j < ...)
    } ## end else [ if ( defined $tbl and ...)]
    my $col              = param( $m_hrParams->{Collation} );
    my $sUniqueCollation = $col ? $m_hrParams->{Collation} : Unique();
    my $extra            = param( $m_hrParams->{Engine} );
    my $sUniqueEngine    = $extra ? $m_hrParams->{Engine} : Unique();
    my $comment          = param( $m_hrParams->{Comment} ) ? param( $m_hrParams->{Comment} ) : '';
    my $sUniqueComment   = $comment ? $m_hrParams->{Comment} : Unique();
    $vars{Collation} = $sUniqueCollation;
    $vars{Engine}    = $sUniqueEngine;
    $vars{Comment}   = $sUniqueComment;

    #     clearSession();
    my $qstring    = createSession( \%vars );
    my $collation  = $m_oDatabase->GetCollation( $sUniqueCollation, $col );
    my $sComment   = translate('comment');
    my $sCollation = translate('collation');
    print qq(
    </tr><tr>
    <td class="forms">$sCollation:</td>
    <td colspan="10" class="forms" align="left">$collation</td>
    </tr>
    <tr>
    <td class="forms">$sComment:</td>
    <td colspan="10" class="forms"><input type="text" value="$comment" name="$sUniqueComment" class="comment"/></td>
    </tr>
    <tr>
    <td colspan="11" class="submit right">
    <input type="submit" name="submit" value="$save" />
    <input type="hidden" name="create_table_session_new_table" value="$qstring"/></td>
    </tr>
    </table>
    </form>);
} ## end sub ShowNewTable

=head2 SaveNewTable()

Action: Dont call direct.

=cut

sub SaveNewTable {
    my $session = param('create_table_session_new_table');
    session( $session, $m_sUser );
    my $tbl = $m_hrParams->{table};
    my @prims;
    if ( defined $tbl and defined $session ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        my $sql  = qq|CREATE TABLE IF NOT EXISTS $tbl2 (\n|;
        my $indexes;
        for ( my $row = 0 ; $row <= $#{ $m_hrParams->{rows} } ; $row++ ) {
            my $type   = param( $m_hrParams->{rows}[$row]{Type} );
            my $length = param( $m_hrParams->{rows}[$row]{Length} );
            my $fie1d  = param( $m_hrParams->{rows}[$row]{Field} );
            $type =
                $type =~ /BLOB|MEDIUMBLOB|LONGBLOB|TINYBLOB|TIMESTAMP/ ? $type
              : $length                                                ? $type . "($length)"
              :                                                          $type;
            my @te = param( 'SET' . $m_hrParams->{rows}[$row]{Type} );
            $set->{$fie1d} = [@te] if $fie1d;
            $te[$_] = $m_oDatabase->quote( $te[$_] ) for 0 .. $#te;
            $type = 'SET(' . ( join ',', @te ) . ')' if $type eq 'SET';
            my $null     = param( $m_hrParams->{rows}[$row]{Null} );
            my $extra    = param( $m_hrParams->{rows}[$row]{Extra} );
            my $default  = param( $m_hrParams->{rows}[$row]{Default} );
            my $attrs    = param( param( $m_hrParams->{rows}[$row]{Attrs} ) );
            my $prim     = param( $m_hrParams->{rows}[$row]{Primary} ) ? param( $m_hrParams->{rows}[$row]{Primary} ) : 'off';
            my $fulltext = param( $m_hrParams->{rows}[$row]{Fulltext} ) ? param( $m_hrParams->{rows}[$row]{Fulltext} ) : 'off';
            my $index    = param( $m_hrParams->{rows}[$row]{Index} ) ? param( $m_hrParams->{rows}[$row]{Index} ) : 'off';
            my $uniqe    = param( $m_hrParams->{rows}[$row]{Unique} ) ? param( $m_hrParams->{rows}[$row]{Unique} ) : 'off';
            my $qfield   = $m_dbh->quote_identifier($fie1d);
            push @prims, $m_dbh->quote_identifier($fie1d) if $prim eq 'on';
            $indexes .= "ALTER TABLE $tbl2 ADD FULLTEXT ($qfield);\n" if ( $fulltext eq 'on' );
            $indexes .= "ALTER TABLE $tbl2 ADD UNIQUE   ($qfield);\n" if ( $uniqe eq 'on' );
            $indexes .= "ALTER TABLE $tbl2 ADD INDEX    ($qfield);\n" if ( $index eq 'on' );
            $default =
              $extra
              ? 'auto_increment'
              : ( $default ? 'default ' . $m_oDatabase->quote($default) : '' );
            $sql .= $m_dbh->quote_identifier($fie1d) . " $type $null $default $attrs";
            $sql .= ",\n" if $row < $#{ $m_hrParams->{rows} };
        } ## end for ( my $row = 0 ; $row...)
        my $comment       = param( $m_hrParams->{Comment} );
        my $vcomment      = $m_dbh->quote($comment);
        my $engine        = param( $m_hrParams->{Engine} ) ? param( $m_hrParams->{Engine} ) : 'MyISAM';
        my $key           = join( ' , ', @prims );
        my $character_set = $m_oDatabase->GetCharacterSet( param( $m_hrParams->{Collation} ) );
        $sql .= qq|, PRIMARY KEY  ($key)| if $#prims >= 0;
        $sql .= qq|) ENGINE=$engine DEFAULT CHARSET=$character_set|;
        $sql .= $comment ? " COMMENT $vcomment;" : ";\n$indexes";
        ExecSql($sql);

        unless ( $m_oDatabase->tableExists($tbl) ) {
            ShowNewTable( $tbl, $m_hrParams->{count} );
        } else {
            EditTable($tbl);
        } ## end else
    } else {
        ShowNewTable( $tbl, $m_hrParams->{count} );
    } ## end else [ if ( defined $tbl and ...)]
} ## end sub SaveNewTable

=head2 ShowDumpTable

Action:

=cut

sub ShowDumpTable {
    my $tbl = param('table');
    ShowDbHeader( $tbl, 1, 'Export' );
    print '<div class="dumpBox"><textarea class="dumpTextarea">';
    DumpTable($tbl);
    print '</textarea></div>';
} ## end sub ShowDumpTable

=head2 DumpTable

Action: table will be print

in void context param( 'table' ) will be used.

=cut

sub DumpTable {
    my $tbl = defined $_[0] ? shift : param('table');
    $tbl = $m_dbh->quote_identifier($tbl);
    my $hr      = $m_oDatabase->fetch_hashref("SHOW CREATE TABLE $tbl");
    my $sql     = $hr->{'Create Table'} . ";$/";
    my @a       = $m_oDatabase->fetch_AoH("select *from $tbl");
    my @columns = $m_oDatabase->fetch_AoH("show columns from $tbl");
    for ( my $n = 0 ; $n <= $#a ; $n++ ) {
        $sql .= "INSERT INTO $tbl (";
        for ( my $i = 0 ; $i <= $#columns ; $i++ ) {
            $sql .= $m_dbh->quote_identifier( $columns[$i]->{'Field'} );
            $sql .= ',' if ( $i < $#columns );
        } ## end for ( my $i = 0 ; $i <=...)
        $sql .= ') values(';
        for ( my $i = 0 ; $i <= $#columns ; $i++ ) {
            unless ( $columns[$i]->{'Type'} =~ /.*blob.*/ ) {
                $sql .= $m_oDatabase->quote( $a[$n]->{ $columns[$i]->{'Field'} } );
            } else {
                $sql .= $m_oDatabase->quote('0');
            } ## end else
            $sql .= ',' if ( $i < $#columns );
        } ## end for ( my $i = 0 ; $i <=...)
        $sql .= ");$/";
    } ## end for ( my $n = 0 ; $n <=...)
    print $sql . $/;
} ## end sub DumpTable

=head2 ShowDumpDatabase

Action

Export the Database.

=cut

sub ShowDumpDatabase {
    ShowDbHeader( $m_sCurrentDb, 0, 'Export' );
    print q(<div align="left" class="dumpBox" style="width:100%;padding-top:5px;"><textarea style="width:100%;height:800px;overflow:auto;">);
    DumpDatabase($m_sCurrentDb);
    print q(</textarea></div>);
} ## end sub ShowDumpDatabase

=head2 DumpDatabase( $database )

In void context $m_sCurrentDb db will be used.

=cut

sub DumpDatabase {
    my $sql =
      ( defined $_[0] ) ? 'show tables from ' . $m_dbh->quote_identifier( $_[0] ) : 'show tables';
    my @tables = $m_oDatabase->fetch_array($sql);
    ChangeDb(
        {
            name     => ( defined $_[0] ) ? $_[0] : $m_sCurrentDb,
            host     => $m_sCurrentHost,
            user     => $m_sCurrentUser,
            password => $m_sCurrentPass,
        }
    );
    for ( my $n = 0 ; $n <= $#tables ; $n++ ) {
        DumpTable( $tables[$n] );
    } ## end for ( my $n = 0 ; $n <=...)
} ## end sub DumpDatabase

=head2 HighlightSQl()

$formated_string = HighlightSQl();

todo: HighlightSQl as html and link to mysql documentation.

=cut

sub HighlightSQl {
    ChangeDb(
        {
            name     => 'mysql',
            host     => $m_sCurrentHost,
            user     => $m_sCurrentUser,
            password => $m_sCurrentPass,
        }
    );
    my $sql = shift;
    $sql =~ s/\b(\w+)\b/getLink($1)/ge;
    ChangeDb(
        {
            name     => $m_sCurrentDb,
            host     => $m_sCurrentHost,
            user     => $m_sCurrentUser,
            password => $m_sCurrentPass,
        }
    );
    return qq|<pre>$sql</pre>|;
} ## end sub HighlightSQl

=head2 getLink()


=cut

sub getLink {
    my $hashref = $m_oDatabase->fetch_hashref( 'select * from `help_topic` where name like ? ', $_[0] );
    if ( defined $hashref->{url} ) {
        return qq|<a style="color:orange;" href="$hashref->{url}" title="$hashref->{description}">$_[0]</a>|;
    } else {
        return
qq|<a style="color:red;" onclick="requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=searchHelpTopic&topic=$_[0]','searchHelpTopic','searchHelpTopic')" title="$m_hrLng->{$ACCEPT_LANGUAGE}{search}">$_[0]</a>|;
    } ## end else [ if ( defined $hashref->...)]
} ## end sub getLink

=head2 searchHelpTopic


=cut

sub searchHelpTopic {
    my $topic = param('topic');
    ChangeDb(
        {
            name     => 'mysql',
            host     => $m_sCurrentHost,
            user     => $m_sCurrentUser,
            password => $m_sCurrentPass,
        }
    );
    my $sql = q|SELECT help_topic.name, help_topic.url, help_topic.description, help_topic.example  FROM help_topic where help_topic.name like ?;|;
    my @aoh = $m_oDatabase->fetch_AoH( $sql, $topic );
    my $sContent = '';
    print '<div class="ShowTables marginTop">';
    for ( my $j = 0 ; $j <= $#aoh ; $j++ ) {
        print qq|<a onclick="document.getElementById('hid$j').scrollIntoView();">$aoh[$j]->{name}</a><br/>|;
        $sContent .=
qq|<div class="ShowTables"><a id="hid$j" href="$aoh[$j]->{url}">$aoh[$j]->{name}</a><a onclick="hide('Example$j');visible('Description$j');">Description</a> |;
        $sContent .=
          qq|<a onclick="visible('Example$j');hide('Description$j');">Example</a><pre id="Example$j" style="display:none;">$aoh[$j]->{example}</pre>|
          if $aoh[$j]->{example};
        $sContent .= qq|<pre id="Description$j" >$aoh[$j]->{description}</pre></div>|;
    } ## end for ( my $j = 0 ; $j <=...)
    print qq|<a href="http://google.com?q=$topic">Google($topic)</a>|;
    print '</div><div  id="topUp" onclick="scrollToTop()" title="top" style="display:none;">^</div>' . $sContent;
    ChangeDb(
        {
            name     => $m_sCurrentDb,
            host     => $m_sCurrentHost,
            user     => $m_sCurrentUser,
            password => $m_sCurrentPass,
        }
    );
} ## end sub searchHelpTopic

=head2 HelpTopics

action

action=HelpTopics

=cut

sub HelpTopics {
    ChangeDb(
        {
            name     => 'mysql',
            host     => $m_sCurrentHost,
            user     => $m_sCurrentUser,
            password => $m_sCurrentPass,
        }
    );
    my @helpTopics = $m_oDatabase->fetch_AoH("select * from `help_topic` order by name");
    my $LocalHelp  = translate('LocalHelp');
    print
qq|<table class="ShowTables" align="center" cellpadding="0" cellspacing="0" style="margin-top:1.25em" border="0"><tr><td class="captionLeft">$LocalHelp</td><td class="captionRight">dev.mysql.com</td></tr>|;
    for ( my $i = 0 ; $i <= $#helpTopics ; $i++ ) {
        print
qq|<tr><td align="left" style="padding-left:0.2em;"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=searchHelpTopic&topic=$helpTopics[$i]->{name}','searchHelpTopic','searchHelpTopic')" title="$helpTopics[$i]->{name}">$helpTopics[$i]->{name}</a></td><td align="left"><a href="$helpTopics[$i]->{url}">$helpTopics[$i]->{url}</a></td></tr>|;
    } ## end for ( my $i = 0 ; $i <=...)
    print '</table>';
    ChangeDb(
        {
            name     => $m_sCurrentDb,
            host     => $m_sCurrentHost,
            user     => $m_sCurrentUser,
            password => $m_sCurrentPass,
        }
    );
} ## end sub HelpTopics

=head2 AddFulltext($table,$columnName)

Action:
 
In void context param('table') and param('column') will be used.

=cut

sub AddFulltext {
    my $tbl   = param('table')  ? param('table')  : shift;
    my $uname = param('column') ? param('column') : shift;
    if ( $m_oDatabase->tableExists($tbl) and defined $uname ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        $uname = $m_dbh->quote_identifier($uname);
        ExecSql("Alter TABLE $tbl2 ADD FULLTEXT ($uname);");
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub AddFulltext

=head2 DropFulltext

Action: In void context param('table') and param('column') will be used.

=cut

sub DropFulltext {
    my $tbl   = param('table')  ? param('table')  : shift;
    my $uname = param('column') ? param('column') : shift;
    if ( $m_oDatabase->tableExists($tbl) and defined $uname ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        $uname = $m_dbh->quote_identifier($uname);
        ExecSql("Alter TABLE $tbl2 DROP FULLTEXT ($uname);");
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub DropFulltext

=head2 AddIndex($table,$indexName)

Action: In void context param('table') and param('column') will be used.

=cut

sub AddIndex {
    my $tbl   = param('table')  ? param('table')  : shift;
    my $uname = param('column') ? param('column') : shift;
    if ( $m_oDatabase->tableExists($tbl) and defined $uname ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        $uname = $m_dbh->quote_identifier($uname);
        ExecSql("Alter TABLE $tbl2 ADD INDEX ($uname);");
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub AddIndex

=head2 DropIndex($table,$indexName)

Action:
 
In void context param('table') and param('column') will be used.

=cut

sub DropIndex {
    my $tbl        = param('table')      ? param('table')      : shift;
    my $uname      = param('index')      ? param('index')      : shift;
    my $constraint = param('constraint') ? param('constraint') : shift;
    if ( $m_oDatabase->tableExists($tbl) and defined $uname ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        my @constraints = $m_oDatabase->getConstraintKeys( $tbl, $constraint );
        my $sql;
        $sql .= "ALTER TABLE $tbl2 DROP FOREIGN KEY `$_`;" for @constraints;
        $sql .= "Alter TABLE $tbl2 DROP INDEX $uname;";
        ExecSql($sql);
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub DropIndex

=head2 AddUnique( $table, $indexName )

Action: In void context param('table') and param('column') will be used.

=cut

sub AddUnique {
    my $tbl   = param('table')  ? param('table')  : shift;
    my $uname = param('column') ? param('column') : shift;
    if ( $m_oDatabase->tableExists($tbl) and defined $uname ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        $uname = $m_dbh->quote_identifier($uname);
        ExecSql("Alter TABLE $tbl2 ADD UNIQUE ($uname);");
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub AddUnique

=head2 DropUnique($table,$indexName)

Action: In void context param('table') and param('column') will be used.

=cut

sub DropUnique {
    my $tbl   = param('table')  ? param('table')  : shift;
    my $uname = param('column') ? param('column') : shift;
    if ( $m_oDatabase->tableExists($tbl) and defined $uname ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        $uname = $m_dbh->quote_identifier($uname);
        ExecSql("Alter TABLE $tbl2 DROP UNIQUE ($uname);");
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub DropUnique

=head2 ExecSql($sql,$boolShowSQL)

this is the 'main' sub to excute sql within this system.

If you write your own sub write something like this:
       
sub foo
{

  print qq(

  #requestURI( url,id,txt )

  <a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=bar&foo=true','bar','bar');">bar</a>);

}

sub bar{

  ExecSql('select * from bar') if param('foo');
  
}

=cut

sub ExecSql {
    my $sql        = shift;
    my $showSql    = defined $_[0] ? shift : 0;
    my $table      = defined $_[0] ? shift : 0;
    my @statements = split /;\s*\r?\n/, $sql;
    my $ret        = 1;
    my $id2        = 0;
    $SQL .= $sql;
    my %types = (
        '1.07' => 'CHAR',
        '2'    => 'NUMERIC',
        '3'    => 'DECIMAL',
        '4'    => 'INTEGER',
        '5'    => 'SMALLINT',
        '6'    => 'FLOAT',
        '7'    => 'REAL',
        '8'    => 'DOUBLE',
        '9'    => 'DATE',
        '10'   => 'TIME',
        '11'   => 'TIMESTAMP',
        '12'   => 'VARCHAR',
        '-1'   => 'LONGVARCHAR',
        '-2'   => 'BINARY',
        '-3'   => 'VARBINARY',
        '-4'   => 'LONGVARBINARY',
        '-5'   => 'BIGINT',
        '-6'   => 'TINYINT',
        '-7'   => 'BIT',
        '-8'   => 'WCHAR',
        '-9'   => 'WVARCHAR',
        '-10'  => 'WLONGVARCHAR',
    );
    my $rows_affected_sum = 0;

    foreach my $s (@statements) {
        my $rows_affected = 0;
        eval {
            my $sth = $m_dbh->prepare($s);
            if ( length($s) > 3 ) {
                $sth->execute();
                $rows_affected = $sth->rows;
                $rows_affected_sum += $rows_affected;
                if ( $m_dbh->errstr ) {
                    $RIBBONCONTENT .= '<div class="ExecSql" align="center">';
                    $RIBBONCONTENT .= length($s) . $m_dbh->errstr . br() . HighlightSQl($s);
                    $RIBBONCONTENT .= '</div>';
                    $ret = 0;
                } ## end if ( $m_dbh->errstr )
                if ($showSql) {
                    if ( $rows_affected > 0 ) {
                        my $TMPRIBBONCONTENT .= '<div class="ExecSql" align="center">';
                        $TMPRIBBONCONTENT .= br() . $table if ( $m_oDatabase->tableExists($table) );
                        my $id = 0;
                        while ( my @rows = $sth->fetchrow_array() ) {
                            my %columns;
                            $TMPRIBBONCONTENT .= '<hr/>' if $id > 0;
                            $TMPRIBBONCONTENT .= '<table width="100%"><tr>';
                            for ( my $i = 0 ; $i < $sth->{NUM_OF_FIELDS} ; $i++ ) {
                                my $nType = $sth->{TYPE}->[$i];
                                my $type  = $types{$nType};
                                $columns{ $sth->{NAME}->[$i] } = $i;
                                $TMPRIBBONCONTENT .= "<td class=\"caption3\">$sth->{NAME}->[$i] ($type)</td>";
                            } ## end for ( my $i = 0 ; $i < ...)
                            $TMPRIBBONCONTENT .= q|</tr><tr>|;
                            for ( my $i = 0 ; $i <= $#rows ; $i++ ) {
                                unless ( is_valid_utf8( $rows[$i] ) ) {
                                    utf8::decode( $rows[$i] );
                                } ## end unless ( is_valid_utf8( $rows...))
                                $TMPRIBBONCONTENT .= q|<td class="values" >| . encode_entities( $rows[$i] ) . '</td>';
                            } ## end for ( my $i = 0 ; $i <=...)
                            $TMPRIBBONCONTENT .= q|</tr>|;
                            if ( $m_oDatabase->tableExists($table) ) {
                                my @p_key = $m_oDatabase->GetPrimaryKey($table);
                                my $eid   = '';
                                if ( $#p_key > 0 ) {
                                    for ( my $j = 0 ; $j < $#p_key ; $j++ ) {
                                        $eid .= "$p_key[$j]=$rows[$columns{$p_key[$j]}]&";
                                    } ## end for ( my $j = 0 ; $j < ...)
                                    $eid .= "$p_key[$#p_key]=$rows[$columns{$p_key[$#p_key]}]";
                                } else {
                                    $eid .= "$p_key[0]=$rows[$columns{$p_key[0]}]";
                                } ## end else [ if ( $#p_key > 0 ) ]
                                my $trdelete = translate('delete');
                                my $tredit   = translate('EditEntry');
                                my $len      = $#rows + 1;
                                $TMPRIBBONCONTENT .= qq|<tr>
                            <td align="right" colspan="$len">
                            <a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=EditEntry&table=$table&$eid','EditEntry','EditEntry');">$tredit</a>
                            <a href="javascript:confirm2('$trdelete ?',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=DeleteEntry&table=$table&$eid','DeleteEntry','DeleteEntry')">$trdelete</a></td>
                            </tr>|;
                            } ## end if ( $m_oDatabase->tableExists...)
                            $id++;
                            $TMPRIBBONCONTENT .= '</table>';
                        } ## end while ( my @rows = $sth->...)
                        $RIBBONCONTENT .= $TMPRIBBONCONTENT . '</div>' if $id > 0;
                    } ## end if ( $rows_affected > ...)
                } ## end if ($showSql)
            } ## end if ( length($s) > 3 )
        };
        if ($@) {
            $ret = 0;
            warn "MySQL::Admin::GUI tables.pl sub EXECSQL:  $@  $/";
        } ## end if ($@)
        $id2++;
    } ## end foreach my $s (@statements)
    $RIBBONCONTENT .= translate('rowsineffect') . $rows_affected_sum if $rows_affected_sum > 0;
    return $ret;
} ## end sub ExecSql

=head2 SQL()

Action: Excute SQL with the "SQL Editor".

=cut

sub SQL {
    ExecSql( param('sql'), 1 );
    ShowTables();
} ## end sub SQL

=head2 ShowTable($table)

Action: 

Call this to show the table overview.

=cut

sub ShowTable {
    my $tbl = param('table') ? param('table') : shift;
    if ( $m_oDatabase->tableExists($tbl) ) {
        my $tb2   = $m_dbh->quote_identifier($tbl);
        my $count = $m_oDatabase->tableLength($tbl);
        $count = defined $count ? $count : 0;
        my @caption = $m_oDatabase->fetch_AoH("show columns from $tb2");
        my $rws     = $#caption + 2;
        my $rows    = $#caption;
        my $field   = $caption[0]->{'Field'};
        my $orderby = defined param('orderBy') ? param('orderBy') : 0;
        $field = $orderby if $orderby;
        my $qfield = $m_dbh->quote_identifier($field);
        my $state  = param('desc') ? param('desc') : 0;
        my $desc   = $state ? 'desc' : '';
        my $lpp    = defined param('links_pro_page') ? param('links_pro_page') : 30;
        $lpp      = $lpp =~ /(\d\d\d?\d?)/     ? $1 : $lpp;
        $m_nStart = $lpp - $m_nStart >= $count ? 0  : $m_nStart;
        my @a = $m_oDatabase->fetch_AoH("select * from $tb2 order by $qfield $desc LIMIT $m_nStart , $lpp");

        if ( $count > 0 ) {
            my %needed = (
                start          => $m_nStart,
                length         => $count,
                style          => $m_sStyle,
                action         => 'ShowTable',
                append         => "&table=$tbl&links_pro_page=$lpp&orderBy=$field&desc=$state",
                path           => $m_hrSettings->{cgi}{bin},
                links_pro_page => $lpp,
                server         => "$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}",
            );
            $PAGES = makePages( \%needed );
        } ## end if ( $count > 0 )
        ShowDbHeader( $tbl, 1, 'Show' );
        print qq|
                     <form onsubmit="submitForm(this,'MultipleAction','MultipleAction');return false;" method="get" enctype="multipart/form-data">
                     <input type="hidden" name="action" value="MultipleAction"/>
                     <input type="hidden" name="table" value="$tbl"/>|;
        my $menu = (
            $count > 10
            ? div(
                { align => 'right' },
                translate('links_pro_page') . ' | '
                  . a(
                    {
                        href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTable&table=$tbl&links_pro_page=10&von=$m_nStart&orderBy=$field&desc=$state','ShowTable','ShowTable')",
                        class => $lpp == 10 ? 'menuLink2' : 'menuLink3'
                    },
                    '10'
                  )
                  . (
                    $count > 20
                    ? ' | '
                      . a(
                        {
                            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTable&table=$tbl&links_pro_page=20&von=$m_nStart&orderBy=$field&desc=$state','ShowTable')",
                            class => $lpp == 20 ? 'menuLink2' : 'menuLink3'
                        },
                        '20'
                      )
                    : ''
                  )
                  . (
                    $count > 30
                    ? ' | '
                      . a(
                        {
                            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTable;&table=$tbl&links_pro_page=30&von=$m_nStart&orderBy=$field&desc=$state','ShowTable','ShowTable')",
                            class => $lpp == 30 ? 'menuLink2' : 'menuLink3'
                        },
                        '30'
                      )
                    : ''
                  )
                  . (
                    $count > 100
                    ? ' | '
                      . a(
                        {
                            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTable&table=$tbl&links_pro_page=100&von=$m_nStart&orderBy=$field&desc=$state','ShowTable','ShowTable')",
                            class => $lpp == 100 ? 'menuLink2' : 'menuLink3'
                        },
                        '100'
                      )
                    : ''
                  )
                  . (
                    $count > 100
                    ? ' | '
                      . a(
                        {
                            href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTable&table=$tbl&links_pro_page=1000&von=$m_nStart&orderBy=$field&desc=$state','ShowTable','ShowTable')",
                            class => $lpp == 1000 ? 'menuLink2' : 'menuLink3'
                        },
                        '1000'
                      )
                    : ''
                  )
              )
            : ''
        );
        my $toolbar = a(
            {
                class => 'toolbarButton',
                onclick =>
q|document.getElementById('popupContent1').style.left='5%';document.getElementById('popupContent1').style.width='90%';showPopup('NewEntry');|,
                onmouseover => q|window.status='| . translate('NewEntry') . q|'|,
                title       => translate('NewEntry')
            },
            translate('NewEntry')
        );    #2
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => q|showPopup('SqlSearch')|,
                title   => translate('search')
            },
            translate('search')
        );    #3
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => 'showSQLEditor()',
                title   => translate('SQL')
            },
            translate('SQL')
        );    #4
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => "requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=EditTable&table=$tbl','EditTable','EditTable')",
                title   => translate('Edit')
            },
            translate('Edit')
        );    #5
        $toolbar .= a(
            {
                class => 'toolbarButton',
                onclick =>
"requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTableDetails&table=$tbl','ShowTableDetails','ShowTableDetails')",
                title => translate('Details')
            },
            translate('Details')
        );    #6
        $toolbar .= a(
            {
                class => 'toolbarButton',
                onclick =>
                  "requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDumpTable&table=$tbl','ShowDumpTable','ShowDumpTable')",
                title => translate("Export")
            },
            translate('Export')
        ) . br();    #7
        $toolbar .= a(
            {
                class => 'toolbarButton',
                onclick =>
                  "requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=AnalyzeTable&table=$tbl','AnalyzeTable','AnalyzeTable')",
                title => translate('AnalyzeTable')
            },
            translate('AnalyzeTable')
        );           #8
        $toolbar .= a(
            {
                class => 'toolbarButton',
                onclick =>
                  "requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=OptimizeTable&table=$tbl','OptimizeTable','OptimizeTable')",
                title => translate('OptimizeTable')
            },
            translate('OptimizeTable')
        );           #9
        $toolbar .= a(
            {
                class => 'toolbarButton',
                onclick =>
                  "requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=RepairTable&table=$tbl','RepairTable','RepairTable')",
                title => translate('RepairTable')
            },
            translate('RepairTable')
        );           #10
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                title   => translate('truncate'),
                onclick => q|confirm2('|
                  . translate('truncate')
                  . "?',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=TruncateTable&table=$tbl','TruncateTable','TruncateTable')",
            },
            translate('truncate')
        );           #11
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                title   => translate('Delete'),
                onclick => q|confirm2('|
                  . translate('delete')
                  . "?',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=DropTable&table=$tbl','DropTable','DropTable')",
            },
            translate('Delete')
        );           #12
        my $rws2 = $#caption + 3;
        print qq(
    <table class="ShowTables" id="toolbarTable" >
    <tr class="captionRadius">
    <td class="captionRadius" colspan="$rws2">$tbl</td></tr>
    <tr><td colspan="$rws2" id="toolbar" class="toolbar"><div id="toolbarcontent"  class="toolbarcontent">$toolbar</div></td></tr>
    );
        print qq(<tr><td colspan="$rws2"  id="toolbar2" class="toolbar2"><div id="toolbarcontent2"  class="toolbarcontent">
    <div class="makePages">$PAGES</div>
    <div class="pagePerSite">$menu</div>
    </div> </td></tr>) if $count > 10;
        print q(<tr class="caption2"><td class="caption2 checkbox"></td>);

        for ( my $i = 0 ; $i <= $rows ; $i++ ) {
            print qq|<td class="caption2">|;
            print a(
                {
                    class => $caption[$i]->{'Field'} eq $field
                    ? 'currentLink'
                    : 'link',
                    href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTable&table=$tbl&links_pro_page=$lpp&von=$m_nStart&orderBy=$caption[$i]->{'Field'}&desc="
                      . (
                        $field eq $caption[$i]->{'Field'}
                        ? ( $desc eq 'desc' ? '0' : '1.07' )
                        : '0'
                      )
                      . q|','ShowTable','showTable')|,
                    title => $caption[$i]->{'Field'}
                },
                $caption[$i]->{'Field'}
              )
              . (
                $caption[$i]->{'Field'} eq $field
                ? (
                    $state
                    ? qq|&#160;<img src="style/$m_sStyle/buttons/up.png" />|
                    : qq|&#160;<img src="style/$m_sStyle/buttons/down.png" />|
                  )
                : ''
              ) . " $caption[$i]->{'Type'}";
            print '</td>';
        } ## end for ( my $i = 0 ; $i <=...)
        print '<td class="caption2 checkbox"></td>';
        my @p_key    = $m_oDatabase->GetPrimaryKey($tbl);
        my $trdelete = translate('delete');
        my $tredit   = translate('EditEntry');
        for ( my $i = 0 ; $i <= $#a ; $i++ ) {
            print q|<tr>|;
            my $eid  = '';
            my $pkey = '';
            if ( $#p_key > 0 ) {
                for ( my $j = 0 ; $j < $#p_key ; $j++ ) {
                    $eid  .= "$p_key[$j]=$a[$i]->{$p_key[$j]}&";
                    $pkey .= "$a[$i]->{$p_key[$j]}/";
                } ## end for ( my $j = 0 ; $j < ...)
                $eid  .= "$p_key[$#p_key]=$a[$i]->{ $p_key[$#p_key]}";
                $pkey .= "$a[$i]->{$p_key[$#p_key]}";
            } else {
                $eid  .= "$p_key[0]=$a[$i]->{$p_key[0]}";
                $pkey .= "$a[$i]->{$p_key[0]}";
            } ## end else [ if ( $#p_key > 0 ) ]
            print qq|<td class="checkbox"><input type="checkbox" name="markBox$i" class="markBox" value="$tbl/$pkey"/></td>|;
            for ( my $j = 0 ; $j <= $rows ; $j++ ) {
                my $headline;
                eval { utf8::encode( $a[$i]->{ $caption[$j]->{Field} } ) unless is_valid_utf8( $a[$i]->{ $caption[$j]->{Field} } ); };
                if ( $caption[$j]->{Type} =~ /blob|longblob|mediumblob|tinyblob/ ) {
                    $headline =
qq|<a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=downLoadFile&table=$tbl&blob=$caption[$j]->{Field}&pkey=$p_key[0]&pkeyValue=$pkey','downLoadFile','downLoadFile')">Download</a>|;
                    print '<td class="values">' . $headline . '</td>';
                } else {
                    $headline =
                      defined $a[$i]->{ $caption[$j]->{Field} }
                      ? $a[$i]->{ $caption[$j]->{Field} }
                      : '';
                    print '<td class="values">' . substr( $headline, 0, int( 120 / ( $rows > 0 ? $rows : 1 ) ) ) . '</td>';
                } ## end else [ if ( $caption[$j]->{Type...})]
            } ## end for ( my $j = 0 ; $j <=...)
            print
qq|<td class="values right"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=EditEntry&table=$tbl&$eid&von=$m_nStart&bis=$m_nEnd','EditEntry','EditEntry')"><img src="style/$m_sStyle/buttons/edit.png" title="$tredit"/></a><a onclick="confirm2('$trdelete ?',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=DeleteEntry&table=$tbl&$eid&von=$m_nStart;&bis=$m_nEnd;','DeleteEntry','DeleteEntry')"><img src="style/$m_sStyle/buttons/delete.png" title="$trdelete"/></a></td></tr>|;
        } ## end for ( my $i = 0 ; $i <=...)
        print qq|<tr><td class="checkbox"><img src="style/$m_sStyle/buttons/feil.gif"/></td>|;
        my $delete   = translate('delete');
        my $mmark    = translate('selected');
        my $markAll  = translate('select_all');
        my $umarkAll = translate('unselect_all');
        my $export   = translate('export');
        my $edit     = translate('edit');
        print qq{
    <td colspan="$rws">
    <table class="MultipleAction"><tr>
    <td ><a id="markAll" href="javascript:markInput(true);" class="links">$markAll</a><a class="links" id="umarkAll" style="display:none;" href="javascript:markInput(false);">$umarkAll</a>
    </td><td class="submit">
    <select name="MultipleAction" class="MultipleAction" onchange="if(this.value != '$mmark' )submitForm(this.form,this.value,this.value);">
    <option value="$mmark" selected="selected">$mmark</option>
    <option value="delete">$delete</option>
    <option value="export">$export</option>
    </select></td></tr></table>};
        print q|</td></tr></table></form>|;
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub ShowTable

=head2 MultipleAction

Action:Multiple Table Actions.

=cut

sub MultipleAction {
    my $a      = param('MultipleAction');
    my @params = param();
    my $tbl    = param('table');
    my ( $tbl2, @p_key );
    unless ( $a eq 'deleteUser' ) {
        $tbl2  = $m_dbh->quote_identifier($tbl);
        @p_key = $m_oDatabase->GetPrimaryKey($tbl);
    } ## end unless ( $a eq 'deleteUser')
    if ( $a eq 'export' ) {
        ShowDbHeader( $tbl, 1, 'Export' );
        print q(<div class="dumpBox" style="padding-top:5px;width:100%;padding-right:2px;"><textarea style="width:100%;height:800px;overflow:auto;">);
    } ## end if ( $a eq 'export' )
    for ( my $i = 0 ; $i <= $#params ; $i++ ) {
        if ( $params[$i] =~ /markBox\d?/ ) {
            my $col = param( $params[$i] );
            my @prims = split /\//, $col;
            $col = shift @prims;
            my $eid = 'where ';
            if ( $#p_key > 0 ) {
                for ( my $j = 0 ; $j < $#p_key ; $j++ ) {
                    $eid .= $m_dbh->quote_identifier( $p_key[$j] ) . ' = ' . $m_oDatabase->quote( $prims[$j] ) . ' && ';
                } ## end for ( my $j = 0 ; $j < ...)
                $eid .= $m_dbh->quote_identifier( $p_key[$#p_key] ) . ' = ' . $m_oDatabase->quote( $prims[$#p_key] );
            } else {
                $eid .=
                  $m_dbh->quote_identifier( $p_key[0] ) . ' = ' . $m_oDatabase->quote( $prims[0] );
            } ## end else [ if ( $#p_key > 0 ) ]
          SWITCH: {
                if ( $a eq 'delete' ) {
                    $m_oDatabase->void("DELETE FROM $tbl2 $eid");
                    last SWITCH;
                } ## end if ( $a eq 'delete' )
                if ( $a eq 'deleteUser' ) {
                    my ( $u, $h ) = split /\//, $col;
                    $u = $m_oDatabase->quote($u);
                    $h = $m_oDatabase->quote($h);
                    $u .= "&& Host = $h" if ( $h ne 'NULL' );
                    $m_oDatabase->void("DELETE FROM mysql.user where user  = $u");
                    last SWITCH;
                } ## end if ( $a eq 'deleteUser')
                if ( $a eq 'truncate' ) {
                    $m_oDatabase->void("truncate $tbl2");
                    last SWITCH;
                } ## end if ( $a eq 'truncate' )
                if ( $a eq 'export' ) {
                    my $a       = $m_oDatabase->fetch_hashref("select * from $tbl2 $eid");
                    my @columns = $m_oDatabase->fetch_AoH("show columns from $tbl2");
                    print "INSERT INTO $tbl (";
                    for ( my $j = 0 ; $j <= $#columns ; $j++ ) {
                        print $m_dbh->quote_identifier( $columns[$j]->{'Field'} );
                        print "," if ( $j < $#columns );
                    } ## end for ( my $j = 0 ; $j <=...)
                    print ') values(';
                    for ( my $j = 0 ; $j <= $#columns ; $j++ ) {
                        print $m_oDatabase->quote( $a->{ $columns[$j]->{'Field'} } );
                        print "," if ( $j < $#columns );
                    } ## end for ( my $j = 0 ; $j <=...)
                    print ");$/";
                    last SWITCH;
                } ## end if ( $a eq 'export' )
            } ## end SWITCH:
        } ## end if ( $params[$i] =~ /markBox\d?/)
    } ## end for ( my $i = 0 ; $i <=...)
    if ( $a eq 'export' ) {
        print '</textarea></div>';
    } elsif ( $a eq 'deleteUser' ) {
        ShowUsers();
    } else {
        ShowTable($tbl);
    } ## end else [ if ( $a eq 'export' ) ]
} ## end sub MultipleAction

=head2 MultipleDbAction

Action: Multiple Database Actions

=cut

sub MultipleDbAction {
    my $a      = param('MultipleDbAction');
    my @params = param();
    if ( $a eq 'export' ) {
        ShowDbHeader( $m_sCurrentDb, 0, 'Export' );
        print q(<div align="left" class="dumpBox"><textarea style="width:100%;height:800px;">);
    } ## end if ( $a eq 'export' )
    if ( $a eq 'exportDb' ) {
        ShowDbHeader( $m_sCurrentDb, 0, 'Export' );
        print q(<div align="left" class="dumpBox"><textarea style="width:100%;height:800px;">);
    } ## end if ( $a eq 'exportDb' )
    for ( my $i = 0 ; $i <= $#params ; $i++ ) {
        if ( $params[$i] =~ /markBox\d?/ ) {
            my $tbl  = param( $params[$i] );
            my $tbl2 = $m_dbh->quote_identifier($tbl);
          SWITCH: {
                if ( $a eq 'dropDb' ) {
                    $m_oDatabase->void("Drop database $tbl2");
                    last SWITCH;
                } ## end if ( $a eq 'dropDb' )
                if ( $a eq 'exportDb' ) {
                    DumpDatabase($tbl);
                } ## end if ( $a eq 'exportDb' )
                if ( $a eq 'delete' ) {
                    $m_oDatabase->void("Drop table $tbl2");
                    last SWITCH;
                } ## end if ( $a eq 'delete' )
                if ( $a eq 'export' ) {
                    DumpTable($tbl);
                    last SWITCH;
                } ## end if ( $a eq 'export' )
                if ( $a eq 'truncate' ) {
                    $m_oDatabase->void("Truncate $tbl2");
                    last SWITCH;
                } ## end if ( $a eq 'truncate' )
                if ( $a eq 'optimize' ) {
                    $m_oDatabase->void("OPTIMIZE TABLE $tbl2");
                    last SWITCH;
                } ## end if ( $a eq 'optimize' )
                if ( $a eq 'analyze' ) {
                    $m_oDatabase->void("ANALYZE TABLE $tbl2");
                    last SWITCH;
                } ## end if ( $a eq 'analyze' )
                if ( $a eq 'repair' ) {
                    $m_oDatabase->void("REPAIR TABLE $tbl2");
                    last SWITCH;
                } ## end if ( $a eq 'repair' )
            } ## end SWITCH:
        } ## end if ( $params[$i] =~ /markBox\d?/)
    } ## end for ( my $i = 0 ; $i <=...)
    if ( $a eq 'exportDb' || $a eq 'export' ) {
        print qq(</textarea></div>);
    } else {
        if ( $a eq 'dropDb' ) {
            ShowDatabases();
        } else {
            ShowTables();
        } ## end else [ if ( $a eq 'dropDb' ) ]
    } ## end else [ if ( $a eq 'exportDb' ...)]
} ## end sub MultipleDbAction

=head2 EditEntry()

Action:

     EditEntry( $table, $id )
     
     In void context param('table') and param('edit') will be used.

=cut

sub EditEntry {
    my $tbl = defined param('table') ? param('table') : 0;
    my $rid = defined param('edit')  ? param('edit')  : 0;
    if ( $m_oDatabase->tableExists($tbl) ) {
        my $tbl2    = $m_dbh->quote_identifier($tbl);
        my @caption = $m_oDatabase->fetch_AoH("show columns from $tbl2");
        my $eid     = 'where ';
        my @p_key   = $m_oDatabase->GetPrimaryKey($tbl);
        if ( $#p_key > 0 ) {
            for ( my $j = 0 ; $j < $#p_key ; $j++ ) {
                $eid .= "$p_key[$j] = " . $m_oDatabase->quote( param( $p_key[$j] ) ) . ' && ';
            } ## end for ( my $j = 0 ; $j < ...)
            $eid .= "$p_key[$#p_key] = " . $m_oDatabase->quote( param( $p_key[$#p_key] ) );
        } else {
            $eid .=
              "$p_key[0] = " . $m_oDatabase->quote( param( $p_key[0] ) ? param( $p_key[0] ) : $rid );
        } ## end else [ if ( $#p_key > 0 ) ]
        my $a = $m_oDatabase->fetch_hashref("select * from $tbl2 $eid");
        $RIBBONCONTENT .= qq(
    <form class="EditEntry" onsubmit="submitForm(this,'SaveEntry','SaveEntry',false,'POST');return false;" method="get" enctype="multipart/form-data">
    <input type="hidden" name="action" value="SaveEntry"/>
    <input type="hidden" name="id" value="$rid"/>
    <input type="hidden" name="table" value="$tbl"/>
    <input type="hidden" name="von" value="$m_nStart"/>
    <input type="hidden" name="bis" value="$m_nEnd"/>
    <input type="hidden" name="primaryKey" value="$a->{$p_key[0]}"/>
    <table class="ShowTables">
    <tr class="caption">
    <td class="caption captionLeft">Field</td>
    <td class="caption">Value</td>
    <td class="caption">Type</td>
    <td class="caption">Null</td>
    <td class="caption">Key</td>
    <td class="caption">Default</td>
    <td class="caption captionRight">Extra</td>
    </tr>);
        for ( my $j = 0 ; $j <= $#caption ; $j++ ) {
            $caption[$j]->{'Type'} = uc $caption[$j]->{'Type'};
          SWITCH: {
                if ( $caption[$j]->{'Type'} eq 'TEXT' ) {
                    $RIBBONCONTENT .=
qq(<tr><td class="values">$caption[$j]->{'Field'}</td><td class="values"><textarea name="tbl$caption[$j]->{'Field'}" >$a->{$caption[$j]->{'Field'}}</textarea></td><td class="values">$caption[$j]->{'Type'}</td><td>$caption[$j]->{'Null'}</td><td class="values">$caption[$j]->{'Key'}</td><td class="values">$caption[$j]->{'Default'}</td><td class="values">$caption[$j]->{'Extra'}</td></tr>);
                    last SWITCH;
                } ## end if ( $caption[$j]->{'Type'...})
                if ( $caption[$j]->{'Type'} =~ /BLOB|LONGBLOB|MEDIUMBLOB|TINYBLOB/ ) {
                    $RIBBONCONTENT .= qq(
          <tr>
          <td class="values">$caption[$j]->{'Field'}</td>
          <td class="values"><input type="file" type="file" name="tbl$caption[$j]->{Field}"/></td>
          <td class="values">$caption[$j]->{'Type'}</td>
          <td class="values">$caption[$j]->{'Null'}</td>
          <td class="values">$caption[$j]->{'Key'}</td>
          <td class="values">$caption[$j]->{'Default'}</td>
          <td class="values">$caption[$j]->{'Extra'}</td>
          </tr>);
                    last SWITCH;
                } ## end if ( $caption[$j]->{'Type'...})
                $RIBBONCONTENT .= qq(<tr>
        <td class="values">$caption[$j]->{'Field'}</td>
        <td class="values"><input type="text" name="tbl$caption[$j]->{'Field'}" value="$a->{$caption[$j]->{'Field'}}" align="left"/></td>
        <td class="values">$caption[$j]->{'Type'}</td>
        <td class="values">$caption[$j]->{'Null'}</td>
        <td class="values">$caption[$j]->{'Key'}</td>
        <td class="values">$caption[$j]->{'Default'}</td>
        <td class="values">$caption[$j]->{'Extra'}</td>
        </tr>);
            } ## end SWITCH:
        } ## end for ( my $j = 0 ; $j <=...)
        my $trsave = translate('save');
        $RIBBONCONTENT .= qq(<tr><td colspan="7" class="submit"><input type="submit" value="$trsave"/></td></tr></table></form>);
        ShowTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub EditEntry

=head2 SaveUpload

Action: SaveUpload

=cut

sub SaveUpload {
    my $tbl             = shift;
    my $column          = shift;
    my $paramFile       = shift;
    my $primaryKey      = shift;
    my $primaryKeyValue = shift;
    my $tbl2            = $m_dbh->quote_identifier($tbl);
    if ($paramFile) {
        my $up = upload($paramFile);
        my $file;
        while (<$up>) {
            $file .= $_;
        } ## end while (<$up>)
        $m_oDatabase->void( "update $tbl2 set $column = ? where $primaryKey = ? ", $file, $primaryKeyValue );
    } ## end if ($paramFile)
} ## end sub SaveUpload

=head2 downLoadFile

action: downLoadFile ( col, table, param)

=cut

sub downLoadFile {
    my $tbl       = defined param('table')     ? param('table')     : shift;
    my $pkeyValue = defined param('pkeyValue') ? param('pkeyValue') : shift;
    my $pkey      = defined param('pkey')      ? param('pkey')      : shift;
    my $blob      = defined param('blob')      ? param('blob')      : shift;
    my $tbl2      = $m_dbh->quote_identifier($tbl);
    my $pkey2     = $m_dbh->quote_identifier($pkey);
    my $blob2     = $m_dbh->quote_identifier($blob);
    my $sql       = "SELECT $blob2 FROM $tbl2 where $pkey2 = ? ";
    my $sth       = $m_dbh->prepare($sql);
    $sth->execute($pkeyValue);
    my $rows_affected = $sth->rows;
    warn $m_dbh->errstr . br() . HighlightSQl($sql) if $m_dbh->errstr;
    my @rows = $sth->fetchrow_array();
    my $dh;
    opendir( $dh, $m_hrSettings->{uploads}{path} ) or warn $!;
    my @files = grep { /.*/ } readdir($dh);
    closedir $dh;
    chdir( $m_hrSettings->{uploads}{path} );
    unlink(@files);
    my $fh = gensym();
    open $fh, ">$m_hrSettings->{uploads}{path}/$pkeyValue.bak"
      or warn "tables::downLoadFile: $m_hrSettings->{uploads}{path}/$pkeyValue.bak $!";
    print $fh $rows[0];
    close $fh;
    my $trDownload = translate('download');
    rename "$m_hrSettings->{uploads}{path}/$pkeyValue.bak", "$m_hrSettings->{uploads}{path}/$pkeyValue"
      or warn "tables::downLoadFile: $!";
    chmod "$m_hrSettings->{uploads}{chmod}", "$m_hrSettings->{uploads}{path}/$pkeyValue"
      if -e "$m_hrSettings->{uploads}{path}/$pkeyValue";
    print qq|<a href="download/$pkeyValue" target="_blank">$trDownload</a>|;
    &ShowTable();
} ## end sub downLoadFile

=head2 ShowNewEntry

Action: In void context param ( 'table' ) will be used.

=cut

sub ShowNewEntry {
    my $tbl = param('table') ? param('table') : shift;
    if ( $m_oDatabase->tableExists($tbl) ) {
        my $tbl2     = $m_dbh->quote_identifier($tbl);
        my @caption  = $m_oDatabase->fetch_AoH("show columns from $tbl2");
        my $newentry = translate('NewEntry');
        print qq(
    <form class="dbForm" onsubmit="submitForm(this,'NewEntry','NewEntry');return false;" method="POST" name="action" enctype="multipart/form-data">
    <input type="hidden" name="action" value="NewEntry"/>
    <input type="hidden" name="table" value="$tbl"/>
    <input type="hidden" name="von" value="$m_nStart"/>
    <input type="hidden" name="bis" value="$m_nEnd"/>
    <table width="100%">
    <tr>
    <td class="caption3">Field</td>
    <td class="caption3">Value</td>
    <td class="caption3">exit</td>
    <td class="caption3">Null</td>
    <td class="caption3">Key</td>
    <td class="caption3">Default</td>
    <td class="caption3">Extra</td>
    </tr>
    );
        for ( my $j = 0 ; $j <= $#caption ; $j++ ) {
            $caption[$j]->{'Type'} = uc $caption[$j]->{'Type'};
          SWITCH: {
                if ( $caption[$j]->{Type} eq 'TEXT' ) {
                    print qq(
          <tr>
          <td class="values">$caption[$j]->{Field}</td>
          <td class="values"><textarea name="tbl$caption[$j]->{'Field'}" align="left" style="width:100%"></textarea></td>
          <td class="values">$caption[$j]->{Type}</td>
          <td class="values">$caption[$j]->{Null}</td>
          <td class="values">$caption[$j]->{Key}</td>
          <td class="values">$caption[$j]->{Default}</td>
          <td class="values">$caption[$j]->{Extra}</td>
          </tr>);
                    last SWITCH;
                } ## end if ( $caption[$j]->{Type...})
                if ( $caption[$j]->{Type} =~ /BLOB|LONGBLOB|MEDIUMBLOB|TINYBLOB/ ) {
                    print qq(
          <tr>
          <td class="values">$caption[$j]->{Field}</td>
          <td class="values"><input type="file" name="tbl$caption[$j]->{Field}"/></td>
          <td class="values">$caption[$j]->{Type}</td>
          <td class="values">$caption[$j]->{Null}</td>
          <td class="values">$caption[$j]->{Key}</td>
          <td class="values">$caption[$j]->{Default}</td>
          <td class="values">$caption[$j]->{Extra}</td>
          </tr>);
                    last SWITCH;
                } ## end if ( $caption[$j]->{Type...})
                print qq(
          <tr>
          <td class="values">$caption[$j]->{Field}</td>
          <td class="values"><input type="text" name="tbl$caption[$j]->{Field}" value='' align="left"/></td>
          <td class="values">$caption[$j]->{Type}</td>
          <td class="values">$caption[$j]->{Null}</td>
          <td class="values">$caption[$j]->{Key}</td>
          <td class="values">$caption[$j]->{Default}</td>
          <td class="values">$caption[$j]->{Extra}</td>
          </tr>);
            } ## end SWITCH:
        } ## end for ( my $j = 0 ; $j <=...)
        my $save = translate('save');
        print qq(<tr><td colspan="7" class="submit"><input type="submit" value="$save"/></td></tr></table></form>);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub ShowNewEntry

=head2 SaveEntry

Action:

=cut

sub SaveEntry {
    my $tbl = param('table');
    if ( $m_oDatabase->tableExists($tbl) ) {
        my @rows;
        my $eid     = 'where ';
        my @p_key   = $m_oDatabase->GetPrimaryKey($tbl);
        my $tbl2    = $m_dbh->quote_identifier($tbl);
        my @columns = $m_oDatabase->fetch_AoH("show full columns from $tbl2");
        my @uploads;
        my @params          = param();
        my $primaryKey      = $p_key[0];
        my $primaryKeyValue = param('primaryKey');
        my $i               = 0;

        while ( $i < $#params ) {
            $i++;
            my $pa = param( $params[$i] );
            if (   $columns[$i]->{Type} eq 'blob'
                or $columns[$i]->{Type} eq 'longblob'
                or $columns[$i]->{Type} eq 'tinyblob'
                or $columns[$i]->{Type} eq 'mediumblob' ) {
                push @uploads,
                  {
                    table => $tbl,
                    field => $columns[$i]->{Field},
                    param => "tbl$columns[$i]->{Field}",
                  };
            } elsif ( $params[$i] =~ /tbl.*/ ) {
                $params[$i] =~ s/tbl//;

                #     $primaryKeyValue = $pa if $params[$i] eq $p_key[0];
                if ( $#p_key > 0 ) {
                    for ( my $j = 0 ; $j < $#p_key ; $j++ ) {
                        $eid .= "$p_key[$j] = " . $m_oDatabase->quote($pa) . ' && '
                          if $params[$i] eq $p_key[$j];
                    } ## end for ( my $j = 0 ; $j < ...)
                    $eid .= "$p_key[$#p_key] = " . $m_oDatabase->quote($pa)
                      if $params[$i] eq $p_key[$#p_key];
                } else {
                    $eid .= "$p_key[0] = " . $m_oDatabase->quote($primaryKeyValue)
                      if $params[$i] eq $p_key[0];
                } ## end else [ if ( $#p_key > 0 ) ]
                unshift @rows, '' . $m_dbh->quote_identifier( $params[$i] ) . ' = ' . $m_oDatabase->quote($pa);
            } ## end elsif ( $params[$i] =~ /tbl.*/)
        } ## end while ( $i < $#params )
        my $sql = "update $tbl set " . join( ',', @rows ) . " $eid";
        ExecSql($sql);
        for ( my $i = 0 ; $i <= $#uploads ; $i++ ) {
            SaveUpload( $uploads[$i]->{table}, $uploads[$i]->{field}, $uploads[$i]->{param}, $primaryKey, $primaryKeyValue );
        } ## end for ( my $i = 0 ; $i <=...)
        ShowTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub SaveEntry

=head2 NewEntry

Action:

=cut

sub NewEntry {
    my @params = param();
    my $tbl    = param('table');
    my @uploads;
    my @p_key = $m_oDatabase->GetPrimaryKey($tbl);
    my $primaryKeyValue;
    if ( $m_oDatabase->tableExists($tbl) ) {
        my $tbl2    = $m_dbh->quote_identifier($tbl);
        my $sql     = "INSERT INTO $tbl2 VALUES(";
        my $i       = 0;
        my $blob    = 1;
        my $bFirst  = 1;
        my @columns = $m_oDatabase->fetch_AoH("show full columns from $tbl2");
        while ( $i < $#params ) {
            $i++;
            my $pa = param( $params[$i] );
            if (
                $columns[$i]->{Type}
                && (   $columns[$i]->{Type} eq 'blob'
                    or $columns[$i]->{Type} eq 'longblob'
                    or $columns[$i]->{Type} eq 'tinyblob'
                    or $columns[$i]->{Type} eq 'mediumblob' )
            ) {
                push @uploads,
                  {
                    table           => $tbl,
                    field           => $columns[$i]->{Field},
                    param           => "tbl$columns[$i]->{Field}",
                    primaryKey      => $p_key[0],
                    primaryKeyValue => $pa
                  };
                $blob++ unless $bFirst;
                $bFirst = 0;
            } elsif ( $params[$i] =~ /tbl.*/ ) {
                $params[$i] =~ s/tbl//;
                $primaryKeyValue = $pa if $params[$i] eq $p_key[0];
                $sql .= $m_oDatabase->quote($pa);
                $sql .= "," if ( $i < $#params - $blob );
            } ## end elsif ( $params[$i] =~ /tbl.*/)
        } ## end while ( $i < $#params )
        $sql .= ');';
        ExecSql($sql);
        for ( my $i = 0 ; $i <= $#uploads ; $i++ ) {
            SaveUpload( $uploads[$i]->{table}, $uploads[$i]->{field}, $uploads[$i]->{param}, $p_key[0], $primaryKeyValue );
        } ## end for ( my $i = 0 ; $i <=...)
        ShowTable( param('table') );
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub NewEntry

=head2 DeleteEntry

Action: In void context param('table') will ne used.

=cut

sub DeleteEntry {
    my $tbl = param('table') ? param('table') : shift;
    if ( $m_oDatabase->tableExists($tbl) ) {
        my $tbl2  = $m_dbh->quote_identifier($tbl);
        my $eid   = 'where ';
        my @p_key = $m_oDatabase->GetPrimaryKey($tbl);
        if ( $#p_key > 0 ) {
            for ( my $j = 0 ; $j < $#p_key ; $j++ ) {
                $eid .= "$p_key[$j] = " . $m_oDatabase->quote( param( $p_key[$j] ) ) . ' && ';
            } ## end for ( my $j = 0 ; $j < ...)
            $eid .= "$p_key[$#p_key] = " . $m_oDatabase->quote( param( $p_key[$#p_key] ) );
        } else {
            $eid .= "$p_key[0] = " . $m_oDatabase->quote( param( $p_key[0] ) );
        } ## end else [ if ( $#p_key > 0 ) ]
        $p_key = $m_dbh->quote_identifier($p_key);
        ExecSql("DELETE FROM $tbl2 $eid");
        ShowTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub DeleteEntry

=head2 round
  
private

=cut

sub round {
    my $x = shift;
    $x = $x ? $x : 0;

    #no warnings 'numeric';
    floor( $x + 0.5 ) if ( $x =~ /\d+/ );
    return $x;
} ## end sub round

=head2 ShowTables

Action:

=cut

sub ShowTables {
    my @a       = $m_oDatabase->fetch_AoH('SHOW TABLE STATUS');
    my $orderby = defined param('orderBy') ? param('orderBy') : 'Name';
    my $state   = param('desc') ? 1 : 0;
    my $nstate  = $state ? 0 : 1;
    my $lpp     = defined param('links_pro_page') ? param('links_pro_page') : 30;
    $lpp = $lpp =~ /(\d\d\d?)/ ? $1 : $lpp;
    my $end = $m_nStart + $lpp > $#a ? $#a : $m_nStart + $lpp;
    if ( $#a > $lpp ) {
        my %needed = (
            start          => $m_nStart,
            length         => $#a,
            style          => $m_sStyle,
            action         => 'ShowTables',
            append         => "&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=$lpp&orderBy=$orderby&desc=$state",
            path           => $m_hrSettings->{cgi}{bin},
            links_pro_page => $lpp,
            server         => "$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}",
        );
        $PAGES = makePages( \%needed );
    } else {
        $PAGES = '';
        $end   = $#a;
    } ## end else [ if ( $#a > $lpp ) ]

    no warnings;    #don't want flood the eror.log with "non numeric" warnings .
    @a = sort { round( $a->{$orderby} ) <=> round( $b->{$orderby} ) } @a;
    @a = reverse @a if $state;
    ShowDbHeader( $m_sCurrentDb, 0, 'Show' );
    my $toolbar = a(
        {
            class   => 'toolbarButton',
            onclick => q|showPopup('CreateTable')|,
            title   => translate('showcreatetable'),
        },
        translate('showcreatetable')
    );    #1
    $toolbar .= a(
        {
            class => 'toolbarButton',
            onclick =>
              "requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDumpDatabase','ShowDumpDatabase','ShowDumpDatabase');",
            title => translate('ShowDumpDatabase')
        },
        translate('ShowDumpDatabase')
    );    #2
    $toolbar .= a(
        {
            class   => 'toolbarButton',
            onclick => q|showPopup('SqlSearch')|,
            title   => translate('search') . "($m_sCurrentDb)"
        },
        translate('search')
    );    #2
    $toolbar .= a(
        {
            class   => 'toolbarButton',
            onclick => 'showSQLEditor()',
            title   => translate('SQL')
        },
        translate('SQL')
    );    #3
    my $menu = div(
        { align => 'right' },
        translate('links_pro_page') . ' | '
          . (
            $#a > 10
            ? a(
                {
                    href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=10&von=$m_nStart&orderBy=$orderby&desc=$state','ShowTables','ShowTables')",
                    class => $lpp == 10 ? 'menuLink2' : 'menuLink3'
                },
                '10'
              )
            : ''
          )
          . (
            $#a > 20
            ? '&#160;'
              . a(
                {
                    href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=20&von=$m_nStart&orderBy=$orderby&desc=$state','ShowTables','ShowTables')",
                    class => $lpp == 20 ? 'menuLink2' : 'menuLink3'
                },
                '20'
              )
            : ''
          )
          . (
            $#a > 30
            ? '&#160;'
              . a(
                {
                    href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=30&von=$m_nStart&orderBy=$orderby&desc=$state','ShowTables','ShowTables')",
                    class => $lpp == 30 ? 'menuLink2' : 'menuLink3'
                },
                '30'
              )
            : ''
          )
          . (
            $#a > 100
            ? '&#160;'
              . a(
                {
                    href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=100&von=$m_nStart&orderBy=$orderby&desc=$state','ShowTables','ShowTables')",
                    class => $lpp == 100 ? 'menuLink2' : 'menuLink3'
                },
                '100'
              )
            : ''
          )
          . (
            $#a > 100
            ? '&#160;'
              . a(
                {
                    href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=1000&von=$m_nStart&orderBy=$orderby&desc=$state','ShowTables','ShowTables')",
                    class => $lpp == 1000 ? 'menuLink2' : 'menuLink3'
                },
                '1000'
              )
            : ''
          )
    ) if $#a > 10;
    print qq(
    <form onsubmit="submitForm(this,'MultipleDbAction','MultipleDbAction');return false;" method="get" enctype="multipart/form-data">
    <input type="hidden" name="action" value="MultipleDbAction"/>
    <table class="ShowTables" id="toolbarTable">
    <tr class="captionRadius"><td class="captionRadius" colspan="7">$m_sCurrentDb</td></tr>
    <tr><td colspan="7" id="toolbar" class="toolbar"><div id="toolbarcontent" class="toolbarcontent">$toolbar</div></td></tr>);
    print
qq(<tr><td colspan="7" id="toolbar2" class="toolbar2"><div id="toolbarcontent2"   class="toolbarcontent"><div class="makePages">$PAGES</div><div class="pagePerSite">$menu</div></div></td></tr>)
      if $#a > $lpp;
    print q(<tr class="caption2"><td class="caption2 checkbox"></td><td class="caption2">)
      . qq(<a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=$lpp&von=$m_nStart&orderBy=Name&desc=$nstate','ShowTables','ShowTables')">Name</a>)
      . (
          $orderby eq 'Name'
        ? $state
              ? qq|&#160;<img src="style/$m_sStyle/buttons/up.png" />|
              : qq|&#160;<img src="style/$m_sStyle/buttons/down.png"   />|
        : ''
      )
      . qq(</td><td class="caption2"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=$lpp&von=$m_nStart&orderBy=Rows&desc=$nstate','ShowTables','ShowTables')">$m_hrLng->{$ACCEPT_LANGUAGE}{rows}</a>)
      . (
          $orderby eq 'Rows'
        ? $state
              ? qq|&#160;<img src="style/$m_sStyle/buttons/up.png" />|
              : qq|&#160;<img src="style/$m_sStyle/buttons/down.png" />|
        : ''
      )
      . q(</td><td class="caption2"> )
      . qq(<a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=$lpp&von=$m_nStart&orderBy=Type&desc=$nstate','ShowTables','ShowTables')">$m_hrLng->{$ACCEPT_LANGUAGE}{type}</a>)
      . (
          $orderby eq 'Type'
        ? $state
              ? qq|&#160;<img src="style/$m_sStyle/buttons/up.png"/>|
              : qq|&#160;<img src="style/$m_sStyle/buttons/down.png"/>|
        : ''
      )
      . q(</td><td class="caption2"> )
      . qq(<a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&db=$m_sCurrentDb&von=$m_nStart&bis=$m_nEnd&links_pro_page=$lpp&von=$m_nStart&orderBy=Data_length&desc=$nstate','ShowTables','ShowTables')">$m_hrLng->{$ACCEPT_LANGUAGE}{size}&#160;(kb)</a>)
      . (
          $orderby eq 'Data_length'
        ? $state
              ? qq|&#160;<img src="style/$m_sStyle/buttons/up.png"/>|
              : qq|&#160;<img src="style/$m_sStyle/buttons/down.png"/>|
        : ''
      ) . q(</td><td class="caption2 checkbox"></td></tr>);
    my $trdatabase = translate('database');
    my $trdelete   = translate('delete');
    my $change     = translate('EditTable');

    for ( my $i = $m_nStart ; $i <= $end ; $i++ ) {
        my $kb    = sprintf( '%.2f', ( $a[$i]->{Index_length} + $a[$i]->{Data_length} ) / 1024 );
        my $eid   = '';
        my @p_key = $m_oDatabase->GetPrimaryKey( $a[$i]->{Name} );
        if ( $#p_key > 0 ) {
            for ( my $j = 0 ; $j < $#p_key ; $j++ ) {
                $eid .= "$p_key[$j]=$a[$i]->{$p_key[$j]}&";
            } ## end for ( my $j = 0 ; $j < ...)
            $eid .= "$p_key[$#p_key]=$a[$i]->{ $p_key[$#p_key]}";
        } else {
            $eid .= "$p_key[0]=$a[$i]->{$p_key[0]}" if defined $p_key[0];
        } ## end else [ if ( $#p_key > 0 ) ]
        print qq(
      <tr>
      <td class="checkbox" width="5%"><input type="checkbox" name="markBox$i" class="markBox" value="$a[$i]->{Name}" /></td>
      <td class="values" width="10%"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTable&table=$a[$i]->{Name}&desc=0','showTable','showTable')">$a[$i]->{Name}</a></td>
      <td class="values" width="10%">$a[$i]->{Rows}</td>
      <td class="values" width="10%">$a[$i]->{Engine}</td>
      <td class="values" width="15%">$kb</td>
      <td class="values right" width="*">
      <img src="style/$m_sStyle/buttons/delete.png" title="$trdelete"  style="cursor:pointer;" onclick="confirm2(' $trdelete?',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=DropTable&table=$a[$i]->{Name}&$eid','DropTable','DropTable')"/>
      <img src="style/$m_sStyle/buttons/edit.png"  alt="$change" style="cursor:pointer;" title="$change" onclick="requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=EditTable&table=$a[$i]->{Name}&$eid','EditTable','EditTable')"/>
      <img src="style/$m_sStyle/buttons/details.png"  style="cursor:pointer;" alt="Details" title="Details" onclick="requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTableDetails&table=$a[$i]->{Name}&$eid','ShowTableDetails','ShowTableDetails')"/></td>
      </tr>
      );
    } ## end for ( my $i = $m_nStart...)
    my $delete   = translate('delete');
    my $mmark    = translate('selected');
    my $markAll  = translate('select_all');
    my $umarkAll = translate('unselect_all');
    my $export   = translate('export');
    my $truncate = translate('truncate');
    my $optimize = translate('optimize');
    my $repair   = translate('repair');
    print qq| 
    <tr>
    <td class="checkbox"><img src="style/$m_sStyle/buttons/feil.gif" alt=''/></td>
    <td colspan="7" align="left">
    <table class="MultipleDbAction" width="100%">
    <tr><td align="left">
    <a id="markAll" href="javascript:markInput(true);" class="links">$markAll</a><a class="links" id="umarkAll" style="display:none;" href="javascript:markInput(false);">$umarkAll</a></td>
    <td class="submit">
    <select name="MultipleDbAction" class="MultipleAction" onchange="if(this.value != '$mmark' )submitForm(this.form,this.value,this.value);">
    <option value="$mmark" selected="selected">$mmark</option>
    <option value="delete">$delete</option>
    <option value="export">$export</option>
    <option value="truncate">$truncate</option>
    <option value="optimize">$optimize</option>
    <option value="repair">$repair</option>
    </select></td>
    </tr></table>
    </td>
    </tr>
    </table>
    </form>|;
} ## end sub ShowTables

=head2 DropTable

Action:

=cut

sub DropTable {
    my $tbl = param('table');
    if ( $m_oDatabase->tableExists($tbl) ) {
        $tbl = $m_dbh->quote_identifier($tbl);
        ExecSql("drop table $tbl");
    } ## end if ( $m_oDatabase->tableExists...)
    ShowTables();
} ## end sub DropTable

=head2 ShowTableDetails

Action:

=cut

sub ShowTableDetails {
    my $tbl = defined $_[0] ? shift : param('table');
    ShowDbHeader( $tbl, 1, 'Details' );
    my @a = $m_oDatabase->fetch_AoH('SHOW TABLE STATUS');
    print qq(
  <table class="ShowTables">
  <tr><td class="captionRadius borderBottom" colspan="3">$tbl</td></tr>
  <tr>
  <td class="caption3">Name</td>
  <td class="caption3">Value</td>
  </tr>);

    # no warnings;
    my $name = param('table');
    for ( my $i = 0 ; $i <= $#a ; $i++ ) {
        if ( $a[$i]->{Name} eq $name ) {
            foreach my $key ( keys %{ $a[0] } ) {
                print qq(<tr class="values"><td class="values">$key</td><td class="values">$a[$i]->{$key}</td></tr>);
            } ## end foreach my $key ( keys %{ $a...})
        } ## end if ( $a[$i]->{Name} eq...)
    } ## end for ( my $i = 0 ; $i <=...)
    print '</table>';
} ## end sub ShowTableDetails

=head2 AddPrimaryKey

action:

=cut

sub AddPrimaryKey {
    my $tbl = defined $_[0] ? shift : param('table');
    my $col = defined $_[0] ? shift : param('column');
    if ( defined $tbl and defined $col ) {
        my @pkeys = $m_oDatabase->GetPrimaryKey($tbl);
        my $tbl   = $m_dbh->quote_identifier($tbl);
        $col = $m_dbh->quote_identifier($col);
        if ( $#pkeys > 0 ) {
            ExecSql("ALTER TABLE $tbl DROP PRIMARY KEY, ADD PRIMARY KEY($col);");
        } else {
            ExecSql("ALTER TABLE $tbl ADD PRIMARY KEY($col);");
        } ## end else [ if ( $#pkeys > 0 ) ]
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $tbl and ...)]
} ## end sub AddPrimaryKey

=head2 DropCol($table,$column)

Action:

=cut

sub DropCol {
    my $tbl = defined $_[0] ? shift : param('table');
    my $col = defined $_[0] ? shift : param('column');
    if ( defined $tbl and defined $col ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        $col = $m_dbh->quote_identifier($col);
        ExecSql("ALTER TABLE $tbl2 DROP COLUMN $col;");
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $tbl and ...)]
} ## end sub DropCol

=head2 TruncateTable($table)

Action:

=cut

sub TruncateTable {
    my $tbl = defined $_[0] ? shift : param('table');
    if ( $m_oDatabase->tableExists($tbl) ) {
        $tbl = $m_dbh->quote_identifier($tbl);
        ExecSql(" TRUNCATE TABLE $tbl");
    } ## end if ( $m_oDatabase->tableExists...)
    ShowTables();
} ## end sub TruncateTable

=head2 EditTable($table)

Action:

=cut

sub EditTable {
    my $tbl = defined $_[0] ? shift : param('table');
    if ( $m_oDatabase->tableExists($tbl) ) {
        my $tbl2     = $m_dbh->quote_identifier($tbl);
        my @caption  = $m_oDatabase->fetch_AoH("show full columns from $tbl2");
        my @p_key    = $m_oDatabase->GetPrimaryKey($tbl);
        my @indexes  = $m_oDatabase->getIndex($tbl);
        my $newentry = translate('editTableProps');
        my $rename   = translate('rename');
        my $save     = translate('save');
        ShowDbHeader( $tbl, 1, 'Edit' );
        my $toolbar = a(
            {
                class   => 'toolbarButton',
                onclick => "requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTable&table=$tbl','ShowTable','ShowTable')",
                title   => translate('Show') . "($tbl)"
            },
            translate('Show') . "($tbl)"
        );    #1
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => q|showPopup('SqlSearch')|,
                title   => translate('search'),
            },
            translate('search')
        );    #2
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => 'showSQLEditor()',
                title   => translate('SQL')
            },
            translate('SQL')
        );    #3
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => q|showPopup('ChangeCharset')|,
                title   => translate('ChangeCharset')
            },
            translate('ChangeCharset')
        );    #4
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => q|showPopup('ChangeAutoInCrementValue')|,
                title   => translate('ChangeAutoInCrementValue')
            },
            translate('ChangeAutoInCrementValue')
        ) . br();    #5
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => q|showPopup('ChangeEngine')|,
                title   => translate('ChangeEngine')
            },
            translate('ChangeEngine')
        );           #5
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => q|showPopup('RenameTable')|,
                title   => translate('rename')
            },
            translate('rename')
        );           #6
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => q|showPopup('ShowEditIndex')|,
                title   => translate('ShowEditIndex')
            },
            translate('ShowEditIndex')
        );           #7
        $toolbar .= a(
            {
                class   => 'toolbarButton',
                onclick => 'ShowNewRow()',
                title   => translate('ShowNewRow')
            },
            translate('ShowNewRow')
        );           #7
        print qq(
    <form onsubmit="setAll();submitForm(this,'SaveEditTable','SaveEditTable');return false;" method="get" enctype="multipart/form-data">
    <input type="hidden" name="action" value="SaveEditTable"/>
    <table class="ShowTables" id="toolbarTable">
    <tr class="captionRadius">
    <td class="captionRadius" colspan="14">$tbl</td></tr>
    <tr><td colspan="14" id="toolbar" class="toolbar"><div id="toolbarcontent"  class="toolbarcontent">$toolbar</div></td></tr>
    );
        print qq|
    <tr class="caption2">
    <td class="caption2">Field</td>
    <td class="caption2">Type</td>
    <td class="caption2">Length</td>
    <td class="caption2">Null</td>
    <td class="caption2">Default</td>
    <td class="caption2">Extra</td>
    <td class="caption2">Collation</td>
    <td class="caption2">Attribute</td>
    <td class="caption2">Comment</td>
    <td class="caption2 checkbox"><img src="style/$m_sStyle/buttons/primary.png" title="Primary Key" align="left" /></td>
    <td class="caption2 checkbox"><img src="style/$m_sStyle/buttons/fulltext.png" title="Fulltext" align="left" /></td>
    <td class="caption2 checkbox"><img src="style/$m_sStyle/buttons/index.png" title="Index"  align="left" /></td>
    <td class="caption2 checkbox"><img src="style/$m_sStyle/buttons/unique.png" title="Unique"  align="left" /></td>
    <td class="caption2 checkbox"></td>
    </tr>|;
        my %vars = (
            user   => $m_sUser,
            action => 'SaveEditTable',
            table  => $tbl,
            rows   => {}
        );
        sessionValidity( 60 * 60 * 3 );

        for ( my $j = 0 ; $j <= $#caption ; $j++ ) {
            my $field            = $caption[$j]->{'Field'};
            my $lght             = $caption[$j]->{'Type'};
            my $length           = ( $lght =~ /\((\d+)\)/ ) ? $1 : '';
            my $sUniqueField     = Unique();
            my $sUniqueType      = Unique();
            my $sUniqueLength    = Unique();
            my $sUniqueNull      = Unique();
            my $sUniqueDefault   = Unique();
            my $sUniqueExtra     = Unique();
            my $sUniqueComment   = Unique();
            my $sUniqueCollation = Unique();
            my $sUniqueAttrs     = Unique();
            my $sUniquePrimary   = Unique();

            #<<
            my $sUniqueFulltext        = Unique();
            my $sUniqueIndex           = Unique();
            my $sUniqueUnique          = Unique();
            my $sUniquePrimaryKeyname  = Unique();
            my $sUniqueFulltextKeyname = Unique();
            my $sUniqueIndexKeyname    = Unique();
            my $sUniqueUniqueKeyname   = Unique();
            my ( $bPrimary, $bIndex, $bUnique, $bFulltext, $sPrimaryKeyname, $sFulltextKeyname, $sUniqueKeyname, $sKeyname ) = 0 * 8;

            for ( my $j = 0 ; $j <= $#indexes ; $j++ ) {
                if ( $indexes[$j]->{field} eq $field ) {
                    if ( $indexes[$j]->{type} eq 'KEY' ) {
                        $bIndex   = 1;
                        $sKeyname = $indexes[$j]->{name};
                    } ## end if ( $indexes[$j]->{type...})
                    if ( $indexes[$j]->{type} eq 'UNIQUE KEY' ) {
                        $bUnique        = 1;
                        $sUniqueKeyname = $indexes[$j]->{name};
                    } ## end if ( $indexes[$j]->{type...})
                    if ( $indexes[$j]->{type} eq 'FULLTEXT KEY' ) {
                        $bFulltext        = 1;
                        $sFulltextKeyname = $indexes[$j]->{name};
                    } ## end if ( $indexes[$j]->{type...})
                } ## end if ( $indexes[$j]->{field...})
            } ## end for ( my $j = 0 ; $j <=...)
            my $clm = 0;
            for ( my $j = 0 ; $j <= $#p_key ; $j++ ) {
                $bPrimary        = 1             if $p_key[$j] eq $field;
                $sPrimaryKeyname = 'PRIMARY KEY' if $p_key[$j] eq $field;
            } ## end for ( my $j = 0 ; $j <=...)
            print qq|
              <tr class="values"> 
              <td class="values"><input class="field" type="text" value="$field" name="$sUniqueField" id="$sUniqueField"/></td>
              <td class="values">|
              . GetTypes( $caption[$j]->{'Type'}, $sUniqueType, $tbl, $field, \$set ) . qq|</td>
              <td class="values"><input class="length" type="text" value="$length" name="$sUniqueLength"/></td>
              <td class="values">|
              . $m_oDatabase->GetNull( $caption[$j]->{'Null'}, $sUniqueNull ) . qq|</td>
              <td class="values"><input class="default" type="text" value="$caption[$j]->{'Default'}" name="$sUniqueDefault"/></td>
              <td class="values">|
              . $m_oDatabase->GetExtra( $caption[$j]->{'Extra'}, $sUniqueExtra ) . '</td>
              <td class="values">'
              . $m_oDatabase->GetColumnCollation( $tbl, $field, $sUniqueCollation ) . q{</td>
              <td class="values">} . $m_oDatabase->GetAttrs( $tbl, $field, $sUniqueAttrs ) . qq{</td>
              <td class="values"><input type="text" value="$caption[$j]->{Comment}" name="$sUniqueComment"/></td><td class="values">}
              . (
                $bPrimary ? qq|<input type="checkbox" name="$sUniquePrimary" title="Primary Key" checked="checked"/>|
                : qq|<input type="checkbox" name="$sUniquePrimary" title="Primary Key" /> |
              )
              . qq|<input type="hidden"  name="$sUniquePrimaryKeyname" value="$sPrimaryKeyname"/></td><td class="values">|
              . (
                $bFulltext ? qq|<input type="checkbox" name="$sUniqueFulltext" title="Fulltext" checked="checked"/>|
                : qq|<input type="checkbox" name="$sUniqueFulltext" title="Fulltext" /> |
              )
              . qq|<input type="hidden"  name="$sUniqueFulltextKeyname" value="$sFulltextKeyname"/></td><td class="values">|
              . (
                $bIndex ? qq|<input type="checkbox" name="$sUniqueIndex" title="Index" checked="checked"/>|
                : qq|<input type="checkbox" name="$sUniqueIndex" title="Index"/> |
              )
              . qq|<input type="hidden"  name="$sUniqueIndexKeyname" value="$sKeyname"/></td><td class="values">|
              . (
                $bUnique ? qq|<input type="checkbox" name="$sUniqueUnique" title="Unique" checked="checked"/>|
                : qq|<input type="checkbox" name="$sUniqueUnique" title="Unique"/> |
              )
              . qq{<input type="hidden"  name="$sUniqueUniqueKeyname"   value="$sUniqueKeyname"/></td>
              </td><td class="values right">
              <a href="javascript:void(0)" onclick="confirm2('Delete $field',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=DropCol&table=$tbl&column=$field','DropCol','DropCol')" title="$m_hrLng->{$ACCEPT_LANGUAGE}{DropColumn} $field" ><img src="style/$m_sStyle/buttons/delete.png"  align="left" /></a>
              </td>
              </tr>
        };
            $vars{rows}{$field} = {
                Field     => $sUniqueField,
                Type      => $sUniqueType,
                Length    => $sUniqueLength,
                Null      => $sUniqueNull,
                Default   => $sUniqueDefault,
                Extra     => $sUniqueExtra,
                Comment   => $sUniqueComment,
                Collation => $sUniqueCollation,
                Attrs     => $sUniqueAttrs,
                Primary   => $sUniquePrimary,
                Fulltext  => $sUniqueFulltext,
                Index     => $sUniqueIndex,
                Unique    => $sUniqueUnique,
                sPrimary  => $sUniquePrimaryKeyname,
                sFulltext => $sUniqueFulltextKeyname,
                sIndex    => $sUniqueIndexKeyname,
                sUnique   => $sUniqueUniqueKeyname,
            };
        } ## end for ( my $j = 0 ; $j <=...)

        #         clearSession();
        my $qstring = createSession( \%vars );
        print qq(
    <tr><td colspan="14" class="submit">
    <input type="submit" value="$save" align="right"/>
    <input type="hidden" name="change_col_sessionRTZHBG" value="$qstring"/>
    </form>
    </td></tr>
    </table>
    );
        my $newCol = translate('newcol');

        #Neue Zeile
        print qq(
          <div id="ShowNewRow" style="display:none;">
              <div class="dbForm">
              <form onsubmit="submitForm(this,'SaveNewColumn','SaveNewColumn');return false;" method="get" enctype="multipart/form-data">
              <input type="hidden" name="action" value="SaveNewColumn"/>
              $newCol
              <table class="listview">
              <tr class="caption3">
              <td class="caption3">Field</td>
              <td class="caption3">Type</td>
              <td class="caption3">LENGTH</td>
              <td class="caption3">Null</td>
              <td class="caption3">Default</td>
              <td class="caption3">Extra</td>
              <td class="caption3">Collation</td>
              <td class="caption3">Attribute</td>
              <td class="caption3">Comment</td>
              </tr>
        );
        sessionValidity( 60 * 60 );
        my $sUniquePrimary    = Unique();
        my $sUniqueColField   = Unique();
        my $sUniqueColType    = Unique();
        my $sUniqueColLength  = Unique();
        my $sUniqueColNull    = Unique();
        my $sUniqueColKey     = Unique();
        my $sUniqueColDefault = Unique();
        my $sUniqueColExtra   = Unique();
        my $sUniqueColComment = Unique();
        my $sUniqueColAttrs   = Unique();
        print qq|
        <tr>
        <td class="values"><input type="text" value='' name="$sUniqueColField" style="width:100px;"/></td>
        <td class="values">|
          . GetTypes( 'INT', $sUniqueColType, $tbl, $sUniqueColField ) . qq{</td>
        <td class="values"><input type="text" value='' name="$sUniqueColLength"/></td>
        <td class="values">
        <select name="$sUniqueColNull" style="width:80px;">
        <option  value="not NULL">not NULL</option>
        <option value="NULL">NULL</option>
        </select>
        </td>
        <td class="values"><input type="text" value='' id="default" onkeyup="intputMaskType('default','$sUniqueColType')" name="$sUniqueColDefault" style="width:80px;"/></td>
        <td class="values">
        <select name="$sUniqueColExtra" style="width:80px;">
        <option value=''></option>
        <option value="auto_increment">auto_increment</option>
        </select>
        </td>
        };
        my $sUniqueColCollation = Unique();
        my $sUniqueColEngine    = Unique();
        my $qstringCol          = createSession(
            {
                user      => $m_sUser,
                action    => 'SaveNewColumn',
                table     => $tbl,
                Collation => $sUniqueColCollation,
                Engine    => $sUniqueColEngine,
                rows      => {
                    Field   => $sUniqueColField,
                    Type    => $sUniqueColType,
                    Length  => $sUniqueColLength,
                    Null    => $sUniqueColNull,
                    Key     => $sUniqueColKey,
                    Default => $sUniqueColDefault,
                    Extra   => $sUniqueColExtra,
                    Comment => $sUniqueColComment,
                    Attrs   => $sUniqueColAttrs,
                    Primary => $sUniquePrimary,
                }
            }
        );
        my $sStart    = translate('startTable');
        my $sEnde     = translate('endTable');
        my $sInsert   = translate('insertAfter');
        my $sAfter    = translate('after');
        my $si        = translate('insert');
        my $collation = $m_oDatabase->GetCollation($sUniqueColCollation);
        my $atrrs     = $m_oDatabase->GetAttrs( $tbl, 'none', $sUniqueColAttrs );
        my $clmns     = $m_oDatabase->GetColumns( $tbl, 'after_name' );
        print qq(
    <td class="values">$collation</td>
    <td class="values">$atrrs</td>
    <td class="values"><input type="text" value='' name="$sUniqueColComment" align="left" style="width:80px;"/></td>
    </tr>
    <tr>
    <td colspan="10" class="submit" >
    $sInsert&#160;$sStart<input type="radio" class="radioButton" value="first"  name="after_col" />&#160;
    $sEnde&#160;<input type="radio" class="radioButton" value="last"  name="after_col" checked="checked"/>&#160;
    $sAfter&#160;<input type="radio" class="radioButton" value="after"  name="after_col"/>
    $clmns&#160;
    <input type="submit" value="$si"/>
    </td>
    </td>
    </tr>
    </table>
    <input type="hidden" name="create_new_col_seesion" value="$qstringCol"/>
    </form>
    </td></tr>
    </table>
    </form>
    </div>
    </div>
       ) . br();
        my @index = $m_oDatabase->fetch_AoH("SHOW INDEX FROM $tbl2");

        if ( $#index >= 0 ) {
            print '
        <table class="ShowTables">
        <tr class="caption">
           <td class="caption captionLeft">' . translate('Non_unique') . '</td>
           <td class="caption">' . translate('Key_name') . '</td>
           <td class="caption">' . translate('Seq_in_index') . '</td>
           <td class="caption">' . translate('Column_name') . '</td>
           <td class="caption">' . translate('Cardinality') . '</td>
           <td class="caption">' . translate('Sub_part') . '</td>
           <td class="caption">' . translate('Packed') . '</td>
           <td class="caption">' . translate('Null') . '</td>
           <td class="caption">' . translate('Index_type') . '</td>
           <td class="caption">' . translate('Comment') . '</td>
           <td class="caption"></td>
           <td class="caption captionRight"></td>
       </tr>';

            # no warnings;
            print qq|
       <tr>
       <td class="values">$_->{'Non_unique'}</td>
       <td class="values">$_->{'Key_name'}</td>
       <td class="values">$_->{'Seq_in_index'}</td>
       <td class="values">$_->{'Column_name'}</td>
       <td class="values">$_->{'Cardinality'}</td>
       <td class="values">$_->{'Sub_part'}</td>
       <td class="values">$_->{'Packed'}</td>
       <td class="values">$_->{'Null'}</td>
       <td class="values">$_->{'Index_type'}</td>
       <td class="values">$_->{'Comment'}</td>
       <td class="values"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowEditIndex&tbl=$tbl&index=$_->{'Key_name'}&editIndexOlp145656=1','ShowEditIndex','ShowEditIndex')" title="Edit Index $_->{'Key_name'}"><img src="style/$m_sStyle/buttons/edit.png" alt="Edit Index $_->{'Key_name'}" /></a></td>
       <td class="values"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=DropIndex&table=$tbl&index=$_->{'Key_name'}&constraint=$_->{'Column_name'}','DropIndex','DropIndex')" title="Drop Index $_->{'Key_name'}"><img src="style/$m_sStyle/buttons/delete.png"  align="left" /></a></td>
       </tr>| foreach @index;
            print '</table>';
        } ## end if ( $#index >= 0 )

        #Index bearbeiten
        my $sOver   = translate('over');
        my $sCols   = translate('columns');
        my $sSubmit = translate('create');
        print qq(
    <table width="100%">
    <tr><td>
    <div id="ShowEditIndex" style="display:none;">
    <div class="dbForm">
    <form class="dbForm" onsubmit="submitForm(this,'ShowEditIndex','ShowEditIndex');return false;" method="get" enctype="multipart/form-data">
    $sOver&#160;<input type="text" class="text" value="1"  name="over_cols" style="width:40px"/>&#160;
    $sCols&#160;<input type="submit" class="button" value="$sSubmit"  name="submit"/>
    <input type="hidden" value="ShowEditIndex" name="action"/>
    <input type="hidden" value="$tbl" name="tbl"/>
    </form>
    </div>
    </div>
    <div id="RenameTable" style="display:none;">
    <div class="dbForm">
    <form class="dbForm" onsubmit="submitForm(this,'RenameTable','RenameTable');return false;" enctype="multipart/form-data" accept-charset="utf-8">
    <input type="hidden" name="action" value="RenameTable"/>
    <input type="hidden" name="table" value="$tbl"/>
    <input type="text" name="newTable" value="$tbl"/>
    <input type="submit" name="submit" value="$rename"/>
    </form>
    </div>
    </div>
    </td>
    </tr>
    <tr>
    <td>
    <div id="ChangeEngine" style="display:none;">
    <div class="dbForm"><form class="dbForm" onsubmit="submitForm(this,'ChangeEngine','ChangeEngine');return false;" method="get" enctype="multipart/form-data">
    ) . $m_oDatabase->GetEngines( $tbl, 'engine' ) . q|
    <input type="submit" value="| . translate('ChangeEngine') . qq|"/>
    <input type="hidden" value="ChangeEngine" name="action"/>
    <input type="hidden" value="$tbl" name="table"/>
    </form>
    </div>
    </div>
    </td>
    </tr>
    </table>
    </td><td>
    <div id="ChangeAutoInCrementValue" style="display:none;">
    <div class="dbForm">
    <form class="dbForm" onsubmit="submitForm(this,'ChangeAutoInCrementValue','ChangeAutoInCrementValue');return false;" method="get" enctype="multipart/form-data">
    | . translate('ChangeAutoInCrementValue') . q|
    <input type="text" value="|
          . $m_oDatabase->GetAutoIncrementValue($tbl) . q|" name="AUTO_INCREMENT"/>
    <input type="submit" value="| . translate('change') . qq|"/>
    <input type="hidden" value="$tbl" name="table"/>
    <input type="hidden" value="ChangeAutoInCrementValue" name="action"/>
    </form></div></div>
    </td></tr>
    <tr><td colspan="2">
    <div id="ChangeCharset" style="display:none;">
    <div class="dbForm"><form class="dbForm" onsubmit="submitForm(this,'ChangeCharset','ChangeCharset');return false;" method="get" enctype="multipart/form-data">
    | . $m_oDatabase->GetCharset( 'charset', $tbl ) . q|<br/>
    <input type="submit" value="| . translate('ChangeCharset') . qq|"/>
    <input type="hidden" value="$tbl" name="table"/>
    <input type="hidden" value="ChangeCharset" name="action"/>
    </form>
    </div>
    </div>
    </td></tr></table>
    |;
    } else {
        ShowTables();
    } ## end else [ if ( $m_oDatabase->tableExists...)]
} ## end sub EditTable

=head2 ShowEditIndex()

Action:

=cut

sub ShowEditIndex {
    my $tbl              = defined $_[0] ? $_[0] : param('tbl');
    my $tbl2             = $m_dbh->quote_identifier($tbl);
    my $cls              = defined $_[1] ? $_[1] : param('over_cols');
    my $keyName          = defined $_[2] ? $_[2] : param('index') ? param('index') : '';
    my $bEditIndex       = defined $_[3] ? 1 : param('editIndexOlp145656') ? 1 : 0;
    my $sUniqueTyp       = Unique();
    my $sUniqueIndexName = Unique();
    my $sUniqueUpdate    = Unique();
    my $sUniqueDelete    = Unique();
    my $sField           = translate('field');
    my $sSize            = translate('size');
    my $sName            = translate('name');
    my $sTyp             = translate('type');
    my @FIELDS;
    my $hashref = $m_oDatabase->fetch_hashref( "SHOW INDEX FROM $tbl2 where `Key_name` = ?", $keyName );
    my @indexes = $m_oDatabase->getIndex($tbl);
    my (
        $foreignFields,   $foreignReferences, $foreignConstraint, $foreignTable, $sForeignUpdate, $sForeignDelete,
        $bForeign,        $sForeignKeyname,   $bPrimary,          $bIndex,       $bUnique,        $bFulltext,
        $sPrimaryKeyname, $sFulltextKeyname,  $sUniqueKeyname,    $sKeyname
    ) = 0 * 16;

    for ( my $j = 0 ; $j <= $#indexes ; $j++ ) {
        if ( $indexes[$j]->{field} eq $hashref->{Column_name} ) {
            if ( $indexes[$j]->{type} eq 'KEY' ) {
                $bIndex   = 1;
                $sKeyname = $indexes[$j]->{name};
            } ## end if ( $indexes[$j]->{type...})
            if ( $indexes[$j]->{type} eq 'UNIQUE KEY' ) {
                $bUnique        = 1;
                $sUniqueKeyname = $indexes[$j]->{name};
            } ## end if ( $indexes[$j]->{type...})
            if ( $indexes[$j]->{type} eq 'FULLTEXT KEY' ) {
                $bFulltext        = 1;
                $sFulltextKeyname = $indexes[$j]->{name};
            } ## end if ( $indexes[$j]->{type...})
            if ( $indexes[$j]->{type} eq 'PRIMARY KEY' ) {
                $bPrimary        = 1;
                $sPrimaryKeyname = $indexes[$j]->{name};
            } ## end if ( $indexes[$j]->{type...})
            if ( $indexes[$j]->{type} eq 'FOREIGN KEY' ) {
                $bForeign          = 1;
                $sForeignKeyname   = $indexes[$j]->{name};
                $sForeignUpdate    = $indexes[$j]->{onupdate};
                $sForeignDelete    = $indexes[$j]->{ondelete};
                $foreignTable      = $indexes[$j]->{foreignTable};
                $foreignConstraint = $indexes[$j]->{field};
                $foreignFields     = $indexes[$j]->{foreignFields};
                $foreignReferences = $indexes[$j]->{foreignReferences};
            } ## end if ( $indexes[$j]->{type...})
        } ## end if ( $indexes[$j]->{field...})
    } ## end for ( my $j = 0 ; $j <=...)
    $RIBBONCONTENT .= qq|
    <div class="ShowTables marginTop">
    <form  onsubmit="submitForm(this,'SaveNewIndex','SaveNewIndex');return false;" method="get" enctype="multipart/form-data">
    <table align="center">
    <tr><td class="caption3">$sField</td>
    <td class="caption3">$sSize</td>
    <td class="caption3 foreign" |
      . ( $bForeign ? '' : 'style="display:none"' ) . q|>Reference Table</td>
    <td class="caption3 foreign" |
      . ( $bForeign ? '' : 'style="display:none"' ) . q|>Reference Field</td></tr>|;
    my @current;
    if ($bEditIndex) {
        my @index = $m_oDatabase->fetch_AoH("SHOW INDEX FROM $tbl2");
        for ( my $i = 0 ; $i <= $#index ; $i++ ) {
            next if $index[$i]->{Key_name} ne $keyName;
            my $cI      = $i + 1;
            my $uName   = Unique();
            my $uSize   = Unique();
            my $columns = $m_oDatabase->GetColumns( $tbl, $uName, $index[$i]->{Column_name} );
            $RIBBONCONTENT .=
qq|<tr><td class="values">$columns</td><td class="values"><input type="text" value="$index[$i]->{Sub_part}" name="$uSize" style="width:40px;"/></td>|;
            my @tables = $m_oDatabase->fetch_array("show Tables;");
            $RIBBONCONTENT .= q|<td class="values foreign" | . ( $bForeign ? '' : 'style="display:none"' ) . qq|>
        <select name="tablelist$i" onchange="DisplayTables($cI,'b$cI'+this.options[this.options.selectedIndex].value)" size="1">|;

            for ( my $j = 0 ; $j <= $#tables ; $j++ ) {
                next if $tables[$j] eq $tbl;
                $RIBBONCONTENT .=
                    qq(<option value="$tables[$j]")
                  . ( $tables[$j] eq $foreignTable ? 'selected="selected"' : '' )
                  . qq( class="table">$tables[$j]</option>);
            } ## end for ( my $j = 0 ; $j <=...)
            $RIBBONCONTENT .= '</select></td><td class="values foreign" ' . ( $bForeign ? '' : 'style="display:none"' ) . '>';
            for ( my $j = 0 ; $j <= $#tables ; $j++ ) {
                next if $tables[$j] eq $tbl;
                my $table = $tables[$j];
                push @current, $cI . $tables[$j]
                  if ( ( $tables[$j] eq $foreignTable ) or ( !$bForeign and $j == 0 ) );
                $table = $m_dbh->quote_identifier($table);
                my @tables2 = $m_oDatabase->fetch_AoH("show columns from $table");
                $RIBBONCONTENT .= qq|<select id="b$cI$tables[$j]" name="table$i$tables[$j]" size="1" style="|
                  . (
                         ( $tables[$j] eq $foreignTable )
                      or ( !$bForeign and $j == 0 ) ? '' : 'display:none;'
                  ) . q|">|;
                for ( my $k = 0 ; $k <= $#tables2 ; $k++ ) {
                    my $bcurrent = 0;
                    for ( my $l = 0 ; $l <= $#{$foreignFields} ; $l++ ) {
                        if (    $foreignReferences->[$l] eq $tables2[$k]->{'Field'}
                            and $index[$i]->{Column_name} eq $foreignFields->[$l] ) {
                            $bcurrent = 1;
                        } ## end if ( $foreignReferences...)
                    } ## end for ( my $l = 0 ; $l <=...)
                    $RIBBONCONTENT .=
                        '<option '
                      . ( $bcurrent ? 'selected="selected"' : '' )
                      . qq(value="$tables2[$k]->{'Field'}" class="table">$tables2[$k]->{'Field'}</option>);
                } ## end for ( my $k = 0 ; $k <=...)
                $RIBBONCONTENT .= '</select>';
            } ## end for ( my $j = 0 ; $j <=...)
            $RIBBONCONTENT .= '</td></tr>';
            push @FIELDS,
              {
                name => $uName,
                size => $uSize,
              };
        } ## end for ( my $i = 0 ; $i <=...)
    } else {
        for ( 1 .. $cls ) {
            my $uName   = Unique();
            my $uSize   = Unique();
            my $columns = $m_oDatabase->GetColumns( $tbl, $uName, $hashref->{Column_name} );
            $RIBBONCONTENT .= qq|
    <tr><td class="values">$columns</td>
    <td class="values"><input type="text" value='' name="$uSize" style="width:40px;"/></td>|;
            my @tables = $m_oDatabase->fetch_array("show Tables;");
            $RIBBONCONTENT .=
                q|<td class="values foreign" |
              . ( $bForeign ? '' : 'style="display:none"' )
              . qq|><select name="tablelist$_" onchange="DisplayTables($_,'b$_'+this.options[this.options.selectedIndex].value)" id="tablelist"  size="1">|;
            for ( my $j = 0 ; $j <= $#tables ; $j++ ) {
                next if $tables[$j] eq $tbl;
                $RIBBONCONTENT .= qq(<option value="$tables[$j]" class="table">$tables[$j]</option>);
            } ## end for ( my $j = 0 ; $j <=...)
            $RIBBONCONTENT .= '</select></td><td class="values foreign" ' . ( $bForeign ? '' : 'style="display:none"' ) . '>';
            for ( my $j = 0 ; $j <= $#tables ; $j++ ) {
                next if $tables[$j] eq $tbl;
                push @current, $_ . $tables[$j] if $j == 0;
                my $table = $tables[$j];
                $table = $m_dbh->quote_identifier($table);
                my @tables2 = $m_oDatabase->fetch_AoH("show columns from $table");
                $RIBBONCONTENT .=
                  qq|<select id="b$_$tables[$j]" name="table$_$tables[$j]" size="1" style="| . ( $j == 0 ? '' : 'display:none;' ) . q|">|;
                for ( my $k = 0 ; $k <= $#tables2 ; $k++ ) {
                    $RIBBONCONTENT .=
                        '<option '
                      . ( $k == 0 ? 'selected="selected"' : '' )
                      . qq(value="$tables2[$k]->{'Field'}" class="table">$tables2[$k]->{'Field'}</option>);
                } ## end for ( my $k = 0 ; $k <=...)
                $RIBBONCONTENT .= '</select>';
            } ## end for ( my $j = 0 ; $j <=...)
            $RIBBONCONTENT .= q|</tr>|;
            push @FIELDS,
              {
                name => $uName,
                size => $uSize,
              };
        } ## end for ( 1 .. $cls )
    } ## end else [ if ($bEditIndex) ]
    my $qstring = createSession(
        {
            user       => $m_sUser,
            action     => 'SaveNewIndex',
            table      => $tbl,
            name       => $sUniqueIndexName,
            typ        => $sUniqueTyp,
            ondelete   => $sUniqueDelete,
            onupdate   => $sUniqueUpdate,
            fields     => [@FIELDS],
            constraint => $foreignConstraint,
        }
    );
    my $ers = translate('editIndex');
    $RIBBONCONTENT .= qq|
    <tr>
    <td class="caption3">Name</td>
    <td class="caption3">$sTyp</td>
    <td class="caption3 foreign"| . ( $bForeign ? '' : 'style="display:none"' ) . q|>ON UPDATE</td>
    <td class="caption3 foreign"| . ( $bForeign ? '' : 'style="display:none"' ) . qq|>ON DELETE</td>
    </tr>
    <tr>
    <td class="values">
    <input type="text" value="$keyName" name="$sUniqueIndexName" style="width:100px;"/>
    </td>
    <td class="values">
    <select name="$sUniqueTyp" onchange="setIndexType(this.options[this.options.selectedIndex].value)">
    <option value="PRIMARY"| .     ( $bPrimary  ? 'selected="selected"' : '' ) . q|>PRIMARY</option>
    <option value="INDEX"| .       ( $bIndex    ? 'selected="selected"' : '' ) . q|>INDEX</option>
    <option value="UNIQUE"| .      ( $bUnique   ? 'selected="selected"' : '' ) . q|>UNIQUE</option>
    <option value="FULLTEXT" | .   ( $bFulltext ? 'selected="selected"' : '' ) . q|>FULLTEXT</option>
    <option value="FOREIGN KEY"| . ( $bForeign  ? 'selected="selected"' : '' ) . q|>FOREIGN</option>
    </select>
    </td>
    <td class="values foreign" | . ( $bForeign ? '' : 'style="display:none"' ) . qq|>
    <select name="$sUniqueUpdate">
    <option value="NO ACTION">NO ACTION</option>
    <option value="CASCADE"|
      . ( $sForeignUpdate eq 'CASCADE' ? 'selected="selected"' : '' ) . q|>CASCADE</option>
    <option value="SET DEFAULT"|
      . ( $sForeignUpdate eq 'SET DEFAULT' ? 'selected="selected"' : '' ) . q|>SET DEFAULT</option>
    </select>
    </td>
    <td class="values foreign" | . ( $bForeign ? '' : 'style="display:none"' ) . qq|>
    <select name="$sUniqueDelete">
    <option value="NO ACTION">NO ACTION</option>
    <option value="CASCADE"| . ( $sForeignDelete ? 'selected="selected"' : '' ) . q|>CASCADE</option>
    <option value="SET DEFAULT"|
      . ( $sForeignDelete eq 'SET DEFAULT' ? 'selected="selected"' : '' ) . qq|>SET DEFAULT</option>
    </select>
    </td>
    </tr>
    <tr><td colspan="4" class="submit"><input type="submit" class="button" value="$ers" name="submit"/></td></tr>
    </table>
    <input type="hidden" value="SaveNewIndex" name="action"/>
    <input type="hidden" value="$qstring" name="save_new_indexhjfgzu"/>
    <input type="hidden" value="$keyName" name="oldname"/>|;
    my $js = "aCurrentShown = ['',";

    for ( 0 .. $#current ) {
        $js .= "'b$current[$_]'";
        $js .= ',' if $_ < $#current;
    } ## end for ( 0 .. $#current )
    $js .= ']';
    $RIBBONCONTENT .= '<input type="hidden" value="1" name="editIndexOlp145656"/>'
      if param('editIndexOlp145656');
    $RIBBONCONTENT .= qq|</form></div><script language="JavaScript">$js</script>|;
    EditTable($tbl);
} ## end sub ShowEditIndex

=head2 SaveNewIndex()

Action:

=cut

sub SaveNewIndex {
    my $session = param('save_new_indexhjfgzu');
    session( $session, $m_sUser );
    my $tbl = $m_hrParams->{table};
    if ( defined $tbl and defined $session ) {
        my $tbl2  = $m_dbh->quote_identifier($tbl);
        my $name  = $m_dbh->quote_identifier( param( $m_hrParams->{name} ) );
        my $oname = param('oldname') ? $m_dbh->quote_identifier( param('oldname') ) : 0;
        my $typ   = param( $m_hrParams->{typ} );
        unless ( $typ eq 'FOREIGN KEY' ) {
            my $sql = qq|ALTER TABLE $tbl2 |
              . (
                param('editIndexOlp145656')
                ? (
                    param('oldname') eq 'PRIMARY'
                    ? 'DROP PRIMARY KEY,'
                    : "DROP INDEX $oname,"
                  )
                : ''
              )
              . ' ADD '
              . ( $typ eq 'PRIMARY' ? 'PRIMARY KEY' : "$typ $name" ) . '(';
            my $nsize = 0;
            for ( my $i = 0 ; $i <= $#{ $m_hrParams->{fields} } ; $i++ ) {
                my $field = $m_dbh->quote_identifier( param( $m_hrParams->{fields}[$i]{name} ) );
                $nsize = param( $m_hrParams->{fields}[$i]{size} ) =~ /(\d+)/ ? $1 : 0;
                $sql .= qq|$field|;
                $sql .= ',' unless $i == $#{ $m_hrParams->{fields} };
            } ## end for ( my $i = 0 ; $i <=...)
            $sql .= ');';
            $sql .= qq|($nsize)| if $nsize;
            ExecSql($sql);
            ShowEditIndex( $tbl, $#{ $m_hrParams->{fields} } + 1, param( $m_hrParams->{name} ), 1 );
        } else {
            my $sql;
            my @params = param();
            my $field;
            for ( my $i = 0 ; $i <= $#{ $m_hrParams->{fields} } ; $i++ ) {
                $field .= $m_dbh->quote_identifier( param( $m_hrParams->{fields}[$i]{name} ) );
                $field .= ',' if $i < $#{ $m_hrParams->{fields} };
            } ## end for ( my $i = 0 ; $i <=...)
            my @constraints = $m_oDatabase->getConstraintKeys( $tbl, $m_hrParams->{constraint} );
            $sql .= "ALTER TABLE $tbl2 DROP FOREIGN KEY `$_`;\n" for @constraints;
            $sql .= "ALTER TABLE $tbl2 DROP KEY $oname;\n" if $oname;
            my @key;
            my $ref;
            for ( 0 .. $#params ) {
                if ( $params[$_] =~ /^(table(\d)+(.+))$/ ) {
                    if ( param("tablelist$2") eq $3 ) {
                        push @key, param($1);
                        $ref = $3;
                    } ## end if ( param("tablelist$2"...))
                } ## end if ( $params[$_] =~ /^(table(\d)+(.+))$/)
            } ## end for ( 0 .. $#params )
            $key[$_] = $m_dbh->quote_identifier( $key[$_] ) for 0 .. $#key;
            $sql .= "ALTER TABLE $tbl2 ADD FOREIGN KEY $name ($field) REFERENCES `$ref` (" . ( join ',', @key ) . ') ';
            $sql .= 'ON DELETE ' . param( $m_hrParams->{onupdate} );
            $sql .= ' ON UPDATE ' . param( $m_hrParams->{onupdate} );
            ExecSql($sql);

            #     ShowEditIndex( $tbl , $#{ $m_hrParams->{fields} }+1 ,param( $m_hrParams->{name} ),1) if $erno;
            #todo parameter wieder anzeigen
        } ## end else
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $tbl and ...)]
} ## end sub SaveNewIndex

=head2 SaveEditTable()

Action:

=cut

sub SaveEditTable {
    my $session = param('change_col_sessionRTZHBG');
    session( $session, $m_sUser );
    my $tbl = $m_hrParams->{table};
    if ( defined $tbl and defined $session ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        my $sql  = '';
        my @prims;
        my $indexes = '';
        my $alter   = 0;
        foreach my $row ( keys %{ $m_hrParams->{rows} } ) {
            my $newrow = param( $m_hrParams->{rows}{$row}{Field} );
            my $type   = param( $m_hrParams->{rows}{$row}{Type} );
            my $length = param( $m_hrParams->{rows}{$row}{Length} );
            $type =
                $type =~ /BLOB|LONGBLOB|MEDIUMBLOB|TINYBLOB|TEXT|TIMESTAMP/ ? $type
              : $length                                                     ? $type . "($length)"
              :                                                               $type;
            my @te = param( 'SET' . $m_hrParams->{rows}{$row}{Type} );
            $set->{$newrow} = [@te] if $newrow;
            $te[$_] = $m_oDatabase->quote( $te[$_] ) for 0 .. $#te;
            $type = 'SET(' . ( join ',', @te ) . ')' if $type eq 'SET';
            my $character_set =
              $m_oDatabase->GetCharacterSet( param( $m_hrParams->{rows}{$row}{Collation} ) );
            my $collation = param( $m_hrParams->{rows}{$row}{Collation} );
            my $null      = param( $m_hrParams->{rows}{$row}{Null} );
            my $comment   = param( $m_hrParams->{rows}{$row}{Comment} );
            my $extra     = param( $m_hrParams->{rows}{$row}{Extra} );
            my $default   = param( $m_hrParams->{rows}{$row}{Default} );
            my $attrs     = param( $m_hrParams->{rows}{$row}{Attrs} );
            my $row2      = $m_dbh->quote_identifier($row);
            my $newrow2   = $m_dbh->quote_identifier($newrow);
            my $prim      = param( $m_hrParams->{rows}{$row}{Primary} );
            my $fulltext  = param( $m_hrParams->{rows}{$row}{Fulltext} );
            my $index     = param( $m_hrParams->{rows}{$row}{Index} );
            my $uniqe     = param( $m_hrParams->{rows}{$row}{Unique} );
            my $sprim     = param( $m_hrParams->{rows}{$row}{sPrimary} );
            my $sfulltext = param( $m_hrParams->{rows}{$row}{sFulltext} );
            my $sindex    = param( $m_hrParams->{rows}{$row}{sIndex} );
            my $suniqe    = param( $m_hrParams->{rows}{$row}{sUnique} );

            if ( $sfulltext and $fulltext ne 'on' ) {
                $m_oDatabase->void("ALTER TABLE $tbl2 drop index `$sfulltext`")
                  if defined $sfulltext;
            } elsif ( !$sfulltext and $fulltext eq 'on' ) {
                $indexes .= "ALTER TABLE $tbl2 ADD FULLTEXT ($newrow);";
            } ## end elsif ( !$sfulltext and $fulltext...)
            if ( $suniqe and $uniqe ne 'on' ) {
                $m_oDatabase->void("ALTER TABLE $tbl2 drop index `$suniqe`");
            } elsif ( !$suniqe and $uniqe eq 'on' ) {
                $indexes .= "ALTER TABLE $tbl2 ADD UNIQUE ($newrow);";
            } ## end elsif ( !$suniqe and $uniqe...)
            if ( $sindex and $index ne 'on' ) {
                $m_oDatabase->void("ALTER TABLE $tbl2 drop index `$sindex`");
            } elsif ( !$sindex and $index eq 'on' ) {
                $indexes .= "ALTER TABLE $tbl2 ADD INDEX ($newrow);";
            } ## end elsif ( !$sindex and $index...)
            $m_oDatabase->void("ALTER TABLE $tbl2 DROP PRIMARY KEY;") if ( $sprim and $prim ne 'on' );
            $alter = 1 if ( !$sprim and $prim eq 'on' );
            push @prims, $newrow if $prim eq 'on';
            $default =
                ( ( $default || $default =~ /0/ ) and $default ne 'CURRENT_TIMESTAMP' ) ? ' default ' . $m_dbh->quote($default)
              : $default eq 'CURRENT_TIMESTAMP' ? ' default CURRENT_TIMESTAMP'
              :                                   0;
            my $vcomment = $m_dbh->quote($comment);
            $sql .= "ALTER TABLE $tbl2 CHANGE $row2 $newrow2 $type";
            $sql .= ' auto_increment ' if $extra eq 'auto_increment';

            if ($collation) {
                $sql .= " CHARACTER SET $character_set COLLATE $collation"
                  unless $character_set eq 'binary' or $collation eq 'NULL';
            } ## end if ($collation)
            $sql .= " $attrs";
            $sql .= " $null ";
            $sql .= " COMMENT $vcomment" if $comment;
            $sql .= $default if $default;
            $sql .= ";$/";
        } ## end foreach my $row ( keys %{ $m_hrParams...})
        my $key = join( ' , ', @prims );
        $sql .= "ALTER TABLE $tbl2 ADD constraint PRIMARY KEY ($key);$/" if ($alter);
        $sql .= $indexes;
        ExecSql($sql);
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $tbl and ...)]
} ## end sub SaveEditTable

=head2 SaveNewColumn()

Action:

=cut

sub SaveNewColumn {
    my $session   = param('create_new_col_seesion');
    my $after_col = param('after_col');
    session( $session, $m_sUser );
    my $tbl = $m_hrParams->{table};
    if ( defined $tbl and defined $session ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        my $sql;
        my $newrow = param( $m_hrParams->{rows}{Field} );
        my $type   = param( $m_hrParams->{rows}{Type} );
        my $length = param( $m_hrParams->{rows}{Length} );
        $type =
            $type =~ /Blob|TEXT|TIMESTAMP/ ? $type
          : $length                        ? $type . "($length)"
          :                                  $type;
        my $character_set = $m_oDatabase->GetCharacterSet( param( $m_hrParams->{Collation} ) );
        my $collation     = param( $m_hrParams->{Collation} );
        my $null          = param( $m_hrParams->{rows}{Null} );
        my $comment       = param( $m_hrParams->{rows}{Comment} );
        my $extra         = param( $m_hrParams->{rows}{Extra} );
        my $default       = param( $m_hrParams->{rows}{Default} );
        my $attrs         = param( $m_hrParams->{rows}{Attrs} );
        my $newrow2       = $m_dbh->quote_identifier($newrow);
        $default =
          ( ( $default || $default =~ /0/ ) and $default ne "CURRENT_TIMESTAMP" )
          ? ' default ' . $m_dbh->quote($default)
          : '';
        my $vcomment = $m_dbh->quote($comment);
        $sql .= "ALTER TABLE $tbl2 ADD  $newrow2 $type";
        $sql .= ' auto_increment ' if $extra eq 'auto_increment';

        if ($collation) {
            $sql .= " CHARACTER SET $character_set COLLATE $collation"
              unless ( $character_set eq 'binary' or $collation eq 'NULL' );
        } ## end if ($collation)
        $sql .= " $attrs";
        $sql .= " $null ";
        $sql .= " COMMENT $vcomment" if $comment;
        $sql .= $default if $default;
        $sql .= ' first' if $after_col eq ' first';
        $sql .= 'after ' . param('after_name') if $after_col eq 'after';
        $sql .= ";$/";
        ExecSql($sql);
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $tbl and ...)]
} ## end sub SaveNewColumn

=head2 RenameTable($table,$newtable)

Action:

=cut

sub RenameTable {
    my $tbl    = param('table')    ? param('table')    : shift;
    my $newtbl = param('newTable') ? param('newTable') : shift;
    if ( defined $tbl and defined $newtbl ) {
        my $tbl2    = $m_dbh->quote_identifier($tbl);
        my $newtbl2 = $m_dbh->quote_identifier($newtbl);
        ExecSql("ALTER TABLE $tbl2 RENAME $newtbl2;");
        EditTable($newtbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $tbl and ...)]
} ## end sub RenameTable

=head2 ChangeEngine($table,$engine)

Action:

=cut

sub ChangeEngine {
    my $tbl    = param('table')  ? param('table')  : shift;
    my $engine = param('engine') ? param('engine') : shift;
    if ( defined $engine and defined $tbl ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        $engine = $m_oDatabase->quote($engine);
        ExecSql("ALTER TABLE $tbl2 ENGINE = $engine");
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $engine and...)]
} ## end sub ChangeEngine

=head2 ChangeAutoInCrementValue($table,$autoInCrement)

Action:

=cut

sub ChangeAutoInCrementValue {
    my $tbl   = param('table')          ? param('table')          : shift;
    my $p_key = param('AUTO_INCREMENT') ? param('AUTO_INCREMENT') : shift;
    if ( defined $p_key and defined $tbl ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        ExecSql("ALTER TABLE $tbl2 AUTO_INCREMENT = $p_key");
        EditTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $p_key and...)]
} ## end sub ChangeAutoInCrementValue

=head2 ShowDbHeader()

create the Table Menu and CreateDatabase CreateUser CreateTable ChangeCurrentDb SqlEditor SqlSearch forms. 

=cut

sub ShowDbHeader {
    my $tbl      = shift;
    my $selected = shift;
    my $current  = shift;
    print q|<div id="NewEntry" style="display:none;">|;
    &ShowNewEntry($tbl) if $m_oDatabase->tableExists($tbl);
    print '</div>';
    my $exec                = translate('ExecSql');
    my $newtable            = translate('next');
    my $newUser             = translate('create');
    my $connect             = translate('connect');
    my $fields              = translate('fields');
    my $password            = translate('password');
    my $name                = translate('name');
    my $right_username_text = translate('right_username_text');
    my $wrong_username_text = translate('wrong_username_text');
    my $right_passwort_text = translate('right_passwort_text');
    my $wrong_passwort_text = translate('wrong_passwort_text');
    my $wrong_database_name = translate('wrong_database_name');
    my $right_database_name = translate('right_database_name');
    $RIBBONCONTENT = $RIBBONCONTENT ? $RIBBONCONTENT : '&#160;';
    print q|
    <div id="CreateDatabase" align="center" style="display:none;">
    <form  align="center" name="CreateDatabase" class="CreateDatabase" method="get" enctype="multipart/form-data" onsubmit="submitForm(this,'CreateDatabase','CreateDatabase');return false;">
    <label for="name" class="caption">| . translate('CreateDatabase') . q|</label>
    <input type="text" name="name" data-regexp="|
      . '/^.{1,100}$/' . qq|" data-error="$wrong_database_name" data-right="$right_database_name">
    <div align="right"><input type="submit" name="submit" value="|
      . translate('create') . q|"/></div>
    <input type="hidden" name="action" value="CreateDatabase"/>
    </form>
    </div>
    <div id="CreateUser" align="center" style="display:none;">
    <form name="CreateUser" class="CreateUser" method="get" enctype="multipart/form-data" onsubmit="submitForm(this,'CreateUser','CreateUser');return false;">
    <label for="name" class="caption">|
      . translate('user') . q(</label>
    <input type="text" name="name" data-regexp=")
      . '/^\w{4,100}$/' . qq(" data-error="$wrong_username_text" data-right="$right_username_text"/>
    <label for="host" class="caption">) . translate('host') . q(</label>
    <input type="text" name="host" data-regexp="/.*/"/>
    <label for="password" class="caption">) . translate('password') . qq|</label>
    <input data-regexp="/.{4,100}/" data-error="$wrong_passwort_text"  data-right="$right_passwort_text" type="password" name="password"/>
    | . qq|
    <div align="right" ><input type="submit" name="submit"  align="right" value="$newUser"/></div>
    <input type="hidden" name="action" value="CreateUser" />
    </form>
    </div>
    <div id="CreateTable" align="center" style="display:none;">
    <form class="CreateTable" method="get" enctype="multipart/form-data" onsubmit="submitForm(this,'CreateTable','showcreatetable');return false;"  name="NewTable">
    <label for="table" class="caption">| . translate('showcreatetable') . qq|</label>
    <input type="text" name="table" data-regexp="/.{1,64}/" data-error=".{1,64}"  data-right="Ok"/>
    <label for="count" class="caption">$fields</label>| . q|
    <input type="text" name="count" id="fields4tbl" data-regexp="/\d{1,3}/" data-error="\d{1,3}"  data-right="Ok"/>|
      . qq|
    <div align="right"><input type="submit" name="submit" value="$newtable"/></div>
    <input type="hidden" name="action" value="ShowNewTable"/>
    </form>
    </div> 
    <div id="ChangeCurrentDb" style="display:none;">
    <form name="CurrentDb" class="ChangeCurrentDb" method="get"  onsubmit="submitForm(this,'ChangeCurrentDb','ChangeCurrentDb');return false;"  accept-charset="UTF-8" >
    <input type="hidden" name="ChangeCurrentDb" value="$m_sCurrentDb"/>
    <label for="m_shost" class="caption">| . translate('host') . qq|</label>
    <input type="text" name="m_shost" value="$m_sCurrentHost"/>
    <label for="m_suser" class="caption">| . translate('user') . qq|</label>
    <input type="text" name="m_suser" value="$m_sCurrentUser"/>
    <label for="m_spass" class="caption">| . translate('password') . qq|</label>
    <input type="password" name="m_spass" value="$m_sCurrentPass"/>
    <div align="right"><input type="submit" name="submit" value="$connect"/></div>
    </form>
    </div>
      <div id="SQLRIGHTS" class="SQLRIGHTS" style="display:none"></div>
      <div id="SqlEditor" class="SqlEditor" style="display:none">
    <form onsubmit="submitForm(this,'execSql','execSql');return false;" method="get" accept-charset="UTF-8">
    <table style="width:100%;margin-bottom:4px;">
    <tr>
    <td valign="top" style="width:30%;">
    | . _insertTables() . qq?</td><td style="width:70%;">
    <textarea name="sql" class="sqlEdit" id="sqlEdit">$SQL</textarea>
    </td>
    </tr>
    <tr><td></td>
    <td align="right" style="padding-right:2px;">
    <input type="hidden" value="$current" name="goto"/>
    <input type="hidden" value="SQL" name="action"/>
    <input type="submit" value="$exec"/></td>
    </tr>
    </table>
    </form>
      </div>
      <div id="SqlSearch" style="display:none;">? . searchForm() . qq(</div>
      <div id="EXECSQL" class="execsql">$RIBBONCONTENT</div>
      );
} ## end sub ShowDbHeader

=head2 _insertTables()

Action:

=cut

sub _insertTables {
    my @tables = $m_oDatabase->fetch_array('show Tables;');
    my $list =
q|<a id="akeywods" onclick="DisplayKeyWords(true)">Keywords</a>&#160;<a id="afieldNames" onclick="DisplayKeyWords(false)" class="currentLink">Field&#160;Names</a><div id="divTables"><select onSubmit="return false;" id="tablelist" class="sqlEdit" name="tablelist" size="10" onkeypress="var keyCode = event.keyCode ? event.keyCode :event.charCode ? event.charCode :event.which;if (keyCode != 13) return;insertAtCursorPosition(this.options[this.options.selectedIndex].value);return false;">|;
    for ( my $i = 0 ; $i <= $#tables ; $i++ ) {
        my $name = $m_dbh->quote_identifier( $tables[$i] );
        $list .=
          qq(<option value="$tables[$i]" onclick="DisplayTable('$tables[$i]');" ondblclick="insertAtCursorPosition('$name');">$tables[$i]</option>);
    } ## end for ( my $i = 0 ; $i <=...)
    $list .= '</select>';
    for ( my $i = 0 ; $i <= $#tables ; $i++ ) {
        my $table = $tables[$i];
        $table = $m_dbh->quote_identifier($table);
        my @tables2 = $m_oDatabase->fetch_AoH("show columns from $table");
        $list .=
qq|<select class="sqlEdit" onsubmit="return false;" id="$tables[$i]" size="10" onkeypress="var keyCode = event.keyCode ? event.keyCode :event.charCode ? event.charCode :event.which;if (keyCode != 13) return;var e = document.getElementById('sqlEdit');e.value +=this.options[this.options.selectedIndex].value;return false;" style="display:none;">|;
        for ( my $i = 0 ; $i <= $#tables2 ; $i++ ) {
            my $name = $m_dbh->quote_identifier( $tables2[$i]->{'Field'} );
            $list .= qq(<option value="$tables2[$i]->{'Field'}" ondblclick="insertAtCursorPosition('$name');">$tables2[$i]->{'Field'}</option>);
        } ## end for ( my $i = 0 ; $i <=...)
        $list .= '</select></div>';
    } ## end for ( my $i = 0 ; $i <=...)
    @tables = $m_oDatabase->fetch_array("select reserved_word from $m_hrSettings->{database}{name}.reserved_words order by 'reserved_words'");
    $list .=
q|<select onsubmit="return false;" id="selKeyword" class="keyWords" size="10" onkeypress="var keyCode = event.keyCode ? event.keyCode :event.charCode ? event.charCode :event.which;if (keyCode != 13) return;insertAtCursorPosition(this.options[this.options.selectedIndex].value);return false;" style="display:none;">|;
    for ( my $i = 0 ; $i <= $#tables ; $i++ ) {
        $list .= qq(<option value="$tables[$i]" onkeydown="return false;" ondblclick="insertAtCursorPosition('$tables[$i]');">$tables[$i]</option>);
    } ## end for ( my $i = 0 ; $i <=...)
    $list .= '</select>';
    return $list;
} ## end sub _insertTables

=head2 AnalyzeTable( $table )

Action:

=cut

sub AnalyzeTable {
    my $tbl = param('table') ? param('table') : shift;
    if ( defined $tbl ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        ExecSql( "ANALYZE TABLE $tbl2", 1 );
        ShowTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $tbl ) ]
} ## end sub AnalyzeTable

=head2 RepairTable($table)

Action:

=cut

sub RepairTable {
    my $tbl = param('table') ? param('table') : shift;
    if ( defined $tbl ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        ExecSql( "REPAIR TABLE $tbl2", 1 );
        ShowTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $tbl ) ]
} ## end sub RepairTable

=head2 OptimizeTable( $table )

Action:

=cut

sub OptimizeTable {
    my $tbl = param('table') ? param('table') : shift;
    if ( defined $tbl ) {
        my $tbl2 = $m_dbh->quote_identifier($tbl);
        ExecSql( "OPTIMIZE TABLE $tbl2", 1 );
        ShowTable($tbl);
    } else {
        ShowTables();
    } ## end else [ if ( defined $tbl ) ]
} ## end sub OptimizeTable

=head2 ShowUsers()

Action:

=cut

sub ShowUsers {
    my @a = $m_oDatabase->fetch_AoH('SELECT * FROM mysql.user');
    ShowDbHeader( $m_sCurrentDb, 0, 'ShowUsers' );
    my $toolbar = a(
        {
            class   => 'toolbarButton',
            onclick => q|showPopup('CreateUser');|,
            title   => translate('CreateUser')
        },
        translate('CreateUser')
    );    #2
    $toolbar .= a(
        {
            class   => 'toolbarButton',
            onclick => q|showPopup('SqlSearch')|,
            title   => translate('search')
        },
        translate('search')
    );    #3
    $toolbar .= a(
        {
            class   => 'toolbarButton',
            onclick => 'showSQLEditor()',
            title   => translate('SQL')
        },
        translate('SQL')
    );    #4
    print q(
    <form onsubmit="submitForm(this,'ShowUsers','ShowUsers');return false;" method="get" enctype="multipart/form-data">
    <input type="hidden" name="action" value="MultipleAction"/>
    <input type="hidden" name="table" value="mysql"/>
    <table class="ShowTables" id="toolbarTable">
    <tr class="captionRadius">
      <td class="captionRadius" colspan="7">) . translate('ShowUsers') . qq(</td>
    </tr>
    <tr>
    <td colspan="8" id="toolbar" class="toolbar"><div id="toolbarcontent" class="toolbarcontent">$toolbar</div>
    </td>
    </tr>
    <tr>
    <td class="caption2 checkbox"></td>
    <td class="caption2">$m_hrLng->{$ACCEPT_LANGUAGE}{user}</td>
    <td class="caption2">$m_hrLng->{$ACCEPT_LANGUAGE}{host}</td>
    <td class="caption2">$m_hrLng->{$ACCEPT_LANGUAGE}{rights}</td>
    <td class="caption2" colspan="2"></td>
    </tr>
    );

    for ( my $i = 0 ; $i <= $#a ; $i++ ) {
        my $trdatabase = translate('database');
        my $trdelete   = translate('delete');
        my $change     = translate('EditMysqlUserRights');
        initRights( $a[$i]->{User}, $a[$i]->{Host} );
        my $sRights;
        foreach my $k ( sort keys %m_hUserRights ) {
            $sRights .= $m_hUserRights{$k} ? $k =~ /^[a-z]+/ ? "$k " : '' : '';
        } ## end foreach my $k ( sort keys %m_hUserRights)
        print qq(
    <tr>
    <td class="checkbox"><input type="checkbox" name="markBox$i" class="markBox" value="$a[$i]->{User}/$a[$i]->{Host}" /></td>
    <td class="values"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowRights&user=$a[$i]->{User}&host=$a[$i]->{Host};','ShowRights','ShowRights')">$a[$i]->{User}</a></td>
    <td class="values">$a[$i]->{Host}</td>
    <td class="values">$sRights</td>
    <td class="values"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowRights&user=$a[$i]->{User}&host=$a[$i]->{Host};','ShowRights','ShowRights')"><img src="style/$m_sStyle/buttons/edit.png"  alt="$change" title="$change"/></a></td>
    <td class="values right"><a href="javascript:void(0)" onclick="confirm2(' $trdelete?',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=DeleteUser&table=mysql&user=$a[$i]->{User}&host=$a[$i]->{Host};','DeleteUser','DeleteUser')"><img src="style/$m_sStyle/buttons/delete.png" title="$trdelete" /></a></td>
    </tr>
    );
    } ## end for ( my $i = 0 ; $i <=...)
    my $delete   = translate('delete');
    my $mmark    = translate('selected');
    my $markAll  = translate('select_all');
    my $umarkAll = translate('unselect_all');
    print qq|
    <tr>
    <td class="checkbox"><img src="style/$m_sStyle/buttons/feil.gif"  alt=''/></td>
    <td colspan="7" align="left">
    <table class="MultipleAction">
    <tr><td colspan="2" align="left">
    <a id="markAll" href="javascript:markInput(true);" class="links">$markAll</a>
    <a class="links" id="umarkAll" style="display:none;" href="javascript:markInput(false);">$umarkAll</a></td>
    <td class="submit">
    <select name="MultipleAction" class="MultipleAction" onchange="if(this.value != '$mmark' )submitForm(this.form,this.value,this.value);">
    <option value="$mmark" selected="selected">$mmark</option>
    <option value="deleteUser" >$delete</option>
    </select>
    </td>
    </tr></table>
    </td>
    </tr>
    </table>
    <br/>
    </form>|;
} ## end sub ShowUsers

=head2 ShowRights()

Action:

=cut

sub ShowRights {
    my $UNIQUE_UPDATE                   = Unique();
    my $UNIQUE_DELETE                   = Unique();
    my $UNIQUE_CREATE                   = Unique();
    my $UNIQUE_DROP                     = Unique();
    my $UNIQUE_RELOAD                   = Unique();
    my $UNIQUE_SHUTDOWN                 = Unique();
    my $UNIQUE_PROCESS                  = Unique();
    my $UNIQUE_FILE                     = Unique();
    my $UNIQUE_REFERENCES               = Unique();
    my $UNIQUE_INDEX                    = Unique();
    my $UNIQUE_ALTER                    = Unique();
    my $UNIQUE_SHOWDATABASES            = Unique();
    my $UNIQUE_SUPER                    = Unique();
    my $UNIQUE_CREATETEMPORARYTABLES    = Unique();
    my $UNIQUE_LOCKTABLES               = Unique();
    my $UNIQUE_REPLICATIONCLIENT        = Unique();
    my $UNIQUE_CREATEVIEW               = Unique();
    my $UNIQUE_SHOWVIEW                 = Unique();
    my $UNIQUE_CREATEROUTINE            = Unique();
    my $UNIQUE_ALTERROUTINE             = Unique();
    my $UNIQUE_CREATEUSER               = Unique();
    my $UNIQUE_REPLICATIONSLAVE         = Unique();
    my $UNIQUE_MAX_QUERIES_PER_HOUR     = Unique();
    my $UNIQUE_MAX_CONNECTIONS_PER_HOUR = Unique();
    my $UNIQUE_MAX_UPDATES_PER_HOUR     = Unique();
    my $UNIQUE_INSERT                   = Unique();
    my $UNIQUE_SELECT                   = Unique();
    my $UNIQUE_EXECUTE                  = Unique();
    my $UNIQUE_HOST                     = Unique();
    my $UNIQUE_DB                       = Unique();
    my $UNIQUE_TBL                      = Unique();
    my $UNIQUE_USER                     = Unique();
    my $UNIQUE_MAX_USER_CONNECTIONS     = Unique();
    my $UNIQUE_update                   = Unique();
    my $UNIQUE_grant                    = Unique();
    my $uname                           = defined $_[0] ? shift : param('user');
    my $hostname                        = defined $_[0] ? shift : param('host');
    my $qstring                         = createSession(
        {
            action => 'SaveRights',
            user   => $m_sUser,
            TBL    => $UNIQUE_TBL,
            DB     => $UNIQUE_DB,
            DBUSER => $UNIQUE_USER,
            uname  => $uname,
            HOST   => $UNIQUE_HOST,
            BOOL   => {
                UPDATE                => $UNIQUE_UPDATE,
                DELETE                => $UNIQUE_DELETE,
                CREATE                => $UNIQUE_CREATE,
                DROP                  => $UNIQUE_DROP,
                RELOAD                => $UNIQUE_RELOAD,
                SHUTDOWN              => $UNIQUE_SHUTDOWN,
                PROCESS               => $UNIQUE_PROCESS,
                FILE                  => $UNIQUE_FILE,
                REFERENCES            => $UNIQUE_REFERENCES,
                INDEX                 => $UNIQUE_INDEX,
                ALTER                 => $UNIQUE_ALTER,
                SHOWDATABASES         => $UNIQUE_SHOWDATABASES,
                SUPER                 => $UNIQUE_SUPER,
                CREATETEMPORARYTABLES => $UNIQUE_CREATETEMPORARYTABLES,
                LOCKTABLES            => $UNIQUE_LOCKTABLES,
                REPLICATIONCLIENT     => $UNIQUE_REPLICATIONCLIENT,
                CREATEVIEW            => $UNIQUE_CREATEVIEW,
                SHOWVIEW              => $UNIQUE_SHOWVIEW,
                CREATEROUTINE         => $UNIQUE_CREATEROUTINE,
                ALTERROUTINE          => $UNIQUE_ALTERROUTINE,
                CREATEUSER            => $UNIQUE_CREATEUSER,
                REPLICATIONSLAVE      => $UNIQUE_REPLICATIONSLAVE,
                INSERT                => $UNIQUE_INSERT,
                SELECT                => $UNIQUE_SELECT,
                EXECUTE               => $UNIQUE_EXECUTE,
                UPDATE                => $UNIQUE_update,
                GRANT                 => $UNIQUE_grant,
            },
            NUMBER => {
                MAX_QUERIES_PER_HOUR     => $UNIQUE_MAX_QUERIES_PER_HOUR,
                MAX_CONNECTIONS_PER_HOUR => $UNIQUE_MAX_CONNECTIONS_PER_HOUR,
                MAX_UPDATES_PER_HOUR     => $UNIQUE_MAX_UPDATES_PER_HOUR,
                MAX_USER_CONNECTIONS     => $UNIQUE_MAX_USER_CONNECTIONS,
            }
        }
    );
    initRights( $uname, $hostname );
    ShowDbHeader( $m_sCurrentDb, 0, 'ShowRights' );
    my $save     = translate('save');
    my $markAll  = translate('select_all');
    my $umarkAll = translate('unselect_all');
    print qq|
    <form onsubmit="submitForm(this,'SaveRights','SaveRights');return false;" method="get" enctype="multipart/form-data">
    <input type="hidden" name="action" value="SaveRights"/>
    <input type="hidden" name="session" value="$qstring"/>
    <table class="ShowTables">
    <tr>
      <td class="caption captionRadius" colspan="8">| . translate('rights') . qq|</td></tr>
    <tr>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_UPDATE" |
      . ( HasRight('update') ? 'checked="checked"' : '' ) . qq| />UPDATE</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_DELETE" |
      . ( HasRight('delete') ? 'checked="checked"' : '' ) . qq| />DELETE</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_CREATE" |
      . ( HasRight('create') ? 'checked="checked"' : '' ) . qq| />CREATE</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_DROP" |
      . ( HasRight('drop') ? 'checked="checked"' : '' ) . qq| />DROP</td>
    </tr>
    <tr>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_RELOAD" |
      . ( HasRight('reload') ? 'checked="checked"' : '' ) . qq| />RELOAD</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_SHUTDOWN" |
      . ( HasRight('shutdown') ? 'checked="checked"' : '' ) . qq| />SHUTDOWN</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_PROCESS" |
      . ( HasRight('process') ? 'checked="checked"' : '' ) . qq| />PROCESS</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_FILE" |
      . ( HasRight('file') ? 'checked="checked"' : '' ) . qq| />FILE</td>
    </tr>
    <tr>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_REFERENCES" |
      . ( HasRight('references') ? 'checked="checked"' : '' ) . qq| />REFERENCES</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_INDEX" |
      . ( HasRight('index') ? 'checked="checked"' : '' ) . qq| />INDEX</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_SHOWDATABASES" |
      . ( HasRight('show_db') ? 'checked="checked"' : '' ) . qq| />SHOW DATABASES</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_SUPER" |
      . ( HasRight('super') ? 'checked="checked"' : '' ) . qq| />SUPER</td>
    </tr>
    <tr>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_CREATETEMPORARYTABLES" |
      . ( HasRight('create_tmp_table') ? 'checked="checked"' : '' ) . qq| />CREATE TEMPORARY TABLES</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_LOCKTABLES" |
      . ( HasRight('lock_tables') ? 'checked="checked"' : '' ) . qq| />LOCK TABLES</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_REPLICATIONSLAVE" |
      . ( HasRight('repl_slave') ? 'checked="checked"' : '' ) . qq| />REPLICATION SLAVE</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_REPLICATIONCLIENT" |
      . ( HasRight('repl_client') ? 'checked="checked"' : '' ) . qq| />REPLICATION CLIENT</td>
    </tr>
    <tr>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_INSERT" |
      . ( HasRight('insert') ? 'checked="checked"' : '' ) . qq| />INSERT</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_CREATEVIEW" |
      . ( HasRight('create_view') ? 'checked="checked"' : '' ) . qq| />CREATE VIEW</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_SHOWVIEW" |
      . ( HasRight('show_view') ? 'checked="checked"' : '' ) . qq| />SHOW VIEW</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_CREATEROUTINE" |
      . ( HasRight('create_routine') ? 'checked="checked"' : '' ) . qq| />CREATE ROUTINE</td>
    </tr>
    <tr>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_SELECT" |
      . ( HasRight('select') ? 'checked="checked"' : '' ) . qq| />SELECT</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_ALTERROUTINE" |
      . ( HasRight('alter_routine') ? 'checked="checked"' : '' ) . qq| />ALTER ROUTINE</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_CREATEUSER" |
      . ( HasRight('create_user') ? 'checked="checked"' : '' ) . qq| />CREATE USER</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_EXECUTE" |
      . ( HasRight('execute') ? 'checked="checked"' : '' ) . qq| />EXECUTE</td>
    </tr>

    <tr>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_ALTER" |
      . ( HasRight('alter') ? 'checked="checked"' : '' ) . qq| />ALTER</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_update" |
      . ( HasRight('update') ? 'checked="checked"' : '' ) . qq| />UPDATE</td>
      <td class="values nobr"><input type="checkbox" class="markBox" name="marksBox$UNIQUE_grant" |
      . ( HasRight('grant') ? 'checked="checked"' : '' ) . qq| />GRANT</td>
      <td class="values nobr"></td>
    </tr>
    <tr>
      <td class="caption4" >$m_hrLng->{$ACCEPT_LANGUAGE}{QUERIES_PER_HOUR}</td>
      <td class="caption4" >$m_hrLng->{$ACCEPT_LANGUAGE}{CONNECTIONS_PER_HOUR}</td>
      <td class="caption4" >$m_hrLng->{$ACCEPT_LANGUAGE}{UPDATES_PER_HOUR}</td>
      <td class="caption4" >$m_hrLng->{$ACCEPT_LANGUAGE}{USER_CONNECTIONS}</td>
    </tr>
    <tr>
      <td class="values" ><input type="text" name="$UNIQUE_MAX_QUERIES_PER_HOUR" value="|
      . HasRight('max_questions') . qq|"/></td>
      <td class="values" ><input type="text" name="$UNIQUE_MAX_CONNECTIONS_PER_HOUR" value="|
      . HasRight('max_connections') . qq|"/></td>
      <td class="values" ><input type="text" name="$UNIQUE_MAX_UPDATES_PER_HOUR" value="|
      . HasRight('max_updates') . qq|"/></td>
      <td class="values right" ><input type="text" name="$UNIQUE_MAX_USER_CONNECTIONS" value="|
      . HasRight('max_user_connections') . qq|"/></td>
    </tr>
    <tr>
      <td class="caption4" >| . translate('Host') . qq|</td>
      <td class="caption4" >| . translate('database') . qq|</td>
      <td class="caption4" >| . translate('table') . qq|</td>
      <td class="caption4" >| . translate('User') . qq|</td>
    </tr>
    <tr>
      <td class="values" ><input type="text" name="$UNIQUE_HOST" value="$hostname"/></td>
      <td class="values" >| . GetDatabases($UNIQUE_DB) . q|</td>
      <td class="values" >| . GetTables($UNIQUE_TBL) . q|</td>
      <td class="values" >| . GetUsers( $UNIQUE_USER, $uname ) . qq|</td>
    </tr>
    <tr>
    <td class="values" style="padding-left:0.6em">
    <a id="markAll" href="javascript:markInput(true);" class="links">$markAll</a>
    <a class="links" id="umarkAll" style="display:none;" onclick="markInput(false);">$umarkAll</a>
    </td><td class="submit" colspan="7"><input type="submit" name="submit" value="$save"></td>
    </tr>
    </table>
    </form>|;
} ## end sub ShowRights

=head2 initRights($user,$host)

the rights for $m_hUserRights will be initialized

=cut

sub initRights {
    my $p_sUser = shift;
    my $p_sHost = shift;
    my $hr      = $m_oDatabase->fetch_hashref( 'SELECT * FROM mysql.user where USER = ? && Host = ?', $p_sUser, $p_sHost );
    foreach ( keys %{$hr} ) {
        if ( $_ =~ /(.*)_priv$/ ) {
            my $key = lc($1);
            $m_hUserRights{$key} = $hr->{$_} eq 'Y' ? 1 : 0;
        } elsif ( $_ =~ /(max_.*)$/ ) {
            my $key = lc($1);
            $m_hUserRights{$key} = $hr->{$_} ? $hr->{$_} : 0;
        } else {
            $m_hUserRights{$_} = $hr->{$_};
        } ## end else [ if ( $_ =~ /(.*)_priv$/)]
    } ## end foreach ( keys %{$hr} )
} ## end sub initRights

=head2 HasRight()

private

=cut

sub HasRight {
    return $m_hUserRights{ lc( $_[0] ) };
} ## end sub HasRight

=head2 GetTables()

  return a <select><option>...</option></select> with the Tables from the current DB. 

=cut

sub GetTables {
    my $name     = shift;
    my $selected = defined $_[0] ? $_[0] : 0;
    my @dbs      = $m_oDatabase->fetch_array('show tables');
    my $return   = qq|<select name="$name"><option value="*"></option>|;
    $return .= qq|<option  value="$_" | . ( $selected eq $_ ? 'selected="selected"' : '' ) . qq|>$_</option>| foreach @dbs;
    $return .= '</select>';
    return $return;
} ## end sub GetTables

=head2 GetDatabases()

  returns a <select><option>...</option></select>  with the Databases
  
  GetDatabases(name, selected Databases)

=cut

sub GetDatabases {
    my $name     = shift;
    my $selected = defined $_[0] ? $_[0] : 0;
    my @dbs      = $m_oDatabase->fetch_array('show databases');
    my $return   = qq|<select name="$name">   
                    <option value="*"></option>|;
    $return .= qq|<option  value="$_" | . ( $selected eq $_ ? 'selected="selected"' : '' ) . qq|>$_</option>| foreach @dbs;
    $return .= '</select>';
    return $return;
} ## end sub GetDatabases

=head2 GetUsers()

  (select) GetUsers(name, selected)

=cut

sub GetUsers {
    my $name = shift;
    my $selected = defined $_[0] ? $_[0] : 0;
    my %users;
    my @dbs = $m_oDatabase->fetch_array('select User from mysql.user');
    $users{$_} = $_ foreach @dbs;
    my $return = qq|<select name="$name">|;
    $return .= qq|<option  value="$_" | . ( $selected eq $_ ? 'selected="selected"' : '' ) . qq|>$_</option>| foreach keys %users;
    $return .= '</select>';
    return $return;
} ## end sub GetUsers

=head2 SaveRights()

Action:

=cut

sub SaveRights {
    my $session = param('session');
    session( $session, $m_sUser );
    if ( defined $session ) {
        my $sql = 'GRANT ';
        my @BOOL;
        push @BOOL, 'UPDATE'     if param( 'marksBox' . $m_hrParams->{BOOL}{UPDATE} ) eq 'on';
        push @BOOL, 'DELETE'     if param( 'marksBox' . $m_hrParams->{BOOL}{DELETE} ) eq 'on';
        push @BOOL, 'CREATE'     if param( 'marksBox' . $m_hrParams->{BOOL}{CREATE} ) eq 'on';
        push @BOOL, 'DROP'       if param( 'marksBox' . $m_hrParams->{BOOL}{DROP} ) eq 'on';
        push @BOOL, 'RELOAD'     if param( 'marksBox' . $m_hrParams->{BOOL}{RELOAD} ) eq 'on';
        push @BOOL, 'SHUTDOWN'   if param( 'marksBox' . $m_hrParams->{BOOL}{SHUTDOWN} ) eq 'on';
        push @BOOL, 'PROCESS'    if param( 'marksBox' . $m_hrParams->{BOOL}{PROCESS} ) eq 'on';
        push @BOOL, 'FILE'       if param( 'marksBox' . $m_hrParams->{BOOL}{FILE} ) eq 'on';
        push @BOOL, 'REFERENCES' if param( 'marksBox' . $m_hrParams->{BOOL}{REFERENCES} ) eq 'on';
        push @BOOL, 'INDEX'      if param( 'marksBox' . $m_hrParams->{BOOL}{INDEX} ) eq 'on';
        push @BOOL, 'ALTER'      if param( 'marksBox' . $m_hrParams->{BOOL}{ALTER} ) eq 'on';
        push @BOOL, 'SHOW DATABASES'
          if param( 'marksBox' . $m_hrParams->{BOOL}{SHOWDATABASES} ) eq 'on';
        push @BOOL, 'SUPER' if param( 'marksBox' . $m_hrParams->{BOOL}{SUPER} ) eq 'on';
        push @BOOL, 'CREATE TEMPORARY TABLES'
          if param( 'marksBox' . $m_hrParams->{BOOL}{CREATETEMPORARYTABLES} ) eq 'on';
        push @BOOL, 'LOCK TABLES' if param( 'marksBox' . $m_hrParams->{BOOL}{LOCKTABLES} ) eq 'on';
        push @BOOL, 'REPLICATION CLIENT'
          if param( 'marksBox' . $m_hrParams->{BOOL}{REPLICATIONCLIENT} ) eq 'on';
        push @BOOL, 'CREATE VIEW' if param( 'marksBox' . $m_hrParams->{BOOL}{CREATEVIEW} ) eq 'on';
        push @BOOL, 'SHOW VIEW'   if param( 'marksBox' . $m_hrParams->{BOOL}{SHOWVIEW} ) eq 'on';
        push @BOOL, 'CREATE ROUTINE'
          if param( 'marksBox' . $m_hrParams->{BOOL}{CREATEROUTINE} ) eq 'on';
        push @BOOL, 'ALTER ROUTINE'
          if param( 'marksBox' . $m_hrParams->{BOOL}{ALTERROUTINE} ) eq 'on';
        push @BOOL, 'CREATE USER' if param( 'marksBox' . $m_hrParams->{BOOL}{CREATEUSER} ) eq 'on';
        push @BOOL, 'REPLICATION SLAVE'
          if param( 'marksBox' . $m_hrParams->{BOOL}{REPLICATIONSLAVE} ) eq 'on';
        push @BOOL, 'INSERT'       if param( 'marksBox' . $m_hrParams->{BOOL}{INSERT} ) eq 'on';
        push @BOOL, 'SELECT'       if param( 'marksBox' . $m_hrParams->{BOOL}{SELECT} ) eq 'on';
        push @BOOL, 'EXECUTE'      if param( 'marksBox' . $m_hrParams->{BOOL}{EXECUTE} ) eq 'on';
        push @BOOL, 'UPDATES'      if param( 'marksBox' . $m_hrParams->{BOOL}{UPDATES} ) eq 'on';
        push @BOOL, 'GRANT OPTION' if param( 'marksBox' . $m_hrParams->{BOOL}{GRANT} ) eq 'on';

        if ( $#BOOL > 0 ) {
            @BOOL = sort(@BOOL);
            for ( my $i = 0 ; $i < $#BOOL ; $i++ ) {
                $sql .= $BOOL[$i] . ",\n";
            } ## end for ( my $i = 0 ; $i < ...)
            $sql .=
              $BOOL[$#BOOL] . ' ON '
              . (
                param( $m_hrParams->{DB} ) ? param( $m_hrParams->{DB} )
                : '*'
              )
              . '.'
              . (
                param( $m_hrParams->{TBL} ) ? param( $m_hrParams->{TBL} )
                : '*'
              )
              . q| TO '|
              . param( $m_hrParams->{DBUSER} ) . "'\@'"
              . param( $m_hrParams->{HOST} ) . "'";
            $sql .= q| WITH GRANT OPTION |;
            $sql .= 'MAX_QUERIES_PER_HOUR ' . param( $m_hrParams->{NUMBER}{MAX_QUERIES_PER_HOUR} );
            $sql .=
              ' MAX_CONNECTIONS_PER_HOUR ' . param( $m_hrParams->{NUMBER}{MAX_CONNECTIONS_PER_HOUR} );
            $sql .= ' MAX_UPDATES_PER_HOUR ' . param( $m_hrParams->{NUMBER}{MAX_UPDATES_PER_HOUR} );
            $sql .= ' MAX_USER_CONNECTIONS ' . param( $m_hrParams->{NUMBER}{MAX_USER_CONNECTIONS} );
            $sql .= ';';
            ExecSql($sql);
        } ## end if ( $#BOOL > 0 )
        $sql = 'REVOKE ';
        my @REVEOKE;
        push @REVEOKE, 'UPDATE'     if param( 'marksBox' . $m_hrParams->{BOOL}{UPDATE} ) ne 'on';
        push @REVEOKE, 'DELETE'     if param( 'marksBox' . $m_hrParams->{BOOL}{DELETE} ) ne 'on';
        push @REVEOKE, 'CREATE'     if param( 'marksBox' . $m_hrParams->{BOOL}{CREATE} ) ne 'on';
        push @REVEOKE, 'DROP'       if param( 'marksBox' . $m_hrParams->{BOOL}{DROP} ) ne 'on';
        push @REVEOKE, 'RELOAD'     if param( 'marksBox' . $m_hrParams->{BOOL}{RELOAD} ) ne 'on';
        push @REVEOKE, 'SHUTDOWN'   if param( 'marksBox' . $m_hrParams->{BOOL}{SHUTDOWN} ) ne 'on';
        push @REVEOKE, 'PROCESS'    if param( 'marksBox' . $m_hrParams->{BOOL}{PROCESS} ) ne 'on';
        push @REVEOKE, 'FILE'       if param( 'marksBox' . $m_hrParams->{BOOL}{FILE} ) ne 'on';
        push @REVEOKE, 'REFERENCES' if param( 'marksBox' . $m_hrParams->{BOOL}{REFERENCES} ) ne 'on';
        push @REVEOKE, 'INDEX'      if param( 'marksBox' . $m_hrParams->{BOOL}{INDEX} ) ne 'on';
        push @REVEOKE, 'ALTER'      if param( 'marksBox' . $m_hrParams->{BOOL}{ALTER} ) ne 'on';
        push @REVEOKE, 'SHOW DATABASES'
          if param( 'marksBox' . $m_hrParams->{BOOL}{SHOWDATABASES} ) ne 'on';
        push @REVEOKE, 'SUPER' if param( 'marksBox' . $m_hrParams->{BOOL}{SUPER} ) ne 'on';
        push @REVEOKE, 'CREATE TEMPORARY TABLES'
          if param( 'marksBox' . $m_hrParams->{BOOL}{CREATETEMPORARYTABLES} ) ne 'on';
        push @REVEOKE, 'LOCK TABLES' if param( 'marksBox' . $m_hrParams->{BOOL}{LOCKTABLES} ) ne 'on';
        push @REVEOKE, 'REPLICATION CLIENT'
          if param( 'marksBox' . $m_hrParams->{BOOL}{REPLICATIONCLIENT} ) ne 'on';
        push @REVEOKE, 'CREATE VIEW' if param( 'marksBox' . $m_hrParams->{BOOL}{CREATEVIEW} ) ne 'on';
        push @REVEOKE, 'SHOW VIEW'   if param( 'marksBox' . $m_hrParams->{BOOL}{SHOWVIEW} ) ne 'on';
        push @REVEOKE, 'CREATE ROUTINE'
          if param( 'marksBox' . $m_hrParams->{BOOL}{CREATEROUTINE} ) ne 'on';
        push @REVEOKE, 'ALTER ROUTINE'
          if param( 'marksBox' . $m_hrParams->{BOOL}{ALTERROUTINE} ) ne 'on';
        push @REVEOKE, 'CREATE USER' if param( 'marksBox' . $m_hrParams->{BOOL}{CREATEUSER} ) ne 'on';
        push @REVEOKE, 'REPLICATION SLAVE'
          if param( 'marksBox' . $m_hrParams->{BOOL}{REPLICATIONSLAVE} ) ne 'on';
        push @REVEOKE, 'INSERT'       if param( 'marksBox' . $m_hrParams->{BOOL}{INSERT} ) ne 'on';
        push @REVEOKE, 'SELECT'       if param( 'marksBox' . $m_hrParams->{BOOL}{SELECT} ) ne 'on';
        push @REVEOKE, 'EXECUTE'      if param( 'marksBox' . $m_hrParams->{BOOL}{EXECUTE} ) ne 'on';
        push @REVEOKE, 'UPDATE'       if param( 'marksBox' . $m_hrParams->{BOOL}{UPDATE} ) ne 'on';
        push @REVEOKE, 'GRANT OPTION' if param( 'marksBox' . $m_hrParams->{BOOL}{GRANT} ) ne 'on';

        if ( $#REVEOKE > 0 ) {
            @REVEOKE = sort(@REVEOKE);
            for ( my $i = 0 ; $i < $#REVEOKE ; $i++ ) {
                $sql .= $REVEOKE[$i] . ",\n";
            } ## end for ( my $i = 0 ; $i < ...)
            $sql .=
              $REVEOKE[$#REVEOKE] . ' ON '
              . (
                param( $m_hrParams->{DB} ) ? param( $m_hrParams->{DB} )
                : '*'
              )
              . '.'
              . (
                param( $m_hrParams->{TBL} ) ? param( $m_hrParams->{TBL} )
                : '*'
              )
              . q| FROM '|
              . param( $m_hrParams->{DBUSER} ) . "'\@'"
              . param( $m_hrParams->{HOST} ) . "'";
            $sql .= ';';
            ExecSql($sql);
        } ## end if ( $#REVEOKE > 0 )
    } ## end if ( defined $session )
    ShowRights( param( $m_hrParams->{DBUSER} ), param( $m_hrParams->{HOST} ) );
} ## end sub SaveRights

=head2 CreateUser()

Action;

=cut

sub CreateUser {
    my $password = $m_oDatabase->quote( param('password') );
    my $name     = $m_oDatabase->quote( param('name') );
    my $host     = $m_oDatabase->quote( param('host') );
    ExecSql("CREATE USER $name\@$host IDENTIFIED BY $password");
    ShowUsers();
} ## end sub CreateUser

=head2 DeleteUser()

Action:

=cut

sub DeleteUser {
    my $name = $m_oDatabase->quote( param('user') );
    my $host = $m_oDatabase->quote( param('host') );
    $name .= "\@$host" if defined $host;
    ExecSql("DROP USER $name");
    ShowUsers();
} ## end sub DeleteUser

=head2 ShowDatabases()

Action:

=cut

sub ShowDatabases {
    my @a = $m_oDatabase->fetch_AoH('SHOW DATABASES');
    for ( my $i = 0 ; $i <= $#a ; $i++ ) {
        my $kb = 0;
        my $db = $m_dbh->quote_identifier( $a[$i]->{Database} );
        my @b  = $m_oDatabase->fetch_AoH("SHOW TABLE STATUS from $db ");
        for ( my $j = 0 ; $j <= $#b ; $j++ ) {
            $kb +=
                ( $b[$j]->{Index_length} and $b[$i]->{Data_length} ) ? $b[$j]->{Index_length} + $b[$i]->{Data_length}
              : $b[$j]->{Index_length} ? $b[$j]->{Index_length}
              : $b[$i]->{Data_length}  ? $b[$i]->{Data_length}
              :                          0;
        } ## end for ( my $j = 0 ; $j <=...)
        $a[$i]->{Size} = $kb > 0 ? sprintf( '%.2f', $kb / 1024 ) : 0;
        $a[$i]->{Tables} = $#b > 0 ? $#b : 0;
    } ## end for ( my $i = 0 ; $i <=...)
    my $orderby = defined param('orderBy')        ? param('orderBy')        : 'Name';
    my $state   = param('desc')                   ? 1                       : 0;
    my $nstate  = $state                          ? 0                       : 1;
    my $lpp     = defined param('links_pro_page') ? param('links_pro_page') : 20;
    $lpp = $lpp =~ /(\d\d\d?)/ ? $1 : $lpp;
    my $end = $m_nStart + $lpp > $#a ? $#a : $m_nStart + $lpp;
    if ( $#a > $lpp ) {
        my %needed = (
            start          => $m_nStart,
            length         => $#a,
            style          => $m_sStyle,
            action         => 'ShowDatabases',
            append         => "&links_pro_page=$lpp&orderBy=$orderby&desc=$state",
            path           => $m_hrSettings->{cgi}{bin},
            links_pro_page => $lpp,
            server         => "$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}",
        );
        $PAGES = makePages( \%needed );
    } else {
        $end = $#a;
    } ## end else [ if ( $#a > $lpp ) ]
    @a = sort { round( $a->{$orderby} ) <=> round( $b->{$orderby} ) } @a;
    @a = reverse @a if $state;
    ShowDbHeader( $m_sCurrentDb, 0, 'ShowDatabases' );
    my $menu =
      translate('links_pro_page') . ' | '
      . (
        $#a > 10
        ? a(
            {
                href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDatabases&links_pro_page=10&von=$m_nStart&orderBy=$orderby&desc=$state','ShowDatabases','ShowDatabases')",
                class => $lpp == 10 ? 'menuLink2' : 'menuLink3'
            },
            '10'
          )
        : ''
      )
      . (
        $#a > 20
        ? '&#160;'
          . a(
            {
                href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDatabases&links_pro_page=20&von=$m_nStart&orderBy=$orderby&desc=$state','ShowDatabases','ShowDatabases')",
                class => $lpp == 20 ? 'menuLink2' : 'menuLink3'
            },
            '20'
          )
        : ''
      )
      . (
        $#a > 30
        ? '&#160;'
          . a(
            {
                href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDatabases&links_pro_page=30&von=$m_nStart&orderBy=$orderby&desc=$state','ShowDatabases','ShowDatabases')",
                class => $lpp == 30 ? 'menuLink2' : 'menuLink3'
            },
            '30'
          )
        : ''
      )
      . (
        $#a > 100
        ? '&#160;'
          . a(
            {
                href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDatabases&links_pro_page=100&von=$m_nStart&orderBy=$orderby&desc=$state','ShowDatabases','ShowDatabases')",
                class => $lpp == 100 ? 'menuLink2' : 'menuLink3'
            },
            '100'
          )
        : ''
      )
      . (
        $#a > 100
        ? '&#160;'
          . a(
            {
                href =>
"javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDatabases&links_pro_page=1000&von=$m_nStart&orderBy=$orderby&desc=$state','ShowDatabases','ShowDatabases')",
                class => $lpp == 1000 ? 'menuLink2' : 'menuLink3'
            },
            '1000'
          )
        : ''
      ) if $#a > 10;
    my $createDatabase = translate('CreateDatabase');
    my $execSql        = translate('sql');
    my $sqlSearch      = translate('SqlSearch');
    my $changeDB       = translate('ChangeCurrentDb');
    print qq(
              <form onsubmit="submitForm(this,'ShowDatabases','ShowDatabases');return false;" method="get" enctype="multipart/form-data">
              <input type="hidden" name="action" value="MultipleDbAction"/>
              <table class="ShowTables" id="toolbarTable"> 
              <tr><td colspan="7" class="captionRadius"">$m_sCurrentHost</td></tr>
              <tr><td colspan="7" id="toolbar" class="toolbar">
              <div id="toolbarcontent" class="toolbarcontent">
               <a class="toolbarButton" onclick="showPopup('ChangeCurrentDb')" class="link"  title="$changeDB">$changeDB</a>
              <a class="toolbarButton" onclick="showPopup('CreateDatabase')" class="link"  title="$createDatabase">$createDatabase</a>
              <a class="toolbarButton" onclick="showPopup('SqlSearch')" class="link"  title="$sqlSearch">$sqlSearch</a>
              <a class="toolbarButton" onclick="showSQLEditor()" class="link"  title="$execSql">$execSql</a>
              </div>
              </tr>);
    print qq(<tr><td colspan="7" id="toolbar2" class="toolbar2"><div id="toolbarcontent2" class="toolbarcontent">
          <div class="makePages">$PAGES</div>
              <div class="pagePerSite">$menu</div>) if $#a > $lpp;
    print q(</div>
              </td>
              </tr> 
              <tr class="values">
              <td class="caption2 checkbox"></td>
              <td class="caption2"> )
      . qq|<a class="captionLink" href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDatabases&links_pro_page=$lpp&von=$m_nStart&orderBy=Name&desc=$nstate','ShowDatabases','ShowDatabases')">$m_hrLng->{$ACCEPT_LANGUAGE}{name}</a>|
      . (
          $orderby eq 'Name'
        ? $state
              ? qq|&#160;<img src="style/$m_sStyle/buttons/up.png" />|
              : qq|&#160;<img src="style/$m_sStyle/buttons/down.png" />|
        : ''
      )
      . q(</td>
              <td class="caption2"> )
      . qq|<a class="captionLink" href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDatabases&links_pro_page=$lpp&von=$m_nStart&orderBy=Tables&desc=$nstate','ShowDatabases','ShowDatabases')">$m_hrLng->{$ACCEPT_LANGUAGE}{showtables}</a>|
      . (
          $orderby eq 'Tables'
        ? $state
              ? qq|&#160;<img src="style/$m_sStyle/buttons/up.png" />|
              : qq|&#160;<img src="style/$m_sStyle/buttons/down.png" />|
        : ''
      )
      . q(</td>
              <td class="caption2"> )
      . qq|<a class="captionLink" href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDatabases&links_pro_page=$lpp&von=$m_nStart&orderBy=Size&desc=$nstate','ShowDatabases','ShowDatabases')">$m_hrLng->{$ACCEPT_LANGUAGE}{size}&#160;(kb)</a>|
      . (
          $orderby eq 'Size'
        ? $state
              ? qq|&#160;<img src="style/$m_sStyle/buttons/up.png" />|
              : qq|&#160;<img src="style/$m_sStyle/buttons/down.png" />|
        : ''
      )
      . q(</td>
              <td class="caption2 checkbox"></td>
              </tr>
    );
    my $trdatabase = translate('database');
    my $trdelete   = translate('delete');
    my $change     = translate('EditTable');

    for ( my $i = $m_nStart ; $i <= $end ; $i++ ) {
        my $class = $i == $m_nStart ? 'firstValue' : 'values';
        print qq(
              <tr class="values">
              <td class="checkbox" width="5%"><input type="checkbox" name="markBox$i" class="markBox" value="$a[$i]->{Database}" /></td>
              <td class="$class" width="10%"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowTables&m_ChangeCurrentDb=$a[$i]->{Database}&desc=0','ShowTables','ShowTables')">$a[$i]->{Database}</a></td>
              <td class="$class" width="10%">$a[$i]->{Tables}</td>
              <td class="$class" width="15%">$a[$i]->{Size}</td>
              <td class="$class right" width="*"><a href="javascript:void(0)" onclick="confirm2(' $trdelete?',requestURI,'$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=DropDatabase&db=$a[$i]->{Database}','DropDatabase','DropDatabase')"><img src="style/$m_sStyle/buttons/delete.png" title="$trdelete" /></a></td>
              </tr>
       );
    } ## end for ( my $i = $m_nStart...)
    my $drop     = translate('drop_database');
    my $mmark    = translate('selected');
    my $markAll  = translate('select_all');
    my $umarkAll = translate('unselect_all');
    my $export   = translate('export');
    print qq|
    <tr>
    <td class="checkbox"><img src="style/$m_sStyle/buttons/feil.gif" alt=''/></td>
    <td colspan="7" align="left">
    <table class="MultipleAction" width="100%">
    <tr><td colspan="2" align="left">
    <a id="markAll" href="javascript:markInput(true);" class="links">$markAll</a><a class="links" id="umarkAll" style="display:none;" href="javascript:markInput(false);">$umarkAll</a></td>
    <td class="submit">
    <select name="MultipleDbAction" class="MultipleAction" onchange="if(this.value != '$mmark' )submitForm(this.form,this.value,this.value)">
    <option value="$mmark" selected="selected">$mmark</option>
    <option value="dropDb">$drop</option>
    <option value="exportDb">$export</option>
    </select>
    </td>
    </tr></table>
    </td>
    </tr>
    </table>
    </form>|;
} ## end sub ShowDatabases

=head2 DropDatabase( databaseName )

Action:

=cut

sub DropDatabase {
    my $db = param('db') ? param('db') : shift;
    my $db2 = $m_dbh->quote_identifier($db);
    ExecSql("Drop DATABASE $db2");
    ChangeDb(
        {
            name     => "$m_hrSettings->{database}{name}",
            host     => $m_sCurrentHost,
            user     => $m_sCurrentUser,
            password => $m_sCurrentPass,
        }
    );
    ShowDatabases();
} ## end sub DropDatabase

=head2 CreateDatabase( databaseName )

Action:

=cut

sub CreateDatabase {
    my $db = param('name') ? param('name') : shift;
    my $db2 = $m_dbh->quote_identifier($db);
    ExecSql("Create DATABASE $db2");
    ShowDatabases();
} ## end sub CreateDatabase

=head2 ShowProcesslist()

Action:

=cut

sub ShowProcesslist {
    ShowDbHeader( $m_sCurrentDb, 0, 'ShowProcesslist' );
    my $processlist = translate('processlist');
    my @a           = $m_oDatabase->fetch_AoH('SHOW PROCESSLIST');
    for ( my $i = 0 ; $i <= $#a ; $i++ ) {
        if ( $a[$i]->{Info} eq 'SHOW PROCESSLIST' ) {
            $m_processlist[0] = $a[$i];
        } elsif ( $a[$i]->{Command} eq 'Sleep' ) {
            $m_processlist[1] = $a[$i];
        } else {
            push @m_processlist, $a[$i];
        } ## end else [ if ( $a[$i]->{Info} eq...)]
    } ## end for ( my $i = 0 ; $i <=...)
    my $reload = param('reload');
    $reload = defined $reload ? $reload : 0;

    # no warnings;
    print q(
      <div class="overflow">
      <table class="ShowTables">
      <tr class="caption">
      <td class="caption captionLeft" align="left">Time</td>
      <td class="caption" align="left">Command</td>
      <td class="caption" align="left">db</td>
      <td class="caption" align="left">Id</td>
      <td class="caption" align="left">Info</td>
      <td class="caption" align="left">User</td>
      <td class="caption" align="left">State</td>
      <td class="caption" align="left">Host</td>
      <td class="caption captionRight" align="left"></td>
      </tr>) unless $reload;
    for ( my $i = 0 ; $i <= $#m_processlist ; $i++ ) {
        print qq(
      <tr class="values" align="left">
      <td class="values" align="left">$m_processlist[$i]->{Time}</td>
      <td class="values" align="left">$m_processlist[$i]->{Command}</td>
      <td class="values" align="left">$m_processlist[$i]->{db}</td>
      <td class="values" align="left">$m_processlist[$i]->{Id}</td>
      <td class="values" align="left">$m_processlist[$i]->{Info}</td>
      <td class="values" align="left">$m_processlist[$i]->{User}</td>
      <td class="values" align="left">$m_processlist[$i]->{State}</td>
      <td class="values" align="left">$m_processlist[$i]->{Host}</td>
      <td class="values nobr" align="left"><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=killProzess&id=$m_processlist[$i]->{Id}','ShowProcesslist','ShowProcesslist')">Kill ($m_processlist[$i]->{Id})</a></td>   
      </tr>);
    } ## end for ( my $i = 0 ; $i <=...)
    print qq|</table></div>
    <script>setTimeout(function start(){if(window.location.search.match(/ShowProcesslist/))requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowProcesslist&reload','ShowProcesslist','ShowProcesslist',false,false,'GET',false)},1000)</script>|
      unless $reload;
    if ( $#m_processlist > 20 ) {
        shift @m_processlist;
    } ## end if ( $#m_processlist >...)
} ## end sub ShowProcesslist

=head2 killProzess()

Action:

=cut

sub killProzess {
    my $id = param('id');
    $id = $id =~ /(\d+)/ ? $1 : 0;
    $m_oDatabase->void("kill $id") if $id;
    ShowProcesslist();
} ## end sub killProzess

=head2 ShowVariables()

Action:

=cut

sub ShowVariables {
    ShowDbHeader( $m_sCurrentDb, 0, 'ShowVariables' );
    my $showVariables = translate('ShowVariables');
    my @a             = $m_oDatabase->fetch_AoH('Show Variables');
    print qq(
    <div class="overflow">
    <table class="ShowTables">
    <tr class="caption">
    <td colspan="2" class="caption captionRadius">$showVariables</td></tr>);
    for ( my $i = 0 ; $i <= $#a ; $i++ ) {
        print
qq(<tr class="values" align="left"><td class="value" align="left">$a[$i]->{Variable_name}</td><td class="value" align="left">$a[$i]->{Value}</td></tr>);
    } ## end for ( my $i = 0 ; $i <=...)
    print '</table></div>';
} ## end sub ShowVariables

=head2 ChangeCharset()

Action:

=cut

sub ChangeCharset {
    my $tbl = param('table');
    $tbl = $m_dbh->quote_identifier($tbl);
    my $charset = param('charset');
    $charset = $m_oDatabase->quote($charset);
    ExecSql("ALTER TABLE $tbl CONVERT TO CHARACTER SET $charset;");
    EditTable( param('table') );
} ## end sub ChangeCharset

=head2 searchForm()

Action:

=cut

sub searchForm {
    my @tables  = $m_oDatabase->fetch_array('show Tables;');
    my $search  = param('query') ? param('query') : '';
    my $ts      = translate('search');
    my $regexp  = translate('regexp');
    my $checked = defined param('regexp') ? 'checked="checked"' : '';
    my $form    = qq|
    <form class="dbForm" onsubmit="submitForm(this,'searchDatabase','searchDatabase');return false;" name="search" method="get" accept-charset="UTF-8">
    <div align="center">
    <table class="searchForm">
    <tr class="caption">
    <td class="captionSearchForm" align="center">Table</td>
    <td class="captionSearchForm" align="center">Column</td>
    </tr>
    <tr>
    <td class="value">
    <select class="tablelist" id="tablelist" multiple="multiple" name="tablelist" size="5" style="width:100%">|;
    for ( my $i = 0 ; $i <= $#tables ; $i++ ) {
        my @te = param('tablelist');
        my %KEYS;
        $KEYS{$_} = 1 foreach @te;
        $form .=
            qq(<option value="$tables[$i]")
          . ( $KEYS{ $tables[$i] } ? 'selected="selected"' : '' )
          . qq( class="table" onclick="DisplayTable('a$tables[$i]');">$tables[$i]</option>);
    } ## end for ( my $i = 0 ; $i <=...)
    $form .= '</select></td><td class="value">';
    for ( my $i = 0 ; $i <= $#tables ; $i++ ) {
        my $table = $tables[$i];
        $table = $m_dbh->quote_identifier($table);
        my @tables2 = $m_oDatabase->fetch_AoH("show columns from $table");
        $form .=
            qq|<select class="tablelist" multiple="multiple" id="a$tables[$i]" name="$tables[$i]" size="5" style="|
          . ( $i == 0 ? '' : 'display:none;' )
          . q|width:100%;">|;
        for ( my $j = 0 ; $j <= $#tables2 ; $j++ ) {
            my @te = param( $tables[$i] );
            my %KEYS;
            $KEYS{$_} = 1 foreach @te;
            $form .=
                '<option '
              . ( $KEYS{ $tables2[$j]->{'Field'} } ? 'selected="selected"' : '' )
              . qq(value="$tables2[$j]->{'Field'}" class="table">$tables2[$j]->{'Field'}</option>);
        } ## end for ( my $j = 0 ; $j <=...)
        $form .= '</select>';
    } ## end for ( my $i = 0 ; $i <=...)
    my $markAll  = translate('select_all');
    my $umarkAll = translate('unselect_all');
    my $limit    = translate('limit');
    $form .= qq|
    </td>
    </tr>
    <tr>
    <td align="center" colspan="2">
    <script language="JavaScript">nCurrentShown = 'a$tables[0]';</script>
    <a id="markAll2" href="javascript:markTables(true);" class="links">$markAll</a>
    <a class="links" id="umarkAll2" style="display:none;" href="javascript:markTables(false);">$umarkAll</a>
    </td>
    </tr>
    <tr>
    <td colspan="2" align="center">
    or&#160;<input type="radio" class="radioButton" value="or"  name="and_or" checked="checked"/>&#160;
    and&#160;<input type="radio" class="radioButton" value="and"  name="and_or"/><br/>
    $regexp: <input type="checkbox" $checked name="regexp" value="regexp" alt="regexp" align="left"/><br/>
    $limit : <input align="left" type="text" title="$ts" name="limit" value="100" style="width:80px;"/>
    <br/>
    </td>
    </tr>
    <tr>
    <td colspan="2" align="center">
    <input  type="hidden" name="action"  value="searchDatabase"/>
    <input align="left" type="text" title="$ts" name="query" id="query" value="$search"/>&#160;
    <input type="submit" name="submit" value="$ts" maxlength="15" alt="$ts" align="left"/>
    </td></tr></table></div></form>|;
    return $form;
} ## end sub searchForm

=head2 searchDatabase()

Action:

=cut

sub searchDatabase {
    my $sQuery = param('query');
    $sQuery = $m_oDatabase->quote($sQuery);
    my $limit  = param('limit') =~ /(\d+)/ ? $1 : 100;       #todo
    my @tables = param('tablelist');
    my $and_or = param('and_or') ? param('and_or') : 'or';
    for ( my $i = 0 ; $i <= $#tables ; $i++ ) {
        my $request = '';
        my @columns = param( $tables[$i] );
        my $table   = $m_dbh->quote_identifier( $tables[$i] );
        my $hash    = 0;
        if ( $#columns eq -1 ) {
            $hash    = 1;
            @columns = $m_oDatabase->fetch_AoH("show columns from $table");
        } ## end if ( $#columns eq -1 )
        for ( my $j = 0 ; $j <= $#columns ; $j++ ) {
            $columns[$j] = (
                  $hash
                ? $m_dbh->quote_identifier( $columns[$j]->{'Field'} )
                : $m_dbh->quote_identifier( $columns[$j] )
            );
        } ## end for ( my $j = 0 ; $j <=...)
        my $col;
        if ( param('regexp') ) {
            for ( my $j = 0 ; $j < $#columns ; $j++ ) {
                $col .= " (  $columns[$j] REGEXP  $sQuery ) $and_or ";
            } ## end for ( my $j = 0 ; $j < ...)
            $col .= "( $columns[$#columns] REGEXP $sQuery )";
        } else {
            $col = join " like $sQuery $and_or ", @columns;
            $col .= "like $sQuery";
        } ## end else [ if ( param('regexp') )]
        $request .= "SELECT * FROM $table  where $col LIMIT 0 , $limit;";
        ExecSql( $request, 1, $tables[$i] );
    } ## end for ( my $i = 0 ; $i <=...)
    ShowTables();
} ## end sub searchDatabase

=head2 showProfile()

Action:

=cut

sub showProfile {
    ShowDbHeader( $m_sCurrentDb, 0, 'showProfile' );
    my $hrUser              = $m_oDatabase->fetch_hashref("select * from  users where user = '$m_sUser'");
    my $wrong_username_text = translate('wrong_username_text');
    my $right_username_text = translate('right_username_text');
    my $wrong_passwort_text = translate('wrong_passwort_text');
    my $right_passwort_text = translate('right_passwort_text');
    print qq|
  <div class="ShowTables marginTop">
  <form  name="changePassword" target="_parent" method="get" onsubmit="submitForm(this,'saveProfile','saveProfile');return false;">
  <label for="user">| . translate('name') . q(</label>
  <br/>
  <input type="text" id="user" data-regexp=")
      . '/^\w{4,100}$/' . qq(" data-error="$wrong_username_text" data-right="$right_username_text" name="user" value="$hrUser->{user}">
  <br/>
  <label for="password">) . translate('password') . qq|</label>
  <br/>
  <input type="password" data-regexp="/.{6,50}/" data-error="$wrong_passwort_text"  data-right="$right_passwort_text" id="password" name="pass"/>
  <br/>
  <label for="newpass">| . translate('newpass') . qq|</label>
  <br/>
  <input type="password" data-regexp="/.{6,50}/" data-error="$wrong_passwort_text"  data-right="$right_passwort_text" id="password" name="newpass"/>
  <br/>
  <label for="retry">| . translate('retry') . qq|</label>
  <br/>
  <input type="password" data-regexp="/.{6,50}/" data-error="$wrong_passwort_text"  data-right="$right_passwort_text" id="password" name="retry"/>
  <br/>
  <br/>
  <input type="submit"  name="submit" value="| . translate('save') . q|"/>
  <input type="hidden" name="action" value="saveProfile"/>
  </form></div>|;
} ## end sub showProfile

=head2 saveProfile

Action:

=cut

sub saveProfile {
    my $pass    = param( translate('pass') );
    my $newpass = param( translate('newpass') );
    my $retry   = param( translate('retry') );
    ShowDbHeader( $m_sCurrentDb, 0, 'saveProfile' );
    my $md5 = new MD5;
    $md5->add($m_sUser);
    $md5->add($pass);
    my $cyrptpass = $md5->hexdigest();
    my $pwChanged = 0;

    if (    $m_oDatabase->checkPass( $m_sUser, $cyrptpass )
        and $newpass eq $retry
        and $newpass =~ /^\S{6,50}$/ ) {
        $pwChanged = 1;
        my $md5 = new MD5;
        $md5->add($m_sUser);
        $md5->add($newpass);
        my $newpass = $md5->hexdigest();
        $m_oDatabase->void("update `users` set `pass` = '$newpass' where user = '$m_sUser'");
    } else {
        &showProfile();
    } ## end else [ if ( $m_oDatabase->checkPass...)]
    print '<div class="ShowTables"><b>' . translate('done') . '</b>
    <br/>
    <table class="flat">
    <tr>
    <td>' . translate('newpass') . '</td>
    <td>' . $newpass . '</td>
    </tr>' if $pwChanged;
    print '</table>'
      . a(
        {
            href  => "javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=showProfile','showProfile','showProfile')",
            class => 'links'
        },
        translate('next')
      ) . '</div>';
} ## end sub saveProfile

=head2 GetTypes

  return the data types

  GetTypes( selected type, select_name, table, field , \$hrSet );

=cut

sub GetTypes {
    my $type  = shift;
    my $name  = shift;
    my $tbl   = shift;
    my $field = shift;
    my $hrSet = shift;
    $type =~ s/(\w+).*/uc $1/eg;
    my $options = '';
    if ( defined $field and defined $tbl and ref $hrSet ne 'REF' ) {
        my @col = $m_oDatabase->fetch_array( "show columns from $tbl where `field` = ?", $field );
        if ( $col[1] and $col[1] =~ /set\((.+)\)/ ) {
            for ( split /,/, $1 ) {
                /^'(.+)'$/;
                my $value = $1;
                $options .= qq|<option class="set" value="$value">$value</option>\n|;
            } ## end for ( split /,/, $1 )
        } ## end if ( $col[1] and $col[...])
    } elsif ( ref $hrSet eq 'REF' ) {
        for ( my $i = 0 ; $i <= $#{ $$hrSet->{$field} } ; $i++ ) {
            $options .= qq|<option class="set" value="$$hrSet->{$field}[$i]">$$hrSet->{$field}[$i]</option>\n|;
        } ## end for ( my $i = 0 ; $i <=...)
        $type = 'SET' if $#{ $$hrSet->{$field} } >= 0;
    } else {
        $options .= '<option></option>';
    } ## end else [ if ( defined $field and...)]
    $typId++;
    if ( defined $type and defined $name ) {
        my $return = qq|<table class="flat">
        <tr>
        <td>
        <select title="data-types" id="ChooseType$typId" class="editTable" onchange="ChangeToolTip('ChooseType$typId',this.options[this.options.selectedIndex].value);if(this.options[this.options.selectedIndex].value =='SET')visible('SET$name');else{ hide('SET$name');clearSelect('select$name');hide(openMenu);nCurrentRow = 0;}"  name="$name">|;
        $return .= '<option></option>';
        $return .=
          $type eq 'TINYINT'
          ? '<option  value="TINYINT"   selected="selected" title="Type">TINYINT</option>'
          : '<option  value="TINYINT" >TINYINT</option>';
        $return .=
          $type eq 'SMALLINT'
          ? '<option selected="selected"  value="SMALLINT" >SMALLINT</option>'
          : '<option value="SMALLINT" >SMALLINT</option>';
        $return .=
          $type eq 'MEDIUMINT'
          ? '<option selected="selected" value="MEDIUMINT" >MEDIUMINT</option>'
          : '<option value="MEDIUMINT" >MEDIUMINT</option>';
        $return .=
          $type eq 'INT'
          ? '<option selected="selected" value="INT">INT</option>'
          : '<option value="INT" >INT</option>';
        $return .=
          $type eq 'BIGINT'
          ? '<option selected="selected" value="BIGINT" >BIGINT</option>'
          : '<option value="BIGINT" >BIGINT</option>';
        $return .=
          $type eq 'FLOAT'
          ? '<option selected="selected" value="FLOAT" >FLOAT</option>'
          : '<option value="FLOAT" >FLOAT</option>';
        $return .=
          $type eq 'DOUBLE'
          ? '<option selected="selected" value="DOUBLE" >DOUBLE</option>'
          : '<option value="DOUBLE" >DOUBLE</option>';
        $return .=
          $type eq 'DECIMAL'
          ? '<option selected="selected" value="DECIMAL" >DECIMAL</option>'
          : '<option value="DECIMAL" >DECIMAL</option>';
        $return .=
          $type eq 'DATE'
          ? '<option selected="selected" value="DATE" >DATE</option>'
          : '<option value="DATE">DATE</option>';
        $return .=
          $type eq 'DATETIME'
          ? '<option selected="selected" value="DATETIME" >DATETIME</option>'
          : '<option value="DATETIME" >DATETIME</option>';
        $return .=
          $type eq 'TIMESTAMP'
          ? '<option selected="selected" value="TIMESTAMP" >TIMESTAMP</option>'
          : '<option value="TIMESTAMP" >TIMESTAMP</option>';
        $return .=
          $type eq 'TIME'
          ? '<option selected="selected" value="TIME" >TIME</option>'
          : '<option value="TIME" >TIME</option>';
        $return .=
          $type eq 'YEAR'
          ? '<option selected="selected"  value="YEAR" >YEAR</option>'
          : '<option value="YEAR"  >YEAR</option>';
        $return .=
          $type eq 'CHAR'
          ? '<option selected="selected"  value="CHAR" >CHAR</option>'
          : '<option value="CHAR" >CHAR</option>';
        $return .=
          $type eq 'VARCHAR'
          ? '<option selected="selected"  value="VARCHAR" >VARCHAR</option>'
          : '<option value="VARCHAR">VARCHAR</option>';
        $return .=
          $type eq 'BLOB'
          ? '<option selected="selected"  value="BLOB">BLOB</option>'
          : '<option value="BLOB" >BLOB</option>';
        $return .=
          $type eq 'TEXT'
          ? '<option selected="selected"  value="TEXT">TEXT</option>'
          : '<option value="TEXT"  >TEXT</option>';
        $return .=
          $type eq 'ENUM'
          ? '<option selected="selected"  value="ENUM">ENUM</option>'
          : '<option value="ENUM"  >ENUM</option>';
        $return .=
          $type eq 'SET'
          ? '<option selected="selected"  value="SET">SET</option>'
          : '<option value="SET">SET</option>';
        $return .=
          $type eq 'TINYBLOB'
          ? '<option selected="selected"  value="SET">SET</option>'
          : '<option value="TINYBLOB">TINYBLOB</option>';
        $return .=
          $type eq 'MEDIUMBLOB'
          ? '<option selected="selected" value="MEDIUMBLOB">MEDIUMBLOB</option>'
          : '<option value="MEDIUMBLOB">MEDIUMBLOB</option>';
        $return .=
          $type eq 'LONGBLOB'
          ? '<option selected="selected"  value="LONGBLOB">LONGBLOB</option>'
          : '<option value="LONGBLOB">LONGBLOB</option>';
        $return .= qq|</select>
      <script language="JavaScript">ChangeToolTip('ChooseType$typId','$type');</script>
      </td><td>
      <div id="SET$name" | . ( $type ne 'SET' ? 'style="display:none;"' : '' ) . qq|>
      <a id="dropdown$name" class="dropdownLink" onclick="showMenu('dropdown$name','setContent$name');"><img src="style/$m_sStyle/buttons/edit.png"  title="Edit"/></a></div>
      </td></tr></table>
      <div id="setContent$name" align="center" style="display:none" class="popupMenu">
      <div class="selectBox">
      <div align="right">
      <a class="setButton" style="color:red;" onclick="deleteEntry('select$name');" title="remove">-</a>
      <a class="setButton" onclick="addEntry('select$name','lineEditSet$name');" title="add">+</a>
      <select multiple="multiple" onchange="editSet('lineEditSet$name',this)" style="width:100%;height:100px;margin:0%;" id="select$name" name="SET$name" class="set" size="10" >
      $options
      </select>
      <br/>
      <input type="text" id="lineEditSet$name" class="short" onkeypress="if(enter(event))return false;" onkeyup="if(enter(event))setEnter(this,'select$name');">
      </div>
      </div>|;
        return $return;
    } else {
        return 0;
    } ## end else [ if ( defined $type and...)]
} ## end sub GetTypes

=head2 renameDatabase()

Action:

=cut

sub renameDatabase {
    $m_oDatabase->void('RENAME {DATABASE | SCHEMA} db_name TO new_db_name');
} ## end sub renameDatabase
1;
