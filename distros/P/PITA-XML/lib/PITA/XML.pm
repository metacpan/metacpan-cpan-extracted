package PITA::XML;

# See POD at end for docs.

use 5.006;
use strict;
use Carp                    ();
use Params::Util            ();
use IO::File                ();
use IO::String              ();
BEGIN {
	# Temporary Hack:
	# IO::String looks like a duck and quacks liks a duck, but we need it
	# to be a real duck. So lets make it a duck (if it didn't turn into a
	# real duck while we weren't looking.)
	unless ( @IO::String::ISA ) {
		@IO::String::ISA = qw{ IO::Handle IO::Seekable };
	}
}
use File::ShareDir          ();
use XML::SAX::ParserFactory ();

# Optionally load the schema validator
BEGIN {
	local $@;
	eval {
		require XML::Validator::Schema;
	};
}

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.52';
}

# The XML Schema File
# Locate the Schema at use-time (instead of compile-time) and
# allow the specification of a custom schema.
use vars qw{$SCHEMA};
$SCHEMA ||= File::ShareDir::dist_file('PITA-XML', 'pita-xml.xsd');

# While in development, use a version-specific namespace.
# In theory, this ensures documents are only truly valid with the
# version they were created with.
use constant XMLNS => "http://ali.as/xml/schema/pita-xml/$VERSION";

# The list of core schemes
use vars qw{%SCHEMES};
BEGIN {
	%SCHEMES = (
		'perl5'       => 1,
		'perl5.make'  => 1,
		'perl5.build' => 1,
		'perl6'       => 1,
	);
}

# Load the various classes
use PITA::XML::Storable  ();
use PITA::XML::Command   ();
use PITA::XML::Test      ();
use PITA::XML::Request   ();
use PITA::XML::Platform  ();
use PITA::XML::File      ();
use PITA::XML::Guest     ();
use PITA::XML::Install   ();
use PITA::XML::Report    ();
use PITA::XML::SAXParser ();
use PITA::XML::SAXDriver ();





#####################################################################
# Main Methods

sub validate {
	my $class = shift;
	my $fh    = $class->_FH(shift);

	# Make schema validation dependant on module availability
	$XML::Validator::Schema::VERSION or return 1;

	# Create the validator
	my $parser = XML::SAX::ParserFactory->parser(
		Handler => XML::Validator::Schema->new(
			file => $SCHEMA,
		),
	);

	# Validate the document
	$parser->parse_file( $fh );

	1;
}




#####################################################################
# Support Methods

sub _FH {
	my $class = shift;
	my $file  = shift;
	if ( Params::Util::_SCALAR($file) ) {
		$file = IO::String->new( $file );
	}
	if ( Params::Util::_INSTANCE($file, 'IO::Handle') ) {
		if ( $file->can('seek') ) {
			# Reset the file handle
			$file->seek( 0, 0 ) or Carp::croak(
				'Failed to reset file handle (seek to 0)',
			);
			return $file;
		}
		Carp::croak('IO::Handle is not seekable');
	}
	unless ( defined $file and ! ref $file and length $file ) {
		Carp::croak('Did not provide a file name or handle');
	}
	unless ( $file and -f $file and -r _ ) {
		Carp::croak('Did not provide a readable file name');
	}
	my $fh = IO::File->new( $file );
	unless ( $fh ) {
		 Carp::croak("Failed to open PITA::XML file '$file'");
	}
	$fh;
}

sub _OUTPUT {
	my ($class, $object, $name) = @_;

	# If provided as a param, clean it up
	if ( exists $object->{$name} ) {
		# Convert from array to scalar ref
		if ( Params::Util::_ARRAY0($object->{$name}) ) {
			# Clean up newlines and merge into SCALAR
			my $param = $object->{$name};
			foreach my $i ( 0 .. $#$param ) {
				$param->[$i] =~ s/[\012\015]+$/\n/;
			}
			$param = join '', @$param;
			$object->{$name} = \$param;
		}
	}

	# Check for scalarness
	Params::Util::_SCALAR0($object->$name()) ? 1 : undef;
}

sub _SCHEME {
	my $class  = shift;
	my $string = Params::Util::_STRING(shift) or return undef;
	($SCHEMES{$string} or $string =~ /x_/) ? $string : undef;
}

sub _MD5SUM {
	my $class  = shift;
	my $md5sum = Params::Util::_STRING(shift) or return undef;
	($md5sum =~ /^[0-9a-f]{32}$/i) ? lc($md5sum) : undef;
}

sub _DISTNAME {
	my $class    = shift;
	my $distname = Params::Util::_STRING(shift) or return undef;
	($distname =~ /^[a-z]\w*(?:\-[a-z]\w*)+$/is) ? $distname : undef;
}

sub _GUID {
	my $class = shift;
	my $guid  = Params::Util::_STRING(shift) or return undef;
	($guid =~ /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/) ? $guid : undef;
}

1;

__END__

=pod

=head1 NAME

PITA::XML - Create, load, save and manipulate PITA-XML files

=head1 STATUS

B<This is an experimental release for demonstration purposes only.>

B<Please note the .xsd schema file may not install correctly as yet.>

=head1 DESCRIPTION

The C<PITA::XML> package supports the various uses of XML throughout
the L<PITA> project.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-XML>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<PITA::XML::Report>

The Perl Image-based Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
