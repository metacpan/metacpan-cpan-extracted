package Net::Easypost::Parcel;
$Net::Easypost::Parcel::VERSION = '0.21';
use Moo;
with qw(Net::Easypost::PostOnBuild);
with qw(Net::Easypost::Resource);

has [qw/length width height weight predefined_package/] => (
    is => 'rw',
);

sub _build_fieldnames { 
    return [qw/length width height weight predefined_package/];
}
sub _build_role      { 'parcel'   }
sub _build_operation { '/parcels' }

sub clone {
    my ($self) = @_;

    return Net::Easypost::Parcel->new(
        map  { $_ => $self->$_ }
        grep { defined $self->$_ }
           'id', @{ $self->fieldnames }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Easypost::Parcel

=head1 VERSION

version 0.21

=head1 SYNOPSIS

Net::Easypost::Parcel->new

=head1 NAME 

Net::Easypost::Parcel

=head1 ATTRIBUTES

=over 4 

=item length

The length of the parcel in inches.

=item width

The width of the parcel in inches.

=item height

The height of the parcel in inches.

=item weight

The weight of the parcel in ounces. (There are 16 ounces in a U.S. pound.)

=item predefined_package

A carrier specific flat-rate package name. See L<https://www.easypost.com/docs/api/#predefined-packages> for these.

=back

=head1 METHODS 

=over 4 

=item _build_fieldnames 

Attributes that make up an Parcel, from L<Net::Easypost::Resource>

=item _build_role

Prefix to data when POSTing to the Easypost API about Parcel objects

=item _build_operation

Base API endpoint for operations on Parcel objects

=item clone 

returns a new Net::Easypost::Parcel object that is a deep-copy of this object

=back

=head1 AUTHOR

Mark Allen <mrallen1@yahoo.com>, Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Allen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
