# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Statistics-ROC.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Statistics::ROC') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.



     ok(loggamma(10) - 12.801827 < 0.000001, 'loggamma');
          
     ok(Xinbta(3,4,Betain(.6,3,4)) - 0.599999 < 0.000001, 'Xinbta');
     
     @e=(0.7, 0.7, 0.9, 0.6, 1.0, 1.1, 1,.7,.6);
     
     ok(join(" ",rank('low',@e)) eq "3 3 6 1 7 9 7 3 1", 'rank low');
     
     
     ok(join(" ",rank('high',@e)) eq "5 5 6 2 8 9 8 5 2", 'rank high');
     
     
     ok(join(" ",rank('mean',@e)) eq "4 4 6 1.5 7.5 9 7.5 4 1.5", 'rank mean');
    

     @var_grp=([1.5,0],[1.4,0],[1.4,0],[1.3,0],[1.2,0],[1,0],[0.8,0],
               [1.1,1],[1,1],[1,1],[0.9,1],[0.7,1],[0.7,1],[0.6,1]);

     @curves=roc('decrease',0.95,@var_grp);
     ok($curves[0][2][0] - 0.464301 < 0.000001, 'curves 1');
     
     
     ok($curves[0][2][1] - 0.025629 < 0.000001, 'curves 2');
     

