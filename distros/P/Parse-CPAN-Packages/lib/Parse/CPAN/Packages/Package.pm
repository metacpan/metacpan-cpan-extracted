package Parse::CPAN::Packages::Package;
use Moo;

use PPI;
use Types::Standard qw( InstanceOf Str );

has 'package'      => ( is => 'rw', isa => Str );
has 'version'      => ( is => 'rw', isa => Str );
has 'prefix'       => ( is => 'rw', isa => Str );
has 'distribution' => ( is => 'rw', isa => InstanceOf ['Parse::CPAN::Packages::Distribution'] );

sub filename {
    my ( $self )     = @_;
    my $distribution = $self->distribution;
    my @filenames    = $distribution->list_files;
    my $package_file = $self->package;
    $package_file =~ s{::}{/}g;
    $package_file .= '.pm';
    my ( $filename ) = grep { /$package_file$/ } sort { length( $a ) <=> length( $b ) } @filenames;
    return $filename;
}

sub file_content {
    my ( $self ) = @_;
    my $filename = $self->filename;
    my $content  = $self->distribution->get_file_from_tarball( $filename );
    return $content;
}

sub subs {
    my ( $self ) = @_;

    my $document = PPI::Document->new( \( $self->file_content ) );
    my $subs = $document->find('PPI::Statement::Sub');

    return map { $_->name } @{$subs};
}

sub has_matching_sub {
    my ( $self, $sub_regex ) = @_;

    my @matching_subs = grep { $_ =~ $sub_regex } $self->subs;

    return @matching_subs;
}

1;

__END__

=head1 NAME

Parse::CPAN::Packages::Package

=head1 DESCRIPTION

Represents a CPAN Package. Note: The functions filename and file_content work
only if a mirror directory was supplied for parsing or the package file was
situated inside a cpan mirror structure.

=head1 METHODS

=head2 filename

Tries to guess the name of the file containing this package by looking through
the files contained in the distribution it belongs to.

=head2 file_content

Tries to return the contents of the file returned by filename().

=head2 subs

Experimental function. Tries to return the names of all subs in the package.

=head2 has_matching_sub( $regex )

Experimental function. Tries to see if any sub name in the package matches the
regex.
