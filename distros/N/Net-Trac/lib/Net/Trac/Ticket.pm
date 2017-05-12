use strict;
use warnings;

package Net::Trac::Ticket;

=head1 NAME

Net::Trac::Ticket - Create, read, and update tickets on a remote Trac instance

=head1 SYNOPSIS

    my $ticket = Net::Trac::Ticket->new( connection => $trac );
    $ticket->load( 1 );
    
    print $ticket->summary, "\n";

=head1 DESCRIPTION

This class represents a ticket on a remote Trac instance.  It provides methods
for creating, reading, and updating tickets and their history as well as adding
comments and getting attachments.

=cut

use Any::Moose;
use Params::Validate qw(:all);
use Lingua::EN::Inflect qw();
use DateTime;

use Net::Trac::TicketSearch;
use Net::Trac::TicketHistory;
use Net::Trac::TicketAttachment;

has connection => (
    isa => 'Net::Trac::Connection',
    is  => 'ro'
);

has state => (
    isa => 'HashRef',
    is  => 'rw'
);


has history => (
    isa     => 'Net::Trac::TicketHistory',
    is => 'rw',
    default => sub {
        my $self = shift;
        my $hist = Net::Trac::TicketHistory->new( { connection => $self->connection } );
        $hist->load($self);
        return $hist;
    },
    lazy => 1
);



has _attachments => (
    isa => 'ArrayRef',
    is => 'rw',
    default => sub {[]}
);

our $LOADED_NEW_METADATA =0;
our $LOADED_UPDATE_METADATA =0;


our (
    $_VALID_MILESTONES, $_VALID_TYPES,       $_VALID_COMPONENTS,
    $_VALID_PRIORITIES, $_VALID_RESOLUTIONS, $_VALID_SEVERITIES
);
sub valid_milestones { shift; $_VALID_MILESTONES = shift if (@_); return $_VALID_MILESTONES || [] }
sub valid_types      { shift; $_VALID_TYPES      = shift if (@_); return $_VALID_TYPES ||[]}
sub valid_components { shift; $_VALID_COMPONENTS = shift if (@_); return $_VALID_COMPONENTS || [] }
sub valid_priorities { shift; $_VALID_PRIORITIES = shift if (@_); return $_VALID_PRIORITIES || [] }
sub valid_resolutions { shift; $_VALID_RESOLUTIONS = shift if (@_); return $_VALID_RESOLUTIONS || []; }
sub valid_severities { shift; $_VALID_SEVERITIES = shift if (@_); return $_VALID_SEVERITIES || [] }

sub basic_statuses { qw( new accepted assigned reopened closed ) }

my @valid_props_arr = ();

sub valid_props { return @valid_props_arr }

sub add_custom_props {
    my ($self, @props) = @_;
    for my $prop (@props) {
        next if grep { $_ eq $prop } @valid_props_arr;
        push @valid_props_arr, $prop;
        no strict 'refs';
        *{ "Net::Trac::Ticket::" . $prop } = sub { shift->state->{$prop} };
    }
}

Net::Trac::Ticket->add_custom_props(qw( id summary type status priority severity resolution owner reporter cc
        description keywords component milestone version time changetime ));

sub valid_create_props { grep { !/^(?:resolution|time|changetime)$/i } $_[0]->valid_props }
sub valid_update_props { grep { !/^(?:time|changetime)$/i } $_[0]->valid_props }

sub created       { my $self= shift; $self->timestamp_to_datetime($self->time) }
sub last_modified { my $self= shift; $self->timestamp_to_datetime($self->changetime) }

=head2 timestamp_to_datetime $stamp

Accept's a timestamp in Trac's somewhat idiosyncratic format and returns a DateTime object

=cut

sub timestamp_to_datetime {
    my ( $self, $prop ) = @_;
    if ( $prop =~ /^(\d{4})-(\d\d)-(\d\d)[\sT](\d\d):(\d\d):(\d\d)(?:Z?([+-][\d:]+))?/i ) {
        my ( $year, $month, $day, $hour, $min, $sec, $offset) = 
                ( $1, $2, $3, $4, $5, $6, $7 );

        $offset ||= '00:00';
        $offset =~ s/://;
        return DateTime->new(
            year   => $year,
            month  => $month,
            day    => $day,
            hour   => $hour,
            minute => $min,
            second => $sec,
            time_zone => $offset);
    }
}

=head1 METHODS

=head2 new HASH

Takes a key C<connection> with a value of a L<Net::Trac::Connection>.  Returns
an empty ticket object.

=head2 load ID

Loads up the ticket with the specified ID.  Returns the ticket ID loaded on success
and undef on failure.

=cut

sub load {
    my $self = shift;
    my ($id) = validate_pos( @_, { type => SCALAR } );

    my $search = Net::Trac::TicketSearch->new( connection => $self->connection );
    $search->limit(1);
    $search->query( id => $id, _no_objects => 1 );

    return unless @{ $search->results };

    my $ticket_data = $search->results->[0];
    $self->_tweak_ticket_data_for_load($ticket_data);

    my $tid = $self->load_from_hashref( $ticket_data);
    return $tid;
}

# We force an order on the keywords prop since trac doesn't let us
# really know what the order used to be
sub _tweak_ticket_data_for_load {
    my $self = shift;
    my $ticket = shift;
    $ticket->{keywords} = join(' ', sort ( split ( /\s+/,$ticket->{keywords})));

}


=head2 load_from_hashref HASHREF [SKIP]

You should never need to use this method yourself.  Loads a ticket from a hashref
of data, optionally skipping metadata loading (values of C<valid_*> accessors).

=cut

sub load_from_hashref {
    my $self = shift;
    my ($hash, $skip_metadata) = validate_pos(
        @_,
        { type => HASHREF },
        { type => BOOLEAN, default => undef }
    );

    return undef unless $hash and $hash->{'id'};

    $self->state( $hash );
    return $hash->{'id'};
}

sub _get_new_ticket_form {
    my $self = shift;
    $self->connection->ensure_logged_in;
    $self->connection->_fetch("/newticket") or return;
    my $i = 1; # form number
    for my $form ( $self->connection->mech->forms() ) {
        return ($form,$i) if $form->find_input('field_summary');
        $i++;
    }
    return undef;
}

sub _get_update_ticket_form {
    my $self = shift;
    $self->connection->ensure_logged_in;
    $self->connection->_fetch("/ticket/".$self->id) or return;
    my $i = 1; # form number;
    for my $form ( $self->connection->mech->forms() ) {
        return ($form,$i) if $form->find_input('field_summary');
        $i++;
    }
    return undef;
}

sub _get_possible_values {
    my $self = shift;
    my ($form, $field) = @_;
    my $res = $form->find_input($field);
    return [] unless defined $res; 
    return [ $res->possible_values ];
}

sub _fetch_new_ticket_metadata {
    my $self = shift;

    return 1 if $LOADED_NEW_METADATA;

    my ($form, $form_num) = $self->_get_new_ticket_form;
    unless ( $form ) {
        return undef;
    }

    $self->valid_milestones(
        $self->_get_possible_values( $form, 'field_milestone' ) );
    $self->valid_types( $self->_get_possible_values( $form, 'field_type' ) );
    $self->valid_components(
        $self->_get_possible_values( $form, 'field_component' ) );
    $self->valid_priorities(
        $self->_get_possible_values( $form, 'field_priority' ) );

    my $severity = $form->find_input("field_severity");
    $self->valid_severities([ $severity->possible_values ]) if $severity;
    $LOADED_NEW_METADATA++;
    return 1;
}

sub _fetch_update_ticket_metadata {
    my $self = shift;

    return 1 if $LOADED_UPDATE_METADATA;
    my ($form, $form_num) = $self->_get_update_ticket_form;
    unless ($form) {
        return undef;
    }
    my $resolutions = $form->find_input("action_resolve_resolve_resolution");
    $self->valid_resolutions( [$resolutions->possible_values] ) if $resolutions;
    
    $LOADED_UPDATE_METADATA++;
    return 1;
}

sub _metadata_validation_rules {
    my $self = shift;
    my $type = lc shift;

    # Ensure that we've loaded up metadata
    $self->_fetch_new_ticket_metadata unless $LOADED_NEW_METADATA;
    $self->_fetch_update_ticket_metadata if ( ( $type eq 'update' ) && ! $LOADED_UPDATE_METADATA);

    my %rules;
    for my $prop ( @_ ) {
        my $method = "valid_" . Lingua::EN::Inflect::PL($prop);
        if ( $self->can($method) ) {
            # XXX TODO: escape the values for the regex?
            my $values = join '|', grep { defined and length } @{$self->$method};
            if ( length $values ) {
                my $check = qr{^(?:$values)$}i;
                $rules{$prop} = { type => SCALAR, regex => $check, optional => 1 };
            } else {
                $rules{$prop} = 0;
            }
        }
        else {
            $rules{$prop} = 0; # optional
        }
    }
    return \%rules;
}

=head2 create HASH

Creates and loads a new ticket with the values specified.
Returns undef on failure and the new ticket ID on success.

=cut

sub create {
    my $self = shift;
    my %args = validate(
        @_,
        $self->_metadata_validation_rules( 'create' => $self->valid_create_props )
    );

    my ($form,$form_num)  = $self->_get_new_ticket_form();

    my %form = map { 'field_' . $_ => $args{$_} } keys %args;

    $self->connection->mech->submit_form(
        form_number => $form_num,
        fields => { %form, submit => 1 }
    );

    my $reply = $self->connection->mech->response;
    $self->connection->_warn_on_error( $reply->base->as_string ) and return;

    if ($reply->title =~ /^#(\d+)/) {
        my $id = $1;
        $self->load($id);
        return $id;
    } else {
        return undef;
    }
}

=head2 update HASH

Updates the current ticket with the specified values.

Returns undef on failure, and the ID of the current ticket on success.

=cut

sub update {
    my $self = shift;
    my %args = validate(
        @_,
        {
            comment         => 0,
            %{$self->_metadata_validation_rules( 'update' => $self->valid_update_props )}
        }
    );

    my ($form,$form_num)= $self->_get_update_ticket_form();

    # Copy over the values we'll be using
    my %form = map  { "field_".$_ => $args{$_} }
               grep { !/comment|no_auto_status|status|resolution|owner/ } keys %args;

    # Copy over comment too -- it's a pseudo-prop
    $form{'comment'} = $args{'comment'};
    $self->connection->mech->form_number( $form_num );

    if ( $args{'resolution'} || $args{'status'} && $args{'status'} eq 'closed' ) {
        $form{'action'}                            = 'resolve';
        $form{'action_resolve_resolve_resolution'} = $args{'resolution'}
          if $args{'resolution'};
    }
    elsif ( $args{'owner'} || $args{'status'} && $args{'status'} eq 'assigned' ) {
        $form{'action'}                         = 'reassign';
        $form{'action_reassign_reassign_owner'} = $args{'owner'}
          if $args{'owner'};
    }
    elsif ( $args{'status'} && $args{'status'} eq 'reopened' ) {
        $form{'action'} = 'reopen';
    }

    $self->connection->mech->submit_form(
        form_number => $form_num,
        fields => { %form, submit => 1 }
    );
    my $reply = $self->connection->mech->response;
    if ( $reply->is_success ) {
        delete $self->{history}; # ICK. I really want a Any::Moose "reset to default"
        return $self->load($self->id);
    }
    else {
        return undef;
    }
}

=head2 comment TEXT

Adds a comment to the current ticket.  Returns undef on failure, true on success.

=cut

sub comment {
    my $self = shift;
    my ($comment) = validate_pos( @_, { type => SCALAR });
    $self->update( comment => $comment );
}

=head2 history

Returns a L<Net::Trac::TicketHistory> object for this ticket.

=cut


=head2 comments

Returns an array or arrayref (depending on context) of history entries which
have comments included.  This will include history entries representing
attachments if they have descriptions.

=cut

sub comments {
    my $self = shift;
    my $hist = $self->history;

    my @comments;
    for ( @{$hist->entries} ) {
        push @comments, $_ if ($_->content =~ /\S/ && ! $_->is_create);
    }
    return wantarray ? @comments : \@comments;
}

sub _get_add_attachment_form {
    my $self = shift;
    $self->connection->ensure_logged_in;
    $self->connection->_fetch("/attachment/ticket/".$self->id."/?action=new") or return;
    my $i = 1; # form number;
    for my $form ( $self->connection->mech->forms() ) {
        return ($form,$i) if $form->find_input('attachment');
        $i++;
    }
    return undef;
}

=head2 attach PARAMHASH

Attaches the specified C<file> with an optional C<description>.
Returns undef on failure and the new L<Net::Trac::TicketAttachment> object
on success.

=cut

sub attach {
    my $self = shift;
    my %args = validate( @_, { file => 1, description => 0 } );

    my ($form, $form_num)  = $self->_get_add_attachment_form();

    $self->connection->mech->submit_form(
        form_number => $form_num,
        fields => {
            attachment  => $args{'file'},
            description => $args{'description'},
            replace     => 0
        }
    );

    my $reply = $self->connection->mech->response;
    $self->connection->_warn_on_error( $reply->base->as_string ) and return;
    delete $self->{history}; # ICK. I really want a Any::Moose "reset to default"

    return $self->attachments->[-1];
}

sub _update_attachments {
    my $self = shift;
    $self->connection->ensure_logged_in;
    my $content = $self->connection->_fetch("/attachment/ticket/".$self->id."/")
        or return;
    
    if ( $content =~ m{<dl class="attachments">(.+?)</dl>}is ) {
        my $html = $1 . '<dt>'; # adding a <dt> here is a hack that lets us
                                # reliably parse this with one regex

        my @attachments;
        while ( $html =~ m{<dt>(.+?)(?=<dt>)}gis ) {
            my $fragment = $1;
            my $attachment = Net::Trac::TicketAttachment->new({
                connection => $self->connection,
                ticket     => $self->id
            });
            $attachment->_parse_html_chunk( $fragment );
            push @attachments, $attachment;
        }
        $self->_attachments( \@attachments );
    }
}

=head2 attachments

Returns an array or arrayref (depending on context) of all the
L<Net::Trac::TicketAttachment> objects for this ticket.

=cut

sub attachments {
    my $self = shift;
    $self->_update_attachments;
    return wantarray ? @{$self->_attachments} : $self->_attachments;
}

=head1 ACCESSORS

=head2 connection

=head2 id

=head2 summary

=head2 type

=head2 status

=head2 priority

=head2 severity

=head2 resolution

=head2 owner

=head2 reporter

=head2 cc

=head2 description

=head2 keywords

=head2 component

=head2 milestone

=head2 version

=head2 created

Returns a L<DateTime> object

=head2 last_modified

Returns a L<DateTime> object

=head2 basic_statuses

Returns a list of the basic statuses available for a ticket.  Others
may be defined by the remote Trac instance, but we have no way of easily
getting them.

=head2 valid_props

Returns a list of the valid properties of a ticket.

=head2 add_custom_props

Adds custom properties to valid properties list.

=head2 valid_create_props

Returns a list of the valid properties specifiable when creating a ticket.

=head2 valid_update_props

Returns a list of the valid updatable properties.

=head2 Valid property values

These accessors are loaded from the remote Trac instance with the valid
values for the properties upon instantiation of a ticket object.

=over

=item valid_milestones

=item valid_types

=item valid_components

=item valid_priorities

=item valid_resolutions - Only loaded when a ticket is loaded.

=item valid_severities - May not be provided by the Trac instance.

=back

=head1 LICENSE

Copyright 2008-2009 Best Practical Solutions.

This package is licensed under the same terms as Perl 5.8.8.

=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

