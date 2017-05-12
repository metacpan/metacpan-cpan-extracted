package Net::Google::Code::Issue::Comment;
use Any::Moose;
use Net::Google::Code::Issue::Attachment;
use Net::Google::Code::Issue::Util;
use Net::Google::Code::DateTime;
with 'Net::Google::Code::Role::HTMLTree';
extends 'Net::Google::Code::Issue::Base';
with 'Net::Google::Code::Role::Authentication';
use Params::Validate ':all';

use XML::FeedPP;


has 'updates' => ( isa => 'HashRef', is => 'rw', default => sub { {} } );
has 'author'  => ( isa => 'Str',     is => 'rw' );
has 'content' => ( isa => 'Str',     is => 'rw' );
has 'sequence' => ( isa => 'Int', is => 'rw' );
has 'date' => ( isa => 'DateTime', is => 'rw' );
has 'attachments' => (
    isa     => 'ArrayRef[Net::Google::Code::Issue::Attachment]',
    is      => 'rw',
    default => sub { [] },
);

has 'issue_id' => (
    isa      => 'Int',
    is       => 'rw',
);

sub parse {
    my $self    = shift;
    my $element = shift;
    my $need_delete = not blessed $element;
    $element = $self->html_tree( html => $element ) unless blessed $element;

    my $author  = $element->look_down( class => 'author' );
    my @a       = $author->find_by_tag_name('a');
    $self->sequence( $a[0]->content_array_ref->[0] );
    $self->author( $a[1]->content_array_ref->[0] );
    $self->date(Net::Google::Code::DateTime->new_from_string( $element->look_down( class => 'date' )->attr('title') ));
    my $content = $element->find_by_tag_name('pre')->as_text;
    $content =~ s/^\s+//;
    $content =~ s/\s+$//;
    $content =~ s/\r\n/\n/g;
    $self->content($content)
      unless $content eq '(No comment was entered for this change.)';

    my $updates = $element->look_down( class => 'updates' );
    if ($updates) {
        my $box_inner = $element->look_down( class => 'box-inner' );
        my $content = $box_inner->content_array_ref;
        while (@$content) {
            my $tag   = shift @$content;
            my $value = shift @$content;
            if ( ref $value && $value->as_HTML =~ m!<br />! ) {
                # this happens when there's no value for $tag
                $value = '';
            }
            else {
                shift @$content;    # this is for the <br>
            }

            my $key = $tag->content_array_ref->[0];
            $key   =~ s/:$//;
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;

            if ( $key eq 'Labels' ) {

               # $value here is like "-Pri-2 -Area-Unknown Pri-3 Area-BrowserUI"
                my @items = split /\s+/, $value;
                for my $value (@items) {
                    push @{$self->updates->{labels}}, $value;
                }
            }
            else {
                $self->updates->{ lc $key } = $value;
            }
        }

    }

    my $att_tag = $element->look_down( class => 'attachments' );
    my @attachments;

    @attachments =
      Net::Google::Code::Issue::Attachment->parse_attachments($att_tag)
      if $att_tag;
    $self->attachments( \@attachments );

    $self->delete if $need_delete;
    return 1;
}

sub parse_hybrid {
    my $self    = shift;
    my $element = shift;
    my $need_delete = not blessed $element;
    $element = $self->html_tree( html => $element ) unless blessed $element;
    my $updates = $element->look_down( class => 'updates' );
    if ($updates) {
        my $box_inner = $element->look_down( class => 'box-inner' );
        my $content = $box_inner->content_array_ref;
        while (@$content) {
            my $tag   = shift @$content;
            my $value = shift @$content;
            if ( ref $value && $value->as_HTML =~ m!<br />! ) {
                # this happens when there's no value for $tag
                $value = '';
            }
            else {
                shift @$content;    # this is for the <br>
            }

            my $key = $tag->content_array_ref->[0];
            $key   =~ s/:$//;
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;

            if ( $key ne 'Labels' ) {
                $self->updates->{ lc $key } = $value;
            }
        }
    }

    my $att_tag = $element->look_down( class => 'attachments' );
    my @attachments;

    @attachments =
      Net::Google::Code::Issue::Attachment->parse_attachments($att_tag)
      if $att_tag;
    $self->attachments( \@attachments );
    $element->delete if $need_delete;
    return 1;
}

sub _load_from_xml {
    my $self  = shift;
    my $ref =
      Net::Google::Code::Issue::Util->translate_from_xml( shift,
        type => 'comment' );

    for my $k ( keys %$ref ) {
        if ( $self->can($k) ) {
            $self->{$k} = $ref->{$k};
        }
    }
    return $self;
}

sub list {
    my $self = shift;
    validate( @_, { max_results => { optional => 1, type => SCALAR }, } );

    my %args = ( max_results => 1_000_000_000, @_ );

    my $url = $self->feeds_issues_url . '/' . $self->issue_id .
        '/comments/full?';
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
            my $t = Net::Google::Code::Issue::Comment->new(
                map { $_ => $self->$_ }
                grep { $self->$_ } qw/project email password token issue_id/
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

Net::Google::Code::Issue::Comment - Issue's Comment

=head1 DESCRIPTION

=head1 ATTRIBUTES

=over 4

=item project

project name

=item email, password

user's email and password

=item issue_id

=item sequence

sequence number, initial comment( when you create an issue ) has sequence 0

=item date

=item content

=item author

=item updates

HashRef that reflects updates

=item attachments

=back

=head1 INTERFACE

=over 4

=item parse( HTML::Element or html segment string )

parse format like the following:

 <td class="vt issuecomment">
 
 
 
 <span class="author">Comment <a name="c18"
 href="#c18">18</a>
 by
 <a href="/u/jsykari/">jsykari</a></span>,
 <span class="date" title="Wed Sep  3 04:44:39 2008">Sep 03, 2008</span>
<pre>
<b>haha</b>

</pre>
 
 <div class="attachments">
 
 <table cellspacing="0" cellpadding="2" border="0">
 <tr><td rowspan="2" width="24"><a href="http://chromium.googlecode.com/issues/attachment?aid=-1323983749556004507&amp;name=proxy_settings.png" target="new"><img width="16" height="16" src="/hosting/images/generic.gif" border="0" ></a></td>
 <td><b>proxy_settings.png</b></td></tr>
 <tr><td>14.3 KB
  
 <a href="http://chromium.googlecode.com/issues/attachment?aid=-1323983749556004507&amp;name=proxy_settings.png">Download</a></td></tr>
 </table>
 
 </div>

 <div class="updates">
 <div class="round4"></div>
 <div class="round2"></div>
 <div class="round1"></div>
 <div class="box-inner">
 <b>Cc:</b> thatan...@google.com<br><b>Status:</b> Available<br><b>Labels:</b> Mstone-X<br>
 </div>
 <div class="round1"></div>
 <div class="round2"></div>
 <div class="round4"></div>
 </div>
 
 </td>

=item list

google's api way to get list of comments
return a list of loaded( no scraping is done here ) comments in list context,
a ref to the list otherwise.

=item parse_hybrid

when C<$Net::Google::Code::Issue::USE_HYBRID> is true,
we will try to load comments with the google's official api,
but as the api is not complete, we still need to do scraping to load
something( e.g. attachments ), this method is used to do this.

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

