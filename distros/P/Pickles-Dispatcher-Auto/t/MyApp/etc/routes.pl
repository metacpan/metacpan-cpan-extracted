router {
    connect '/item/:id'               => { 'controller' => 'Item',                  action => 'view', };
    connect '/my/item/:id'            => { 'controller' => 'My::Item',              action => 'view', };
    connect '/my/some/item/:id'       => { 'controller' => 'My::Some::Item',        action => 'view', };
    connect '/my/some/klass/item/:id' => { 'controller' => 'My::Some::Klass::Item', action => 'view', };
};
