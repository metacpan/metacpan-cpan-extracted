#!perl
use lib 't/lib';
use Test::Sietima;
use Email::Stuffer;
use Path::Tiny;

package TestClassWithMS {
    use Moo;
    use Sietima::Policy;
    with 'Sietima::Role::WithMailStore';
};

subtest 'Role::WithMailStore' => sub {
    subtest 'plain instance' => sub {
        require Test::Sietima::MailStore;
        ok(
            lives {
                TestClassWithMS->new({
                    mail_store => Test::Sietima::MailStore->new,
                })
            },
            'passing a test instance should work',
        );
    };
    subtest 'type coercion' => sub {
        my $tc;
        my $root = Path::Tiny->tempdir;
        ok(
            lives {
                $tc = TestClassWithMS->new({
                    mail_store => {
                        class => 'Sietima::MailStore::FS',
                        root => $root,
                    },
                })
            },
            'passing a hashref should work (and load the class)',
        );
        is(
            $tc->mail_store,
            object {
                prop blessed => 'Sietima::MailStore::FS';
                call root => $root;
            },
            'the mailstore should be built correctly',
        );
    };
};

sub mkmail($id) {
    Email::Stuffer
          ->from("from-${id}\@example.com")
          ->to("to-${id}\@example.com")
          ->subject("subject $id")
          ->text_body("body $id \nbody body\n")
          ->email;
}

sub chkmail($id) {
    object {
        call [header=>'from'] => "from-${id}\@example.com";
        call [header=>'to'] => "to-${id}\@example.com";
        call [header=>'subject'] => "subject $id";
        call body => match qr{\bbody \Q$id\E\b};
    };
}

sub chk_multimail(@ids) {
    return bag {
        for my $id (@ids) {
            item hash {
                field id => D();
                field mail => chkmail($id);
                end;
            };
        }
        end;
    };
}

sub test_store($store) {
    my %stored_id;

    subtest 'storing' => sub {
        ok($stored_id{1}=$store->store(mkmail(1),'tag1','tag2'));
        ok($stored_id{2}=$store->store(mkmail(2),'tag2'));
        ok($stored_id{3}=$store->store(mkmail(3),'tag1'));
    };

    subtest 'retrieving by id' => sub {
        is(
            $store->retrieve_by_id($stored_id{$_}),
            chkmail($_),
        ) for 1..3;
    };

    subtest 'retrieving by tag' => sub {
        my $tag1 = $store->retrieve_by_tags('tag1');
        is(
            $tag1,
            chk_multimail(1,3),
            'tag1 should have mails 1 & 3',
        );

        my $tag2 = $store->retrieve_by_tags('tag2');
        is(
            $tag2,
            chk_multimail(1,2),
            'tag1 should have mails 1 & 2',
        );

        my $tag12 = $store->retrieve_by_tags('tag2','tag1');
        is(
            $tag12,
            chk_multimail(1),
            'tag1+tag2 should have mail 1',
        );

        my $tag_all = $store->retrieve_by_tags();
        is(
            $tag_all,
            chk_multimail(1,2,3),
            'no tags should retrieve all mails',
        );
    };

    subtest 'retrieving ids by tag' => sub {
        my $tag1 = $store->retrieve_ids_by_tags('tag1');
        is(
            $tag1,
            bag { item $stored_id{1}; item $stored_id{3}; end },
            'tag1 should have ids 1 & 3',
        );

        my $tag2 = $store->retrieve_ids_by_tags('tag2');
        is(
            $tag2,
            bag { item $stored_id{1}; item $stored_id{2}; end },
            'tag1 should have ids 1 & 2',
        );

        my $tag12 = $store->retrieve_ids_by_tags('tag2','tag1');
        is(
            $tag12,
            bag { item $stored_id{1}; end },
            'tag1+tag2 should have id 1',
        );

        my $tag_all = $store->retrieve_ids_by_tags();
        is(
            $tag_all,
            bag { item $stored_id{1}; item $stored_id{2}; item $stored_id{3}; end },
            'no tags should retrieve all ids',
        );
    };

    subtest 'removing' => sub {
        $store->remove($stored_id{2});
        is(
            $store->retrieve_by_tags('tag2'),
            chk_multimail(1),
            'remove should remove',
        );
    };

    subtest 'clearing' => sub {
        $store->clear;
        is(
            $store->retrieve_by_tags(),
            [],
            'clear should clear',
        );
    };
}

subtest 'test store' => sub {
    test_store(Test::Sietima::MailStore->new);
};

subtest 'file store' => sub {
    my $root = Path::Tiny->tempdir;

    test_store(Sietima::MailStore::FS->new({root => $root}));
};

done_testing;
