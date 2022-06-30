package Net::Easypost::Label;
$Net::Easypost::Label::VERSION = '0.23';
use Moo;
with qw(Net::Easypost::Resource);

use Carp qw(croak);
use Net::Easypost::Request;

has 'tracking_code' => (
    is       => 'ro',
    required => 1
);

has 'filename' => (
    is       => 'ro',
    required => 1,
);

has 'filetype' => (
    is      => 'ro',
    lazy    => 1,
    default => 'image/png',
);

has 'url' => (
   is        => 'ro',
   predicate => 1,
   required  => 1,
);

has 'rate' => (
   is  => 'ro',
);

has 'image' => (
    is        => 'ro',
    lazy      => 1,
    predicate => 1,
    default   => sub {
        my ($self) = @_;

        croak "Cannot retrieve image for " . $self->filename . " without URL"
            unless $self->has_url;

        return $self->requester->get($self->url);
    }
);

sub _build_operation { '' }
sub _build_role { 'label' }
sub _build_fieldnames { 
    return [qw/tracking_code url filetype filename/];
}

sub save {
    my ($self) = @_;

    $self->image
        unless $self->has_image;

    open my $fh, ">:raw", $self->filename
        or croak "Couldn't save " . $self->filename . ": $!";

    print {$fh} $self->image;
    close($fh);

    return 1;
}

sub clone {
   my $self = shift;

   return Net::Easypost::Label->new(
      map { $_ => $self->$_ }
         grep { defined $self->$_ }
            'id', @{ $self->fieldnames }
   );
}

sub serialize {
   my ($self) = @_;

   return {
      map  { $self->role . "[$_]" => $self->$_ }
      grep { defined $self->$_ }
         @{ $self->fieldnames }
   };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Easypost::Label

=head1 VERSION

version 0.23

=head1 SYNOPSIS

Net::Easypost::Label->new

=head1 NAME 

Net::Easypost::Label

=head1 ATTRIBUTES

=over 4 

=item tracking_code

The carrier generated tracking code for this label.

=item filename

The filename the Easypost API used to create the label file. (Also used
for local storage.)

=item filetype

The file type for the image data. Defaults to 'image/png'

=item url

The URL from which to download the label image.

=item rate

The chosen rate for this Label

has rate => (
   is  => 'ro',
);

=item image

This is the label image data.  It lazily downloads this information if a
URL is defined. It currently uses a L<Net::Easypost::Request> role to
get the data from the Easypost service.

=back

=head1 METHODS

=over 4 

=item _build_fieldnames

=item _build_role

=item save

Store the label image locally using the filename in the object. This will typically be
in the current working directory of the caller.

=item clone 

returns a new Net::Easypost::Label object that is a deep-copy of this object

=item serialize

serialized format for Label objects

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>, Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
