use strict;
use warnings;

use Test::More;

eval { require AnyEvent; 1 } or plan skip_all => $@;

use Promise::XS qw/deferred resolved rejected collect/;
Promise::XS::use_event('AnyEvent');

sub delayed {
    my ($seconds, $sub)= @_;
    my $timer; $timer= AnyEvent->timer( after => $seconds, cb => sub {
        undef $timer;
        &$sub;
    } );
}
sub expect_resolve {
    $_[0]->then(sub {
        1;
    }, sub {
        diag( 'Expected resolution but got:' );
        diag explain \@_;
        fail;
    });
}
sub expect_reject {
    $_[0]->then(sub {
        fail;
    }, sub {
        1;
    });
}

my %tests= (
    no_duplicate_invoke_callback => sub {
        my $all_good;
        resolved->then(sub {
            fail if $all_good;
            $all_good= 1;
        }, sub {
            fail;
        })->finally(sub {
            ok($all_good);
        });
    },
    cannot_resolve_and_reject => sub {
        my $d= deferred;
        $d->resolve;
        eval { $d->reject; fail; };
        expect_resolve($d->promise);
    },
    cannot_reject_and_resolve => sub {
        my $d= deferred;
        $d->reject;
        eval { $d->resolve; fail; };
        expect_reject($d->promise);
    },
    delayed_resolve_and_reject => sub {
        my $d= deferred;
        delayed(0.1, sub {
            $d->resolve;
            eval { $d->resolve; fail; };
            eval { $d->reject; fail; };
        });
        expect_resolve($d->promise);
    },
    rejected_state_must_not_change => sub {
        my $d= deferred;
        $d->reject;
        eval { $d->resolve; fail; };
        expect_reject($d->promise);
    },
    rejected_immediately => sub {
        expect_reject(rejected());
    },
    rejected_delayed => sub {
        my $d= deferred;
        delayed(0.1, sub {
            $d->reject;
        });
        expect_reject($d->promise);
    },
    resolved_immediately => sub {
        expect_resolve(resolved());
    },
    resolved_delayed => sub {
        my $d= deferred;
        delayed(0.1, sub {
            $d->resolve;
        });
        expect_resolve($d->promise);
    },
    resolve_with_garbage => sub {
        expect_reject(resolved->then({}));
    },
    reject_with_garbage => sub {
        expect_reject(rejected->catch(5));
    },
    reject_with_named_function => sub {
        expect_reject(rejected->catch("main::fail"));
    },
    finally_with_garbage => sub {
        expect_reject(resolved->finally(123));
    },
    pass_value_to_callback => sub {
        expect_resolve(
            resolved(1, 2, 3, 4)->then(sub {
                is_deeply(\@_, [1,2,3,4]);
            })
        );
    },
    callback_sent_later => sub {
        my $d= deferred;
        my $ok= 0;
        delayed(0.1, sub {
            $d->resolve;
            $ok= 1;
        });
        expect_resolve(
            $d->promise->then(sub {
                ok($ok);
            })
        );
    },
    never_resolved => sub {
        my $d= deferred;
        $d->promise->then(sub { fail; });
        resolved;
    },
    called_once => sub {
        my $d= deferred;
        my $times_called;
        my $p= $d->promise->then(sub {
            $times_called++;
        });
        $d->resolve;
        eval { $d->resolve; fail; };
        $p->then(sub {
            is($times_called, 1);
        });
    },
    multiple_thens => sub {
        my $d= deferred;
        my $d2= deferred;
        my ($one, $two, $three);
        $d->promise->then(sub { $one++; });
        delayed(0.05, sub { $d->promise->then(sub { $two++; }) });
        delayed(0.10, sub {
            is($one, undef);
            is($two, undef);
            is($three, undef);
            $d->resolve;
        });
        delayed(0.15, sub { $d->promise->then(sub { $three++; }) });
        delayed(0.2, sub {
            $d2->resolve;
        });
        $d2->promise->then(sub {
            is($one, 1);
            is($two, 1);
            is($three, 1);
        });
    },
    call_me_later => sub {
        my $not_now= 1;
        my $p= resolved->then(sub {
            is($not_now, 0);
        });
        $not_now= 0;
        $p
    },
    call_me_later_2 => sub {
        my $d= deferred;
        my $not_now= 1;
        my $p= $d->promise->then(sub {
            is($not_now, 0);
        });
        $d->resolve;
        $not_now= 0;
        $p
    },
    then_in_then_call_me_later => sub {
        my $r= resolved;
        my $not_now= 1;
        my $but_now= 0;
        my $p= $r->then(sub {
            $r->then(sub {
                is($but_now, 1);
                is($not_now, 0);
            });
            $but_now= 1;
            is($not_now, 0);
        });
        $not_now= 0;
        $p
    },
    call_me_later_async => sub {
        my $d= deferred;
        my $ok;
        my $p= $d->promise->then(sub {
            is($ok, 1);
        });
        delayed(0, sub {
            $d->resolve;
            $ok= 1;
        });
        $p
    },
    no_pass_underbar => sub {
        $_= 5;
        resolved->then(sub {
            is($_, undef);
        });
    },
    ordered_thens => sub {
        my $r= resolved;
        my $last= 0;
        collect(
            $r->then(sub {
                is($last++, 0);
            }),
            $r->then(sub {
                is($last++, 1);
            }),
            $r->then(sub {
                is($last++, 2);
            }),
        );
    },
    multiple_thens_with_values => sub {
        my $r= resolved(1);
        collect(
            $r->then(sub {
                is($_[0], 1);
                resolved(5);
            })->then(sub {
                is($_[0], 5);
            }),
            $r->then(sub {
                is($_[0], 1);
                resolved(6);
            })->then(sub {
                is($_[0], 6);
            }),
            $r->then(sub {
                is($_[0], 1);
                resolved(8, 9);
            })->then(sub {
                is($_[0], 8);
                is($_[1], 9);
            }),
            $r->then(sub {
                rejected(1);
            })->catch(sub {
                is($_[0], 1);
            }),
        );
    },
    strict_order => sub {
        my $r= resolved;
        my $i;
        collect(
            $r->then(sub {
                is($i++, 0);
                $r->then(sub {
                    is($i++, 2);
                });
            }),
            $r->then(sub {
                is($i++, 1);
            }),
        );
    },
    then_returns_promise => sub {
        my $r= resolved;
        ok($r->then(sub{ 1; })->can('then'));
        $r
    },
    then_may_die => sub {
        my $caught;
        resolved->then(sub {
            die [1, 2];
        })->catch(sub {
            is_deeply($_[0], [1,2]);
            $caught= 1;
        })->finally(sub {
            ok($caught);
        })
    },
    then_may_die_str => sub {
        my $caught;
        resolved->then(sub {
            die "test message";
        })->catch(sub {
            ok(!!($_[0] =~ /test message/));
            $caught= 1;
        })->finally(sub {
            ok($caught);
        })
    },
    chain_should_work => sub {
        resolved(5)->catch(sub {
            fail;
        })->then(sub {
            is($_[0], 5);
            die [5];
        })->then(sub {
            fail;
        })->catch(sub {
            is_deeply($_[0], [5]);
        });
    },
    no_resolve_with_self => sub {
        my $r= resolved;
        my $p; $p= $r->then(sub {
            $p
        });
        $p->catch(sub {
            ok(!!($_[0] =~ /TypeError/));
        });
    },
    can_thenable_other => sub {
        my $d= MyBadCode->new;
        delayed(0.1, sub {
            $d->resolve(5, 6);
        });
        resolved->then(sub {
            $d
        })->then(sub {
            is_deeply($_[0], 5);
            is_deeply($_[1], 6);
        });
    },
    can_thenable_other_reject => sub {
        my $d= MyBadCode->new;
        delayed(0.1, sub {
            $d->reject(5, 6);
        });
        resolved->then(sub {
            $d
        })->catch(sub {
            is_deeply($_[0], 5);
            is_deeply($_[1], 6);
        });
    },
    can_handle_crazy_thenable => sub {
        resolved->then(sub {
            ReallyBad->new
        })->then(sub {
            is($_[0], 1);
        })
    },
    can_handle_other_crazy_thenable => sub {
        resolved->then(sub {
            ThenCalledButThrows->new
        })->then(sub {
            is($_[0], 2);
        })
    },
    finally_with_resolve => sub {
        resolved(1)->finally(sub{2})->then(sub {
            is($_[0], 1);
        })
    },
    finally_with_reject => sub {
        rejected(1)->finally(sub{2})->then(sub {
            fail;
        }, sub {
            is($_[0], 1);
        })
    },
    finally_with_reject_die => sub {
        rejected(1)->finally(sub {
            die 123;
        })->then(sub {
            fail;
        }, sub {

            # Old behavior that threw away finally rejections:
            # is($_[0], 1);

            like($_[0], qr<\A123 >);
        })
    },

    # Regrettion (regression tests)
    no_alias_on_resolve => sub {
        my $d= deferred;
        my $reason= 'abc';
        $d->resolve($reason);
        $reason= 'def';
        $d->promise->then(sub {
            is($_[0], 'abc');
        });
    },
    no_alias_on_reject => sub {
        my $d= deferred;
        my $reason= 'abc';
        $d->reject($reason);
        $reason= 'def';
        $d->promise->then(sub {
            fail;
        }, sub {
            is($_[0], 'abc');
        });
    },
    no_alias_on_return => sub {
        my $msg= 'abc';
        resolved()->then(sub {
            $msg;
        })->then(sub {
            $msg= 'def';
            is($_[0], 'abc');
        });
    },
);

my @promises= map {
    my $test= $_;
    $tests{$test}->()->then(sub {
        ok(1, $test);
    }, sub {
        fail($test) or diag $_[0];
    })
} keys %tests;

my $cv= AnyEvent->condvar();
collect(@promises)->then(sub {
    ok(1, "All good");
    1;
}, sub {
    fail("Something unexpected happened!");
    die "Not good";
})->finally($cv);

$cv->recv;
done_testing;

package MyBadCode;
sub new { bless {c=>[]}, $_[0] }
sub then { push @{$_[0]{cb}}, [0,$_[1],$_[2]]; $_[0]->cb; (); }
sub resolve { my $c= shift; $c->{v}= [@_]; $c->{st}= 1; $c->cb; }
sub reject { my $c= shift; $c->{v}= [@_]; $c->{st}= 2; $c->cb; }
sub cb { return unless $_[0]{st}; while (my $i= shift @{$_[0]{cb}}) { $i->[$_[0]{st}]->(@{$_[0]{v}}) if $i->[$_[0]{st}]; } (); }

package ReallyBad;
sub new { bless {}, $_[0] }
sub then { $_[1]->(1); $_[2]->(2); $_[1]->(3); $_[2]->(4); }

package ThenCalledButThrows;
sub new { bless {}, $_[0] }
sub then { $_[1]->(2); die "hello"; }
