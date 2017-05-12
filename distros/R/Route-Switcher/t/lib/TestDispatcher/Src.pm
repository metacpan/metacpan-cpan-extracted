package TestDispatcher::Src;
use Amon2::Web::Dispatcher::RouterBoom;
use Route::Switcher;

Route::Switcher->init(qw/get post any delete_/);


switcher '/user_account' => 'Hoge::UserAccount', sub {
    get('/new'  => '#new');
    post('/new'  => '#new');
    get('/edit' => '#edit');
    any('/edit' => '#edit');
};

switcher '/post/' => 'Hoge::Post', sub {
    get('new'  => '#new');
    post('new'  => '#new');
    get('edit' => '#edit');
    delete_('delete' => '#delete');
};

switcher  '' => '', sub {
    get('new'  => 'NoBase#new');
};


get('/no_base'  => 'NoBase#new');
post('/no_base'  => 'NoBase#new');
any('/no_base'  => 'NoBase#new');
delete_('/no_base'  => 'NoBase#new');

1;
