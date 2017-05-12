package Net::Google::Code::Issue;
use Any::Moose;
use Params::Validate qw(:all);
with 'Net::Google::Code::TypicalRoles';
use Net::Google::Code::DateTime;
use Net::Google::Code::Issue::Comment;
use Net::Google::Code::Issue::Attachment;
use Scalar::Util qw/blessed/;

use Net::Google::Code::Issue::Util;
extends 'Net::Google::Code::Issue::Base';

# set this to true to enable hybrid load, create and update
our $USE_HYBRID;

use XML::FeedPP;

has 'id' => (
    isa      => 'Int',
    is       => 'rw',
);

has 'status' => (
    isa => 'Str',
    is  => 'rw',
);

has 'owner' => (
    isa => 'Str',
    is  => 'rw',
);

has 'cc' => (
    isa => 'Str',
    is  => 'rw',
);

has 'summary' => (
    isa => 'Str',
    is  => 'rw',
);

has 'reporter' => (
    isa => 'Str',
    is  => 'rw',
);

has 'reported' => (
    isa => 'DateTime',
    is  => 'rw',
);

has 'merged' => (
    isa => 'Int',
    is  => 'rw',
);

has 'stars' => (
    isa => 'Int',
    is  => 'rw',
);

has 'closed' => (
    isa => 'Str',
    is  => 'rw',
);

has 'description' => (
    isa => 'Str',
    is  => 'rw',
);

has 'labels' => (
    isa     => 'ArrayRef',
    is      => 'rw',
    default => sub { [] },
);

has 'comments' => (
    isa     => 'ArrayRef[Net::Google::Code::Issue::Comment]',
    is      => 'rw',
    default => sub { [] },
);

has 'attachments' => (
    isa     => 'ArrayRef[Net::Google::Code::Issue::Attachment]',
    is      => 'rw',
    default => sub { [] },
);

sub load {
    my $self = shift;
    my $id = shift || $self->id;
    die "current object doesn't have id and load() is not passed an id either"
      unless $id;

    if ($USE_HYBRID) {
        unless ( $self->{loaded_way}
            && $self->{loaded_way} eq 'api'
            && $id == $self->id )
        {
            my ($issue) = $self->list( id => $id );
            %$self = %$issue;
        }
        $self->{loaded_way} = 'hybrid';

        $self->load_comments;

        # here we do scraping to get stuff not can be seen from feeds
        my $content =
          $self->fetch( $self->base_url . "issues/detail?id=" . $id );
        return $self->parse_hybrid($content);
    }
    else {
        my $content =
          $self->fetch( $self->base_url . "issues/detail?id=" . $id );
        $self->id( $id );
        $self->{loaded_way} = 'scraping';
        return $self->parse($content);
    }
}

sub parse {
    my $self    = shift;
    my $tree    = shift;

    my $need_delete = not blessed $tree;
    $tree = $self->html_tree( html => $tree ) unless blessed $tree;

    # extract summary
    my ($summary) = $tree->look_down( class => 'h3' );
    $self->summary( $summary->as_text );

    # extract reporter, reported and description
    my $description = $tree->look_down( class => 'vt issuedescription' );
    my $author_tag = $description->look_down( class => "author" );
    $self->reporter( $author_tag->content_array_ref->[1]->as_text );
    $self->reported( Net::Google::Code::DateTime->new_from_string($author_tag->look_down( class => 'date' )->attr('title') ));


    my $text = $description->find_by_tag_name('pre')->as_text;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    $text =~ s/\r\n/\n/g;
    $self->description( $text );

    my $att_tag = $description->look_down( class => 'attachments' );
    my @attachments;
    @attachments =
      Net::Google::Code::Issue::Attachment->parse_attachments($att_tag)
      if $att_tag;
    $self->attachments( \@attachments );

    my ($meta) = $tree->look_down( id => 'issuemeta' );
    {

        # let's find stars
        my ($header) = $tree->look_down( id => 'issueheader' );
        if (   $header
            && $header->as_text =~ /(\d+) \w+ starred this issue/ )
        {
# the \w+ is person or people, I don't know if google will change that word
# some time, so just use \w+
            my $stars = $1;
            $self->stars($stars);
        }
    }

    my @meta = $meta->find_by_tag_name('tr');
    my @labels;
    for my $meta (@meta) {
        my ( $key, $value );
        if ( my $k = $meta->find_by_tag_name('th') ) {
            my $v         = $meta->find_by_tag_name('td');
            my $k_content = $k->content_array_ref->[0];
            while ( ref $k_content ) {
                $k_content = $k_content->content_array_ref->[0];
            }
            $key = $k_content;    # $key is like 'Status:#'
            $key =~ s/:.$//;      # s/:#$// doesn't work, no idea why
            $key = lc $key;

            if ($v) {
                $value = $v->as_text;
                $value =~ s/^\s+//;
                $value =~ s/\s+$//;
            }

            if ( $self->can( $key ) ) {
                if ( $key eq 'merged' && $value =~ /issue\s+(\d+)/ ) {
                    $value = $1;
                }
                $self->$key( $value );
            }
            else {
                warn "no idea where to keep $key";
            }
        }
        else {
            my $href = $meta->look_down( class => 'label' )->attr('href');
            if ( $href =~ /list\?q=label:(.+)/ ) {
                push @labels, $1;
            }
        }
    }
    $self->labels( \@labels );

    # extract comments
    my @comments_tag = $tree->look_down( class => 'vt issuecomment' );
    my @comments;
    for my $tag (@comments_tag) {
        next unless $tag->look_down( class => 'author' );
        my $comment =
          Net::Google::Code::Issue::Comment->new( project => $self->project );
        $comment->parse($tag);
        push @comments, $comment;
    }

    my $initial_comment = Net::Google::Code::Issue::Comment->new(
        project     => $self->project,
        sequence    => 0,
        date        => $self->reported,
        author      => $self->reporter,
        content     => $self->description,
        attachments => $self->attachments,
    );

    my @initial_labels = @{$self->labels};
    my %meta = map { $_ => 1 } qw/summary status cc owner/;
    for my $c ( reverse @comments ) {
        my $updates = $c->updates;
        for ( keys %meta ) {
            # once these changes, we can't know the inital value
            delete $meta{$_} if exists $updates->{$_};
        }
        if ( $updates->{labels} ) {
            my @labels = @{$updates->{labels}};
            for my $label (@labels) {
                if ( $label =~ /^-(.*)$/ ) {
                    unshift @initial_labels, $1;
                }
                else {
                    @initial_labels = grep { $_ ne $label } @initial_labels;
                }
            }
        }
    }

    $initial_comment->updates->{labels} = \@initial_labels;
    for ( keys %meta ) {
        $initial_comment->updates->{$_} = $self->$_;
    }

    unshift @comments, $initial_comment;

    $self->comments( \@comments );
    $tree->delete if $need_delete;
    return 1;
}

sub load_comments {
    my $self = shift;
    require Net::Google::Code::Issue::Comment;
    my $comment = Net::Google::Code::Issue::Comment->new(
        issue_id => $self->id,
        map { $_ => $self->$_ }
          grep { $self->$_ } qw/project email password token/
    );

    # $comment is for initial comment we will work out
    $self->comments( [ $comment, $comment->list ] );
}

sub parse_hybrid {
    my $self    = shift;
    my $tree    = shift;
    my $need_delete = not blessed $tree;
    $tree = $self->html_tree( html => $tree ) unless blessed $tree;

    my $description = $tree->look_down( class => 'vt issuedescription' );
    my $att_tag = $description->look_down( class => 'attachments' );
    my @attachments;
    @attachments =
      Net::Google::Code::Issue::Attachment->parse_attachments($att_tag)
      if $att_tag;
    $self->attachments( \@attachments );

    my ($meta) = $tree->look_down( id => 'issuemeta' );
    my @meta = $meta->find_by_tag_name('tr');
    my @labels;
    for my $meta (@meta) {

        my ( $key, $value );
        if ( my $k = $meta->find_by_tag_name('th') ) {
            my $v         = $meta->find_by_tag_name('td');
            my $k_content = $k->content_array_ref->[0];
            while ( ref $k_content ) {
                $k_content = $k_content->content_array_ref->[0];
            }
            $key = $k_content;    # $key is like 'Status:#'
            $key =~ s/:.$//;      # s/:#$// doesn't work, no idea why
            $key = lc $key;

            if ($v) {
                $value = $v->as_text;
                $value =~ s/^\s+//;
                $value =~ s/\s+$//;
            }
            if ( $self->can( $key ) ) {
                if ( $key eq 'merged' && $value =~ /issue\s+(\d+)/ ) {
                    $value = $1;
                }
                $self->$key( $value );
            }
            else {
                warn "no idea where to keep $key";
            }
        }
    }

    # extract comments
    my @comments_tag = $tree->look_down( class => 'vt issuecomment' );
    ( undef, my @comments ) = @{$self->comments};
    my $number = 1; # 0 is for initial comment
    for my $tag (@comments_tag) {
        next unless $tag->look_down( class => 'author' );
        my $comment = $self->comments->[$number++];
        $comment->parse_hybrid($tag);
    }

    my $initial_comment = Net::Google::Code::Issue::Comment->new(
        sequence    => 0,
        date        => $self->reported,
        author      => $self->reporter,
        content     => $self->description,
        attachments => $self->attachments,
        issue_id    => $self->id,
        map { $_ => $self->$_ }
          grep { $self->$_ } qw/project email password token/
    );

    my @initial_labels = @{$self->labels};
    my %meta = map { $_ => 1 } qw/summary status cc owner/;
    for my $c ( reverse @comments ) {
        my $updates = $c->updates;
        for ( keys %meta ) {
            # once these changes, we can't know the inital value
            delete $meta{$_} if exists $updates->{$_};
        }
        if ( $updates->{labels} ) {
            my @labels = @{$updates->{labels}};
            for my $label (@labels) {
                if ( $label =~ /^-(.*)$/ ) {
                    unshift @initial_labels, $1;
                }
                else {
                    @initial_labels = grep { $_ ne $label } @initial_labels;
                }
            }
        }
    }

    $initial_comment->updates->{labels} = \@initial_labels;
    for ( keys %meta ) {
        $initial_comment->updates->{$_} = $self->$_;
    }
    $self->comments->[0] = $initial_comment;
    $tree->delete if $need_delete;
    return 1;
}

sub _load_from_xml {
    my $self = shift;
    my $ref =
      Net::Google::Code::Issue::Util->translate_from_xml( shift,
        type => 'issue' );

    for my $k ( keys %$ref ) {
        if ( $self->can($k) ) {
            $self->{$k} = $ref->{$k};
        }
    }
    return $self;
}

sub create {
    my $self = shift;
    my %args = validate(
        @_,
        {
            labels => { type => ARRAYREF, optional => 1 },
            files  => { type => ARRAYREF, optional => 1 },
            map { $_ => { type => SCALAR, optional => 1 } }
              qw/comment summary status owner cc/,
        }
    );

    if ( $args{files} || !$USE_HYBRID) {
        $self->sign_in;
        $self->fetch( $self->base_url . 'issues/entry' );

        if ( $args{files} ) {

            # hack hack hack
            # manually add file fields since we don't have them in page.
            my $html = $self->mech->content;
            for ( 1 .. @{ $args{files} } ) {
                $html =~
s{(?<=id="attachmentareadeventry"></div>)}{<input name="file$_" type="file">};
            }
            $self->mech->update_html($html);
        }

        $self->mech->form_with_fields( 'comment', 'summary' );

        # leave labels alone unless there're labels.
        $self->mech->field( 'label', $args{labels} ) if $args{labels};

        if ( $args{files} ) {
            for ( my $i = 0 ; $i < scalar @{ $args{files} } ; $i++ ) {
                $self->mech->field( 'file' . ( $i + 1 ), $args{files}[$i] );
            }
        }

        $self->mech->submit_form(
            fields => {
                map { $_ => $args{$_} }
                grep { exists $args{$_} } qw/comment summary status owner cc/
            }
        );

        my ( $contains, $id ) = $self->html_tree_contains(
            html      => $self->mech->content,
            look_down => [ class => 'notice' ],
            as_text   => qr/Issue\s+(\d+)/i,
        );

        if ($contains) {
            $self->load($id);
            return $id;
        }
        else {
            warn 'create issue failed';
            return;
        }
    }
    else {

        # we can use google's official api here
        my $author = $self->email;
        $author =~ s/@.*//;
        my %args = ( author => $author, @_ );

        my $xml =
          Net::Google::Code::Issue::Util->translate_to_xml( \%args,
            type => 'create' );
        my $ua = $self->ua;

        my $url     = $self->feeds_issues_url . '/full';
        my $request = HTTP::Request->new( 'POST', $url, undef, $xml );
        my $res     = $ua->request($request);
        if ( $res->is_success ) {
            my $content = $res->content;

            # let's fake wrap the entry with <feed>
            $content =~ s!<entry!<feed><entry!;
            $content =~ s{$}{</feed>};
            my $feed = XML::FeedPP->new($content);
            my ($item) = $feed->get_item;
            $self->_load_from_xml($item);
            $self->load( $self->id );
            return 1;
        }
        else {
            die "try to POST $url failed: "
              . $res->status_line . "\n"
              . $res->content;
        }

    }
}

sub update {
    my $self = shift;
    my %args = validate(
        @_,
        {
            labels => { type => ARRAYREF, optional => 1 },
            files  => { type => ARRAYREF, optional => 1 },
            map { $_ => { type => SCALAR, optional => 1 } }
              qw/comment summary status owner merge_into cc blocked_on/,
        }
    );

    if (   $args{files}
        || $args{merge_into}
        || $args{blocked_on}
        || !$USE_HYBRID )
    {

        $self->sign_in;
        $self->fetch( $self->base_url . 'issues/detail?id=' . $self->id );

        if ( $args{files} ) {

            # hack hack hack
            # manually add file fields since we don't have them in page.
            my $html = $self->mech->content;
            for ( 1 .. @{ $args{files} } ) {
                $html =~
s{(?<=id="attachmentarea"></div>)}{<input name="file$_" type="file">};
            }
            $self->mech->update_html($html);
        }

        $self->mech->form_with_fields( 'comment', 'summary' );

        # leave labels alone unless there're labels.
        $self->mech->field( 'label', $args{labels} ) if $args{labels};
        if ( $args{files} ) {
            for ( my $i = 0 ; $i < scalar @{ $args{files} } ; $i++ ) {
                $self->mech->field( 'file' . ( $i + 1 ), $args{files}[$i] );
            }
        }

        $self->mech->submit_form(
            fields => {
                map { $_ => $args{$_} }
                  grep { exists $args{$_} }
                  qw/comment summary status owner merge_into cc blocked_on/
            }
        );

        if (
            $self->html_tree_contains(
                html      => $self->mech->content,
                look_down => [ class => 'notice' ],
                as_text   => qr/has been updated/,
            )
          )
        {
            $self->load( $self->id );    # maybe this is too much?
            return 1;
        }
        else {
            warn 'update failed';
            return;
        }
    }
    else {
        my $author = $self->email;
        $author =~ s/@.*//;
        my %args = (
            author => $author,
            (
                map { $_ => $self->$_ } qw/title content status owner cc labels/
            ),
            @_,
        );

        my $xml =
          Net::Google::Code::Issue::Util->translate_to_xml( \%args,
            type => 'update' );
        my $ua  = $self->ua;
        my $url = $self->feeds_issues_url . '/' . $self->id . '/comments/full';

        my $request = HTTP::Request->new( 'POST', $url, undef, $xml );
        my $res = $ua->request($request);
        if ( $res->is_success ) {
            $self->load( $self->id );    # let's reload
            return 1;
        }
        else {
            die "try to POST $url failed: "
              . $res->status_line . "\n"
              . $res->content;
        }

    }
}

sub updated {
    my $self = shift;
    my $last_comment = $self->comments->[-1];
    return $last_comment ? $last_comment->date : undef;
}

sub list {
    my $self = shift;
    validate(
        @_,
        {
            q             => { optional => 1, type => SCALAR },
            can           => { optional => 1, type => SCALAR },
            author        => { optional => 1, type => SCALAR },
            id            => { optional => 1, type => SCALAR },
            label         => { optional => 1, type => SCALAR },
            max_results   => { optional => 1, type => SCALAR },
            owner         => { optional => 1, type => SCALAR },
            published_min => { optional => 1, type => SCALAR },
            published_max => { optional => 1, type => SCALAR },
            updated_min   => { optional => 1, type => SCALAR },
            updated_max   => { optional => 1, type => SCALAR },
            start_index   => { optional => 1, type => SCALAR },
        }
    );

    my %args = @_;
    my $url = $self->feeds_issues_url . '/full?';
    require URI::Escape;
    for my $k ( keys %args ) {
        next unless $args{$k};
        my $v = $args{$k};
        $k =~ s/_/-/g;
        $url .= "$k=" . URI::Escape::uri_escape($v) . '&';
    }

    my $ua  = $self->ua;
    my $res = $ua->get($url);
    if ( $res->is_success ) {
        my $feed = XML::FeedPP->new($res->content);
        my @items = $feed->get_item;
        my @list = map {
            my $t = Net::Google::Code::Issue->new(
                loaded_way => 'api',
                map { $_ => $self->$_ }
                  grep { $self->$_ } qw/project email password token/
            );
            $t->_load_from_xml($_);
        } @items;
        return wantarray ? @list : \@list;
    }
    else {
        die "try to get $url failed: "
          . $res->status_line . "\n"
          . $res->content;
    }
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Google::Code::Issue - Google Code Issue

=head1 SYNOPSIS

    use Net::Google::Code::Issue;
    
    my $issue = Net::Google::Code::Issue->new( project => 'net-google-code' );
    $issue->load(42);

=head1 DESCRIPTION

=head1 ATTRIBUTES

=over 4

=item project

project name

=item email, password

user's email and password

=item id

=item status

=item owner 

=item reporter

=item reported

=item merged

=item stars

=item closed

=item cc

=item summary

=item description

=item labels

=item comments

=item attachments

=back

=head1 INTERFACE

=over 4

=item load

=item parse

=item updated

the last comment's date.

=item create
comment, summary, status, owner, cc, labels, files.

=item update
comment, summary, status, owner, merge_into, cc, labels, blocked_on, files.

=item list( q => '', can => '', author => '', id => '', label => '', max_results => '', owner => '', published_min => '', published_max => '', updated_min => '', updated_max => '', start_index => '' )

google's api way to get/search issues

return a list of loaded issues in list context, a ref to the list otherwise.

=item load_comments

google's api way to get and load comments( no scraping is done here )

=item parse_hybrid

when C<$USE_HYBRID> is true, we will try to load issue with the google's official
api, but as the api is not complete, we still need to do scraping to load
something( e.g. attachments ), this method is used to do this.

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
