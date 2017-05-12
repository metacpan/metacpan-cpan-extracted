package Net::Lighthouse::Project::TicketBin;
use Any::Moose;
use Params::Validate ':all';
use Net::Lighthouse::Util;
extends 'Net::Lighthouse::Base';

# read only attr
has 'updated_at' => (
    isa => 'DateTime',
    is  => 'ro',
);

has [ 'user_id', 'position', 'project_id', 'tickets_count', 'id' ] => (
    isa => 'Int',
    is  => 'ro',
);

has 'shared' => (
    isa => 'Bool',
    is  => 'ro',
);

# read&write attr
has 'default' => (
    isa => 'Bool',
    is  => 'rw',
);

has [qw/name query/] => (
    isa => 'Maybe[Str]',
    is  => 'rw',
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub load {
    my $self = shift;
    validate_pos( @_, { type => SCALAR, regex => qr/^\d+|\w+$/ } );
    my $id = shift;

    if ( $id !~ /^\d+$/ ) {

        # so we got a name, let's find it
        my ($bin) = grep { $_->name eq $id } $self->list;
        if ($bin) {
            $id = $bin->id;
        }
        else {
            die "can't find ticket bin $id in project "
              . $self->project_id
              . ' in account '
              . $self->account;
        }
    }

    my $ua = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id
      . '/bins/'
      . $id . '.xml';
    my $res = $ua->get($url);
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
    my $ref  = Net::Lighthouse::Util->translate_from_xml(shift);

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
            name    => { type     => SCALAR },
            query   => { type     => SCALAR },
            default => { optional => 1, type => BOOLEAN },
        }
    );
    my %args = @_;

    my $xml = Net::Lighthouse::Util->translate_to_xml(
        \%args,
        root    => 'bin',
        boolean => ['default'],
    );

    my $ua = $self->ua;

    my $url = $self->base_url . '/projects/' . $self->project_id . '/bins.xml';

    my $request = HTTP::Request->new( 'POST', $url, undef, $xml );
    my $res = $ua->request($request);
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
            name    => { optional => 1, type     => SCALAR },
            query   => { optional => 1, type     => SCALAR },
            default => { optional => 1, type => BOOLEAN },
        }
    );
    my %args = ( ( map { $_ => $self->$_ } qw/name query default/ ), @_ );

    my $xml = Net::Lighthouse::Util->translate_to_xml(
        \%args,
        root    => 'bin',
        boolean => ['default'],
    );

    my $ua = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id
      . '/bins/'
      . $self->id . '.xml';

    my $request = HTTP::Request->new( 'PUT', $url, undef, $xml );
    my $res = $ua->request($request);
    if ( $res->is_success ) {
        $self->load( $self->id );    # let's reload
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
    my $ua   = $self->ua;
    my $url =
        $self->base_url
      . '/projects/'
      . $self->project_id
      . '/bins/'
      . $self->id . '.xml';

    my $request = HTTP::Request->new( 'DELETE', $url );
    my $res = $ua->request($request);
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
    my $url  = $self->base_url . '/projects/' . $self->project_id . '/bins.xml';
    my $ua   = $self->ua;
    my $res  = $ua->get($url);
    if ( $res->is_success ) {
        my $bs =
          Net::Lighthouse::Util->read_xml( $res->content )->{'ticket-bins'}{'ticket-bin'};
        my @list = map {
            my $t = Net::Lighthouse::Project::TicketBin->new(
                map { $_ => $self->$_ }
                  grep { $self->$_ } qw/account auth project_id/
            );
            $t->load_from_xml($_);
        } ref $bs eq 'ARRAY' ? @$bs : $bs;
        return wantarray ? @list : \@list;
    }
    else {
        die "try to get $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }

}

1;

__END__

=head1 NAME

Net::Lighthouse::Project::TicketBin - Project TicketBin

=head1 SYNOPSIS

    use Net::Lighthouse::Project::TicketBin;
    my $bin = Net::Lighthouse::Project::TicketBin->new(
        account    => 'sunnavy',
        auth       => { token => '' },
        project_id => 12345,
    );
    $bin->load( 1 );
    print $bin->name;
    $bin->delete;


=head1 ATTRIBUTES

=over 4

=item updated_at

ro, DateTime

=item user_id, position, project_id, tickets_count, id

ro, Int

=item shared

ro, Bool

=item default

rw, Bool

=item name, query,

rw, Maybe Str

=back

=head1 INTERFACE

=over 4

=item load( $id | $name ), load_from_xml( $hashref | $xml_string )

load a ticket bin, return the loaded ticket bin object

=item create( name => '', query => '', default => '' );

create a ticket bin, return true if succeeded

=item update( name => '', query => '', default => '' );

update a ticket bin, return true if succeeded

=item delete

delete the ticket bin, return true if succeeded

=item list

return a list of ticket bins, each isa L<Net::Lighthouse::Project::TicketBin>.

=back

=head1 SEE ALSO

L<http://lighthouseapp.com/api/ticket-bins>

=head1 ATTRIBUTES

=head1 INTERFACE


=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

