package Statistics::R::IO::RData;
# ABSTRACT: Supply object methods for RData files
$Statistics::R::IO::RData::VERSION = '1.0001';
use 5.010;

use Class::Tiny::Antlers;

extends 'Statistics::R::IO::Base';

use Statistics::R::IO::REXPFactory;
use Carp;

use namespace::clean;


sub read {
    my $self = shift;
    
    my $data = $self->_read_and_uncompress;
    
    if (substr($data, 0, 5) ne "RDX2\n") {
        croak 'File does not start with the RData magic number: ' .
            unpack('H*', substr($data, 0, 5));
    }

    my ($value, $state) = @{Statistics::R::IO::REXPFactory::unserialize(substr($data, 5))};
    croak 'Could not parse RData file' unless $state;
    croak 'Unread data remaining in the RData file' unless $state->eof;
    Statistics::R::IO::REXPFactory::tagged_pairlist_to_rexp_hash $value;
}

    
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::IO::RData - Supply object methods for RData files

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::IO::RData;
    
    my $rdata = Statistics::R::IO::RData->new('.RData');
    my %r_workspace = $rdata->read;
    while (my ($var_name, $value) = each %r_workspace) {
        print $var_name, $value;
    }
    $rdata->close;

=head1 DESCRIPTION

C<Statistics::R::IO::RData> provides an object-oriented interface to
parsing RData files. RData files store a serialization of a collection
of I<named> objects, typically a workspace. These files are created in
R using the C<save> function and are typically named with the
C<.RData> file extension. (Contents of the R workspace can also be
saved automatically on exit to the file named F<.RData>, which is by
default automatically read in on startup.)

=head1 METHODS

C<Statistics::R::IO::RData> inherits from L<Statistics::R::IO::Base>
and provides an implementation for the L</read> method that parses
RData files.

=over

=item read

Reads a contents of the filehandle and returns a hash whose keys are
the names of objects stored in the file with corresponding values as
L<Statistics::R::REXP> instances.

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
