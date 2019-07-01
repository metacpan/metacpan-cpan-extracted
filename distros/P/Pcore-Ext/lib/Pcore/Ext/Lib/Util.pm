package Pcore::Ext::Lib::Util;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

# TODO make text bindable
# TODO redraw on update text
sub EXT_no_selection : Extend('Ext.Panel') {
    return {
        layout => 'center',

        config => { text => l10n('No item selected'), },

        initialize => func <<"JS",
            this.callParent(arguments);

            if (!this.getHtml()) {
                this.setHtml('<div style="text-align:center;color:grey;"><i class="$FAR_TIMES_CIRCLE" style="font-size:7em;"></i><br/><br/><div class="x-label-text-el" style="font-size:2em;">' + this.getText() + '</div></div>');
            }
JS
    };
}

# THEME
sub EXT_theme_controller : Extend('Ext.app.ViewController') {
    return {
        themes => P->cfg->read( $ENV->{share}->get('data/ext/material-themes.json') ),

        init => func ['view'],
        <<"JS",
            this.callParent(arguments);

            var columnsPanel = this.lookup('columns'),
                columns = [],
                currentCol;

                for (var i = 1; i <= view.getColumns(); i++) {
                    columns.push(columnsPanel.add({}));
                }

                for ( var name in this.themes ) {
                    currentCol = columns.shift();
                    columns.push(currentCol);

                    currentCol.add({
                        text: name
                    });
                }
JS

        setTheme => func [ 'button', 'e' ], <<"JS",
            Ext.fireEvent('setTheme', this.themes[button.getText()]);
JS
    };
}

sub EXT_theme : Extend('Ext.Panel') {
    return {
        controller => $type{'theme_controller'},

        config => {
            columns => 3,    # number of columns to distribute themes buttons
        },

        layout => 'vbox',

        items => [
            {   reference => 'columns',
                layout    => {
                    type  => 'hbox',
                    align => 'start',
                    pack  => 'start',
                },
                defaults => {
                    layout => {
                        type  => 'vbox',
                        align => 'start',
                        pack  => 'start',
                    },
                    defaults => {
                        xtype   => 'button',
                        iconCls => $FAS_PALETTE,
                        handler => 'setTheme',
                    },
                },
            },
            {   xtype    => 'togglefield',
                boxLabel => l10n('DARK MODE'),
                bind     => '{session.theme.darkMode}',
            },
        ],
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Util

=head1 SYNOPSIS

    # no selection panel
    xtype => $type{'/pcore/Util/no_selection'},
    text  => l10n('No campaign selected'),

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
