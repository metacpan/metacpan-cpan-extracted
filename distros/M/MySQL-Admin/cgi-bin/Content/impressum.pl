use utf8;
use warnings;
no warnings 'redefine';
use vars qw($hrUser $contakt $puplisher);
$hrUser    = $m_oDatabase->fetch_hashref("select * from  users where user = 'admin'");
$contakt   = translate('contakt');
$puplisher = translate('puplisher');
print qq|
<div class="marginTop"><h1>Impressum</h1>
<h2>$puplisher:</h2>
$hrUser->{firstname} $hrUser->{name}<br/>
 $hrUser->{street}<br/>
<br/>
 $hrUser->{postcode} $hrUser->{city} 
<h2>$contakt:</h2>
$hrUser->{email}<br/>
$hrUser->{phone}<br/></div>
|;
1;

