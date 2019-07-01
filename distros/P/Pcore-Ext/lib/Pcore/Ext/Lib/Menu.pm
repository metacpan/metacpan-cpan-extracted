package Pcore::Ext::Lib::Menu;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_controller : Extend('Ext.app.ViewController') {
    return {
        listen => {
            global => {    #
                showMenu => 'showMenu',
            },
        },

        init => func ['view'],
        <<"JS",
            view.insert(0, { xtype: '$type{'top'}' });
            view.add({xtype: 'spacer'});
            view.add({xtype: '$type{'profile'}'});
            view.add({xtype: '$type{'bottom'}'});
            view.add({xtype: '$type{'version'}'});

            var session = this.getViewModel().get('session'),
                localeButton = this.lookup('change-locale-button'),
                locales = this.getViewModel().get('session').locales;

            if (view.getShowLocalesButton() && !Ext.Object.isEmpty(locales)) {
                var localeMenu = [];

                for (var locale of Object.keys(locales).sort()) {
                    localeMenu.push({
                        value: locale,
                        text: locales[locale],
                        handler: 'setLocale'
                    });
                }

                localeButton.setMenu(localeMenu);
            }
            else {
                localeButton.hide();
            }

            this.configureMenu(session);
JS

        defaultMenuItemHandler => func ['button'], <<'JS',
            this.getView().hide();

            if (button.route) this.redirectTo(button.route);
JS

        configureMenu => func ['session'], <<'JS',
JS

        showMenu => func <<'JS',
            this.getView().show();
JS

        setLocale => func [ 'menuItem', 'e' ], <<"JS",
            this.getView().hide();

            Ext.fireEvent('setLocale', menuItem.value);

JS

        signout => func <<"JS",

            // hide menu
            this.getView().hide();

            Ext.fireEvent('signout');
JS
    };
}

sub EXT_panel : Extend('Ext.ActionSheet') {
    return {
        controller => $type{controller},

        config => { showLocalesButton => \1, },

        cover      => \1,
        reveal     => \0,
        side       => 'right',
        displayed  => \0,
        padding    => 0,
        margin     => 0,
        maxWidth   => '80%',
        width      => 300,
        layout     => 'vbox',
        pack       => 'left',
        scrollable => 1,

        defaults => { xtype => $type{'item'}, },
    };
}

sub EXT_item : Extend('Ext.Button') {
    return {
        textAlign => 'left',
        padding   => '0 0 0 5',
        handler   => 'defaultMenuItemHandler',
    };
}

# BLOCKS
sub EXT_top : Extend('Ext.Panel') {
    return {
        layout    => 'vbox',
        height    => 130,
        innerCls  => 'x-tabbar',
        bodyStyle => {
            padding => '20px',
            margin  => '0px',
        },

        items => [
            {   xtype  => 'image',
                bind   => { src => '{session.avatar}', },
                width  => 60,
                height => 60,
                cls    => 'pcore-avatar',
            },
            {   xtype => 'component',
                bind  => '<br>{session.user_name}',
                style => 'color:white;font-size:1.5em;',
            },
        ],
    };
}

sub EXT_profile : Extend('Ext.Panel') {
    return {
        layout => 'vbox',

        defaults => { xtype => $type{'/pcore/Menu/item'}, },

        items => [
            {   reference => 'menu-profile',
                text      => l10n('Profile'),
                iconCls   => $FAS_USER_ALT,
                route     => 'profile',
            },
            {   text    => l10n('Sign out'),
                iconCls => $FAS_SIGN_OUT_ALT,
                handler => 'signout',
            },
        ],
    };
}

sub EXT_bottom : Extend('Ext.Panel') {
    return {
        layout  => 'hbox',
        padding => '0 10 0 10',

        items => [
            {   xtype    => 'togglefield',
                boxLabel => l10n('DARK MODE'),
                bind     => '{session.theme.darkMode}',
            },
            { xtype => 'spacer' },
            {   reference => 'change-locale-button',
                xtype     => 'button',
                iconCls   => $FAS_LANGUAGE,
                textAlign => 'left',
                bind      => '{session.localeName}',
            },
        ],
    };
}

sub EXT_version : Extend('Ext.Panel') {
    return {
        padding => '10 10 0 10',

        items => [
            {   xtype => 'component',
                bind  => '{session.version}',
                style => 'color:grey;text-align:right;',
            },
        ],
    };
}

# BUTTON
sub EXT_button : Extend('Ext.Container') {
    return {
        layout => 'fit',
        width  => 60,

        items => [ {
            xtype   => 'button',
            iconCls => $FAS_BARS,
            ui      => 'action',
            handler => func q[Ext.fireEvent('showMenu');],
        } ]
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Menu

=head1 SYNOPSIS



=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
