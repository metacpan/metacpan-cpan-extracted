package Pcore::Ext::Overrides::modern;

use Pcore -l10n;
use Pcore::CDN::Static::FA qw[:ALL];

sub EXT_override_grid_menu_SortAsc : Override('Ext.grid.menu.SortAsc') {
    return { config => { text => l10n('Sort Ascending'), }, };
}

sub EXT_override_grid_menu_SortDesc : Override('Ext.grid.menu.SortDesc') {
    return { config => { text => l10n('Sort Descending'), }, };
}

sub EXT_override_panel_Collapser : Override('Ext.panel.Collapser') {
    return {
        config => {
            collapseToolText => { html => l10n('Collapse panel') },
            expandToolText   => { html => l10n('Expand panel') },
        },
    };
}

sub EXT_override_dataview_plugin_ListPaging : Override('Ext.dataview.plugin.ListPaging') {
    return {
        config => {
            loadMoreText      => l10n('LOAD MORE ...'),
            noMoreRecordsText => l10n('NO MORE RECORDS'),
        },
    };
}

sub EXT_override_grid_PagingToolbar : Override('Ext.grid.PagingToolbar') {
    return {
        config => {
            prevButton => {
                xtype   => 'button',
                iconCls => $FAS_ARROW_LEFT,
            },
            nextButton => {
                xtype   => 'button',
                iconCls => $FAS_ARROW_RIGHT,
            },
        },
    };
}

sub EXT_override_field_Display : Override('Ext.field.Display') {
    return {    #
        defaultBindProperty => 'value',
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Overrides::modern

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
