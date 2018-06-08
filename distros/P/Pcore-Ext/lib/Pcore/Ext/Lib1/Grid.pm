package Pcore::Ext::Lib::Grid;

use Pcore -l10n;

sub EXT_statusbar($ext) : Extend('Ext.toolbar.Toolbar') {
    return {
        mixins => ['Ext.util.StoreHolder'],

        totalText  => l10n('Total {0}'),
        reloadText => l10n('Reload'),

        defaultBindProperty => 'store',

        initComponent => $ext->js_func(
            <<'JS'
                var me = this,
                    userItems = me.items || me.buttons || [],
                    pagingItems;

                me.bindStore(me.store || 'ext-empty-store', true);

                // pagingItems = me.getPagingItems();

                pagingItems = [
                    {   xtype: 'tbtext',
                        itemId: 'totalItem'
                    },
                    '->',
                    {   xtype: 'button',
                        glyph: 0xf021,
                        tooltip: me.reloadText,
                        overflowText: me.reloadText,
                        handler: me.reloadStore,
                        scope: me
                    }
                ];

                if (me.prependButtons) {
                    me.items = userItems.concat(pagingItems);
                } else {
                    me.items = pagingItems.concat(userItems);
                }

                // delete me.buttons;

                // if (me.displayInfo) {
                //     me.items.push('->');
                //     me.items.push({
                //         xtype: 'tbtext',
                //         itemId: 'displayItem'
                //     });
                // }

                me.callParent();
JS
        ),

        onAdded => $ext->js_func(
            ['owner'], <<'JS'
                var me = this,
                    oldStore = me.store,
                    autoStore = me._autoStore,
                    listener, store;

                // When we are added to our first container, if we have no meaningful store,
                // switch into "autoStore" mode:
                if (autoStore === undefined) {
                    me._autoStore = autoStore = !(oldStore && !oldStore.isEmptyStore);
                }

                if (autoStore) {
                    listener = me._storeChangeListener;

                    if (listener) {
                        listener.destroy();
                        listener = null;
                    }

                    store = owner && owner.store;
                    if (store) {
                        listener = owner.on({
                            destroyable: true,
                            scope: me,

                            storechange: 'onOwnerStoreChange'
                        })
                    }

                    me._storeChangeListener = listener;
                    me.onOwnerStoreChange(owner, store);
                }

                me.callParent(arguments);
JS
        ),

        onOwnerStoreChange => $ext->js_func(
            [ 'owner', 'store' ], <<'JS'
                this.setStore(store || Ext.getStore('ext-empty-store'));
JS
        ),

        updateInfo => $ext->js_func(
            <<'JS'
                this.onTotalCountChange(this.store.getCount());
JS
        ),

        getStoreListeners => $ext->js_func(
            ['store'], <<'JS'
                return {
                    totalCountChange: this.onTotalCountChange,
                    // beforeload: this.onTotalCountChange,
                    // load: this.onTotalCountChange,
                    prefetch: this.updateInfo,
                    // exception: this.onTotalCountChange
                };
JS
        ),

        reloadStore => $ext->js_func(
            <<'JS'
                this.store.reload();
JS
        ),

        onTotalCountChange => $ext->js_func(
            ['total'], <<'JS'
                var totalItem = this.child('#totalItem');

                var msg = Ext.String.format(this.totalText, total);

                totalItem.setText(msg);
JS
        ),

        onBindStore => $ext->js_func(
            [ 'store', 'initial' ], <<'JS'
                if (this.rendered) {
                    this.updateInfo();
                }
JS
        ),

        doDestroy => $ext->js_func(
            <<'JS'
                var me = this,
                    listener = me._storeChangeListener;

                if (listener) {
                    listener.destroy();
                    me._storeChangeListener = null;
                }

                me.bindStore(null);

                me.callParent();
JS
        )
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Grid

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
