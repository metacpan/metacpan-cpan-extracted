## PAGI::FastAPI

[![CPAN version](https://badge.fury.io/pl/PAGI-FastAPI.svg)](https://metacpan.org/pod/PAGI::FastAPI)

FastAPI-inspired asynchronous micro-framework for Perl built on the **PAGI** protocol with **Type::Tiny** validation and automatic **OpenAPI 3.1** / **Swagger UI** documentation.

## SYNOPSIS

    use v5.36;
    use PAGI::FastAPI;
    use PAGI::FastAPI::Depends qw(Depends);
    use Types::Standard qw(Int Str);
    use Future::AsyncAwait;

    my $app = PAGI::FastAPI->new(
        title   => 'Store Microservice',
        version => '1.0.0',
    );

    # 1. Add CORS Support
    $app->add_cors(
        allow_origins => ['https://example.com'],
        allow_methods => ['GET', 'POST'],
    );

    # 2. Add Authentication Middleware Hook
    $app->add_middleware(async sub ($c, $next) {
        my $auth = $c->header('Authorization') // '';
        if ($auth ne 'Bearer secret_token') {
            $c->status(401);
            return { detail => 'Unauthorized' };
        }
        $c->stash->{user_id} = 42;
        return await $next->($c);
    });

    # 3. Register Lifespan Handlers
    $app->on_startup(async sub {
        warn "Connecting to database connection pool...\n";
    });

    $app->on_shutdown(async sub {
        warn "Closing database connections...\n";
    });

    # 4. Declare Async Dependencies
    my $get_db = async sub ($c) {
        return { db_name => 'production_db' };
    };

    my $get_current_user = async sub ($c) {
        my $token = $c->header('Authorization') // '';
        unless ($token eq 'Bearer secret_token') {
            $c->status(401);
            return { detail => 'Invalid credentials' };
        }
        return { user_id => 42, role => 'admin' };
    };

    # 5. Route using HashRef Dependency Map
    $app->get('/profile',
        dependencies => {
            db   => $get_db,
            user => $get_current_user,
        },
        handler => async sub ($c) {
            my $db   = $c->stash->{db};
            my $user = $c->stash->{user};
            return { user => $user, db => $db->{db_name} };
        }
    );

    # 6. Route using Depends() Array Spec
    $app->get('/admin',
        dependencies => [
            Depends($get_current_user, key => 'user'),
            async sub ($c) {
                if ($c->stash->{user}{role} ne 'admin') {
                    $c->status(403);
                    return { detail => 'Admin privileges required' };
                }
            }
        ],
        handler => async sub ($c) {
            return { message => 'Welcome to admin panel' };
        }
    );

    # 7. Non-blocking GET route with path parameter & query validation
    $app->get('/items/{id}',
        query   => { limit => Int },
        handler => async sub ($c) {
            return {
                item_id => $c->param('id'),
                limit   => $c->param('limit'),
                status  => 'active',
            };
        }
    );

    # 8. Non-blocking POST route with JSON payload validation
    $app->post('/items',
        body    => { name => Str, price => Int },
        handler => async sub ($c) {
            return {
                created => 1,
                name    => $c->body('name'),
                price   => $c->body('price'),
            };
        }
    );

    my $pagi_app = $app->to_app;

## LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License. By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you, you are nevertheless required to ensure that your Modified Version
complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make, have made, use, offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are necessarily infringed by the Package. If you institute patent litigation
(including a cross-claim or counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement, then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
