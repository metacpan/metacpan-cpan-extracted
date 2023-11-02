use Test2::V0;

package O { };

package TestScope1 {
    use Test2::V0;
    use PerlX::ScopeFunction qw($tap);

    sub run {
        my $obj = bless {}, 'O';

        subtest "\$tap can be imported", sub {
            my $pass = 0;
            $obj->$tap(sub {
                           is $_->isa('O'), T();
                           $pass++;
                       })
                ->$tap(sub {
                           is $_[0]->isa('O'), T();
                           $pass++;
                       });
            is $pass, 2;
        };

        subtest "\$tap can be lexical", sub {
            my $tap2 = $PerlX::ScopeFunction::tap;

            my $pass = 0;
            $obj->$tap2(sub {
                            is $_->isa('O'), T();
                            $pass++;
                        })
                ->$tap2(sub {
                            is $_[0]->isa('O'), T();
                            $pass++;
                        });
            is $pass, 2;
        };
    }
}

package TestScope2 {
    use Test2::V0;
    use PerlX::ScopeFunction qw($tap);

    sub run {
        subtest "\$tap is imported", sub {
            is $tap, D();
        };

        PerlX::ScopeFunction->unimport();

        subtest "\$tap can be unimported", sub {
            is $tap, U();
        };
    }
}

package TestScope3 {
    use Test2::V0;
    use PerlX::ScopeFunction '$tap' => { -as => '$also' };
    sub run {
        is $also, D(), '$also is imported';
    }
}

TestScope1->run();
TestScope2->run();
TestScope3->run();

done_testing;
