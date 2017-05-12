package Net::Google::Code::Issue::Search;
use Any::Moose;
use Params::Validate qw(:all);
use Any::Moose 'Util::TypeConstraints';
with 'Net::Google::Code::Role::URL';
with 'Net::Google::Code::Role::Fetchable';
with 'Net::Google::Code::Role::Pageable';
with  'Net::Google::Code::Role::HTMLTree';
use Net::Google::Code::Issue;

our %CAN_MAP = (
    'all'    => 1,
    'open'   => 2,
    'new'    => 6,
    'verify' => 7,
);


has 'project' => (
    isa      => 'Str',
    is       => 'rw',
);

has 'results' => (
    isa     => 'ArrayRef[Net::Google::Code::Issue]',
    is      => 'rw',
    default => sub { [] },
);

sub updated_after {
    my $self  = shift;
    my ( $after, $fallback_to_search ) =
      validate_pos( @_, { isa => 'DateTime' },
        { optional => 1, default => 1 } );
    
    my @results;

    my $content = $self->fetch( $self->base_feeds_url . 'issueupdates/basic' );
    require Net::Google::Code::AtomParser;
    my $atom_parser = Net::Google::Code::AtomParser->new;
    my ( $feed, $entries ) = $atom_parser->parse( $content );
    if (@$entries) {
        my $min_updated =
          Net::Google::Code::DateTime->new_from_string( $entries->[-1]->{updated} );
        if ( $min_updated < $after ) {

            # yeah! we can get all the results by parsing the feed
            my %seen;
            for my $entry (@$entries) {
                my $updated = Net::Google::Code::DateTime->new_from_string(
                    $entry->{updated} );
                next unless $updated >= $after;
                if ( $entry->{title} =~ /issue\s+(\d+)/i ) {
                    next if $seen{$1}++;
                    push @results,
                      Net::Google::Code::Issue->new(
                        project => $self->project,
                        id      => $1,
                      );
                }
            }
            $_->load for @results;
            return $self->results( \@results );
        }
    }

    return unless $fallback_to_search;

    # now we have to find issues by search
    if ( $self->search( load_after_search => 1, can => 'all', q => '' ) ) {
        my $results = $self->results;
        @$results = grep { $_->updated >= $after } @$results;
    }
}

sub search {
    my $self = shift;
    my %args = (
        limit             => 999_999_999,
        load_after_search => 1,
        can               => 2,
        colspec           => 'ID+Type+Status+Priority+Milestone+Owner+Summary',
        @_
    );

    if ( $args{can} !~ /^\d$/ ) {
        $args{can} = $CAN_MAP{ $args{can} };
    }

    my @results;

    my $mech = $self->mech;
    my $url  = $self->base_url . 'issues/list?';
    for my $type (qw/can q sort colspec/) {
        next unless defined $args{$type};
        $url .= $type . '=' . $args{$type} . '&';
    }
    $self->fetch($url);

    die "Server threw an error " . $mech->response->status_line . 'when search'
      unless $mech->response->is_success;

    my $content = $mech->response->content;
    utf8::downgrade( $content, 1 );

    if ( $mech->title =~ /issue\s+(\d+)/i ) {

        # get only one ticket
        my $issue = Net::Google::Code::Issue->new(
            project => $self->project,
            id      => $1,
        );
        @results = $issue;
    }
    elsif ( $mech->title =~ /issues/i ) {

        # get a ticket list
        my @rows = $self->rows(
            html           => $content,
            limit          => $args{limit},
        );

        for my $row (@rows) {
            push @results,
              Net::Google::Code::Issue->new(
                project => $self->project,
                %$row,
              );
        }
    }
    else {
        warn "no idea what the content like";
        return;
    }

    if ( $args{load_after_search} ) {
        $_->load for @results;
    }
    $self->results( \@results );
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Net::Google::Code::Issue::Search - Issues Search API 


=head1 DESCRIPTION

=head1 INTERFACE

=over 4

=item search ( can => 'all', q = 'foo', sort => '-modified', limit => 1000, load_after_search => 1 )

do the search, the results is set to $self->results,
  which is an arrayref with Net::Google::Code::Issue as element.

If a "sort" argument is specified, that will be passed to google code's
issue list.
Generally, these are composed of "+" or "-" followed by a column name.

limit => Num is to limit the results number.

load_after_search => Bool is to state if we should call $issue->load after
search

return true if search is successful, false on the other hand.

=item updated_after( date_string || DateTime object )

find all the issues that have been updated or created after the date.
the issues are all loaded.

return true if success, false on the other hand

=item project

=item results

this should be called after a successful search.
returns issues as a arrayref.

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

