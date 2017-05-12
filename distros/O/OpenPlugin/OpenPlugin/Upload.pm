package OpenPlugin::Upload;

# $Id: Upload.pm,v 1.13 2003/04/03 01:51:24 andreychek Exp $

use strict;
use base                    qw( OpenPlugin::Plugin );
use Data::Dumper            qw( Dumper );

$OpenPlugin::Upload::VERSION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'upload' }

*get = \*get_incoming;

sub get_incoming {
    my ( $self, $name ) = @_;
    unless ( $name ) {
        return ( ref $self->state->{upload} eq 'HASH' )
                 ? keys %{ $self->state->{upload} } : ();
    }
    if ( ref $self->state->{upload}{ $name } eq 'ARRAY' and wantarray ) {
        return @{ $self->state->{upload}{ $name } };
    }

    return $self->state->{upload}{ $name };
}

sub set_incoming {
    my ( $self, $upload ) = @_;

    return undef unless ( $upload->{ name } );

    return $self->state->{ upload }{ $upload->{ name } } = $upload;

}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Upload - Handle file uploads

=head1 SYNOPSIS

 my $OP = OpenPlugin->new();

 my @uploads = $OP->upload->get_incoming()

 my $upload = $OP->upload->get_incoming( $name );

=head1 METHODS

B<get_incoming( [ $name ] )>

B<get( [ $name ] )>

With no arguments, this returns a list of filenames mapping to the files
uploaded by the client. If you pass in C<$name> then you get a hashref
containing the keys:

=over 4

=item * name

The name given in the upload field.

=item * type

The content-type of the file.

=item * size

The size of the file.

=item * filehandle

The file handle of the file.

=item * filename

The real name of the file being uploaded.

=back

B<set_incoming( \%upload )>

Associates the L<OpenPlugin::Upload> C<%upload> hash with C<$upload->{ name }>.

See C<get_incoming> for a list of valid parameters this function accepts.

=head1 TO DO

See the TO DO section of the <OpenPlugin::Request> plugin.

=head1 BUGS

None known.

=head1 SEE ALSO

See the individual driver documentation for settings and parameters specific to
that driver.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
