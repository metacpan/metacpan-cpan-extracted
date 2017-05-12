package Net::Lighthouse::Project;
use Any::Moose;
use Net::Lighthouse::Util;
use Params::Validate ':all';
use Net::Lighthouse::Project::Ticket;
use Net::Lighthouse::Project::TicketBin;
use Net::Lighthouse::Project::Milestone;
use Net::Lighthouse::Project::Message;
use Net::Lighthouse::Project::Changeset;

extends 'Net::Lighthouse::Base';
# read only attr

has [qw/created_at updated_at/] => (
    isa => 'DateTime',
    is  => 'ro',
);

has [qw/ open_states_list closed_states_list open_states closed_states /] => (
    isa        => 'ArrayRef',
    is         => 'ro',
    auto_deref => 1,
);

has [
    qw/default_assigned_user_id default_milestone_id id open_tickets_count /] =>
  (
    isa => 'Maybe[Int]',
    is  => 'ro',
  );
has [ qw/hidden send_changesets_to_events/ ] =>
  (
    isa => 'Bool',
    is  => 'ro',
  );

has [qw/description description_html permalink access license/] => (
    isa => 'Maybe[Str]',
    is  => 'ro',
);

# read&write attr
has [qw/archived public/] => (
    isa => 'Bool',
    is  => 'rw',
);

has [qw/name/] => (
    isa => 'Str',
    is  => 'rw',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub load {
    my $self = shift;
    validate_pos( @_, { type => SCALAR, regex => qr/^\d+|\w+$/ } );
    my $id = shift;

    if ( $id !~ /^\d+$/ ) {

        # so we got a project name, let's find it
        my ( $project ) = grep { $_->name eq $id } $self->list;
        if ($project) {
            $id = $project->id;
        }
        else {
            die "can't find project $id in account " . $self->account;
        }
    }

    my $ua = $self->ua;
    my $url = $self->base_url . '/projects/' . $id . '.xml';
    my $res = $ua->get( $url );
    if ( $res->is_success ) {
        $self->load_from_xml( $res->content );
    }
    else {
        die "try to get $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub load_from_xml {
    my $self = shift;
    my $ref = $self->_translate_from_xml( shift );

    # dirty hack: some attrs are read-only, and Mouse doesn't support
    # writer => '...'
    for my $k ( keys %$ref ) {
        $self->{$k} = $ref->{$k};
    }
    return $self;
}

sub create {
    my $self = shift;
    validate(
        @_,
        {
            name     => { type => SCALAR },
            archived => { optional => 1, type => BOOLEAN },
            public   => { optional => 1, type => BOOLEAN },
        }
    );
    my %args = @_;

    my $xml = Net::Lighthouse::Util->translate_to_xml(
        \%args,
        root    => 'project',
        boolean => [qw/archived public/],
    );

    my $ua = $self->ua;

    my $url = $self->base_url . '/projects.xml';

    my $request = HTTP::Request->new( 'POST', $url, undef, $xml );
    my $res = $ua->request( $request );
    if ( $res->is_success ) {
        $self->load_from_xml( $res->content );
        return 1;
    }
    else {
        die "try to POST $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub update {
    my $self = shift;
    validate(
        @_,
        {
            archived => { optional => 1, type => BOOLEAN },
            name     => { optional => 1, type => SCALAR },
            public   => { optional => 1, type => BOOLEAN },
        }
    );
    my %args = ( ( map { $_ => $self->$_ } qw/archived name public/ ), @_ );

    my $xml = Net::Lighthouse::Util->translate_to_xml(
        \%args,
        root    => 'project',
        boolean => [qw/archived public/],
    );

    my $ua = $self->ua;
    my $url = $self->base_url . '/projects/' . $self->id . '.xml';

    my $request = HTTP::Request->new( 'PUT', $url, undef, $xml );
    my $res = $ua->request( $request );
    if ( $res->is_success ) {
        $self->load( $self->id ); # let's reload
        return 1;
    }
    else {
        die "try to PUT $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub delete {
    my $self = shift;
    my $ua = $self->ua;
    my $url = $self->base_url . '/projects/' . $self->id . '.xml';

    my $request = HTTP::Request->new( 'DELETE', $url );
    my $res = $ua->request( $request );
    if ( $res->is_success ) {
        return 1;
    }
    else {
        die "try to DELETE $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub list {
    my $self = shift;
    my $ua = $self->ua;
    my $url = $self->base_url . '/projects.xml';
    my $res = $ua->get( $url );
    if ( $res->is_success ) {
        my $ps = Net::Lighthouse::Util->read_xml( $res->content )->{projects}{project};
        my @list = map {
            my $p = Net::Lighthouse::Project->new(
                map { $_ => $self->$_ }
                  grep { $self->$_ } qw/account auth/
            );
            $p->load_from_xml($_);
        } ref $ps eq 'ARRAY' ? @$ps : $ps;
        return wantarray ? @list : \@list;
    }
    else {
        die "try to get $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }

}

sub initial_state {
    my $self = shift;
    my $ua = $self->ua;
    my $url = $self->base_url . '/projects/new.xml';
    my $res = $ua->get( $url );
    if ( $res->is_success ) {
        return $self->_translate_from_xml( $res->content );
    }
    else {
        die "try to get $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

sub tickets { return shift->_list( 'Ticket', @_ ) }
sub ticket_bins { return shift->_list( 'TicketBin', @_ ) }
sub messages { return shift->_list( 'Message', @_ ) }
sub milestones { return shift->_list( 'Milestone', @_ ) }
sub changesets { return shift->_list( 'Changeset', @_ ) }

sub ticket { return shift->_new( 'Ticket' ) }
sub ticket_bin { return shift->_new( 'TicketBin' ) }
sub message { return shift->_new( 'Message' ) }
sub milestone { return shift->_new( 'Milestone' ) }
sub changeset { return shift->_new( 'Changeset' ) }

sub _new {
    my $self = shift;
    validate_pos(
        @_,
        {
            type  => SCALAR,
            regex => qr/^(TicketBin|Ticket|Message|Changeset|Milestone)$/,
        }
    );
    my $class  = 'Net::Lighthouse::Project::' . shift;
    my $object = $class->new(
        project_id => $self->id,
        map { $_ => $self->$_ }
          grep { $self->$_ } qw/account auth/
    );
    return $object;
}

sub _list {
    my $self = shift;
    validate_pos(
        @_,
        {
            type  => SCALAR,
            regex => qr/^(TicketBin|Ticket|Message|Changeset|Milestone)$/,
        },
        (0)x(@_-1)
    );
    my $class  = 'Net::Lighthouse::Project::' . shift;
    my $object = $class->new(
        project_id => $self->id,
        map { $_ => $self->$_ }
          grep { $self->$_ } qw/account auth/
    );
    return $object->list(@_);
}

sub _translate_from_xml {
    my $self = shift;
    my $ref = Net::Lighthouse::Util->translate_from_xml(shift);
    for (qw/open_states_list closed_states_list/) {
        $ref->{$_} = [ split /,/, $ref->{$_} ];
    }

    for my $states (qw/ open_states closed_states /) {
        my @values = split /\n/, $ref->{$states};
        my @new_values;
        for my $value (@values) {
            # e.g. new/f17  # You can add comments here
            if ( $value =~ m{(\w+)(?:/(\w+))?\s+#?\s*(.*)?} ) {
                push @new_values, { name => $1, color => $2, comment => $3 };
            }
            else {
                warn "parse $value failed";
            }
        }
        $ref->{$states} = [@new_values];
    }
    return $ref;
}

1;

__END__

=head1 NAME

Net::Lighthouse::Project - Project

=head1 SYNOPSIS

    use Net::Lighthouse::Project;
    my $project = Net::Lighthouse::Project->new(
        account => 'foo',
        auth    => { token => 'bla' },
    );

    $project->load( 35918 ); # load by id
    $project->load( 'foo' ); # load by name

    my $description = $project->description;
    my $created_at = $project->created_at; # DateTime object, UTC based

    my @projects   = $project->list;
    my $ticket     = $project->ticket;
    my @tickets    = $project->tickets;
    my $bin        = $project->ticket_bin;
    my @bins       = $project->ticket_bins;
    my $changeset  = $project->changeset;
    my @changesets = $project->changesets;
    my $milestone  = $project->milestone;
    my @milestones = $project->milestones;
    my $message    = $project->message;
    my @messages   = $project->messages;

=head1 ATTRIBUTES

=over 4

=item created_at, updated_at

ro, DateTime object, UTC based

=item open_states_list, closed_states_list, open_states, closed_states

ro, Array

=item default_assigned_user_id, default_milestone_id, id, open_tickets_count

ro, Maybe Int

=item hidden, send_changesets_to_events

ro, Bool

=item description, description_html, permalink, access, license

ro, Maybe Str

=item archived, public

rw, Bool

=item name

rw, Bool

=back

=head1 INTERFACE

=over 4

=item projects, changesets, tickets, ticket_bins, messages, milestones

return a list of corresponding object

=item changeset, ticket, ticket_bin, message, milestone

return a corresponding object, with account and auth prefilled if exist.

=item create( name => '', archived => '', public => '' )

create a project, return true if succeeded

=item update( name => '', archived => '', public => '' )

update the project, return true if succeeded

=item delete

delete the project, return true if succeeded

=item list

return a list of projects, each isa L<Net::Lighthouse::Project>

=item load( $id | $name ), load_from_xml( $hahsref | $xml_string )

load a project, return loaded project object

=item initial_state

return hashref, carrying the initial_state info

=back

=head1 SEE ALSO

L<http://lighthouseapp.com/api/projects>

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

