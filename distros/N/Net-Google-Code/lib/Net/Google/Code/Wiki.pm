package Net::Google::Code::Wiki;

use Any::Moose;
use Params::Validate qw(:all);
with 'Net::Google::Code::TypicalRoles';

has 'project' => (
    isa      => 'Str',
    is       => 'rw',
);

has 'name' => (
    isa => 'Str',
    is  => 'rw',
);

has 'source' => (
    isa => 'Str',
    is  => 'rw',
);

has 'content' => (
    isa => 'Str',
    is  => 'rw',
);

has 'updated' => (
    isa => 'Str',
    is  => 'rw',
);

has 'updated_by' => (
    isa => 'Str',
    is  => 'rw',
);

has 'labels' => (
    isa => 'ArrayRef[Str]',
    is  => 'rw',
);

has 'summary' => (
    isa => 'Str',
    is  => 'rw',
);

has 'comments' => (
    isa => 'ArrayRef[Net::Google::Code::Wiki::Comment]',
    is  => 'rw',
);

sub load_source {
    my $self = shift;
    die "current object doesn't have name" unless $self->name;
    my $source =
      $self->fetch( $self->base_svn_url . 'wiki/' . $self->name . '.wiki' );
    $self->source($source);
    return $self->parse_source;
}

sub parse_source {
    my $self = shift;
    my @meta = grep { /^#/ } split /\n/, $self->source;
    for my $meta (@meta) {
        chomp $meta;
        if ( $meta =~ /summary\s+(.*)/ ) {
            $self->summary($1);
        }
        elsif ( $meta =~ /labels\s+(.*)/ ) {
            my @labels = split /,\s*/, $1;
            $self->labels( \@labels );
        }
    }
}

sub load {
    my $self = shift;
    my $name = shift || $self->name;
    die "current object doesn't have name and load() is not passed a name either"
      unless $name;

    # http://code.google.com/p/net-google-code/wiki/TestPage
    my $content = $self->fetch( $self->base_url . 'wiki/' . $name );

    $self->name($name) unless $self->name && $self->name eq $name;
    $self->load_source;
    return $self->parse($content);
}

sub parse {
    my $self    = shift;
    my $tree    = shift;
    $tree = $self->html_tree( html => $tree ) unless blessed $tree;

    my $wiki = $tree->look_down( id => 'wikimaincol' );
    my $updated =
      $wiki->find_by_tag_name('td')->find_by_tag_name('span')->attr('title');
    my $updated_by =
      $wiki->find_by_tag_name('td')->find_by_tag_name('a')->as_text;
    $self->updated($updated)       if $updated;
    $self->updated_by($updated_by) if $updated_by;

    $self->content( $tree->content_array_ref->[-1]->as_HTML );

    my @comments = ();
    my @comments_element = $tree->look_down( class => 'artifactcomment' );
    for my $element (@comments_element) {
        next unless $element->look_down( class => 'commentcontent' );
        require Net::Google::Code::Wiki::Comment;
        my $comment = Net::Google::Code::Wiki::Comment->new;
        $comment->parse($element);
        push @comments, $comment;
    }
    $self->comments( \@comments );
    $tree->delete;
    return 1;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Net::Google::Code::Wiki - Google Code Wiki

=head1 SYNOPSIS

    use Net::Google::Code::Wiki;
    
    my $wiki = Net::Google::Code::Wiki->new(
        project => 'net-google-code',
        name    => 'TestPage',
    );
    $wiki->load;
    $wiki_entry->source;

=head1 INTERFACE

=over 4

=item load

=item parse

=item load_source

=item parse_source

=item project

=item name

=item source

=item summary

=item labels

=item content

=item updated_by

=item updated

=item comments

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

