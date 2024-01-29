use warnings;
use strict;

package RT::Extension::FormTools;

our $VERSION = '1.02';

RT->AddStyleSheets('rt-extension-formtools.css');
RT->AddJavaScript('rt-extension-formtools.js');

RT::System->AddRight( Admin => AdminForm => 'Create, modify and disable forms' ); # loc

use Time::HiRes 'time';
use Digest::SHA 'sha1_hex';

# page ids are based on current time, keep 100 recent ids in case CPU is really fast
my @recent_page_ids;

sub GeneratePageId {
    shift if ( $_[0] // '' ) eq __PACKAGE__;
    my $form = shift;
    my %current;
    if ($form) {
        %current = map { $_ => 1 } keys %{ $form->{'formtools-pages'} };
    }

    my %skip = (
        map { $_ => 1 } @recent_page_ids,
        $form && $form->{'formtools-pages'} ? keys %{ $form->{'formtools-pages'} } : ()
    );

    my $page_id = _GeneratePageId();

    for ( 1 .. 100 ) {
        if ( $skip{$page_id} ) {
            $page_id = _GeneratePageId();
        }
        else {
            push @recent_page_ids, $page_id;
            shift @recent_page_ids while @recent_page_ids > 100;
            return $page_id;
        }
    }
    RT->Logger->error("Could not generate a new page id");
    return;
}

sub _GeneratePageId {
    return substr( sha1_hex( time . int rand 10000 ), 0, 8 );
}

sub _ParseContent {
    shift if ( $_[0] // '' ) eq __PACKAGE__;
    my %args = (
        Content   => undef,
        TicketObj => undef,
        @_,
    );
    return $args{Content} unless $args{TicketObj} && $args{Content} && $args{Content} =~ /\{\s*\$\w+\s*\}/;
    require RT::Template;
    return RT::Template->_ParseContentSimple(
        TemplateArgs => { Ticket => $args{TicketObj} },
        Content      => $args{Content},
    );
}

{
    package RT::Attribute;
    no warnings 'redefine';
    use Role::Basic 'with';
    with "RT::Record::Role::Rights";

    my $orig_available_rights = RT::Attribute->can('AvailableRights');
    *AvailableRights = sub {
        my $self = shift;

        if ( $self->__Value('Name') eq 'FormTools Form' ) {
            return { ShowForm => 'View forms' };
        }
        return $orig_available_rights->($self, @_);
    };

    my $orig_right_categories = RT::Attribute->can('RightCategories');
    *RightCategories = sub {
        my $self = shift;

        if ( $self->__Value('Name') eq 'FormTools Form' ) {
            return { ShowForm => 'General' };
        }
        return $orig_right_categories->($self, @_);
    };

    my $orig_current_user_has_right = RT::Attribute->can('CurrentUserHasRight');
    *CurrentUserHasRight = sub {
        my $self  = shift;
        my $right = shift;
        if ( $self->__Value('Name') eq 'FormTools Form' ) {
            return 1 if $self->CurrentUser->HasRight( Object => RT->System, Right => 'AdminForm' );
            $right = 'ShowForm' if $right eq 'display';
            return $self->CurrentUser->HasRight( Object => $self, Right => $right );
        }
        return $orig_current_user_has_right->( $self, $right, @_ );
    };

    RT::Attribute->AddRight( General => ShowForm => 'View forms' ); # loc
}

=head1 NAME

RT-Extension-FormTools - Create multi-page ticket creation wizards for RT

=head1 DESCRIPTION

Starting in version 1.00, this extension provides a full UI for
RT administrators to create multi-page form wizards to collect
information and create a ticket.

=for html <p><img width="600" src="https://static.bestpractical.com/images/formtools/formtools-modify-page-example-shadow.png" alt="FormTools Modify Page" /></p>

=head1 RT VERSION

Works with RT 5.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::FormTools');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 USAGE

=head2 Creating Forms

=head3 Modify

Once installed and activated, users with the SuperUser or
AdminForms right can go to Admin > FormTools > Create to build
new forms. Use Select to view a list of existing forms.

When you initially create a form, you select the queue that the ticket
will be created in after a user fills out the form. The selected
queue will also determine which custom fields are available in the
form builder.

The Modify page allows you to configure all of the pages for the
selected form. The Components bar on the left lists HTML elements,
Core RT fields, and all custom fields available to the queue selected
for the current form. To build pages in your form, drag elements from
the left into the Content area in the FormTools Pages section on the
right.

You can drag elements up and down to arrange content for each page.
To configure elements or add text content, click the pencil icon.

Click the plus (+) to create new pages. To change the order of the pages,
click the gearbox and update the sort order.

=head3 Description

Your forms will be made available to users on a dedicated Forms page in
the RT web UI. Forms can be accessed by privileged users in the main RT
interface and by unprivilged users in the self service interface.

The Description tab allows you to upload an icon and provide text to show
on this forms page. Include an icon that represents what the form is
intended for and include a description to help users pick the right form
for the right task.

=head3 Advanced

The advanced page shows the raw JSON representation of the configured pages
in your form. We recommend not editing the JSON directly. However, you can
copy the content and paste it into another page if you want to migrate
a form from development to production. You can also save the JSON to a file
and use the C<rt-insert-formtools-config> utility to load it into another RT.

=head3 Rights

You can control access to forms by granting the ShowForm right for groups
or users. By default, only SuperUsers can see forms, so you need to grant
ShowForm to users or groups for them to be visible.

=head2 Using Forms

Privileged and unprivileged users can find a list of available forms
at Home > Forms. Users need to have the ShowForm right to see forms
listed.

Once the form is filled out, it will create a ticket, so form users
also need CreateTicket in the queue where the form will be created.
FormTools checks this at the beginning of a form and shows the user a
message if they don't have sufficient rights.

=head1 Internals

In earlier versions, this extension provided code-level Mason templates
as helpers to manually code forms. We believe pages created with these
earlier versions will continue to work, but it's possible they may stop
working at some point as we continue to work on FormTools. If you have
older FormTools code, it's safest to run with version 0.60. Going forward,
we recommend converting your forms to the new interface using the
new UI.

The documentation below is retained as the components are all still
available.

=head2 Mason Components

See F<ex/RT-Example-FormTools/> for an example extension written using
this module.

=head3 C</FormTools/Form>

The top-level component that most elements will call, as a wrapper:

    <&|/FormTools/Form, next => "/URI/of/next/page" &>
    (form elements)
    </&>

It requires that the next page in the wizard be passed as the C<next>
parameter; this may be empty at the end of the wizard.  It renders page
decoration (using C</Elements/Header>). It assumes that the queue will
be stored in C<$m->notes('queue')>.

=head3 C</FormTools/Field>

Renders a field in the form. It takes the name of a core field, or CF
name:

    <& /FormTools/Field, name => 'Requestors' &>

Valid core fields include:

=over

=item Requestors

=item Cc

=item AdminCc

=item Subject

=item Content

=item Attach

=item Due

=back

Any other argument to C<name> is assumed to be the name of a custom
field.

=head3 C</FormTools/Next>

Renders the "Next page" button.

=head3 C</FormTools/ShowChoices>

Shows the values that have already been submitted.

=head2 Internal Functions

In addition to the Mason components, this module provides a number of
functions which may be useful to call from Mason templates.

=head3 is_core_field C<field_name>

Checks if the given C<field_name> is is a field that we consider 'core'
to RT (subject, AdminCc, etc) rather than something which should be
treated as a Custom Field.

Naming a Custom Field Subject would cause serious pain with FormTools.

=cut

my %is_core_field = map { $_ => 1 } qw(
    Requestors
    Cc
    AdminCc
    Subject
    Content
    Attach
    Due
);

sub is_core_field {
    return $is_core_field{ $_[0] };
}

=head3 validate_cf C<CF>, C<ARGSRef>

Takes a given L<RT::CustomField> object and a hashref of query
parameters, and returns a list of a boolean of if the custom field
validates, followed by a list of errors.

=cut

sub validate_cf {
    my ($CF, $ARGSRef) = @_;
    my $NamePrefix = "Object-RT::Ticket--CustomField-";
    my $field = $NamePrefix . $CF->Id . "-Value";
    my $valid = 1;
    my $value;
    my @res;
    if ($ARGSRef->{"${field}s-Magic"} and exists $ARGSRef->{"${field}s"}) {
        $value = $ARGSRef->{"${field}s"};
        # We only validate Single Combos -- multis can never be user input
        return ($valid) if ref $value;
    }
    else {
        $value = $ARGSRef->{$field};
    }

    my @values = ();
    if ( ref $value eq 'ARRAY' ) {
        @values = @$value;
    } elsif ( $CF->Type =~ /text/i ) {
        @values = ($value);
    } else {
        @values = split /\r*\n/, ( defined $value ? $value : '');
    }
    @values = grep $_ ne '',
        map {
            s/\r+\n/\n/g;
            s/^\s+//;
            s/\s+$//;
            $_;
        }
        grep defined, @values;
    @values = ('') unless @values;

    foreach my $value( @values ) {
        next if $CF->MatchPattern($value);

        my $msg = "Input must match ". $CF->FriendlyPattern;
        push @res, $msg;
        $valid = 0;
    }
    return ($valid, @res);
}

=head3 email_is_privileged C<email_address>

Returns true if the given email address belongs to a privileged user.

=cut

sub email_is_privileged {
    my $email = shift;
    my $user = RT::User->new($RT::SystemUser);
    $user->LoadByEmail($email);
    return (1) if ($user->id && $user->Privileged);
    return (0, "Invalid account: $email");
}

=head3 has_value C<value>

Returns true if the value is defined and non-empty.

=cut

sub has_value {
    my $value = shift;
    return 1 if defined($value) && length($value) > 0;
    return (0, "You must provide a value for this field");
}

=head3 LoadFormIcon($current_user, $form_id)

Loads the form icon attribute associated with the passed form id.

Returns a tuple of attribute object or false, and a message.

=cut

sub LoadFormIcon {
    my $current_user = shift;
    my $form_id = shift;

    my $form_icon = RT::Attribute->new( $current_user );
    my ( $ok, $msg ) = $form_icon->LoadByCols(
        Name => 'FormTools Icon',
        ObjectType => 'RT::Attribute',
        ObjectId => $form_id );

    if ( $ok ) {
        return ( $form_icon, $msg );
    }
    else {
        RT->Logger->error("Unable to load icon: $msg");
        return ( 0, $msg );
    }
}

=head1 AUTHOR

Best Practical Solutions, LLC

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-FormTools@rt.cpan.org|mailto:bug-RT-Extension-FormTools@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-FormTools>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014-2023 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
