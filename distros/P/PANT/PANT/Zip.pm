# PANT::Zip - Provide support for zip archives

package PANT::Zip;

use 5.008;
use strict;
use warnings;
use Carp;
use Cwd;
use XML::Writer;
use Archive::Zip  qw( :ERROR_CODES :CONSTANTS );;
use Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PANT ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.04';


sub new {
    my($clsname, $writer, $zipname, @rest) =@_;
    my $self = { 
	writer=>$writer,
	name=>$zipname,
	zip=>Archive::Zip->new(),
	compression=>9,
	@rest,
    };
    bless $self, $clsname;
    return $self;
}

sub Compression {
    my $self = shift;
    my $oval = $self->{compression};
    $self->{compression} = shift;
    return $oval;
}

sub AddFile {
    my($self, $name, $newname) = @_;
    my $writer = $self->{writer};
    my $zip = $self->{zip};
    my $extra = $newname ? " as $newname" : "";
    $writer->dataElement('li', "Adding file $name$extra to zip archive $self->{name}\n");
    return 1 if ($self->{dryrun});
    return $zip->addFile($name, $newname);
}

sub AddTree {
    my($self, $name, $newname, $func) = @_;
    my $writer = $self->{writer};
    my $zip = $self->{zip};
    my $extra = $newname ? " as $newname" : "";
    $writer->dataElement('li', "Adding tree $name$extra to zip archive $self->{name}\n");
    return 1 if ($self->{dryrun});
    return $zip->addTree($name, $newname, $func) == AZ_OK;
}

sub Close {
    my($self) = @_;
    my $writer = $self->{writer};
    my $zip = $self->{zip};
    foreach my $zm ($zip->members()) {
	$zm->desiredCompressionLevel($self->{compression});
    }
    $writer->dataElement('li', "Writing out zip file $self->{name}\n");
    return 1 if ($self->{dryrun});
    return $zip->writeToFileNamed($self->{name}) == AZ_OK;
}

1;
__END__

=head1 NAME

PANT::Zip - PANT support for zipping up files

=head1 SYNOPSIS

  use PANT;

  $zipper = Zip("foo.zip);
  $zipper->AddFile("test-thing", "thing");
  $zipper->AddTree("buildlib", "lib");
  $zipper->Compression(9);
  $zipper->Close();  

=head1 ABSTRACT

  This is part of a module to help construct automated build environments.
  This part is for help zipping up files.

=head1 DESCRIPTION

This module is part of a set to help run automated
builds of a project and to produce a build log. This part
is designed to provide support for zipping up files as needed.

It is really just a thin wrapping layer around Archive::Zip.

=head1 EXPORTS

None

=head1 METHODS

=head2 new($xml, "foo.zip");

Constructor for a test object. Requires an XML::Writer object and a
zip name as parameters, which it will use for subsequent log
construction. The PANT function ZIP calls this constructor with the
current xml stream, and passes on the arguments for you. So normally
you would call it via the accessor.

=head2 AddFile(file, newname)

Adds the given file to the zip, optionally renaming it on the way if a
2nd argument is given.

=head2 AddTree(directory, dirname, func)

Adds the given directory tree to the zip, recursively. If the newname
is given, then the base directory will be renamed to that. Finally the
3rd parameter if present is a subroutine reference to be called for
each prospective file. It can examine $_ and return true/false to add
it.

=head2 Compression(no)

Set the overall archive compression number. This is a number between 0 and 9,
0 being no compression, and 9 being maximum compression.

=head1 SEE ALSO

Uses Archive::Zip for the zip operations.
Makes use of XML::Writer to construct the build log.


=head1 AUTHOR

Julian Onions, E<lt>julianonions@yahoo.nospam-co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Julian Onions

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 


=cut
