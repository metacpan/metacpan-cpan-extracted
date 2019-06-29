use 5.20.0;
use warnings;

package Mojolicious::Plugin::BootstrapHelpers;

# ABSTRACT: Type less bootstrap
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0206';

use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::BootstrapHelpers::Helpers;
use experimental qw/postderef signatures/;

sub register($self, $app, $args) {

    if(exists $args->{'short_strappings_prefix'}) {
        $app->log->debug("'short_strappings_prefix' is deprecated. Use 'shortcut_prefix' instead");
        $args->{'shortcut_prefix'} //= $args->{'short_strappings_prefix'};
    }
    if(exists $args->{'init_short_strappings'}) {
        $app->log->debug("'init_short_strappings' is deprecated. Use 'init_shortcuts' instead");
        $args->{'init_shortcuts'} //= $args->{'init_short_strappings'};
    }
    my $tp = setup_prefix($args->{'tag_prefix'});
    my $ssp = setup_prefix($args->{'shortcut_prefix'});
    my $init_shortcuts = $args->{'init_shortcuts'} //= 1;

    $app->helper($tp.'bootstrap' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstraps_bootstraps);
    $app->helper($tp.'table' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_table);
    $app->helper($tp.'panel' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_panel);
    $app->helper($tp.'formgroup' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_formgroup);
    $app->helper($tp.'button' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_button);
    $app->helper($tp.'submit_button' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_submit);
    $app->helper($tp.'badge' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_badge);
    $app->helper($tp.'context_menu' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_context_menu);
    $app->helper($tp.'dropdown' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_dropdown);
    $app->helper($tp.'buttongroup' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_buttongroup);
    $app->helper($tp.'toolbar' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_toolbar);
    $app->helper($tp.'input' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_input);
    $app->helper($tp.'navbar' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_navbar);
    $app->helper($tp.'nav' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_nav);

    if(exists $args->{'icons'}{'class'} && $args->{'icons'}{'formatter'}) {
        $app->config->{'Plugin::BootstrapHelpers'} = $args;
        $app->helper($tp.'icon' => \&Mojolicious::Plugin::BootstrapHelpers::Helpers::bootstrap_icon);
    }

    if($init_shortcuts) {
        my @sizes = qw/xsmall small medium large/;
        my @contexts = qw/default active primary success info warning danger/;
        my @table = qw/striped bordered hover condensed responsive/;
        my @direction = qw/right left block vertical justified dropup/;
        my @menu = qw/caret hamburger/;
        my @misc = qw/disabled inverse/;

        foreach my $helper (@sizes, @contexts, @table, @direction, @menu, @misc) {
           $app->helper($ssp.$helper, sub { ("__$helper" => 1) });
        }
    }
}

sub setup_prefix($prefix) {
    return defined $prefix && !length $prefix   ?   '_'
         : defined $prefix                      ?   $prefix
         :                                          ''
         ;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::BootstrapHelpers - Type less bootstrap



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.20+-blue.svg" alt="Requires Perl 5.20+" />
<a href="https://travis-ci.org/Csson/p5-mojolicious-plugin-bootstraphelpers"><img src="https://api.travis-ci.org/Csson/p5-mojolicious-plugin-bootstraphelpers.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Mojolicious-Plugin-BootstrapHelpers-0.0206"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Mojolicious-Plugin-BootstrapHelpers/0.0206" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Mojolicious-Plugin-BootstrapHelpers%200.0206"><img src="http://badgedepot.code301.com/badge/cpantesters/Mojolicious-Plugin-BootstrapHelpers/0.0206" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-87.2%-orange.svg" alt="coverage 87.2%" />
</p>

=end html

=head1 VERSION

Version 0.0206, released 2019-06-24.

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('BootstrapHelpers');

    # ::Lite
    plugin 'BootstrapHelpers';

    # Meanwhile, somewhere in a template...
    %= formgroup 'Email', text_field => ['email'], large, cols => { small => [3, 9] }

    # ...that renders into
    <div class="form-group form-group-lg">
        <label class="control-label col-sm-3" for="email">Email</label>
        <div class="col-sm-9">
            <input class="form-control" id="email" name="email" type="text">
        </div>
    </div>

=head1 STATUS

Relatively stable. This distribution will not be updated to support Bootstrap 4. There might be a separate distribution for that.

All examples are tested.

=head1 DESCRIPTION

Mojolicious::Plugin::BootstrapHelpers is a convenience plugin that reduces some bootstrap complexity by introducing several tag helpers specifically for L<Bootstrap 3|http://www.getbootstrap.com/>.

The goal is not to have tag helpers for everything, but for common use cases.

All examples below (and more, see tests) is expected to work.

=head2 How to use Bootstrap

If you don't know what Bootstrap is, see L<http://www.getbootstrap.com/> for possible usages.

You might want to use L<Mojolicious::Plugin::Bootstrap3> in your templates.

To get going quickly by using the official CDN you can use the following helpers:

    # CSS
    %= bootstrap

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">

    # or (if you want to use the theme)
    %= bootstrap 'theme'

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap-theme.min.css">

    # And the javascript
    %= bootstrap 'js'

    <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

    # Or just:
    %= bootstrap 'all'

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap-theme.min.css">
    <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

It is also possible to automatically include jQuery (2.*)

    %= bootstrap 'jsq'

    <script src="//code.jquery.com/jquery-2.2.4.min.js"></script>
    <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

    %= bootstrap 'allq'

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap-theme.min.css">
    <script src="//code.jquery.com/jquery-2.2.4.min.js"></script>
    <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

=head2 Shortcuts

There are several shortcuts for applying context and size classes that automatically expands to the correct class depending
on which tag it is applied to. For instance, if you apply the C<info> shortcut to a panel, it becomes C<panel-info>, but when applied to a button it becomes C<btn-info>.

You can use them in two different ways, but internally they are the same. These to lines are exactly identical:

    # 'standalone shortcut'
    %= button 'Push me', primary

    # 'longform shortcut'
    %= button 'Push me', __primary => 1

For sizes, you can only use the longform (C<xsmall>, C<small>, C<medium> and C<large>). They are shortened to the Bootstrap type classes.

The following shortcuts are available:

   xsmall    default     striped       caret     right
   small     primary     bordered
   medium    success     hover
   large     info        condensed
             warning     responsive
             danger

Add two leading underscores if you don't want to use the standalone form.

See below for usage. B<Important:> You can't follow a standalone shortcut with a fat comma (C<=E<gt>>). The fat comma auto-quotes the string on the left, and then it breaks.

If a shortcut you try to apply isn't available in that context, it is silently not applied.

=for html <p>The standalone form is recommended for readability, but it does setup several helpers in your templates.
You can turn off this style, see <a href="#init_shortcuts">init_shortcuts</a>.</p>

=head2 Syntax convention

In the syntax sections below the following conventions are used:

    name            A specific string
    $name           Any string
    %name           One or more key-value pairs, written as:
                      key => 'value', key2 => 'value2'
                         or, if you use standalone shortcuts:
                      primary, large
    $key => [...]   Both of these are array references where the ordering of strings
    key  => [...]     are significant, for example:
                      key => [ $thing, $thing2, %hash ]
    $key => {...}   Both of these are hash references where the ordering of pairs are
    key  => {...}     are insignificant, for example:
                      key => { key2 => $value, key3 => 'othervalue' }
    (...)           Anything between parenthesis is optional. The parenthesis is not part of the
                      actual syntax
    |...|           Two pipes is a reference to another specification. For instance, button toolbars contain
                      button groups that contain buttons. Using this syntax makes the important parts clearer.
                      The pipes are not part of the actual syntax.

Ordering between two hashes that follows each other is also not significant.

B<About C<%has>>

The following applies to all C<%has> hashes below:

=over 4

=item * They refer to any html attributes and/or shortcuts to apply to the current element.

=item * When helpers are nested, all occurrencies are change to tag-specific names, such as C<%panel_has>.

=item * This hash is always optional. It is not marked so in the definitions below in order to reduce clutter.

=item * Depending on context either the leading or following comma is optional together with the hash. It is usually obvious.

=item * Sometimes on nested helpers (such as tables in panels just below), C<%has> is the only thing that can be applied to
        the other element. In this case C<panel =E<gt> { %panel_has }>. It follows from above that in those cases this entire
        expression is I<also> optional. Such cases are also not marked as optional in syntax definitions and are not mentioned
        in syntax description, unless they need further comment.

=back

From this definition:

    %= table ($title,) %table_has, panel => { %panel_has }, begin
           $body
    %  end

Both of these are legal:

    # since both panel => { %panel_has } and %table_has are hashes, their ordering is not significant.
    %= table 'Heading Table', panel => { success }, condensed, id => 'the-table', begin
         <tr><td>A Table Cell</td></tr>
    %  end


    %= table begin
         <tr><td>A Table Cell</td></tr>
    %  end

=head2 References

All other C<|references|> are also helpers, so C<|link|> and C<|item|> needs special mention.

=head3 |link|

C<|link|> creates an C<E<lt>aE<gt>> tag.

    |link|

Is exactly the same as

    $link_text, [ $url ], %link_has

B<C<$link_text>>

Mandatory. The text on the link.

B<C<$url>>

Mandatory. It sets the C<href> on the link. L<url_for|Mojolicious::Controller#url_for> is used to create the link.

B<C<%link_has>>

Which shortcuts are available varies depending on context.

=head3 |item|

C<|item|> is used in the various submenus/dropdowns. One C<|item|> creates one C<E<lt>liE<gt>> tag.

    |item|

Is exactly the same as

    [ |link| ]

    # or
    $header_text

    # or
    []

So, a submenu item can be one of three things:

=over 4

=item 1. A link, in which case you create a C<|link|> in an array reference.

=item 2. A C<.dropdown-header>, in which case you give it a C<'string'> which then is turned into the text of the header.

=item 3. A C<.divider>, in which case you give it an empty array reference.

=back

See L</"Dropdowns">, L</"Button groups"> and L</"Navbars"> for examples.

=head1 EXAMPLES

All examples below, and more, are included in html files in C</examples>. They are also available on github:

=over 4

=item *

L<Badges|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/badge-1.html>

=item *

L<Include bootstrap|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/bootstrap-1.html>

=item *

L<Buttons|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/button-1.html>

=item *

L<Button groups|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/button_group-1.html>

=item *

L<Dropdowns|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/dropdown-1.html>

=item *

L<Form groups|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/formgroup-1.html>

=item *

L<Icons|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/icon-1.html>

=item *

L<Input groups|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/input_group-1.html>

=item *

L<Navs|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/nav-1.html>

=item *

L<Navbars|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/navbar-1.html>

=item *

L<Panels|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/panel-1.html>

=item *

L<Tables|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/table-1.html>

=item *

L<Toolbars|http://htmlpreview.github.io/?https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers/blob/master/examples/toolbar-1.html>

=back

=head1 HELPERS

=head2 Badges

L<Bootstrap documentation|http://getbootstrap.com/components/#badges>

=head3 Syntax

    %= badge $text, %has

B<C<$text>>

Mandatory. If it is C<undef> no output is produced.

B<Available shortcuts>

C<right> applies C<.pull-right>.

=head3 Examples



=begin html

A basic badge:

=end html

    <%= badge '3' %>

    <span class="badge">3</span></a>

=begin html

A right aligned badge with a data attribute:

=end html

    <%= badge '4', data => { custom => 'yes' }, right %>

    <span class="badge pull-right" data-custom="yes">4</span>

=head2 Buttons

L<Bootstrap documentation|http://getbootstrap.com/css/#buttons>

=head3 Syntax

    %= button $button_text(, [$url]), %has

    %= submit_button $text, %has

B<C<$button_text>>

Mandatory. The text on the button.

B<C<[$url]>>

Optional array reference. It is handed off to L<url_for|Mojolicious::Controller#url_for>, so with it this is
basically L<link_to|Mojolicious::Plugin::TagHelpers#link_to> with Bootstrap classes.

Not available for C<submit_button>.

B<Available shortcuts>

C<default> C<primary> C<success> C<info> C<warning> C<danger> C<link> applies the various C<.btn-*> classes.

C<large> C<small> C<xsmall> applies C<.btn-lg> C<.btn-sm> C<.btn-xs> respectively.

C<active> C<block> applies the C<.active> and C<.block> classes.

C<disabled> applies the C<.disabled> class if the generated element is an C<E<lt>aE<gt>>. On a C<E<lt>buttonE<gt>> it applies the C<disabled="disabled"> attribute.

=head3 Examples



=begin html

An ordinary button, with applied shortcuts:

=end html

    %= button 'The example 5' => large, warning

    <button class="btn btn-lg btn-warning" type="button">The example 5</button>

=begin html

With a url the button turns into a link:

=end html

    %= button 'The example 1' => ['http://www.example.com/'], small

    <a class="btn btn-default btn-sm" href="http://www.example.com/">The example 1</a>

=begin html

A submit button for use in forms. It overrides the build-in submit_button helper:

=end html

    %= submit_button 'Save 2', primary

    <button class="btn btn-primary" type="submit">Save 2</button>

    %= button 'Loop', active

    <button class="active btn btn-default" type="button">Loop</button>

    %= button 'Loop', block

    <button class="block btn btn-default" type="button">Loop</button>

=head2 Button groups

=head3 Syntax

There are two different syntaxes. One for single-button groups and one for multi-button groups. The difference is that single-button groups can't change
anything concerning the buttongroup (e.g. it can't be C<justified>). If you need to do that there is nothing wrong with having a multi-button
group with just one button.

    # multi button
    <%= buttongroup %has,
                    buttons => [
                        [ |button|,
                          (items => [ |item| ])
                        ]
                    ]
    %>

    # single button
    <%= buttongroup [ |button|,
                      (items => [ |item| ])
                    ]
    %>

B<C<buttons =E<gt> []>>

The single-button style is a shortcut for the C<buttons> array reference. It takes ordinary L<buttons|/"Buttons">, with two differences: The C<items> array reference, and it is unnecessary to give a button
with C<items> a url.

=over 4

B<C<items =E<gt> [...]>>

Giving a button an C<items> array reference consisting of one or many C<|item|> creates a L<dropdown|/"Dropdowns"> like submenu. Read more under L</"item">.

=back

=head3 Examples



=begin html

A basic button group:

=end html

    <%= buttongroup
        buttons => [
            ['Button 1'],
            ['Button 2'],
            ['Button 3'],
        ]
    %>

    <div class="btn-group">
        <button class="btn btn-default" type="button">Button 1</button>
        <button class="btn btn-default" type="button">Button 2</button>
        <button class="btn btn-default" type="button">Button 3</button>
    </div>

=begin html

Nested button group. Note that the <code>small</code> shortcut is only necessary once. The same classes are automatically applied to the nested <code>.btn-group</code>:

=end html

    <%= buttongroup small,
        buttons => [
            ['Button 1'],
            ['Dropdown 1', caret, items => [
                ['Item 1', ['item1'] ],
                ['Item 2', ['item2'] ],
                [],
                ['Item 3', ['item3'] ],
            ] ],
            ['Button 2'],
            ['Button 3'],
        ],
    %>

    <div class="btn-group btn-group-sm">
        <button class="btn btn-default" type="button">Button 1</button>
        <div class="btn-group btn-group-sm">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">Dropdown 1 <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
        <button class="btn btn-default" type="button">Button 2</button>
        <button class="btn btn-default" type="button">Button 3</button>
    </div>

=begin html

Nested button group, with the <code>vertical</code> shortcut:

=end html

    <%= buttongroup vertical,
        buttons => [
            ['Button 1'],
            ['Dropdown 1', caret, items => [
                  ['Item 1', ['item1'] ],
                  ['Item 2', ['item2'] ],
                  [],
                  ['Item 3', ['item3'] ],
            ] ],
            ['Button 2'],
            ['Button 3'],
        ],
    %>

    <div class="btn-group-vertical">
        <button class="btn btn-default" type="button">Button 1</button>
        <div class="btn-group">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">Dropdown 1 <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
        <button class="btn btn-default" type="button">Button 2</button>
        <button class="btn btn-default" type="button">Button 3</button>
    </div>

=begin html

Mix links and <code>dropup</code> menus in <code>justified</code> button groups:

=end html

    <%= buttongroup justified,
        buttons => [
            ['Link 1', ['http://www.example.com/'] ],
            ['Link 2', ['http://www.example.com/'] ],
            ['Dropup 1', caret, dropup, items => [
                ['Item 1', ['item1'] ],
                ['Item 2', ['item2'] ],
                [],
                ['Item 3', ['item3'] ],
            ] ],
        ]
    %>

    <div class="btn-group btn-group-justified">
        <a class="btn btn-default" href="http://www.example.com/">Link 1</a>
        <a class="btn btn-default" href="http://www.example.com/">Link 2</a>
        <div class="btn-group dropup">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">Dropup 1 <span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
    </div>

=begin html

Split button dropdowns uses the same syntax as any other multi-button dropdown. Set the <code>caret</code> button title to <code>undef</code>:

=end html

    <%= buttongroup
        buttons => [
            ['Link 1', ['http://www.example.com/'] ],
            [undef, caret, items => [
                ['Item 1', ['item1'] ],
                ['Item 2', ['item2'] ],
                [],
                ['Item 3', ['item3'] ],
            ] ],
        ]
    %>

    <div class="btn-group">
        <a class="btn btn-default" href="http://www.example.com/">Link 1</a>
        <div class="btn-group">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown"><span class="caret"></span>
            </button>
            <ul class="dropdown-menu">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
    </div>

=begin html

Using the simpler single-button button group dropdown syntax:

=end html

    <%= buttongroup ['Default', caret, items  => [
                        ['Item 1', ['item1'] ],
                        ['Item 2', ['item2'] ],
                        [],
                        ['Item 3', ['item3'] ],
                    ] ]
    %>

    <%= buttongroup ['Big danger', caret, large, danger, items => [
                          ['Item 1', ['item1'] ],
                          ['Item 2', ['item2'] ],
                          [],
                          ['Item 3', ['item3'] ],
                    ] ]
    %>

    <div class="btn-group">
        <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">Default <span class="caret"></span>
        </button>
        <ul class="dropdown-menu">
            <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
            <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
            <li class="divider"></li>
            <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
        </ul>
    </div>

    <div class="btn-group">
        <button class="btn btn-danger btn-lg dropdown-toggle" type="button" data-toggle="dropdown">Big danger <span class="caret"></span>
        </button>
        <ul class="dropdown-menu">
            <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
            <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
            <li class="divider"></li>
            <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
        </ul>
    </div>

=head2 Button toolbars

=head3 Syntax

    <%= toolbar %toolbar_has,
                groups => [
                    { |button_group| }
                ]
    %>

B<C<groups =E<gt> [ { |button_group| } ]>>

A mandatory array reference of L<button groups|/"Button-groups">.

=head3 Examples



    <%= toolbar id => 'my-toolbar',
                groups => [
                    { buttons => [
                        ['Button 1'],
                        ['Button 2'],
                        ['Button 3'],
                      ],
                    },
                    { buttons => [
                        ['Button 4', primary],
                        ['Button 5'],
                        ['Button 6'],
                      ],
                    },
                ]
    %>

    <div class="btn-toolbar" id="my-toolbar">
        <div class="btn-group">
            <button class="btn btn-default" type="button">Button 1</button>
            <button class="btn btn-default" type="button">Button 2</button>
            <button class="btn btn-default" type="button">Button 3</button>
        </div>
        <div class="btn-group">
            <button class="btn btn-primary" type="button">Button 4</button>
            <button class="btn btn-default" type="button">Button 5</button>
            <button class="btn btn-default" type="button">Button 6</button>
        </div>
    </div>

=head2 Context menus

Context menus are a slight variation on L<dropdowns|/Dropdowns>, where the button or other thing that opens the menu isn't part of the menu, such as menus that
opens on right click. The context menu is created without the E<lt>div class="dropdown"E<gt>E<lt>/divE<gt> wrapper, so for it to show up at the right place its
position must be set using either CSS or Javascript.

=head3 Syntax

    <%= context_menu %has, items  => [ |item| ] %>

B<C<items>>

Mandatory array reference consisting of one or many C<|item|>. Read more under L</"item">.

=head3 Examples



        <%= context_menu id => 'my-context-menu', items => [
                ['Item 1', ['item1'] ],
                ['Item 2', ['item2'] ],
                [],
                ['Item 3', ['item3'] ]
             ] %>
    </div>

    <ul class="dropdown-menu" id="my-context-menu">
        <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
        <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
        <li class="divider"></li>
        <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
    </ul>

=head2 Dropdowns

=head3 Syntax

    <%= dropdown  %has,
                  [ |button|, items  => [ |item| ]
                  ]

B<C<[ |button| ]>>

Mandatory array reference. It takes an ordinary L<button|/"Buttons">, with two differences: The C<items> array reference, and it is unnecessary to give a button
with C<items> a url.

=over 4

B<C<items>>

Mandatory array reference consisting of one or many C<|item|>. Read more under L</"item">.

=back

B<Available shortcuts>

C<caret> adds a C<E<lt>span class="caret"E<gt>E<lt>/span<E<gt>> element on the button.

=head3 Examples



=begin html

By default, <code>tabindex</code> is set to <code>-1</code>:

=end html

    <div class="text-right">
        <%= dropdown
             ['Dropdown 1', id => 'a_custom_id', right, items => [
                ['Item 1', ['item1'] ],
                ['Item 2', ['item2'] ],
                [],
                ['Item 3', ['item3'] ]
             ] ] %>
    </div>

    <div class="text-right">
        <div class="dropdown">
            <button class="btn btn-default dropdown-toggle" type="button" id="a_custom_id" data-toggle="dropdown">Dropdown 1</button>
            <ul class="dropdown-menu dropdown-menu-right">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
    </div>

=begin html

...but it can be overridden:

=end html

    <%= dropdown
         ['Dropdown 2', caret, large, primary, items => [
            ['Item 1', ['item1'], data => { attr => 2 } ],
            ['Item 2', ['item2'], disabled, data => { attr => 4 } ],
            [],
            ['Item 3', ['item3'], data => { attr => 7 } ],
            [],
            ['Item 4', ['item4'], tabindex => 4 ],
            'This is a header',
            ['Item 5', ['item5'] ],
         ] ] %>

    <div class="dropdown">
        <button class="btn btn-lg btn-primary dropdown-toggle" type="button" data-toggle="dropdown">Dropdown 2 <span class="caret"></span></button>
        <ul class="dropdown-menu">
            <li><a class="menuitem" href="item1" tabindex="-1" data-attr="2">Item 1</a></li>
            <li class="disabled"><a class="menuitem" href="item2" tabindex="-1" data-attr="4">Item 2</a></li>
            <li class="divider"></li>
            <li><a class="menuitem" href="item3" tabindex="-1" data-attr="7">Item 3</a></li>
            <li class="divider"></li>
            <li><a class="menuitem" href="item4" tabindex="4">Item 4</a></li>
            <li class="dropdown-header">This is a header</li>
            <li><a class="menuitem" href="item5" tabindex="-1">Item 5</a></li>
        </ul>
    </div>

=head2 Form groups

L<Bootstrap documentation|http://getbootstrap.com/css/#forms>

=head3 Syntax

    <%= formgroup ($labeltext,)
                   %formgroup_has,
                  (cols => { $size => [ $label_columns, $input_columns ], (...) })
                   $fieldtype => [
                       $input_name,
                      ($input_value,)
                       %input_has,
                  ]

    %>

    # The $labeltext can also be given in the body
    %= formgroup <as above>, begin
        $labeltext
    %  end

B<C<$labeltext>>

Optional. It is either the first argument, or placed in the body. It creates a C<label> element before the C<input>.

B<C<cols>>

Optional. It is only used when the C<form> is a C<.form-horizontal>. You can defined the widths for one or more or all of the sizes. See examples.

=over 4

B<C<$size>>

Mandatory. It is one of C<xsmall>, C<small>, C<medium> or C<large>. C<$size> takes a two item array reference.

=over 4

B<C<$label_columns>>

Mandatory. The number of columns that should be used by the label for that size of screen. Applies C<.col-$size-$label_columns> on the label.

B<C<$input_columns>>

Mandatory. The number of columns that should be used by the input for that size of screen. Applies C<.col-$size-$input_columns> around the input.

=back

=back

B<C<$fieldtype>>

Mandatory. Is one of C<text_field>, C<password_field>, C<datetime_field>, C<date_field>, C<month_field>, C<time_field>, C<week_field>,
C<number_field>, C<email_field>, C<url_field>, C<search_field>, C<tel_field>, C<color_field>.

There can be only one C<$fieldtype> per C<formgroup>.

=over 4

B<C<$name>>

Mandatory. It sets both the C<id> and C<name> of the input field. If the C<$name> contains dashes then those are translated
into underscores when setting the C<name>. If C<id> exists in C<%input_has> then that is used for the C<id> instead.

B<C<$input_value>>

Optional. If you prefer you can set C<value> in C<%input_has> instead. (But don't do both for the same field.)

=back

=head3 Examples



=begin html

The first item in the array ref is used for both <code>id</code> and <code>name</code>. Except...

=end html

    %= formgroup 'Text test 1', text_field => ['test_text']

    <div class="form-group">
        <label class="control-label" for="test_text">Text test 1</label>
        <input class="form-control" id="test_text" name="test_text" type="text" />
    </div>

=begin html

...if the input name (the first item in the text_field array ref) contains dashes -- those are replaced (in the <code>name</code>) to underscores:

=end html

    %= formgroup 'Text test 4', text_field => ['test-text', large]

    <div class="form-group">
        <label class="control-label" for="test-text">Text test 4</label>
        <input class="form-control input-lg" id="test-text" name="test_text" type="text" />
    </div>

=begin html

An input with a value:

=end html

    %= formgroup 'Text test 5', text_field => ['test_text', '200' ]

    <div class="form-group">
        <label class="control-label" for="test_text">Text test 5</label>
        <input class="form-control" id="test_text" name="test_text" type="text" value="200" />
    </div>

=begin html

Note the difference with the earlier example. Here <code>large</code> is outside the <code>text_field</code> array reference, and therefore <code>.form-group-lg</code> is applied to the form group:

=end html

    <form class="form-horizontal">
        %= formgroup 'Text test 6', text_field => ['test_text'], large, cols => { small => [2, 10] }
    </form>

    <form class="form-horizontal">
        <div class="form-group form-group-lg">
            <label class="control-label col-sm-2" for="test_text">Text test 6</label>
            <div class="col-sm-10">
                <input class="form-control" id="test_text" name="test_text" type="text">
            </div>
        </div>
    </form>

=begin html

A formgroup used in a <code>.form-horizontal</code> <code>form</code>:

(Note that in this context, <code>medium</code> and <code>large</code> are not shortcuts, but ordinary hash keys.)

=end html

    %= formgroup 'Text test 8', text_field => ['test_text'], cols => { medium => [2, 10], small => [4, 8] }

    <div class="form-group">
        <label class="control-label col-md-2 col-sm-4" for="test_text">Text test 8</label>
        <div class="col-md-10 col-sm-8">
            <input class="form-control" id="test_text" name="test_text" type="text" />
        </div>
    </div>

=head2 Icons

This helper needs to be activated separately, see options below.

=head3 Syntax

    %= icon $icon_name

B<C<$icon_name>>

Mandatory. The specific icon you wish to create. Possible values depends on your icon pack.

=head3 Examples



    <%= icon 'copyright-mark' %>
    %= icon 'sort-by-attributes-alt'

    <span class="glyphicon glyphicon-copyright-mark"></span>
    <span class="glyphicon glyphicon-sort-by-attributes-alt"></span>

=head2 Input groups

=head3 Syntax

    <%= input %has,
              (prepend => ...,)
              input => { |input_field| },
              (append => ...)
    %>

B<C<input =E<gt> { }>>

Mandatory hash reference. The content is handed off to L<input_tag|Mojolicious::Plugin::TagHelpers/"input_tag"> in L<Mojolicious::Plugin::TagHelpers>.

B<C<prepend> and C<append>>

Both are optional, but input groups don't make sense if neither is present. They take the same arguments, but there are a few to choose from:

=over 4

B<C<prepend =E<gt> $string>>

B<C<prepend =E<gt> { check_box =E<gt> [ |check_box| ] }>>

Creates a checkbox by giving its content to L<check_box|Mojolicious::Plugin::TagHelpers/"check_box"> in L<Mojolicious::Plugin::TagHelpers>.

B<C<prepend =E<gt> { radio_button =E<gt> [ |radio_button| ] }>>

Creates a radiobutton by giving its content to L<radio_button|Mojolicious::Plugin::TagHelpers/"radio_button"> in L<Mojolicious::Plugin::TagHelpers>.

B<C<prepend =E<gt> { buttongroup =E<gt> { |buttongroup| }>>

Creates a single button buttongroup. See L<button groups|/"Button-groups"> for details.

B<C<prepend =E<gt> { buttongroup =E<gt> [ |buttongroup| ]>>

Creates a multi button buttongroup. See L<button groups|/"Button-groups"> for details.

=back

=head3 Examples



=begin html

An input group with a checkbox:

=end html

    <%= input input => { text_field => ['username'] },
              prepend => { check_box => ['agreed'] }
    %>

    <div class="input-group">
        <span class="input-group-addon"><input name="agreed" type="checkbox" /></span>
        <input class="form-control" id="username" type="text" name="username" />
    </div>

=begin html

A <code>large</code> input group with a radio button prepended and a string appended:

=end html

    <%= input large,
              prepend => { radio_button => ['yes'] },
              input => { text_field => ['username'] },
              append => '@'
    %>

    <div class="input-group input-group-lg">
        <span class="input-group-addon"><input name="yes" type="radio" /></span>
        <input class="form-control" id="username" type="text" name="username" />
        <span class="input-group-addon">@</span>
    </div>

=begin html

An input group with a button:

=end html

    <%= input input => { text_field => ['username'] },
              append => { button => ['Click me!'] },
    %>

    <div class="input-group">
        <input class="form-control" id="username" type="text" name="username" />
        <span class="input-group-btn"><button class="btn btn-default" type="button">Click me!</button></span>
    </div>

=begin html

An input group with a button dropdown appended. Note that <code>right</code> is manually applied:

=end html

    <%= input input  => { text_field => ['username'] },
              append => { buttongroup => [['The button', caret, right, items => [
                                  ['Item 1', ['item1'] ],
                                  ['Item 2', ['item2'] ],
                                  [],
                                  ['Item 3', ['item3'] ],
                              ] ] ]
                        }
    %>

    <div class="input-group">
        <input class="form-control" id="username" type="text" name="username" />
        <div class="input-group-btn">
            <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown">The button <span class="caret"></span>
            </button>
            <ul class="dropdown-menu dropdown-menu-right">
                <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                <li class="divider"></li>
                <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
            </ul>
        </div>
    </div>

=begin html

An input group with a split button dropdown prepended:

=end html

    <%= input input   => { text_field => ['username'] },
              prepend => { buttongroup => [
                              buttons => [
                                ['Link 1', ['http://www.example.com/'] ],
                                [undef, caret, items => [
                                      ['Item 1', ['item1'] ],
                                      ['Item 2', ['item2'] ],
                                      [],
                                      ['Item 3', ['item3'] ],
                                  ],
                               ],
                            ],
                         ],
                      },
    %>

    <div class="input-group">
        <div class="input-group-btn">
            <a class="btn btn-default" href="http://www.example.com/">Link 1</a>
            <div class="btn-group">
                <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown"><span class="caret"></span>
                </button>
                <ul class="dropdown-menu">
                    <li><a class="menuitem" href="item1" tabindex="-1">Item 1</a></li>
                    <li><a class="menuitem" href="item2" tabindex="-1">Item 2</a></li>
                    <li class="divider"></li>
                    <li><a class="menuitem" href="item3" tabindex="-1">Item 3</a></li>
                </ul>
            </div>
        </div>
        <input class="form-control" id="username" type="text" name="username" />
    </div>

=head2 Navs

=head3 Syntax

    <%= nav %has,
            $type => [ |link|,
                      (items => [ |item| ])
                    ]
    %>

C<Navs> are syntactically similar to L<button groups|/"Button-groups">.

B<C<$type =E<gt> [...]>>

Mandatory. C<$type> is either C<pills> or C<tabs> (or C<items> if the C<nav> is in a L<navbar|/"Navbars">) and applies the adequate class to the surrounding C<ul>.

=over 4

B<C<items =E<gt> [ |item| ]>>

If present does the same as C<items> in L<dropdown|/"Dropdowns">. Also see L</"item">.

=back

=head3 Examples



=begin html

A simple pills navigation:

=end html

    <%= nav pills => [
                ['Item 1', ['#'] ],
                ['Item 2', ['#'], active ],
                ['Item 3', ['#'] ],
                ['Item 4', ['#'], disabled ],
            ]
    %>

    <ul class="nav nav-pills">
        <li><a href="#">Item 1</a></li>
        <li class="active"><a href="#">Item 2</a></li>
        <li><a href="#">Item 3</a></li>
        <li class="disabled"><a href="#">Item 4</a></li>
    </ul>

=begin html

A tab navigation with a menu:

=end html

    <%= nav justified, id => 'my-nav', tabs => [
                ['Item 1', ['#'] ],
                ['Item 2', ['#'], active ],
                ['Item 3', ['#'] ],
                ['Dropdown', ['#'], caret, items => [
                        ['There are...', ['#'] ],
                        ['...three...', ['#'] ],
                        [],
                        ['...choices', ['#'] ],
                    ],
                ],
            ]
    %>

    <ul class="nav nav-justified nav-tabs" id="my-nav">
        <li><a href="#">Item 1</a></li>
        <li class="active"><a href="#">Item 2</a></li>
        <li><a href="#">Item 3</a></li>
        <li class="dropdown">
            <a class="dropdown-toggle" data-toggle="dropdown" href="#">Dropdown <span class="caret"></span></a>
            <ul class="dropdown-menu">
                <li><a href="#">There are...</a></li>
                <li><a href="#">...three...</a></li>
                <li class="divider"></li>
                <li><a href="#">...choices</a></li>
            </ul>
        </li>
    </ul>

=head2 Navbars

=head3 Syntax

    navbar (inverse,) (container => 'normal',) header => [ |link|, %navbar_has ],
                 form => [
                     [ [ $url ], %form_has ],
                     [
                         formgroup => [ |formgroup| ],
                         input => [ |input| ],
                         button => [ |button| ],
                         submit_button => [ |submit_button| ],
                      ]
                  ],
                  button => [ |button| ],
                  nav => [ |nav| ]
                  p => [ $text, %p_has ]

C<Navbars> are complex structures. They take the following arguments:

B<C<inverse>>

The C<inverse> shortcut is placed outside the C<%navbar_has>. It applies the C<.navbar-inverse> class.

B<C<container>>

Default: C<fluid>

Allowed values: C<fluid>, C<normal>

Sets the class on the container inside the navbar.

B<C<header =E<gt> [ |link|, %navbar_has ]>>

C<header> creates a C<navbar-header>. There can be only one C<header>.

=over 4

B<C<|link|>>

Creates the C<brand>. Set the link text to C<undef> if you don't want a brand.

B<C<%navbar_has>>

Can take the following extra arguments:

=over 4

The C<hamburger> shortcut creates the menu button for collapsed navbars.

B<C<toggler =E<gt> $collapse_id>>

This sets the C<id> on the collapsing part of the navbar. Set it if you need to reference that part of the navbar, otherwise an id will be generated.

=back

=back

The following arguments can appear any number of times, and is rendered in order.

=over 4

B<C<button =E<gt> [ |button| ]>>

Creates a L<button|/"Buttons">.

B<C<nav =E<gt> [ |nav| ]>>

Creates a L<nav|/"Navs">. Use C<items> if you need to create submenus.

B<C<p =E<gt> [ $text, %p_has ]>>

Creates a C<E<lt>pE<gt>$textE<lt>/pE<gt>> tag.

B<C<form =E<gt> [...]>>

Creates a C<form>, by leveraging L<form_for|Mojolicious::Plugin::TagHelpers#form_for> in L<Mojolicious::Plugin::TagHelpers>.

=over 4

B<C<[ [ $url ], %form_has ]>>

Mandatory array reference. This sets up the C<form> tag.

B<C<[...]>>

Mandatory array reference. The second argument to C<form> can take different types (any number of times, rendered in order):

=over 4

B<C<formgroup =E<gt> [ |formgroup| ]>>

B<C<input =E<gt> [ |input| ]>>

B<C<button =E<gt> [ |button| ]>>

B<C<submit_button =E<gt> [ |submit_button| ]>>

Creates L<form groups|/"Form-groups">, L<input groups|/"Input-groups">, L<buttons|/"Buttons"> and L<submit_buttons|/"Submit_buttons">

=back

=back

=back

=head3 Examples



=begin html

A simple navbar with a couple of links and a submenu:

=end html

    <%= navbar header => ['The brand', ['#'], hamburger, toggler => 'bs-example-navbar-collapse-2'],
               nav => [ items => [
                       ['Link', ['#'] ],
                       ['Another link', ['#'], active ],
                       ['Menu', ['#'], caret, items => [
                           ['Choice 1', ['#'] ],
                           ['Choice 2', ['#'] ],
                           [],
                           ['Choice 3', ['#'] ],
                       ] ],
                   ]
               ]
    %>

    <nav class="navbar navbar-default">
        <div class="container-fluid">
            <div class="navbar-header">
                <button class="collapsed navbar-toggle" data-target="#bs-example-navbar-collapse-2" data-toggle="collapse" type="button">
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                <a class="navbar-brand" href="#">The brand</a>
            </div>
            <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-2">
                <ul class="nav navbar-nav">
                    <li><a href="#">Link</a></li>
                    <li class="active"><a href="#">Another link</a></li>
                    <li class="dropdown">
                        <a class="dropdown-toggle" data-toggle="dropdown" href="#">Menu <span class="caret"></span></a>
                        <ul class="dropdown-menu">
                            <li><a href="#">Choice 1</a></li>
                            <li><a href="#">Choice 2</a></li>
                            <li class="divider"></li>
                            <li><a href="#">Choice 3</a></li>
                        </ul>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

=begin html

This is (almost) identical to the <a href="http://getbootstrap.com/components/#navbar">Bootstrap documentation example</a>. The differences should be: The <code>form</code> has an action and the <code>input</code> has an <code>id</code> and a <code>name</code>:

=end html

    <%= navbar header => ['Brand', ['#'], hamburger, toggler => 'collapse-4124'],
               nav => [ items => [
                       ['Link', ['#'], active ],
                       ['Link', ['#'] ],
                       ['Dropdown', ['#'], caret, items => [
                           ['Action', ['#'] ],
                           ['Another action', ['#'] ],
                           ['Something else here', ['#'] ],
                           [],
                           ['Separated link', ['#'] ],
                           [],
                           ['One more separated link', ['#'] ],
                       ] ] ],
                ],
                form => [
                    [['/login'], method => 'post', left],
                    [
                        formgroup => [
                            text_field => ['the-search', placeholder => 'Search' ],
                        ],
                        submit_button => ['Submit'],
                    ]
                ],
                nav => [
                    right,
                    items => [
                        ['Link', ['#'] ],
                        ['Dropdown', ['#'], caret, items => [
                                ['Action', ['#'] ],
                                ['Another action', ['#'] ],
                                ['Something else here', ['#'] ],
                                [],
                                ['Separated link', ['#'] ],
                            ],
                        ]
                    ],
                ]
    %>

    <nav class="navbar navbar-default">
        <div class="container-fluid">
            <div class="navbar-header">
                <button type="button" class="collapsed navbar-toggle" data-toggle="collapse" data-target="#collapse-4124">
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                <a class="navbar-brand" href="#">Brand</a>
            </div>
            <div class="collapse navbar-collapse" id="collapse-4124">
                <ul class="nav navbar-nav">
                    <li class="active"><a href="#">Link</a></li>
                    <li><a href="#">Link</a></li>
                    <li class="dropdown">
                        <a class="dropdown-toggle" data-toggle="dropdown" href="#">Dropdown <span class="caret"></span></a>
                        <ul class="dropdown-menu">
                            <li><a href="#">Action</a></li>
                            <li><a href="#">Another action</a></li>
                            <li><a href="#">Something else here</a></li>
                            <li class="divider"></li>
                            <li><a href="#">Separated link</a></li>
                            <li class="divider"></li>
                            <li><a href="#">One more separated link</a></li>
                        </ul>
                    </li>
                </ul>
                <form action="/login" class="navbar-form navbar-left" method="post">
                    <div class="form-group">
                        <input class="form-control" id="the-search" name="the_search" placeholder="Search" type="text" />
                    </div>
                    <button class="btn btn-default" type="submit">Submit</button>
                </form>
                <ul class="nav navbar-nav navbar-right">
                    <li><a href="#">Link</a></li>
                    <li class="dropdown">
                        <a class="dropdown-toggle" data-toggle="dropdown" href="#">Dropdown <span class="caret"></span></a>
                        <ul class="dropdown-menu">
                            <li><a href="#">Action</a></li>
                            <li><a href="#">Another action</a></li>
                            <li><a href="#">Something else here</a></li>
                            <li class="divider"></li>
                            <li><a href="#">Separated link</a></li>
                        </ul>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

=head2 Panels

L<Bootstrap documentation|http://getbootstrap.com/components/#panels>

=head3 Syntax

    %= panel ($title, %has, begin
        $body
    %  end)

B<C<$title>>

Usually mandatory, but can be omitted if there are no other arguments to the C<panel>. Otherwise, if you don't want a title, set it C<undef>.

B<C<$body>>

Optional (but panels are not much use without it). The html inside the C<panel>.

=head3 Examples



=begin html

The class is set to <code>.panel-default</code>, by default:

=end html

    %= panel

    <div class="panel panel-default">
        <div class="panel-body">
        </div>
    </div>

=begin html

If you want a panel without title, set the title to <code>undef</code>:

=end html

    %= panel undef ,=> begin
        <p>A short text.</p>
    %  end

    <div class="panel panel-default">
        <div class="panel-body">
            <p>A short text.</p>
        </div>
    </div>

=begin html

A <code>success</code> panel with a header:

=end html

    %= panel 'Panel 5', success, begin
        <p>A short text.</p>
    %  end

    <div class="panel panel-success">
        <div class="panel-heading">
            <h3 class="panel-title">Panel 5</h3>
        </div>
        <div class="panel-body">
            <p>A short text.</p>
        </div>
    </div>

=head2 Tables

L<Bootstrap documentation|http://getbootstrap.com/css/#tables>

=head3 Syntax

    %= table ($title,) %table_has, panel => { %panel_has }, begin
           $body
    %  end

B<C<$title>>

Optional. If set the table will be wrapped in a panel, and the table replaces the body in the panel.

B<C<$body>>

Mandatory. C<thead>, C<td> and so on.

B<C<panel =E<gt> { %panel_has }>>

Optional if the table has a C<$title>, otherwise without use.

=head3 Examples



=begin html

A basic table:

=end html

    <%= table begin %>
        <thead>
            <tr>
                <th>th 1</th>
                <th>th 2</th>
        </thead>
        <tbody>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
        </tbody>
    <% end %>

    <table class="table">
        <thead>
            <tr>
                <th>th 1</th>
                <th>th 2</th>
        </thead>
        <tbody>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
        </tbody>
    </table>

=begin html

Several classes applied to the table:

=end html

    %= table hover, striped, condensed, begin
        <thead>
            <tr>
                <th>th 1</th>
                <th>th 2</th>
        </thead>
        <tbody>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
        </tbody>
    %  end

    <table class="table table-condensed table-hover table-striped">
        <thead>
            <tr>
                <th>th 1</th>
                <th>th 2</th>
        </thead>
        <tbody>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
        </tbody>
    </table>

=begin html

A <code>condensed</code> table with an <code>id</code> wrapped in a <code>success</code> panel:

=end html

    %= table 'Heading Table 4', panel => { success }, condensed, id => 'the-table', begin
            <thead>
                <tr>
                    <th>th 1</th>
                    <th>th 2</th>
            </thead>
            <tbody>
                <tr>
                    <td>Cell 1</td>
                    <td>Cell 2</td>
                </tr>
                <tr>
                    <td>Cell 1</td>
                    <td>Cell 2</td>
                </tr>
            </tbody>
    %  end

    <div class="panel panel-success">
        <div class="panel-heading">
            <h3 class="panel-title">Heading Table 4</h3>
        </div>
        <table class="table table-condensed" id="the-table">
            <thead>
                <tr>
                    <th>th 1</th>
                    <th>th 2</th>
            </thead>
            <tbody>
                <tr>
                    <td>Cell 1</td>
                    <td>Cell 2</td>
                </tr>
                <tr>
                    <td>Cell 1</td>
                    <td>Cell 2</td>
                </tr>
            </tbody>
        </table>
    </div>

=head1 OPTIONS

Some options are available:

    $app->plugin('BootstrapHelpers', {
        tag_prefix => 'bs',
        shortcut_prefix => 'set',
        init_shortcuts => 1,
        icons => {
            class => 'glyphicon'
            formatter => 'glyphicon-%s',
        },
    });

=head2 tag_prefix

Default: C<undef>

If you want to you change the name of the tag helpers, by applying a prefix. These are not aliases;
by setting a prefix the original names are no longer available. The following rules are used:

=over 4

=item *
If the option is missing, or is C<undef>, there is no prefix.

=item *
If the option is set to the empty string, the prefix is C<_>. That is, C<panel> is now used as C<_panel>.

=item *
If the option is set to any other string, the prefix is that string. If you set C<tag_prefix =E<gt> 'bs'>, then C<panel> is now used as C<bspanel>.

=back

=head2 shortcut_prefix

Default: C<undef>

This is similar to C<tag_prefix>, but is instead applied to the standalone shortcuts. The same rules applies.

=head2 init_shortcuts

Default: C<1>

If you don't want the standalone shortcuts setup at all, set this option to a defined but false value.

All functionality is available, but instead of C<warning> you must now write C<__warning =E<gt> 1>.

With standalone form turned off, sizes are still only supported in long form: C<__xsmall>, C<__small>, C<__medium> and C<__large>. The Bootstrap abbreviations (C<xs> - C<lg>) are not available.

=head2 icons

Default: not set

By setting these keys you activate the C<icon> helper. You can pick any icon pack that sets one main class and one subclass to create an icon.

=over 4

B<C<class>>

This is the main icon class. If you use the glyphicon pack, this should be set to 'glyphicon'.

B<C<formatter>>

This creates the specific icon class. If you use the glyphicon pack, this should be set to 'glyphicon-%s', where the '%s' will be replaced by the icon name you give the C<icon> helper.

=back

=head1 SOURCE

L<https://github.com/Csson/p5-mojolicious-plugin-bootstraphelpers>

=head1 HOMEPAGE

L<https://metacpan.org/release/Mojolicious-Plugin-BootstrapHelpers>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Bootstrap itself is (c) Twitter. See L<their license information|http://getbootstrap.com/getting-started/#license-faqs>.

L<Mojolicious::Plugin::BootstrapHelpers> is third party software, and is not endorsed by Twitter.

=cut
