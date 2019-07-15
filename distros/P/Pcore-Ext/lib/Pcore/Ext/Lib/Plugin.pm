package Pcore::Ext::Lib::Plugin;

use Pcore -l10n;

sub EXT_swipe_tab : Extend('Ext.plugin.Abstract') : Type('plugin') {
    return {
        config => {
            cmp             => undef,
            allowOverflow   => \1,
            allowDirections => [ 'left', 'right', 'up', 'down' ]
        },

        init => func ['cmp'], <<'JS',
            this.updateCmp(cmp);
JS

        updateCmp => func [ 'newCmp', 'oldCmp' ], <<'JS',
            if (newCmp) {
                this.setCmp(newCmp);

                newCmp.element.on('swipe', this.onSwipe, this);
            }

            if (oldCmp) {
                oldCmp.element.un('swipe', this.onSwipe);
            }
JS

        onSwipe => func ['e'], <<'JS',
            if (this.getAllowDirections().indexOf(e.direction) < 0) {
                return;
            }

            var cmp           = this.getCmp(),
                allowOverflow = this.getAllowOverflow(),
                direction     = e.direction,
                activeItem    = cmp.getActiveItem(),
                innerItems    = cmp.getInnerItems(),
                numIdx        = innerItems.length - 1,
                idx           = Ext.Array.indexOf(innerItems, activeItem),
                newIdx        = idx + (direction === 'left' ? 1 : -1),
                newItem;

            if (newIdx < 0) {
                if (allowOverflow) {
                    newItem = innerItems[numIdx];
                }
            } else if (newIdx > numIdx) {
                if (allowOverflow) {
                    newItem = innerItems[0];
                }
            } else {
                newItem = innerItems[newIdx];
            }

            if (newItem) {
                cmp.setActiveItem(newItem);
            }
JS
    };
}

sub EXT_list_paging : Extend('Ext.dataview.plugin.ListPaging') : Type('plugin') {
    return {
        init => func ['view'],
        <<'JS',
            view.setScrollToTopOnRefresh(true);

            this.callParent(arguments);
JS

        destroy => func <<'JS',
            Ext.destroy(this._storeSortersListeners);

            this.callParent();
JS

        bindStore => func ['store'], <<'JS',
            this.callParent(arguments);

            this._storeSortersListeners = Ext.destroy(this._storeSortersListeners);

            if (store) {
                var sorters = store.getSorters();

                this._storeSortersListeners = sorters.on({
                    beginUpdate: 'onSortersBeginUpdate',
                    scope: this
                });
            }
JS

        onSortersBeginUpdate => func <<'JS',
            this.cmp.store.currentPage = 1;
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Plugin

=head1 SYNOPSIS

    # swipe tab plugin
    plugins => {
        $type{'/pcore/Plugin/swipe_tab'} => {
            allowOverflow   => \0,
            allowDirections => [ 'left', 'right' ],
        },
    },

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
