# NAME

Mojolicious::Plugin::Breadcrumbs - Mojolicious plugin for autogenerating breadcrumbs links

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    #!perl

    use Mojolicious::Lite;

    plugin 'Breadcrumbs';

    get '/user/account-settings' => 'account-settings';

    app->start;

    __DATA__

    @@ account-settings.html.ep

    You are at <%== breadcrumbs %>

<div>
    </div></div>
</div>

The output in the browser then be this
_(actual output will not have line breaks)_:

    You are at
    <section class="breadcrumbs">
        <a href="/">Home</a><span class="breadcrumb_sep">▸</span>
        <a href="/user">User</a><span class="breadcrumb_sep">▸</span>
            <span class="last_breadcrumb">Account settings</span>
    </section>

By default, `/` path will be named `Home`, and all other paths
will be named by changing `-` and `_` characters to spaces and
capitalizing the first letter. You can provide your
own mapping for certain paths, by passing a mapping
hashref to `breadcrumbs` helper. Anything not found in the map will
still be named as described above.

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    #!perl

    use Mojolicious::Lite;

    plugin 'Breadcrumbs';
    app->breadcrumbs({
        '/'     => 'Start page',
        '/user' => 'Your account',
        '/user/account-settings' => 'Settings',
    });
    get '/user/account-settings' => 'account-settings';

    app->start;

    __DATA__

    @@ account-settings.html.ep

    You are at <%== breadcrumbs %>

<div>
    </div></div>
</div>

The output in the browser then be this
_(actual output will not have line breaks)_:

    You are at
    <section class="breadcrumbs">
        <a href="/">Start page</a><span class="breadcrumb_sep">▸</span>
        <a href="/user">Your account</a>
        <span class="breadcrumb_sep">▸</span>
            <span class="last_breadcrumb">Settings</span>
    </section>

# DESCRIPTION

[Mojolicious::Plugin::Breadcrumbs](https://metacpan.org/pod/Mojolicious::Plugin::Breadcrumbs) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin for
auto-generating breadcrumbs.

# METHODS

[Mojolicious::Plugin::Breadcrumbs](https://metacpan.org/pod/Mojolicious::Plugin::Breadcrumbs) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## `->register()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png">
</div>

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# HELPERS

## `breadcrumbs`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png">
</div>

Using in HTML:

    You are at <%== breadcrumbs %>

Setting custom link names:

    app->breadcrumbs(
        '/'     => 'Start page',
        '/user' => 'Your account',
        '/user/account-settings' => 'Settings',
    );

See SYNOPSIS for full description of use and arguments.

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/Mojolicious-Plugin-Breadcrumbs](https://github.com/zoffixznet/Mojolicious-Plugin-Breadcrumbs)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/Mojolicious-Plugin-Breadcrumbs/issues](https://github.com/zoffixznet/Mojolicious-Plugin-Breadcrumbs/issues)

If you can't access GitHub, you can email your request
to `bug-mojolicious-plugin-breadcrumbs at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
