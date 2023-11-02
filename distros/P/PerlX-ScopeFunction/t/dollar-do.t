use Test2::V0;

package O { };

package TestScope1 {
    use Test2::V0;
    use PerlX::ScopeFunction qw($do);

    sub run {
        my $obj = bless {}, 'O';

        subtest "\$do can be imported", sub {
            my $pass = 0;
            $obj->$do(sub {
                          is $_->isa('O'), T();
                          $pass++;
                      });
            $obj->$do(sub {
                          is $_[0]->isa('O'), T();
                          $pass++;
                      });
            is $pass, 2;
        };

        subtest "\$do can be lexical", sub {
            my $do2 = $PerlX::ScopeFunction::do;

            my $pass = 0;
            $obj->$do2(sub {
                           is $_->isa('O'), T();
                           $pass++;
                       });
            $obj->$do2(sub {
                           is $_[0]->isa('O'), T();
                           $pass++;
                       });
            is $pass, 2;
        };
    }
}

package TestScope2 {
    use Test2::V0;
    use PerlX::ScopeFunction qw($do);

    sub run {
        subtest "\$do is imported", sub {
            is $do, D();
        };

        PerlX::ScopeFunction->unimport();

        subtest "\$do can be unimported", sub {
            is $do, U();
        };
    }
}

package TestScope3 {
    use Test2::V0;
    use PerlX::ScopeFunction '$do' => { -as => '$run' };
    sub run {
        is $run, D(), '$run is imported';
    }
}

TestScope1->run();
TestScope2->run();
TestScope3->run();

done_testing;
