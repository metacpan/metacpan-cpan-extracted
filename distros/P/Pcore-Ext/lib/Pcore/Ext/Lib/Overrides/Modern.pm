package Pcore::Ext::Lib::Overrides::Modern;

use Pcore -l10n;

sub EXT_override_grid_menu_SortAsc : Override('Ext.grid.menu.SortAsc') : Ext('modern') {
    return { config => { text => l10n('Sort Ascending'), }, };
}

sub EXT_override_grid_menu_SortDesc : Override('Ext.grid.menu.SortDesc') : Ext('modern') {
    return { config => { text => l10n('Sort Descending'), }, };
}

sub EXT_override_panel_Collapser : Override('Ext.panel.Collapser') : Ext('modern') {
    return {
        config => {
            collapseToolText => { html => l10n('Collapse panel') },
            expandToolText   => { html => l10n('Expand panel') },
        },
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Overrides::Modern

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
