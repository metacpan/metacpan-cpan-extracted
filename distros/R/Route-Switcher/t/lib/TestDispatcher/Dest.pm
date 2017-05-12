package TestDispatcher::Dest;
use Amon2::Web::Dispatcher::RouterBoom;


# base '/user_account' => 'Hoge::UserAccount';
get('/user_account/new'  => 'Hoge::UserAccount#new');
post('/user_account/new'  => 'Hoge::UserAccount#new');
get('/user_account/edit'  => 'Hoge::UserAccount#edit');
any('/user_account/edit'  => 'Hoge::UserAccount#edit');

# base '/post/' => 'Hoge::Post';
get('/post/new'  => 'Hoge::Post#new');
post('/post/new'  => 'Hoge::Post#new');
get('/post/edit'  => 'Hoge::Post#edit');
delete_('/post/delete'  => 'Hoge::Post#delete');

#  base '' => '';
get('new'  => 'NoBase#new');

# base '' => '';
get('/no_base'  => 'NoBase#new');
post('/no_base'  => 'NoBase#new');
any('/no_base'  => 'NoBase#new');
delete_('/no_base'  => 'NoBase#new');

1;
