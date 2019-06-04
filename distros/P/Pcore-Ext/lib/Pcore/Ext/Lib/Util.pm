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
                this.setHtml('<div style="text-align:center;color:gray;"><i class="$FAR_TIMES_CIRCLE" style="font-size:7em;"></i><br/><br/><div class="x-label-text-el" style="font-size:2em;">' + this.getText() + '</div></div>');
            }
JS
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
