package Siebel::Srvrmgr::Log::Enterprise;

use Moose 2.0401;
use namespace::autoclean 0.13;
use File::Copy;
use File::Temp qw(tempfile);
use Carp qw(cluck confess);
use String::BOM 0.3 qw(strip_bom_from_string);
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::Log::Enterprise - module to read a Siebel Enterprise log file

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Log::Enterprise;
    my $enterprise_log = Siebel::Srvrmgr::Log::Enterprise->new( { path => File::Spec->catfile('somewhere', 'under', 'the', 'rainbow')} );
	my $next = $enterprise_log->read();

	while (my $line = $next->()) {

        # do something

	}


=head1 DESCRIPTION

A class that knows how to read Siebel Enterprise log files: it knows the header details and how to safely read lines from the file.

=head1 ATTRIBUTES

=head2 path

A string with the complete pathname to the Siebel Enterprise log file.

This attribute is required during object creation.

=cut

has path => ( is => 'ro', isa => 'Str', reader => 'get_path', required => 1 );

=head2 eol

A string identifying the character(s) used as end-of-line in the Siebel Enterprise log file is configured.

This attribute is read-only, this class will automatically try to define the field separator being used.

=cut

has eol => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_eol',
    writer  => '_set_eol',
    default => 0
);

=head2 fs

A string identifying the character(s) used to separate the fields ("fs" stands for "field separator") in the Siebel Enterprise log file is configured.

This attribute is read-only, this class will automatically try to define the EOL being used.

=cut

has fs => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_fs',
    writer  => '_set_fs',
    default => 0
);

=head2 fh

The file handle reference to the Siebel Enterprise log file, after was opened.

=cut

has fh =>
  ( is => 'ro', isa => 'FileHandle', reader => 'get_fh', writer => '_set_fh' );

=head2 filename

The complete path to the temporary filename that this class uses to store the lines of the Siebel Enterprise Log file.

=cut

has filename => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_filename',
    writer => '_set_filename'
);

=head2 header

The header of the Siebel Enterprise log file, without the BOM.

=cut

has header => (
    is      => 'ro',
    isa     => 'Str',
    reader  => 'get_header',
    writer  => '_set_header',
    trigger => \&_check_header
);

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::OS::Unix>

=back

=head1 METHODS

=head2 read

Reads the Siebel Enterprise log file, returning a iterator over the lines of the file.

The method will try to read the file as safely as possible, copying it to a temporary location before reading.

Several attributes will be defined during the file reading, automatically whenever it is possible. In some cases, if unable to
define those attributes, an exception will be raised.

=cut

sub read {

    my $self     = shift;
    my $template = __PACKAGE__ . '_XXXXXX';
    $template =~ s/\:{2}/_/g;

# :TODO:09/18/2015 09:14:14 PM:: insecure, must check if it not possible to keep the file handle, copy the file
# over and use seek to go back to the beginning of the file
    my ( $fh, $filename ) = tempfile($template);
    close($fh);
    copy( $self->get_path(), $filename );

    open( $fh, '<:encoding(utf8)', $filename )
      or die "Cannot read $filename: $!";
    $self->_set_filename($filename);
    my $header = <$fh>;

    # remove BOM, see https://rt.cpan.org/Public/Bug/Display.html?id=101175
    $header = strip_bom_from_string($header);
    $header =~ s/^\x{feff}//;

    # don't know which EOL is available
    $header =~ tr/\012//d;
    $header =~ tr/\015//d;

    $self->_set_fh($fh);

    $self->_set_header($header);
    my $eol = $self->get_eol();

    return sub {

        local $/ = $eol;
        return <$fh>;

      }

}

=head2 DEMOLISH

During object termination, the associated temporary log file will be closed and removed automatically, if available.

=cut

sub DEMOLISH {

    my $self = shift;

    my $fh = $self->get_fh();

    if ( defined($fh) ) {

        close($fh);

    }

    my $file = $self->get_filename();

    if ( ( defined($file) ) and ( -e $self->get_filename() ) ) {

        unlink $file or cluck "Could not remove $file: $!";

    }

}

sub _check_header {

    my $self = shift;
    my @parts = split( /\s/, $self->get_header() );
    $self->_define_eol( $parts[0] );
    $self->_define_fs( $parts[9], $parts[10] );

}

sub _define_fs {

    my $self             = shift;
    my $field_del_length = shift;
    my $field_delim      = shift;
    my $num;

    for my $i ( 1 .. 4 ) {

        my $temp = chop($field_del_length);
        if ( $temp != 0 ) {

            $num .= $temp;

        }
        else {

            last;

        }

    }

    confess "field delimiter unimplemented" if ( $num > 1 );

# converting hex number to the corresponding character as defined in ASCII table
    $self->_set_fs( chr( unpack( 's', pack 's', hex($field_delim) ) ) );

}

sub _define_eol {

    my $self = shift;
    my $part = shift;
    my $eol  = substr $part, 0, 1;

  CASE: {

        if ( $eol eq '2' ) {

            $self->_set_eol("\015\012");
            last CASE;

        }

        if ( $eol eq '1' ) {

            $self->_set_eol("\012");
            last CASE;

        }

        if ( $eol eq '0' ) {

            $self->_set_eol("\015");
            last CASE;

        }
        else {

            confess "EOL is custom, don't know what to use!";

        }

    }

}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
