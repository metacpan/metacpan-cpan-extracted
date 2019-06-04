package Pcore::Ext::Lib::Mixin;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_route : Extend('Ext.Mixin') {
    return {
        router       => undef,
        defaultRoute => undef,
        routePath    => undef,
        lastRoute    => undef,

        processRoute => func [ 'routes', 'path' ],
        <<"JS",
            this.routePath = path ? path + '/' : '';

            var view = this.getView(),
                route = routes.shift();

            if (route == undefined || route == '') {
                if (this.lastRoute) {
                    this.redirectTo(this.routePath + this.lastRoute, {replace: true});
                }
                else {
                    this.redirectTo(this.routePath + this.defaultRoute, {replace: true});
                }
            }
            else {
                var routeView;

                if (this.router) {
                    if (!this.router[route]) {
                        this.redirectTo(this.routePath + this.defaultRoute, {replace: true});
                    }
                    else {
                        var routeView = this.lookup(route) || view.add({
                            xtype: this.router[route],
                            reference: route
                        });
                    }
                }
                else {
                    routeView = this.lookup(route);
                }

                if (!routeView) {
                    this.redirectTo(this.routePath + this.defaultRoute, {replace: true});
                }
                else {
                    this.lastRoute = route;

                    var routeViewController = routeView.getController(),
                        canProcessRoute = routeViewController && !!routeViewController.processRoute;

                    if (!canProcessRoute && routes.length) {
                        this.redirectTo(this.routePath + route, {replace: true});
                    }
                    else {
                        view.suspendEvent('beforeActiveItemChange');

                        view.setActiveItem(routeView);

                        view.resumeEvent('beforeActiveItemChange');

                        if (canProcessRoute) routeViewController.processRoute(routes, this.routePath + route);
                    }
                }
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
