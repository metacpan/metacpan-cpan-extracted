use utf8;
use warnings;
no warnings 'redefine';
use vars qw($tn $ts $td $tl $te $tna $tr $trn);
$tn  = translate('editnavi');
$ts  = translate('settings');
$td  = translate('database');
$tl  = translate('bookmarks');
$tf  = translate('explorer');
$te  = translate('env');
$tna = translate('navigation');
$tr  = translate('trash');
$trn = translate('translate');
print
  qq|<table align="center" border="0" cellpadding="5" cellspacing="5" class="ShowTables marginTop" summary="adminlayout" >
<tr>
<td align="center"><img src="style/$m_sStyle/buttons/settings.png" alt="$ts" border="0" title="$ts"/><br/><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=settings','settings','settings')">$ts</a></td>
<td align="center"><img src="style/$m_sStyle/buttons/mysql.jpg" alt="$td" border="0" title="$td"/><br/><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=ShowDatabases','ShowDatabases','ShowDatabases')">$td</a>
</td>
</tr></tr>
<td align="center"><img src="style/$m_sStyle/buttons/folder_txt.png" alt="$tna" border="0" title="$tna"/><br/><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=editTreeview','editTreeview','editTreeview')">$tna</a></td>
<td align="center"><img src="style/$m_sStyle/buttons/bookmark.png" alt="$tl" border="0" title="$tl"/><br/><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=editTreeview&dump=links','editTreeview','editTreeview')">$tl</a></td>
</tr><tr>
<td align="center"><img src="style/$m_sStyle/buttons/explorer.png" alt="$tf" border="0" title="$tf"/><br/><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=showDir','showDir','showDir')">$tf</a></td>
<td align="center"><img src="style/$m_sStyle/buttons/env.png" alt="$te" border="0" title="$te"/><br/><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=env','env','env')">$te</a></td>
</tr>
<tr>
<td align="center"><img src="style/$m_sStyle/buttons/trash.png" alt="$tr" border="0" title="$tr"/><br/><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=trash','trash','trash')">$tr</a></td>
<td align="center"><img src="style/$m_sStyle/buttons/translate.png" alt="$trn" border="0" title="$trn"/><br/><a href="javascript:requestURI('$m_hrSettings->{cgi}{serverName}$ENV{SCRIPT_NAME}?action=translate','translate','translate')">$trn</a></td>
</tr></table><br/>|;
1;
