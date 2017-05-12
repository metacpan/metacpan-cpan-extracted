package TM::Coverage;

our $VERSION = '0.1';

=pod

=head1 NAME

TM::Coverage - Topic Maps, Code Coverage

=head1 DESCRIPTION

This auxiliary package keeps track of the code coverage. Probably
quite irrelevant for a user.

Automatically generated for TM (1.44).

   
   
   ---------------------------- ------ ------ ------ ------ ------ ------ ------
   File                           stmt   bran   cond    sub    pod   time  total
   ---------------------------- ------ ------ ------ ------ ------ ------ ------
   blib/lib/TM.pm                 96.4   84.5   58.0   93.7   90.6   27.5   89.6
   blib/lib/TM/Analysis.pm       100.0   90.9    n/a  100.0  100.0    0.0   97.5
   blib/lib/TM/AsTMa/Fact.pm     100.0    n/a    n/a  100.0    n/a    0.0  100.0
   blib/lib/TM/AsTMa/Fact2.pm    100.0    n/a    n/a  100.0    n/a    0.0  100.0
   blib/lib/TM/Bulk.pm            76.8   71.4   62.5   85.7  100.0    0.0   75.3
   blib/lib/TM/CTM/CParser.pm     65.6   34.3   31.0   84.6    0.0    1.6   52.5
   blib/lib/TM/CTM/Parser.pm      90.9   50.0    n/a  100.0    0.0    0.0   79.4
   blib/lib/TM/DM.pm             100.0   65.0   66.7  100.0    n/a    0.0   96.5
   blib/lib/TM/Graph.pm           99.1   88.5    n/a  100.0  100.0    0.0   97.4
   blib/lib/TM/Index.pm          100.0   80.0   60.0  100.0   83.3    0.3   87.8
   .../Index/Characteristics.pm  100.0  100.0    n/a  100.0    0.0    0.0   97.0
   blib/lib/TM/Index/Match.pm     98.5   87.5    n/a  100.0  100.0    0.5   97.6
   blib/lib/TM/LTM/CParser.pm     84.9   45.3   42.7   98.2    0.0    0.2   67.8
   blib/lib/TM/LTM/Parser.pm      95.7   62.5   50.0  100.0    0.0    0.0   87.1
   blib/lib/TM/Literal.pm         45.8    0.0   11.8   30.0    0.0    0.4   24.2
   blib/lib/TM/MapSphere.pm       96.5   84.6   68.8  100.0  100.0    0.0   91.7
   .../TM/Materialized/AsTMa.pm  100.0    n/a    n/a  100.0    0.0    0.0   95.5
   ...ib/TM/Materialized/LTM.pm  100.0    n/a    n/a  100.0    0.0    0.0   95.5
   .../TM/Materialized/MLDBM.pm  100.0   83.3    n/a  100.0    0.0    0.0   92.6
   ...b/TM/Materialized/Null.pm  100.0    n/a    n/a  100.0    n/a    0.0  100.0
   ...TM/Materialized/Stream.pm  100.0  100.0  100.0  100.0    0.0    0.0   96.0
   ...ib/TM/Materialized/XTM.pm  100.0    n/a    n/a  100.0    0.0    0.0   96.7
   blib/lib/TM/PSI.pm            100.0    n/a    n/a  100.0    n/a    0.0  100.0
   blib/lib/TM/QL.pm              91.4   61.5   66.7  100.0   50.0    0.1   83.9
   blib/lib/TM/QL/CParser.pm      76.2   42.4   41.9   90.3    0.0    9.1   62.0
   blib/lib/TM/QL/PE.pm           83.8   77.3   80.0   91.7    0.0   52.5   80.5
   blib/lib/TM/QL/TS.pm           65.2   35.4   27.8   70.8   53.3    2.4   56.9
   blib/lib/TM/ResourceAble.pm    88.1   87.5    n/a  100.0  100.0    0.0   90.0
   .../TM/ResourceAble/MLDBM.pm  100.0   75.0    n/a  100.0    0.0    0.0   94.2
   blib/lib/TM/Serializable.pm    94.9   65.6  100.0  100.0  100.0    0.0   84.1
   .../TM/Serializable/AsTMa.pm   99.1   87.9   66.7  100.0  100.0    0.0   94.2
   ...TM/Serializable/Dumper.pm  100.0    n/a    n/a  100.0    0.0    0.0   93.5
   ...ib/TM/Serializable/LTM.pm   94.1    n/a    n/a   83.3  100.0    0.0   92.0
   ...ib/TM/Serializable/XTM.pm   96.3   85.2   72.9  100.0  100.0    0.2   91.5
   .../lib/TM/Synchronizable.pm  100.0   75.0  100.0  100.0  100.0    0.0   97.2
   ...M/Synchronizable/MLDBM.pm  100.0   50.0    n/a  100.0    0.0    0.0   89.3
   ...nchronizable/MapSphere.pm  100.0   63.6   64.3  100.0  100.0    0.0   88.6
   ...TM/Synchronizable/Null.pm  100.0    n/a    n/a  100.0    0.0    0.0   87.5
   blib/lib/TM/Tau.pm            100.0   91.7   80.0  100.0    0.0    0.0   95.6
   blib/lib/TM/Tau/Federate.pm    63.2   39.3    n/a   62.5   27.3    0.0   54.5
   blib/lib/TM/Tau/Filter.pm     100.0   91.7   66.7  100.0   50.0    0.0   90.0
   .../TM/Tau/Filter/Analyze.pm  100.0    n/a    n/a  100.0  100.0    0.0  100.0
   blib/lib/TM/Tree.pm           100.0   57.1   44.4  100.0   66.7    0.0   88.0
   blib/lib/TM/Utils.pm          100.0   50.0    n/a  100.0    0.0    0.0   89.3
   ...ib/TM/Utils/TreeWalker.pm  100.0  100.0    n/a  100.0    0.0    0.0   96.0
   ...ib/TM/Workbench/Plugin.pm  100.0    n/a    n/a  100.0    0.0    0.0   75.0
   ...M/Workbench/Plugin/Tau.pm   87.5   50.0    n/a   80.0    0.0    0.0   73.1
   yapp/astma-fact.yp             96.9   91.5   73.3   97.8    0.0    4.8   92.7
   yapp/astma2-fact.yp            97.4   91.6   58.3  100.0    0.0    0.2   91.6
   Total                          76.8   45.2   40.2   91.2   57.0  100.0   63.8
   ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

L<TM>

=head1 COPYRIGHT AND LICENSE

Copyright 200[8] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;

