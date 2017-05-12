package Net::Google::Code::Download;

use Any::Moose;
use Params::Validate qw(:all);
use Scalar::Util qw/blessed/;

with 'Net::Google::Code::TypicalRoles';

has 'project' => (
    isa      => 'Str',
    is       => 'rw',
);

has 'name' => (
    isa => 'Str',
    is  => 'rw',
);

has 'size' => (
    isa => 'Str',
    is  => 'rw',
);

has 'download_url' => (
    isa => 'Str',
    is  => 'rw',
);

has 'count' => (
    isa => 'Int',
    is  => 'rw',
);

has 'labels' => (
    isa => 'ArrayRef[Str]',
    is  => 'rw',
);

has 'checksum' => (
    isa => 'Str',
    is  => 'rw',
);

has 'uploaded_by' => (
    isa => 'Str',
    is  => 'rw',
);

has 'uploaded' => (
    isa => 'Str',
    is  => 'rw',
);

sub load {
	my $self = shift;
    my $name = shift || $self->name;
    die "current object doesn't have name and load() is not passed a name either"
      unless $name;
	
	# http://code.google.com/p/net-google-code/downloads/detail?name=Net-Google-Code-0.01.tar.gz
	
    my $content =
      $self->fetch( $self->base_url . "downloads/detail?name=$name" );
	
    $self->name( $name ) unless $self->name && $self->name eq $name;
    return $self->parse( $content );
}

sub parse {
    my $self = shift;
    my $tree = shift;
    my $need_delete = not blessed $tree;
    $tree = $self->html_tree( html => $tree ) unless blessed $tree;

    my $entry;
    my $uploaded = $tree->look_down(class => 'date')->attr('title');
    $self->uploaded( $uploaded ) if $uploaded;

    my @labels_tag = $tree->look_down( class => 'label' );
    my @labels;
    for my $tag ( @labels_tag ) {
        push @labels, $tag->as_text;
    }
    $self->labels( \@labels );

    # parse uploaded_by and download count.
    # uploaded and labels are kind of special, so they're handleed above
    my ($meta) = $tree->look_down( id => 'issuemeta' );
    my @meta = $meta->find_by_tag_name('tr');
    for my $meta (@meta) {

        my ( $key, $value );
        $key = $meta->find_by_tag_name('th');
        next unless $key;
        $key = $key->as_text;

        my $td = $meta->find_by_tag_name('td');
        next unless $td;
        $value = $td->as_text;
        if ( $key =~ /Uploaded.*?by/ ) {
            $self->uploaded_by($value);
        }
        elsif ( $key =~ /Downloads/ ) {
            $self->count($value);
        }
    }

    # download_url and size
    my $desc  = $tree->look_down( class => 'vt issuedescription' );
    my $box_inner = $desc->look_down( class => 'box-inner' );
    $self->download_url( $box_inner->content_array_ref->[0]->attr('href') );

    my $size = $box_inner->content_array_ref->[3];
    $size =~ s/^\D+//;
    $size =~ s/\s+$//;
    $self->size( $size ) if $size;

    # checksum
    my $span = $desc->find_by_tag_name('span');
    my $checksum = $span->content_array_ref->[0];
    if ( $checksum =~ /^SHA1 Checksum:\s+(\w+)/ ) {
        $self->checksum( $1 );
    }
    $tree->delete if $need_delete;
}

sub BUILDARGS {
    my $class        = shift;
    my %args;
    if ( @_ % 2 && ref $_[0] eq 'HASH' ) {
        %args = %{$_[0]};
    }
    else {
        %args = @_;
    }

    my %translations = ( filename => 'name', 'downloadcount' => 'count' );
    for my $key ( keys %translations ) {
        if ( exists $args{$key} ) {
            $args{ $translations{$key} } = $args{$key};
        }
    }
    return $class->SUPER::BUILDARGS(%args);
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Net::Google::Code::Download - Google Code Download

=head1 SYNOPSIS

    use Net::Google::Code::Download;
    
    my $issue = Net::Google::Code::Download->new( project => 'net-google-code' );
    $issue->load( 'Net-Google-Code-0.01.tar.gz' );

=head1 DESCRIPTION

=head1 INTERFACE

=over 4

=item load

=item parse

=item project

=item name

=item size

=item download_url

=item count

=item labels

=item checksum

=item uploaded_by

=item uploaded

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
