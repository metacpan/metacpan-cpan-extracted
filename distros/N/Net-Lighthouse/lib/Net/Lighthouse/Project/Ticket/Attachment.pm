package Net::Lighthouse::Project::Ticket::Attachment;
use Any::Moose;
use Params::Validate ':all';
use Net::Lighthouse::Util;

# read only attr
has [ 'created_at' ] => (
    isa => 'DateTime',
    is  => 'ro',
);

has [ 'width', 'height', 'size', 'uploader_id', 'id', ] => (
    isa => 'Maybe[Int]',
    is  => 'ro',
);

has [ 'content_type', 'filename', 'url', 'code' ] => (
    isa => 'Str',
    is  => 'ro',
);

# make tests happy, added Test::MockObject
if ( $INC{'Moose.pm'} ) {
    require Moose::Util::TypeConstraints;
    Moose::Util::TypeConstraints::class_type( 'LWP::UserAgent' );
    Moose::Util::TypeConstraints::class_type( 'Test::MockObject' );
}
else {
    require Mouse::Util::TypeConstraints;
    Mouse::Util::TypeConstraints::class_type( 'LWP::UserAgent' );
    Mouse::Util::TypeConstraints::class_type( 'Test::MockObject' );
}

has 'ua' => ( is => 'ro', isa => 'LWP::UserAgent|Test::MockObject', );

has 'content' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $ua   = $self->ua;
        my $res  = $ua->get( $self->url );
        if ( $res->is_success ) {
            return $res->content;
        }
        else {
            return;
        }
    }
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;

sub load_from_xml {
    my $self = shift;
    my $ref = Net::Lighthouse::Util->translate_from_xml(shift);

    # dirty hack: some attrs are read-only, and Mouse doesn't support
    # writer => '...'
    for my $k ( keys %$ref ) {
        $self->{$k} = $ref->{$k};
    }
    return $self;
}

1;

__END__

=head1 NAME

Net::Lighthouse::Project::Ticket::Attachment - Project Ticket Attachment

=head1 SYNOPSIS

    use Net::Lighthouse::Project::Ticket::Attachment;

=head1 ATTRIBUTES

=over 4

=item created_at

ro, DateTime, UTC based

=item width, height, size, uploader_id, id

ro, Maybe Int

=item content_type, filename, url, code

ro, Str

=item ua

ro, LWP::UserAgent

=item content

ro, Str

=back

=head1 INTERFACE

=over 4

=item load_from_xml( $hashref | $xml_string )

load ticket attachment, return loaded ticket attachment

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

