package Pcore::Ext::Lib::Mixin;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_view_router : Extend('Ext.Mixin') {
    return {
        config => { routerConfig => undef, },

        # routerConfig => {
        #     items => [],
        #     lazyItems => \0,
        # },

        mixinConfig => {
            configs => \1,
            after   => { initialize => 'initialize', },
        },

        initialize => func <<'JS',

            // init config
            if (!this.getRouterConfig()) this.setRouterConfig({});

            var me = this,
                routerConfig = this.getRouterConfig();

            if (routerConfig.items) {
                let session = this.getViewModel().get('session');

                routerConfig.itemsIdx = {};

                routerConfig.items.forEach(function (item) {
                    if (session.hasPermissions(item.permissions)) {
                        if (!routerConfig.defaultRoute) routerConfig.defaultRoute = item.reference;

                        routerConfig.itemsIdx[item.reference] = item;

                        if (!routerConfig.lazyItems) me.add(item);
                    }
                });
            }

            this.on({
                scope: this,
                beforeActiveItemChange: this.routeToItem
            });
JS

        routeToItem => func [ 'view', 'newItem', 'oldItem', 'eOpts' ], <<'JS',

            // it is not a redirect if ld item is not specified
            if (!oldItem) return;

            var routerConfig = this.getRouterConfig();

            this.redirectTo(routerConfig.routePath + newItem.getReference());

            return false;
JS

        redirectTo => func [ 'hash', 'args' ], <<'JS',
            Ext.fireEvent('redirectTo', hash, args);
JS

        redirectToDefaultRoute => func <<'JS',
            var routerConfig = this.getRouterConfig();

            this.redirectTo(routerConfig.routePath + this.getDefaultRoute(), {replace: true});
JS

        redirectToLastRoute => func <<'JS',
            var routerConfig = this.getRouterConfig();

            this.redirectTo(routerConfig.routePath + (routerConfig.lastRoute || this.getDefaultRoute()), {replace: true});
JS

        getDefaultRoute => func <<'JS',
            var routerConfig = this.getRouterConfig();

            return routerConfig.defaultRoute || this.getAt(0).getReference();
JS

        processRoute => func [ 'routes', 'path' ], <<'JS',
            var routerConfig = this.getRouterConfig(),
                route = routes.shift(),
                routeView;

            routerConfig.routePath = path ? path + '/' : '';

            // route is empty
            if (route == undefined || route == '') {
                this.redirectToLastRoute();

                return;
            }

            // has routers config specified
            else if (routerConfig.itemsIdx) {

                // route is known
                if (routerConfig.itemsIdx[route]) {

                    // find or create view
                    routeView = this.lookup(route) || this.add(routerConfig.itemsIdx[route]);
                }
            }

            // has no routers config
            else {
                routeView = this.lookup(route);
            }

            // route view wasn't found / created
            if (!routeView) {
                this.redirectToDefaultRoute();
            }

            // route view was found
            else {
                routerConfig.lastRoute = route;

                var canProcessRoute = !!routeView.processRoute;

                if (!canProcessRoute && routes.length) {
                    this.redirectTo(routerConfig.routePath + route, {replace: true});
                }
                else {
                    this.suspendEvent('beforeActiveItemChange');

                    this.setActiveItem(routeView);

                    this.resumeEvent('beforeActiveItemChange');

                    if (canProcessRoute) routeView.processRoute(routes, routerConfig.routePath + route);
                }
            }
JS
    };
}

sub EXT_lazy_items : Extend('Ext.Mixin') {
    return {
        config => {
            removeItemsOnDeactivate => \0,

            lazyItems => undef,
        },

        mixinConfig => {
            configs => \1,

            before => { constructor => 'beforeConstructor', },
            after  => { constructor => 'afterConstructor', },
        },

        beforeConstructor => func ['config'], <<'JS',
            config.lazyItems = config.items || this.config.items;

            config.items = null;
JS

        afterConstructor => func ['config'], <<'JS',
            this.on({
                scope      : this,
                activate   : 'onLazyItemsActivate',
                deactivate : 'onLazyItemsDeactivate'
            });
JS

        onLazyItemsActivate => func <<'JS',
            var items = this.getLazyItems();

            this.setLazyItems(null);

            if (!items) return;

             this.add(items);
JS

        onLazyItemsDeactivate => func <<'JS',
            if(!this.getRemoveItemsOnDeactivate()) return;

            var items = this.getItems().items,
                i = 0,
                len = items.length,
                lazyItems = [];

            for (; i < len; i++) {
                lazyItems.push(items[i]);
            }

            this.setLazyItems(lazyItems);

            this.removeAll(false, true);
JS
    };
}

sub EXT_upload : Extend('Ext.Mixin') {
    return {
        uploadStatusText => {
            new       => l10n('New'),
            starting  => l10n('Starting'),
            hash      => l10n('Calculating checksum'),
            uploading => l10n('Uploading'),
            cancelled => l10n('Cancelled'),
            error     => l10n('Error'),
            done      => l10n('Done'),
        },

        getUploadStatusText => func [ 'status', 'reason' ], <<'JS',
            var text = this.uploadStatusText[status];

            if (reason) text += ': ' + reason;

            return text;
JS

        getUploadStatusTextProgress => func [ 'status', 'reason', 'progress' ], <<'JS',
            var text = this.getUploadStatusText(status, reason);

            if (progress !== undefined) {
                return text + ' ' + Math.round(progress * 100) + '%';
            }
            else {
                return text;
            }
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Mixin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
