
use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Regexp::SAR') };


matchTest(['abcd'], 'qabcdef', 1);
matchTest(['abcd', 'abcf'], "zqabcdwabcfr", 3);
matchTest(['abcd', 'abc'], "zqabcdwr", 3);

matchTest(['abcd', 'amk', 'axf', 'awe', 'aitr'], "zqabcdwamkraxfaz", 7);
matchTest(['a'], 'a', 1, "match");
matchTest(['a'], 'b', 0, "");
matchTest(['a'], 'ma', 1, "");
matchTest(['a'], 'maa', 2, "");
matchTest(['asv'], 'bbbbasvmm', 1, "");
matchTest(['asv'], 'asv', 1, "");
matchTest(['asv', 'kdf'], 'bbasvmkdfm', 3, "");

matchTest(['as', 'ask'], 'bbasvmaskm', 4, "");
matchTest(['as', 'ask'], 'bbaskmmmm', 3, "");

matchTest(['ab?cd', 'dk?m'], 'aaadmabcdn', 3, "");
matchTest(['ab?cd', 'k?m'], 'aaadmabcdn', 3, "");
matchTest(['zzm?'], 'iozzj', 1, "");
matchTest(['zzm?'], 'iozzmj', 2, "");
matchTest(['zzm?n?'], 'iozzjzznj', 3, "");
matchTest(['ab?cde', 'acdf'], 'mmabcdfkkacdeoo', 1, "");
matchTest(['ab?cd?e'], 'mabcdem macdem macem mabcem nbcden', 4, "");
matchTest(['ab?c?d?e'], 'maem madem mabem', 3, "");
matchTest(['ac?c?c?e'], 'm ace m', 1, "");
matchTest(['ac?c?c?e', 'ace'], 'm ace m', 3, "");
matchTest(['ac?c?c?c?e'], 'm acce m', 1, "");

matchTest(['ab?cd', 'acd'], 'qacdq', 3, "");

matchTest(['ab+cd'], 'aadmabcdn', 1, "");
matchTest(['ab+cd'], 'aadmabbcdn', 1, "");
matchTest(['ab+cd'], 'aadmabbbbbbbbcdn', 1, "");

matchTest(['b+'], 'abbbc', 3, "");
matchTest(['b+c'], 'abbbcd', 3, "");

matchTest(['ab+'], 'aadmabbbbcdn', 1, "");
matchTest(['ab+c+d'], 'aadmabcccccdn', 1, "");
matchTest(['ab+c+d'], 'aadmabdn', 0, "");
matchTest(['ab+b?d'], 'aadmabdn', 1, "");
matchTest(['ab+b?d'], 'aadmabbbbdn', 1, "");
matchTest(['ab+c?d'], 'aadmabbbbdn', 1, "");
matchTest(['ab+b+d'], 'aadmabbbbdn', 1, "");
matchTest(['ab+b+d'], 'aadmabdn', 0, "");
matchTest(['ab+cd', 'ab?cd'], 'aaacdabbbbbbcdn', 3, "");

matchTest(['ab*cd'], 'aaadmabcdn', 1, "");
matchTest(['ab*cd'], 'aaadmabbbbcdn', 1, "");
matchTest(['ab*cd'], 'aaadmacdn', 1, "");
matchTest(['ab*c*d'], 'aamadn', 1, "");
matchTest(['ab*c*d'], 'aamacccccccdn', 1, "");

matchTest(['ab*c?d'], 'aamadn', 1, "");
matchTest(['ab*c?d'], 'aamabcdn', 1, "");
matchTest(['ab*c?d'], 'aamacdn', 1, "");
matchTest(['ab*c?d'], 'aamabdn', 1, "");

matchTest(['ab?cd', 'ab+cd'], 'mmabcdmm', 3, "");
matchTest(['ab?cd', 'ab+cd'], 'mmacdmm', 1, "");
matchTest(['ab?cd', 'ab+cd'], 'mmabbbcdmm', 2, "");
matchTest(['ab*c?b+e'], 'mmabedmm', 1, "");
matchTest(['ab*c?b+e'], 'mmabcbedmm', 1, "");
matchTest(['ab+b?b+c'], 'mmabbcdmm', 1, "");
matchTest(['ab+c?b+c'], 'mmabbbcdmm', 1, "");

matchTest(['ab\cd'], "q1abcdef", 1);
matchTest(['ab\cd'], "q1abcdef", 1);
matchTest(['ab\\\\cd'], "q2abcdef", 0);
matchTest(['ab\\\\cd'], 'q3ab\cdef', 1);
matchTest(['ab\\\\\\\\cd'], 'q3ab\\\\cdef', 1);
matchTest(['ab\?cd'], "qabcdef", 0);
matchTest(['ab\?cd'], 'qab?cdef', 1);

matchTest(['abcd\?'], "qabcd?ef", 1);
matchTest(["abcd\\"], "qabcdef", 1);
matchTest(['ab?cd'], "qabcdef", 1);
matchTest(['abcd?'], "qabcef", 1);
matchTest(['abcd?'], "qabcdef", 2);
matchTest(['ab?cd'], "qacdef", 1);
matchTest(['ab?cd'], "qab?cdef", 0);
matchTest(['ab\?cd'], "qab?cdef", 1);
matchTest(['ab?cd', 'abce'], "qacem", 0);
matchTest(['abd', 'ab?d', 'kkk', 'abc?d'], "qabdm", 11);
matchTest(['ab?b?b?b?b?cd'], "qacdef", 1);
matchTest(['ab?b?b?cd'], "qabcdef", 1);
matchTest(['ab?b?b?cd'], "qabbcdef", 1);
matchTest(['abc??'], "qabc?def", 1);

matchTest(['ab+cd'], 'qabbbbcdef', 1);
matchTest(['ab+cd'], "qabcdq qabbbbcdq", 2);
matchTest(['am+e'], "qammmeq", 1);
matchTest(['ab+c', 'am+e'], "qabcq qabbbbbcq qammmeq", 4);
matchTest(['ab+c+d'], "qabbcdq", 1);

matchTest(['ab+cd', 'abcf'], "abbcd", 1);
matchTest(['ab+cd', 'abcf'], "abbcf", 0);
matchTest(['ab+cd'], "acdf", 0);
matchTest(['ab+'], "qabcdq qabbbbcdq qacdq", 2);
matchTest(['ab+bcd'], "qabcdq", 0);
matchTest(['ab+bcd'], "qabbcdq", 1);
matchTest(['ab+b+cd'], "qabbcdq", 1);
matchTest(['ab+b+cd'], "qabcdq", 0);
matchTest(['ab+b+b+cd'], "qabbcdq", 0);
matchTest(['ab+b+b+cd'], "qabbbcdq", 1);
matchTest(['ab+b+b+cd'], "qabbbbbbbbbbbbbbbbbcdq", 1);
matchTest(['a\?+cd'], "qa????cdq", 1);
matchTest(['ab*cd'], 'qabbbbcdef', 1);
matchTest(['ab*cd'], 'qacdef', 1);

matchTest(['ab?cd+d+ef'], 'q acddddef q', 1);
matchTest(['ab?cd+d+ef'], 'q acdef q', 0);
matchTest(['ab?cd+d+ef'], 'q acddddef q', 1);

matchTest(['a\++b'], 'q a+++++++b q', 1);

# 3 matches: 'bbb', 'bb', 'b'
matchTest(['b+'], 'm bbb m', 3, "");
matchTest(['ab+'], 'm abbb m', 1, "");

matchTest(['a\+c'], 'm a+c ', 1, "");
matchTest(['a\+c'], 'm aac ', 0, "");
matchTest(['ab\?c'], 'm aac ', 0, "");
matchTest(['ab\?+c'], 'm aab??????c ', 1, "");

matchTest(['a\dc', 'a5c'], 'm a5c m', 3, "");
matchTest(['a\dc'], 'm a5c a8c m', 2, "");
matchTest(['ab\d?c'], 'm abc m', 1, "");
matchTest(['ab\d?c'], 'm ab1c m', 1, "");
matchTest(['ab\d?c'], 'm abdc m', 0, "");

matchTest(['ab\d+c'], 'm ab7c m', 1, "");
matchTest(['ab\d+c'], 'm ab7657234c m', 1, "");
matchTest(['ab\d*c'], 'm abc m', 1, "");
matchTest(['ab\d*c'], 'm ab234c m', 1, "");
matchTest(['ab\d+\d+c'], 'm ab234c m', 1, "");
matchTest(['ab\d+\d+c'], 'm ab2c m', 0, "");

matchTest(['\d+\d+c'], 'm ab234c m', 2, "");
matchTest(['\d+'], 'm ab234c m', 3, "");

matchTest(['a\sc', 'a.c'], 'm a c m', 3, "");
matchTest(['a\sc'], 'm a c a c m', 2, "");
matchTest(['ab\s?c'], 'm abc m', 1, "");
matchTest(['a\s*c'], 'm ac a c a      c m', 3, "");

matchTest(['\a'], ' t ', 1, "");
matchTest(['\a'], ' 4 ', 0, "");
matchTest(['\a+'], ' t ', 1, "");
matchTest(['\a+'], ' 4 ', 0, "");
matchTest(['\a+'], ' tre ', 3, "");
matchTest(['\a+'], ' 456 ', 0, "");
matchTest(['a\ac', 'a.c'], 'm afc m', 3, "");
matchTest(['a\ac'], 'm asc auc m', 2, "");
matchTest(['a\ac'], 'm a4c m', 0, "");
matchTest(['ab\a?c'], 'm abc m', 1, "");
matchTest(['a\a*c'], 'm ac atc asggfc a8c m', 3, "");

matchTest(['a\wc'], 'm a4c adc m', 2, "");
matchTest(['ab\w?c'], 'm abtc m', 1, "");
matchTest(['a\w*c'], 'm ac ahc asd87sc m', 3, "");

matchTest(['a.c'], 'm a5d m', 0, "");
matchTest(['a.c'], 'm akcm alc l ', 2, "");
matchTest(['a.?c'], 'm akcm ac l ', 2, "");
matchTest(['a.+c'], 'm  abbregtjhbc m', 1, "");
matchTest(['a.+.+c'], 'm  ahbc m', 1, "");
matchTest(['a.+.+c'], 'm  ahc m', 0, "");
matchTest(['a\.+c'], 'm abbc m', 0, "");
matchTest(['a\.+c'], 'm a..c m', 1, "");
matchTest(['a\.c'], 'm a.cm', 1, "");
matchTest(['a\.c'], 'm ahcm', 0, "");
matchTest(['.'], 'm', 1, "");
matchTest(['\.'], 'm', 0, "");
matchTest(['a\.?b'], 'amb', 0, "");
matchTest(['a\.?b'], 'ab', 1, "");
matchTest(['a\.?b'], 'a.b', 1, "");

matchTest(['a\^bc'], 'm adc m', 1, "");
matchTest(['a\^bdc'], 'm aqdc m', 1, "");
matchTest(['a\^bc'], 'm abc m', 0, "");

matchTest(['a\^b?dc'], 'm adc m', 1, "");
matchTest(['a\^b?dc'], 'm aqdc m', 1, "");
matchTest(['a\^b?bc'], 'm abc m', 1, "");
matchTest(['a\^b?c'], 'm ac m', 1, "");
matchTest(['a\^b?\^m?c'], 'm attc m', 1, "");
matchTest(['a\^b?\^m?c'], 'm ac m', 1, "");

matchTest(['a\^bc'], 'm adc a c a6c m', 3, "");
matchTest(['a\^b\^dc'], 'm affc m', 1, "");
matchTest(['a\^b\^dc'], 'm afdc m', 0, "");
matchTest(['a\^b\^dc'], 'm abfc m', 0, "");
matchTest(['a\^b\^dc'], 'm affa m', 0, "");
matchTest(['a\^\\\\c'], 'm adc m', 1, "");
matchTest(['a\^\\\\c'], 'm a\c m', 0, "");

matchTest(['a\^\sc'], 'm a c m', 0, "");
matchTest(['a\^\sc'], 'm adc m', 1, "");
matchTest(['a\^\dc'], 'm a6c m', 0, "");
matchTest(['a\^\dc'], 'm adc m', 1, "");
matchTest(['a\^\ac'], 'm adc m', 0, "");
matchTest(['a\^\ac'], 'm a6c m', 1, "");
matchTest(['a\^\wc'], 'm a6c m', 0, "");
matchTest(['a\^\wc'], 'm adc m', 0, "");
matchTest(['a\^\wc'], 'm a c m', 1, "");

matchTest(['a\^b+c'], 'm adc m', 1, "");
matchTest(['a\^b+c'], 'm aduic m', 1, "");
matchTest(['a\^b+\^b+c'], 'm adfc m', 1, "");
matchTest(['a\^b+dc'], 'm adghjdc m', 1, "");
matchTest(['a\^b+dc'], 'm adghbjdc m', 0, "");
matchTest(['a\^b*dc'], 'm adc m', 1, "");
matchTest(['a\^b*c'], 'm atc m', 1, "");
matchTest(['a\^b*c'], 'm atghhgc m', 1, "");
matchTest(['a\^\d+c'], 'm adgdc m', 1, "");
matchTest(['a\^\d+c'], 'm adghjc m', 1, "");
matchTest(['a\^\d+c'], 'm adgh7jc m', 0, "");
matchTest(['a\^\w+c'], 'm a-+-c m', 1, "");
matchTest(['a\^\a+c'], 'm a-+-c m', 1, "");
matchTest(['a\^\s+c'], 'm a-+-c m', 1, "");




sub matchTest {
  my $regexps = shift;
  my $matchStr = shift;
  my $expectedRes = shift;

  my $pathRes = 0;
  my $rootNode = Regexp::SAR::buildRootNode();
  for (my $i=0; $i < @$regexps; ++$i)
    {
      my $reNum = 2**$i;
      my $reg = $regexps->[$i];
      Regexp::SAR::buildPath($rootNode, $reg, length $reg, sub { $pathRes += $reNum; });
    }
  Regexp::SAR::lookPath($rootNode, $matchStr, 0);
  is($pathRes, $expectedRes, "\nMatch fail for: ". join(', ', @$regexps). ": in >>$matchStr<<\n");
}





###############################################
done_testing();