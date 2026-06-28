package PDF::Make::Action;
use strict;
use warnings;

our $VERSION = '0.02';

1;

__END__

=head1 NAME

PDF::Make::Action - PDF action objects for navigation and interactivity

=head1 SYNOPSIS

    use PDF::Make::Document;
    
    my $doc = PDF::Make::Document->new();
    $doc->add_page(612, 792);
    
    # Create a URI action
    my $action = $doc->action_uri('https://perl.org');
    
    # Create link annotation with action
    $doc->add_link_with_action(100, 700, 200, 720, $action);

=head1 DESCRIPTION

PDF::Make::Action represents PDF action objects that define behaviors
triggered by events like clicking a link or bookmark.

Actions are created via the PDF::Make::Document factory methods:

=over 4

=item * action_uri($uri) - Link to web URL

=item * action_goto($page_index, $dest_type, ...) - Internal navigation

=item * action_named($name) - Named actions (NextPage, PrevPage, etc.)

=item * action_javascript($script) - Execute JavaScript

=item * action_gotor($file, $page, $new_window) - External PDF

=back

=head1 CONSTANTS

=head2 Action Types

    GOTO        - Navigate to destination in same document
    GOTOR       - Navigate to destination in another PDF
    URI         - Open a URI (web link)
    NAMED       - Execute a named action
    JAVASCRIPT  - Execute JavaScript code
    HIDE        - Show/hide annotations
    LAUNCH      - Launch external application

=head2 Named Actions

    NEXTPAGE    - Go to next page
    PREVPAGE    - Go to previous page
    FIRSTPAGE   - Go to first page
    LASTPAGE    - Go to last page
    PRINT       - Print the document

=head2 Highlight Modes

    HIGHLIGHT_NONE     - No visual feedback
    HIGHLIGHT_INVERT   - Invert colors (default)
    HIGHLIGHT_OUTLINE  - Draw outline
    HIGHLIGHT_PUSH     - Push button effect

=head1 METHODS

=head2 type

    my $type = $action->type;

Returns the action type constant.

=head2 obj_num

    my $num = $action->obj_num;

Returns the PDF object number (0 if not yet written).

=head2 write

    my $num = $action->write;

Writes the action to the PDF document and returns the object number.

=head2 chain

    $action->chain($next_action);

Chains another action to execute after this one.

=head1 SEE ALSO

L<PDF::Make::Document>, L<PDF::Make>

=cut
