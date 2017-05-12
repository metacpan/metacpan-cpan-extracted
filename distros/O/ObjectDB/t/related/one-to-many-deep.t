use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use Author;
use Thread;
use Reply;
use Notification;

describe 'one to many' => sub {

    before each => sub {
        TestEnv->prepare_table('author');
        TestEnv->prepare_table('thread');
        TestEnv->prepare_table('reply');
        TestEnv->prepare_table('notification');
    };

    it '123' => sub {
        my $author1 = Author->new(name => 'vti')->create;
        my $author2 = Author->new(name => 'bar')->create;
        my $thread =
          Thread->new(title => 'foo', author_id => $author1->get_column('id'))
          ->create;
        my $reply1 = Reply->new(
            content   => 'foo',
            author_id => $author1->get_column('id'),
            thread_id => $thread->get_column('id')
        )->create;
        my $reply2 = Reply->new(
            content   => 'foo2',
            parent_id => $reply1->get_column('id'),
            author_id => $author2->get_column('id'),
            thread_id => $thread->get_column('id')
        )->create;

        Notification->new(reply_id => $reply1->get_column('id'))->create;
        Notification->new(reply_id => $reply2->get_column('id'))->create;

        my @notifications = Notification->find(
            with => [
                qw/
                  reply.author
                  reply.thread.author
                  reply.parent.author
                  /
            ]
        );

        is @notifications, 2;

        is $notifications[0]->related('reply')->get_column('content'), 'foo';
        is $notifications[0]->related('reply')->related('author')->get_column('name'), 'vti';
        is $notifications[0]->related('reply')->related('thread')->get_column('title'), 'foo';
        ok !$notifications[0]->related('reply')->related('parent');

        is $notifications[1]->related('reply')->get_column('content'), 'foo2';
        is $notifications[1]->related('reply')->related('author')->get_column('name'), 'bar';
        is $notifications[1]->related('reply')->related('thread')->get_column('title'), 'foo';
        is $notifications[1]->related('reply')->related('parent')->get_column('content'), 'foo';
        is $notifications[1]->related('reply')->related('parent')->related('author')->get_column('name'), 'vti';

        #use Data::Dumper; warn Dumper($notifications[1]->to_hash);
    };

};

runtests unless caller;
