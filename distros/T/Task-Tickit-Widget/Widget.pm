package Task::Tickit::Widget;

# Pragmas.
use strict;
use warnings;

# Version.
our $VERSION = 0.05;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Task::Tickit::Widget - Install the Tickit::Widget modules.

=head1 SYNOPSIS

 cpanm Task::Tickit::Widget

=head1 SEE ALSO

=over

=item L<Tickit::Widget>

Abstract base class for on-screen widgets.

=item L<Tickit::Widget::Border>

Draw a fixed-size border around a widget.

=item L<Tickit::Widget::Box>

Apply spacing and positioning to a widget.

=item L<Tickit::Widget::Breadcrumb>

Render a breadcrumb trail.

=item L<Tickit::Widget::Button>

A widget displaying a clickable button.

=item L<Tickit::Widget::Calendar::MonthView>

?

=item L<Tickit::Widget::CheckButton>

A widget allowing a toggle true/false.

=item L<Tickit::Widget::Choice>

A widget giving a choice from a list.

=item L<Tickit::Widget::Decoration>

Do nothing, in a visually-appealing way.

=item L<Tickit::Widget::Entry>

A widget for entering text.

=item L<Tickit::Widget::Figlet>

Trivial wrapper around Text::FIGlet for banner rendering.

=item L<Tickit::Widget::FileViewer>

Support for viewing files in Tickit.

=item L<Tickit::Widget::Fill>

Fill an area with repeated text.

=item L<Tickit::Widget::FloatBox>

Manage a collection of floating widgets.

=item L<Tickit::Widget::Frame>

Draw a frame around another widget.

=item L<Tickit::Widget::GridBox>

Lay out a set of child widgets in a grid.

=item L<Tickit::Widget::HBox>

Distribute child widgets in a horizontal row.

=item L<Tickit::Widget::HSplit>

An adjustable horizontal split between two widgets.

=item L<Tickit::Widget::Layout::Desktop>

Provides a holder for "desktop-like" widget behaviour.

=item L<Tickit::Widget::Layout::Relative>

Apply sizing to a group of Tickit widgets.

=item L<Tickit::Widget::LinearBox>

Abstract base class for "HBox" and "VBox".

=item L<Tickit::Widget::LinearSplit>

?

=item L<Tickit::Widget::LogAny>

Log message rendering.

=item L<Tickit::Widget::Menu>

Display a menu of choices.

=item L<Tickit::Widget::MenuBar>

Display a menu horizontally.

=item L<Tickit::Widget::Menu::Item>

An item to display in a "Tickit::Widget::Menu".

=item L<Tickit::Widget::Placegrid>

A placeholder grid display.

=item L<Tickit::Widget::Progressbar>

Simple progressbar implementation for Tickit.

=item L<Tickit::Widget::Progressbar::Horizontal>

Simple progressbar implementation for Tickit.

=item L<Tickit::Widget::Progressbar::Vertical>

Simple progressbar implementation for Tickit.

=item L<Tickit::Widget::RadioButton>

A widget allowing a selection from multiple options.

=item L<Tickit::Widget::ScrollBox>

Allow a single child widget to be scrolled.

=item L<Tickit::Widget::ScrollBox::Extent>

Represents the range of scrolling extent.

=item L<Tickit::Widget::Scroller>

A widget displaying a scrollable collection of items.

=item L<Tickit::Widget::Scroller::Item>

Interface for renderable scroller items.

=item L<Tickit::Widget::Scroller::Item::RichText>

Static text with render attributes.

=item L<Tickit::Widget::Scroller::Item::Text>

Add static text to a Scroller.

=item L<Tickit::Widget::SegmentDisplay>

Show a single character like a segmented display.

=item L<Tickit::Widget::SparkLine>

Minimal graph implementation for Tickit.

=item L<Tickit::Widget::Spinner>

A widget displaying a small text animation.

=item L<Tickit::Widget::Static>

A widget displaying static text.

=item L<Tickit::Widget::Statusbar>

Provides a simple status bar implementation.

=item L<Tickit::Widget::Statusbar::Clock>

A simple clock implementation.

=item L<Tickit::Widget::Statusbar::CPU>

CPU usage.

=item L<Tickit::Widget::Statusbar::Memory>

Memory usage.

=item L<Tickit::Widget::Statusbar::WidgetList>

?

=item L<Tickit::Widget::Tabbed>

Provide tabbed window support.

=item L<Tickit::Widget::Tabbed::Ribbon>

Base class for "Tickit::Widget::Tabbed" control ribbon.

=item L<Tickit::Widget::Table>

Table widget with support for scrolling/paging.

=item L<Tickit::Widget::Table::Paged>

Table widget with support for scrolling/paging.

=item L<Tickit::Widget::Tree>

Tree widget implementation for Tickit.

=item L<Tickit::Widget::VBox>

Distribute child widgets in a vertical column.

=item L<Tickit::Widget::VHBox>

Distribute child widgets vertically or horizontally.

=item L<Tickit::Widget::VSplit>

An adjustable vertical split between two widgets.

=item L<Tickit::Widgets>

Load several Tickit::Widget classes at once.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Task-Tickit-Widget>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2015 Michal Špaček
 Artistic License
 BSD 2-Clause License

=head1 VERSION

0.05

=cut
