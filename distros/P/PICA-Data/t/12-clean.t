use strict;
use Test::More;

use PICA::Schema 'clean_pica';

sub check {
    my ($record, $errors, $message, %options) = @_;
    my @found;
    my $res = clean_pica( $record, error => sub { push @found, $_[0] }, %options );
    is_deeply \@found, $errors, $message;
    ok @$errors ? !$res : $res;
}

check($_, ['PICA record must be array reference'], 'report malformed record')
    for {}, { record => 0 }, undef, '', '003@ $00';

check([], ['PICA record should not be empty'], 'report empty record');
check([], [], 'ignore empty record', ignore_empty_records => 1);

check(['42'], ['PICA field must be array reference'], 'report malformed field');

check([['300A','a','0','0']], ["Malformed PICA tag: 300A", "Malformed occurrence: a"], 
    'report malformed tags and occurrences');

check([['300A','','?']],
      ["Malformed PICA tag: 300A", "Malformed PICA subfield: ?", "PICA subfield \$? must be non-empty string"],
      'report malformed subfields');

check([['234A',$_,'a','x']], [], 'be lax on occurrences')
    for '', undef, 0, 1, '1', '999'; 

check([['123@','123','a','x']], ["Three digit occurrences only allowed on PICA level 2"],
    'three-digit occurrence only on level 2');

done_testing;
