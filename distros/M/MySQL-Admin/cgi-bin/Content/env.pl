use utf8;
use warnings;
no warnings 'redefine';
use vars qw($env);
$env = translate('env');
print '<div class="ShowTables marginTop">';
print "<b>$env</b>";
print '<table align ="center" border ="0" cellpadding ="2" cellspacing="2" summary="env">';

foreach my $key (keys %ENV) {
    print
      qq(<tr><td class="env" valign="top" width="100"><strong>$key</strong></td><td class="envValue" valign="top" width ="400">)
      . join('<br/>', split(/,/, $ENV{$key}))
      . '</td></tr>';
}
print '</table></div>';
1;