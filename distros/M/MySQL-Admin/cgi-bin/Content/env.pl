use utf8;
use warnings;

no warnings 'redefine';

use vars qw($env);

$env = translate('env');

print qq|<p style="margin-top:1.65em"><b>$env</b></p>

    <table align ="left" border ="0" cellpadding ="2" cellspacing="2" summary="env">|;



foreach my $key (keys %ENV) {

    print

      qq(<tr><td class="env" valign="top" width="100" align="left"><strong>$key</strong></td><td class="envValue" valign="top" width ="400" align="left">)

      . join('<br/>', split(/,/, $ENV{$key}))

      . '</td></tr>';

}

print '</table>';

1;