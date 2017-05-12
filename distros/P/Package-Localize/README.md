# NAME

Package::Localize - localize package variables in other packages

# SYNOPSIS

Say you've got this pesky package someone wrote that decided to use globals:

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    package Foo;
    our $var = 42;
    sub inc { $var++ }

<div>
    </div></div>
</div>

Whenever you call `Foo::inc()`,
it'll always be increasing that `$var`, even if
you call it from different places. `Package::Localize` to the rescue:

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    my $p1 = Package::Localize->new('Foo');
    my $p2 = Package::Localize->new('Foo');

    say $p1->inc; # prints 42
    say $p1->inc; # prints 43

    say $p2->inc; # prints 42

<div>
    </div></div>
</div>

# DESCRIPTION

This module allows you to use multple instances of packages that have
package variables operated by the functions the module offers.

Currently there is no support for OO modules; functions only.

# METHODS

## `new`

    my $p1 = Package::Localize->new('Foo');

Takes one mandatory argument which is the name of the package you want to
localize.

Returns an object. Call functions from your original package as methods
on this object to operate on localizes package variables only.

## `name`

    my $name = $p1->name;
    no strict 'refs';
    my $p1_var = ${"$name::var"};

Returns the name of the localized package.

# BUGS AND CAVEATS

Currently there is no support for OO modules; functions only.
Patches are definitely welcome though.

# SEE ALSO

[Package::Stash](https://metacpan.org/pod/Package::Stash)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/Package-Localize](https://github.com/zoffixznet/Package-Localize)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/Package-Localize/issues](https://github.com/zoffixznet/Package-Localize/issues)

If you can't access GitHub, you can email your request
to `bug-Package-Localize at rt.cpan.org`

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
