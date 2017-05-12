use utf8;
use warnings;
no warnings 'redefine';
use vars qw(@menu $newAction);
ChangeDb(
         {
          name     => $m_sCurrentDb,
          host     => $m_sCurrentHost,
          user     => $m_sCurrentUser,
          password => $m_sCurrentPass,
         }
        );
@menu = $m_oDatabase->fetch_array('show tables');
print q|
<table>
<tr>
<td class="menuCaption">
<b><a class="menupoint" onclick="showTab('tabQuickbar')">MySQL</a></b>
</td>
</tr>
<tr id="tabQuickbar" class="cnt"><td style="display:none;">
<form name="changeDb" method="GET" onsubmit="submitForm(this,dbAction,dbAction);return false;">|;
print '' . $m_oDatabase->GetDataBases('m_ChangeCurrentDb', 1) . '</form>';
$newAction =
    $m_sAction =~ /^(ShowTable|ShowTableDetails|EditTable)$/
  ? $1
  : 'ShowTable';
print qq|
<script language="JavaScript1.5" type="text/javascript">dbAction = '$newAction';</script>
<select onchange="setDbAction(this.options[this.options.selectedIndex].value)">
<option value="ShowTable" |
  . (param('action') eq 'ShowTable' ? 'selected="selected"' : '') . '>'
  . translate('show')
  . '</option>
<option value="ShowTableDetails" '
  . (param('action') eq 'ShowTableDetails' ? 'selected="selected"' : '') . '>'
  . translate('details')
  . '</option>
<option value="EditTable" '
  . (param('action') eq 'EditTable' ? 'selected="selected"' : '') . '>'
  . translate('edit')
  . '</option>
<option value="ShowDumpTable" '
  . (param('action') eq 'ShowDumpTable' ? 'selected="selected"' : '') . '>'
  . translate('Export')
  . '</option>
<option value="AnalyzeTable" '
  . (param('action') eq 'AnalyzeTable' ? 'selected="selected"' : '') . '>'
  . translate('AnalyzeTable')
  . '</option>
<option value="OptimizeTable" '
  . (param('action') eq 'OptimizeTable' ? 'selected="selected"' : '') . '>'
  . translate('OptimizeTable')
  . '</option>
<option value="RepairTable" '
  . (param('action') eq 'RepairTable' ? 'selected="selected"' : '') . '>'
  . translate('RepairTable')
  . '</option>
  </select></div><div align="left">';

for (my $i = 0 ; $i <= $#menu ; $i++) {
    my $txt = $menu[$i];
    maxlength(15, \$txt);
    print
      qq|<a class="menuLink" href="javascript:requestURI('$ENV{SCRIPT_NAME}?action='+dbAction+'&table=$menu[$i]','database','database')">$txt</a><br/>|;
}
print q|</div></td></tr></table><script>showTab('tabQuickbar')</script>|;

ChangeDb(
         {
          name     => $m_hrSettings->{database}{name},
          host     => $m_hrSettings->{database}{host},
          user     => $m_hrSettings->{database}{user},
          password => $m_hrSettings->{database}{password},
         }
        );
