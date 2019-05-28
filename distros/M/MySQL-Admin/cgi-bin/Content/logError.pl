use utf8;
use warnings;
no warnings 'redefine';
use vars qw($mes  $txt $line);
$mes = param('message');
$txt = param('file');
$line = param('line');

if($m_oDatabase->checkFlood( remote_addr() )){
    $m_oDatabase->void("INSERT INTO `errorLog`(message,file,line) VALUES (?,?,?);",$mes , $txt,$line );
}
print $@ if $@;
1;
