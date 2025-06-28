use strict;
use warnings;
package RT::Extension::InlineHelp;

our $VERSION = '1.00';

RT->AddStyleSheets('inlinehelp.css');
RT->AddJavaScript('inlinehelp.js');

use RT::Config;
$RT::Config::META{ShowInlineHelp} = {
    Section         => 'General',
    Overridable     => 1,
    Description     => 'Show Inline Help',
    Widget          => '/Widgets/Form/Boolean',
    WidgetArguments => {
        Description => 'Show inline help?',                # loc
        Hints       => 'Displays icons for help topics'    # loc
    },
};

{
    use RT::Interface::Web;
    package HTML::Mason::Commands;

    # GetInlineHelpClass locales
    #
    # Given a list of locales, find the best article class that has been associated with the
    # 'Inline Help' custom field. Locales are searched in order. The first Class with an
    # 'Inline Help' custom field and matching 'Locale' custom field will be returned.

    sub GetInlineHelpClass {
        my $locales = shift || ['en'];

        # Find the custom field that indicates a Class is participating in the Inline Help
        my $cf = RT::CustomField->new( RT->SystemUser );
        my ( $ret, $msg ) = $cf->Load("Inline Help");
        unless ( $ret and $cf->Id ) {
            RT::Logger->warn("Could not find custom field for 'Inline Help' $msg");
            return;
        }

        # Loop over the supplied locales in order. Return the first Class that is participating
        # in the Inline Help that also has a matching Locale custom field value
        my $Classes = RT::Classes->new( RT->SystemUser );
        ( $ret, $msg ) = $Classes->LimitCustomField( CUSTOMFIELD => $cf->Id, OPERATOR => "=", VALUE => "yes" );
        if ($ret) {
            for my $locale (@$locales) {
                $Classes->GotoFirstItem;
                while ( my $class = $Classes->Next ) {
                    my $val = $class->FirstCustomFieldValue('Locale');
                    return $class if $val eq $locale;
                }
            }
        }
        else {
            RT::Logger->debug("Could not find a participating help Class $msg");
        }

        # none found
        RT::Logger->debug("Could not find a suitable help Class for locales: @$locales");
        return;
    }

    # GetInlineHelpArticleTitle class_id, article_name
    #
    # Returns the value of the C<Display Name> Custom Field of an Article of the given Class.

    sub GetInlineHelpArticleTitle {
        my $class_id     = shift || return '';    # required
        my $article_name = shift || return '';    # required

        # find the article of the given class
        my $Article = RT::Article->new( RT->SystemUser );
        my ( $ret, $msg ) = $Article->LoadByCols( Name => $article_name, Class => $class_id, Disabled => 0 );
        if ( $Article and $Article->Id ) {
            return $Article->FirstCustomFieldValue('Display Name') || '';
        }

        # no match was found
        RT::Logger->debug("No help article found for '$article_name'");
        return '';
    }

    # GetInlineHelpArticleContent class_id, article_name
    #
    # Returns the raw, unscrubbed and unescaped Content of an Article of the given Class.

    sub GetInlineHelpArticleContent {
        my $class_id     = shift || return '';    # required
        my $article_name = shift || return '';    # required

        # find the article of the given class
        my $Article = RT::Article->new( RT->SystemUser );
        my ( $ret, $msg ) = $Article->LoadByCols( Name => $article_name, Class => $class_id, Disabled => 0 );
        if ( $Article and $Article->Id ) {
            RT::Logger->debug( "Found help article id: " . $Article->Id );
            return $Article->FirstCustomFieldValue('Content');
        }

        # no match was found
        RT::Logger->debug("No help article found for '$article_name'");
        return '';
    }
}


1;

__END__

=head1 NAME

RT-Extension-InlineHelp - InlineHelp

=head1 DESCRIPTION

This extension supplies the ability to add inline help to RT web pages.

=head1 RT VERSION

Works with RT 6.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::InlineHelp');

To show InlineHelp by default:

    Set($ShowInlineHelp, 1);

=item Clear your mason cache

    rm -rf /opt/rt6/var/mason_data/obj

=item Restart your webserver

=back

=head1 OVERVIEW

This extension adds help icons to various elements on pages throughout the
application.  When the user hovers over the help icon, a popup dialog will
display useful information related to that element.

Custom fields and custom roles in RT already have input help that show "Entry hints"
as tooltips. This extension replaces those elements with the version provided
by InlineHelp, so the icons are the same size and the display is a popup with
a title instead of a tooltip. The content still comes from the entry hint,
so your existing configurations will continue to work.

=head2 How it works

Help content is managed as a collection of articles in specially-designated classes.
If a class has the "Inline Help" custom field set to "yes", then the articles
in that class will be used when finding help topics. A second custom
field called "Locale" identifies the language used by articles in that class.
In these classes, the article names map to parts of the RT interface
to determine where to show the article content as help.

=head2 Sync vs Async

There are basically two modes of operation for the InlineHelp: synchronous and
asynchronous.

In synchronous mode, all of the help content is either retrieved or supplied directly on
the server side when the initial page is rendered. This means that the help content itself
is delivered to the browser.

In asynchronous mode, only the help topic is supplied when the page is rendered. When
the user hovers over the help icon, the help content is dynamically retrieved from the
server and displayed in the popup dialog. See L</Async> for more details.

Both modes can be used interchangeably on the same page.

=head1 USAGE

InlineHelp can be used at render time on the server. For example, in
a Mason template, you might use the C<PopupHelp> template to annotate a form
field:

    <div class="form-row">
      <div class="label col-3">
        <span>Ticket Id</span>
        <& /Elements/PopupHelp, Title => 'My Topic' &>:
      </div>
      <div class="value col-9">
        <input class="form-control" type="text" name="ticketId" />
      </div>
    </div>

InlineHelp can also be used at runtime on the client. For example,
you can add the same help topic to every HTML element matching a certain
query. The following would associate a help topic to a specific button:

    <script>
    jQuery(document).ready(function() {
        addPopupHelpItems( { "selector": "button#save-form", "title": "My Topic" } )
    })
    </script>

=head1 REFERENCE

There are four primary ways to use the Inline Help:

=over

=item *
L</Target Selector>

=item *
L</Mason Templates>

=item *
L</HTML Attributes>

=item *
L</JavaScript>

=back

=head2 Target Selector

With this approach, you don't need to write any Mason/HTML/JS code and
you can add new help topics by adding or updating articles via the RT web UI.
Articles in the Inline Help class will have a custom field called Target
applied to them. To add inline help to some element in RT, specify
the HTML elements of that element in the Target field, using jQuery
selector syntax. jQuery is very flexible, so you can use many elements
in the DOM to target elements including ids, classes, and even text.
Once you get the selector to match, the content of that article will
show up in the web UI on that location.

=head3 Examples

Below are some examples of the Target value you would use to add
help text to different parts of RT.

=over

=item "Search" in the main top menu

Target: C<#search>

=item Ticket display page, Status label

Target: C<div.form-row.status div.label>

=item RT at a glance, Unowned tickets portlet

Target: C<.titlebox .titlebox-title span.left a[href^="/Search/Results.html"]:contains("newest unowned tickets")>

=back

=head2 Mason Templates

Add a C</Elements/PopupHelp> component anywhere in a Mason template:

    <& /Elements/PopupHelp, Title => "My Topic" &>

This will render an empty HTML span element

    <span data-help="My Topic"
          data-content="The article contents"
          data-action="replace"
          style="display: none;"
    ></span>

which will be picked up and processed on page load by the default "helpification"
rule when all of the accumulated rules are executed when C<renderPopupHelpItems> is
called (for example, in the C<Elements/Footer> component in the page footer).

If no valid help article named C<My Help Topic> is found, (see L</OVERVIEW>) or the
C<ShowInlineHelp> setting/user-preference is false, the C<E<lt>spanE<gt>> will be suppressed
altogether.

Because the help content has already been retrieved and sent to the client,
it will already be in the DOM and there should be virtually no delay when displaying
the help popup following a user hover.

=head3 Example

To add help to a form field, a Mason template might create a help tag directly:

    <div class="form-row">
      <div class="label col-3">
        <span>Ticket Id</span>
        <& /Elements/PopupHelp, Title => 'My Topic' &>:
      </div>
      <div class="value col-9">
        <input class="form-control" type="text" name="ticketId" />
      </div>
    </div>

or might create help tags dynamically based on a Custom Field called Category:

    % while (my $ticket = $tickets->Next) {
    %   my $ctgy = $ticket->FirstCustomFieldValue("Category")
    <h1><% $ticket->Subject %></h1><& /Elements/PopupHelp, Title => $ctgy &>
    % }

=head2 HTML Attributes

Add C<data-help="My Topic"> and (optionally) C<data-content="The help content">
attributes to any HTML elements.

=over

=item * C<data-help>
Required. The name of the help topic. If C<data-content>
is omitted, content will come from an article with this Name.
See L</Async>.

=item * C<data-content>
Optional. The help content. If omitted, asynchronous mode will be used to dynamically retrieve
the help content. See L</Async>.

=item * C<data-action>
Optional. The action to use when adding the help icon to the DOM. Defaults to C<"append">. See
L</Help Selector Rules> section for more details.

=back

=head3 Example

A Mason template might add the C<data-help> attribute to an element along
with some static help content that includes custom HTML

    <button data-help="Save Widget"
            data-content="Saves the Widget to RT"
            data-action="after">Save</button>

Or we could omit the C<data-content> altogether to have RT return the help content from the
matching C<"List Sprockets"> article when the user hovers over the help icon

    <button data-help="List Sprockets" data-action="after">List</button>

=head2 JavaScript

Call C<addPopupHelpItems> to add one or more rules to the list of help topics on a page that
should be decorated with help icons.

The C<addPopupHelpItems> function populates the C<pagePopupHelpItems> array with a list of
declarative rules that define elements in the DOM that should have associated help icons. If
a rule's C<selector> key matches one or more elements, its C<action> key will
determine where a help icon should be added to the DOM with help content corresponding to
the C<content> key or from a valid help article with the same name as the C<title> key.

Any rules thus added will be picked up and processed on page load when all of the accumulated
rules are executed when C<renderPopupHelpItems> is called (for example, in the C<Elements/Footer>
component in the page footer).

This includes the default rule

    { selector: "[data-help]" }

which matches anything with a C<data-help> attribute and therefore powers the L</HTML Attributes>
method.

This method of using JavaScript allows for tremendous flexibly annotating the DOM with help items,
even after it has been rendered--perhaps by other templates altogether, making it attractive as a
mechanism for users to annotate aspects of RT--however it has been installed for them, including
any and all extensions--simply by inspecting what is rendered to the browser and writing the
appropriate rules. Importantly, these rules can usually be added to one place (e.g. in a page
callback somewhere) so they do not need to overlay virtually every template in RT just to
add help icons throughout.

=head3 Help Selector Rules

A help selector rule is a JavaScript object with the following keys:

=over

=item * C<selector> - I<String>

Required. Defines which DOM elements should receive a help icon. Can match 0, 1, or many elements.
Selectors matching 0 elements have no impact on the DOM.

=over

=item * I<String>
A JQuery selector string that defines the matching DOM elements

=back

=item * C<title> - I<String>

Optional. The help topic(s) that should be associated with the element(s) matching the C<selector>

=over

=item * I<String>
The name of the help topic that should be matched against the article Name. If the C<selector>
matches exactly one element, this will be its help topic. If more than one element are
matched, they will all get this same help topic.

=back

=item * C<content> - I<String>

Optional. The help content to be displayed in the popup when the user hovers
over the help icon.

If missing, asynchronous mode is automatically triggered (see L</Async>)

=over

=item * I<String>
The help content. May contain HTML. Will be applied for all elements matched by C<selector>.

=back

=item * C<action> - I<String>

Optional. The action that should be taken with each help icon that results from the application
of C<selector>. Responsible for actually adding the help icons to the DOM. This controls, for
example, where the icon should be rendered relative to the matching DOM element.

If missing, C<"append"> is the default.

=over

=item * I<String>

=over

=item * I<before>
The help icon will be prepended to the DOM I<before> the element(s) matched by C<selector>

=item * I<after>
Default. The help icon will be appended to the DOM I<after> the element(s) matched by C<selector>

=item * I<append>
The help icon will be appended to the end of the DOM element(s) matched by C<selector>

=item * I<prepend>
The help icon will be prepended to the beginning of the DOM element(s) matched by C<selector>

=item * I<replace>
The help icon will be inserted into the DOM I<in place of> the element(s) matched by C<selector>.
This action is used, for example, by the C</Elements/PopupHelp> Mason component.

=back

=back

=back

=head3 Examples

Add a help topic named C<"My Topic"> to the DOM element with an id of C<"ticket-id">

    addPopupHelpItems(
        {
            selector: "#ticket-id",
            title: "My Topic"
        }
    )

Add a help topic named C<"Phone"> and custom HTML content to the DOM element with an id of C<"phone-nbr">

    addPopupHelpItems(
        {
            selector: "#phone-nbr",
            title: "Phone",
            content: "The customer phone number. This <i>MUST</i> include the country code."
        }
    )

Add more than one rule at a time

    addPopupHelpItems(
        { selector: "#ticket-status", title: "Status Topic" },
        { selector: "#ticket-queue",  title: "Queue Topic"  }
    )

Add a help topic named C<"A Note on Submitting Forms"> to every C<E<lt>buttonE<gt>> element
of type C<submit>.

    addPopupHelpItems( { selector: "button[type='submit']", title: "A Note on Submitting Forms" } )

Prepend help topics to all form radio buttons

    addPopupHelpItems(
        {
            selector: "form input[type='radio']",
            title:    "Radio Button Help",
            content:  "You can only select one at a time",
            action:   "prepend"
        }
    )

=head2 Programmatic API

The following functions are part of, and used by, InlineHelp. You can also call them
directly from your code.

=head3 HTML::Mason::Commands::GetInlineHelpClass( locales )

Given a list of locales, find the best article class that has been associated with the
C<"Inline Help"> custom field. Locales are searched in order. The first Class with an
C<"Inline Help"> custom field and matching C<"Locale"> custom field will be returned.

=head3 HTML::Mason::Commands::GetInlineHelpArticleTitle( class_id, article_name )

Returns the value of the C<Display Name> Custom Field of an Article of the given Class.

=head3 HTML::Mason::Commands::GetInlineHelpArticleContent( class_id, article_name )

Returns the raw, unscrubbed and unescaped C<Content> of an Article of the given Class.

=head2 Async

In asynchronous mode, only the help topic is supplied when the page is rendered. Only when
the user hovers over the help icon is the help content dynamically retrieved from the server
with a second AJAX request to which will attempt to fetch the given help article contents.
The contents are returned directly as an HTML fragment--that is, they are not wrapped in
a C<E<lt>htmlE<gt>> tag, for example.

The AJAX call will be a request to C</Helpers/HelpTopic?key=MyTopic> which will return
the raw contents of the C<MyTopic> Article, which may contain HTML. It will not be sanitized.
If no valid C<MyTopic> help article exists (see L</OVERVIEW>),

    <div class="text-danger">No help was found for 'MyTopic'.</div>

will be returned instead.

The C</Helpers/HelpTopic> component does not consider the C<ShowInlineHelp> setting/user-preference.
However, if C<ShowInlineHelp> is not set, the help icon would generally not have been rendered
anyway, so the AJAX call would never have been made.

Asynchronous mode does have the benefit of reducing the number of database calls that need
to be made to retrieve help article content on page request, but the user may experience a
slight lag when the help icon is hovered over and the AJAX request is being made. This will need
to be evaluated on a case-by-case basis. On a heavily used RT system, the performance of pages
with many help topics may benefit from using asynchronous mode more generously.

=head1 NAMING

Since InlineHelp uses the help topic as the key to find a corresponding article, it
helps to have a somewhat predictable naming convention for help topics.

=head2 RT objects

In general, help topics for built-in RT functionality will be prefixed by C<"RT-">

=over

=item *
RT-{The Name}

=item *
RT-{Context}-{The Name}

=item *
RT-{Path/To/Page}-{The Name}

=item *
RT-MainMenu-{}-{}-...

=item *
RT-PageMenu-{}-{}-...

=back

=head2 User-defined objects

When you wish to dynamically create help topics based on the name of an object that the end
users create, the following naming conventions can serve as a guide

=over

=item *
User-Dashboard-{The Name}

=item *
System-Dashboard-{The Name}

=item *
CustomRole-{The Name}

=item *
SystemRole-{The Name}

=item *
CustomField-{The Name}

=item *
User-SavedSearch-{The Name}

=item *
{Group Name}-SavedSearch-{The Name}

=item *
System-SavedSearch-{The Name}

=back

=head1 DESIGN CONSIDERATIONS

Choosing synchronous vs asynchronous mode involves several tradeoffs already discussed in
L</Async>.

In synchronous mode, there are also tradeoffs in choosing whether to provide content directly
via the C<data-content> attribute or the C<content> property of a JavaScript help rule. It is
often convenient to provide the help directly, especially if it has to be constructed in order
to do so. However, this makes it much more difficult for end users to edit or customize the
help content (since it now lives in code instead of an article). It also makes it more
difficult to support multiple locales.

=head1 MISC

=head2 Change Icon Size

By default the icon size is inherited from its parent, to customize it, you
can add css rules on Admin Theme page like:

    span.popup-help {
        font-size: larger;
    }

    span.popup-help {
        font-size: smaller;
    }

    span.popup-help {
        font-size: 12px;
    }

=head1 INTERNATIONALIZATION

InlineHelp works with multiple languages by using articles in classes. Each class should
have a different value for its C<Locale> custom field. All of the articles in that class should
be in that language.

=head2 Adding a new language

=over

=item *
To add a new language, create a new class with the settigns below. You can use any
name for the class. If you plan to have several languages, you'll likely want to
have consistent naming for your classes.

=item *
Set the "Inline Help" custom field to "yes".

=item *
Set "Locale" to the language you want.

=item *
Add articles to your new Class

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-InlineHelp@rt.cpan.org">bug-RT-Extension-InlineHelp@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-InlineHelp">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-InlineHelp@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-InlineHelp

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
