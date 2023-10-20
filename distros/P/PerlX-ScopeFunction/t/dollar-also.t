use Test2::V0;

package O { };

package TestScope1 {
    use Test2::V0;
    use PerlX::ScopeFunction qw($also);

    sub run {
        my $obj = bless {}, 'O';

        subtest "\$also can be imported", sub {
            my $pass = 0;
            $obj->$also(sub {
                           is $_[0]->isa('O'), T();
                           $pass++;
                       })
                ->$also(sub {
                           is $_[0]->isa('O'), T();
                           $pass++;
                       });
            is $pass, 2;
        };

        subtest "\$also can be lexical", sub {
            my $also2 = $PerlX::ScopeFunction::tap;

            my $pass = 0;
            $obj->$also2(sub {
                            is $_[0]->isa('O'), T();
                            $pass++;
                        })
                ->$also2(sub {
                            is $_[0]->isa('O'), T();
                            $pass++;
                        });
            is $pass, 2;
        };
    }
}

package TestScope2 {
    use Test2::V0;
    use PerlX::ScopeFunction qw($also);

    sub run {
        subtest "\$also is imported", sub {
            is $also, D();
        };

        PerlX::ScopeFunction->unimport();

        subtest "\$also can be unimported", sub {
            is $also, U();
        };
    }
}

package TestScope3 {
    use Test2::V0;
    use PerlX::ScopeFunction '$also' => { -as => '$meanWhile' };
    sub run {
        is $meanWhile, D(), '$meanWhile is imported';
    }
}

TestScope1->run();
TestScope2->run();
TestScope3->run();

done_testing;
