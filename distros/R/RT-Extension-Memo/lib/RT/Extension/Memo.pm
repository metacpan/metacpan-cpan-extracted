use utf8;
use strict;
use warnings;
no warnings qw(redefine);
package RT::Extension::Memo;

our $VERSION = '0.09';

=encoding utf8

=head1 NAME

RT::Extension::Memo - Add a memo widget to tickets

=head1 DESCRIPTION

This module adds a new widget to any L<ticket|RT::Ticket> which allows to add, edit and display information directly on the ticket display page.

In many cases, resolving a ticket involves to collect and store some information which helps the owner of the ticket to find some solution. Such information includes tips and tricks, I<todo> list, etc. The common way to handle such information in RT is to paste it into comments.

To do so has several drawbacks. First, it mixed information which is relevant only to the owner of the ticket with communication between internal actors, that occurs through comments, for instance between the owner of the ticket and some of her colleagues. Second, the owner of the ticket has to search in the history for all comments to keep up with what has been done and what is left to be done, various issues that have arisen, etc. Third, when the owner of the ticket wants to add a new comment, she has to leave the display page of the ticket for the update form, loosing any access to the history of the comments, as well as various information about the ticket, such as its custom fields, dates or people. One solution to have the history at hand when adding a new comment, is to reply to the previous comment each time something has to be added. But the information is then copied in each reply with unneeded and cumbersome redundancy. Fourth, replying to the previous comment implies that this previous comment is folded when displaying the new one, with the consequence that it must be unfolded to read it and that its content cannot be searched until it is unfolded.

The C<RT-Extension-Memo> plugin provides a new widget to manage such information. It is displayed on the top of the history in the display page of the ticket, therefore gathering all information at the same place. It can be edited directly on this same display page, with all information about the ticket at hand.

Internally, such a I<Memo> is stored in a single attribute, avoiding too much extra storage space (as it would have been the case if it was stored as a custom field value where all revisions are kept up in the database). The counterpart of this technical implementation is that caution has to be made when editing the I<Memo>: any previous revision is overwritten, so if information is deleted when editing the I<Memo>, it is actually forever lost.

=head1 CONFIGURATION

These options are set in F<etc/Memo_Config.pm> and can be overridden by users in their preferences.

=over 4

=item C<$MemoRichText>

Should "rich text" editing be enabled for memo widget?

=item C<$MemoHeight>

Set number of lines of the textarea for editing memo.

=item C<$MemoRichTextHeight>

Set height (in number of pixels) of the rich text editor for editing memo.

=back

=head1 RIGHTS

The following new rights can be applied at the global level or at the queue level:

=over 4

=item C<SeeMemo>

Users and groups with this right are able to see the I<Memo> on the display page of a ticket.

=item C<ModifyMemo>

Users and groups with this right are able to add a new I<Memo> and to edit existing I<Memo> attached to a ticket.

=back

=head1 STYLING

The CSS properties of the Memo widget can be styled by overwriting defaults set in F<static/css/memo.cc>.

=head1 RT VERSION

Works with RT 4.2 or greater.

=head2 RT 6

In RT 6, C<Memo> is available as a I<widget>, that you can use on C<Display Layouts> for Tickets.

Also, in RT 6, a new C<Description> field has been added to tickets, which can play the same role as C<Memo>. Still there are some differences between these two widgets. C<Memo> widget can be used only once in a page layout, while C<Description> can be used multiple times in the same page layout. C<Memo> widget is supposed to be used only on C<Display Layouts> for tickets, while C<Description> can also be used in C<Create Layouts> and C<Update Layouts>. C<Description> widget is not available in C<SelfService> while C<Memo> is. C<Description> widget can only be edited with richtext editor (C<CKEditor>) while C<Memo> can be configured to be edited in plain text.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::Memo');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::Memo));

or add C<RT::Extension::Memo> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 TEST SUITE

C<Memo> comes with a fairly complete test suite. As for every L<RT extention|https://docs.bestpractical.com/rt/6.0.2/writing_extensions.html#Tests>, to run it, you will need a installed C<RT>, set up in L<development mode|https://docs.bestpractical.com/rt/6.0.2/hacking.html#Test-suite>. Since C<Memo> operates dynamically to show or edit information, some parts of its processing rely on C<Javascript>. Therefore, the test suite requires a scriptable headless browser with C<Javascript> capabilities. So, to work with L<Selenium::Remote::Driver>, you need to install C<Firefox> and C<geckodriver>, or alternatively C<Chrome> and C<chromedriver> (see documentation for L<Selenium Tests|https://docs.bestpractical.com/rt/6.0.2/hacking.html#Test-suite>).

It should be noted that I<Best Practical> is planing to implement automated browser testing using C<Playwright>, since C<Selenium> tests in I<RT Core> have issues with false negatives, often because of C<htmx> and issues with implementing correct waiting behavior for pages. C<Memo> tests experience the same issues where a test can sometimes fail while the same test pass most of the time. C<Memo> tests will be rewritten with C<Playwright> to be more robust, when such tests will be available in I<RT Core>.

=cut

# Add some rights at the queue level
RT::Queue->AddRight( Staff => SeeMemo    => 'View memo');
RT::Queue->AddRight( Staff => ModifyMemo => 'Modify memo');

# Add custom css and js
RT->AddStyleSheets('memo.css');
RT->AddJavaScript('memo.js');

# User overridable options
$RT::Config::META{MemoRichText} = {
    Section         => 'Ticket composition',
    Overridable     => 1,
    SortOrder       => 12,
    Widget          => '/Widgets/Form/Boolean',
    WidgetArguments => {
        Description => 'WYSIWYG memo composer'
    },
};
$RT::Config::META{MemoHeight} = {
    Section         => 'Ticket composition',
    Overridable     => 1,
    SortOrder       => 15.2,
    Widget          => '/Widgets/Form/Integer',
    WidgetArguments => {
        Description => 'Memo height (in number of lines) for plain text editing',
    },
};
$RT::Config::META{MemoRichTextHeight} = {
    Section         => 'Ticket composition',
    Overridable     => 1,
    SortOrder       => 15.3,
    Widget          => '/Widgets/Form/Integer',
    WidgetArguments => {
        Description => 'Memo height (in number of pixel) for rich text editing',
    },
};

# Copy memo when merging ticket
my $old_MergeInto = RT::Ticket->can("_MergeInto");
*RT::Ticket::_MergeInto = sub {
    my $self = shift;
    my $MergeInto = shift;

    $self->ClearAttributes;
    my $attr = $self->FirstAttribute('Memo');
    $MergeInto->ClearAttributes;
    my $merged_attr = $MergeInto->FirstAttribute('Memo');

    my ($ok, $msg) = $old_MergeInto->($self, $MergeInto);

    if ($ok) {
        if ($attr && $attr->Content && $attr->Content !~ /^\s*$/) {
            my $merged_memo = '';
            if ($merged_attr && $merged_attr->Content && $merged_attr->Content !~ /^\s*$/) {
                if (RT->Config->Get('MemoRichText', $self->CurrentUser)) {
                    $merged_memo = $merged_attr->Content . "<br />";
                } else {
                    $merged_memo = $merged_attr->Content . "\n";
                }
            }
            $merged_memo .= $attr->Content;
            my ($memo_ok, $memo_msg) = $MergeInto->SetAttribute(Name => 'Memo', Content => $merged_memo);
            unless ($memo_ok) {
                $RT::Handle->Rollback();
                return (0, $self->loc("Merge failed. Couldn't merge Memo"));
            }
        }
    }

    return ($ok, $msg);
};

=head1 AUTHOR

Gérald Sédrati E<lt>gibus@easter-eggs.comE<gt>

=head1 REPOSITORY

L<https://github.com/gibus/RT-Extension-Memo>

=head1 BUGS

All bugs should be reported via email to

L<bug-RT-Extension-Memo@rt.cpan.org|mailto:bug-RT-Extension-Memo@rt.cpan.org>

or via the web at

L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-Memo>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2017-2022 by Gérald Sédrati, Easter-Eggs

This is free software, licensed under:

The GNU General Public License, Version 3, June 2007

=cut

1;
