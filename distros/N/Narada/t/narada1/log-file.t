use t::narada1::share; guard my $guard;

BEGIN {
    system('echo file > config/log/type');
    system('echo var/log/file > config/log/output');
    ok !-e 'var/log/file', 'log file not exists';
}
use Narada::Log qw( $LOGFILE );


ok -e 'var/log/file', 'log file exists';
ok ref $LOGFILE, 'log object imported';
ok !-s 'var/log/file', 'log file empty';

$LOGFILE->level('INFO');
$LOGFILE->DEBUG('debug');
system('true'); # force FH flush in perl
ok !-s 'var/log/file', 'log file still empty after DEBUG()';

$LOGFILE->INFO('info');
system('true'); # force FH flush in perl
ok -s 'var/log/file', 'log file not empty after INFO()';


done_testing();
