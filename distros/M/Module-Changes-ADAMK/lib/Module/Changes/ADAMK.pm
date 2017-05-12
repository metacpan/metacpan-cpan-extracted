package Module::Changes::ADAMK;

=pod

=head1 NAME

Module::Changes::ADAMK - Parse a traditional Changes file (as ADAMK interpretes it)

=head1 SYNOPSIS

  my $changes  = Module::Changes::ADAMK->read('Changes');
  my $latest   = $changes->current;
  my $datetime = $changes->datetime; # DateTime object

=head1 DESCRIPTION

This module was written for parsing ADAMK's Changes files (which are a pretty
traditional format that might be of us to others).

It is provided to the CPAN community for discussion and testing purposes.

It is currently not documented in detail, see the source code for the API.

=cut

use 5.006;
use strict;
use warnings;
use Carp                             'croak';
use DateTime                  0.4501 ();
use DateTime::Format::CLDR      1.06 ();
use DateTime::Format::DateParse 0.04 (); 

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}

use Module::Changes::ADAMK::Release ();
use Module::Changes::ADAMK::Change  ();

use Object::Tiny 1.03 qw{
	file
	string
	header
	dist_name
	module_name
};





#####################################################################
# Constructor and Accessors

sub read {
	my $class = shift;

	# Check the file
	my $file = shift or croak('You did not specify a file name');
	croak("File '$file' does not exist")              unless -e $file;
	croak("'$file' is a directory, not a file")       unless -f _;
	croak("Insufficient permissions to read '$file'") unless -r _;

	# Slurp in the file
	local $/ = undef;
	open CFG, $file or croak("Failed to open file '$file': $!");
	my $contents = <CFG>;
	close CFG;

	# Hand off to the actual parser
	my $self = $class->read_string( $contents );

	# Keep the file name so we can save later
	$self->{file} = $file;
	return $self;
}

sub read_string {
	my $class = shift;

	# Normalize newlines
	my $string = shift;
	return undef unless defined $string;
	$string =~ s/(?:\015{1,2}\012|\015|\012)/\n/gs;

	# Create the unpopulated object
	my $self  = $class->new(
		string => $string,
	);

	# Split into paragraphs
	my @paragraphs = split /\n{2,}(?=[^ \t])/, $string;
	foreach ( @paragraphs ) {
		s/\n\z//;
	}

	# The first paragraph contains the name of the module, which
	# should be the last word.
	$self->{header} = shift @paragraphs;
	my @header_words = $self->{header} =~ /([\w:-]+)/g;
	unless ( @header_words ) {
		croak("Failed to find any words in the header");
	}
	my $name = $header_words[-1];
	$self->{dist_name}   = $name;
	$self->{module_name} = $name;
	if ( $name =~ /-/ ) {
		$self->{module_name} =~ s/-/::/g;
	} elsif ( $name =~ /::/ ) {
		$self->{dist_name} =~ s/::/-/g;
	}

	# Parse each paragraph into a release
	my @releases = ();
	foreach my $paragraph ( @paragraphs ) {
		next unless $paragraph =~ /\S/;
		push @releases, Module::Changes::ADAMK::Release->new($paragraph);
	}
	$self->{releases} = \@releases;

	return $self;
}

sub releases {
	return @{$_[0]->{releases}};
}

sub save {
	my $self = shift;
	unless ( $self->{file} ) {
		die("Tried to save Changes file without a file name");
	}

	# Generate and write
	open( CFG, '>', $self->{file} ) or die "open: $!";
	print CFG $self->as_string;
	close CFG;

	return 1;
}





#####################################################################
# Main Methods

sub current {
	$_[0]->{releases}->[0];
}

sub current_version {
	$_[0]->current->version;
}





#####################################################################
# Stringification

sub as_string {
	my $self  = shift;
	my @parts = (
		$self->header,
		map { $_->as_string } $self->releases,
	);
	return join "\n", map { "$_\n" } @parts;
}

sub roundtrips {
	$_[0]->string eq $_[0]->as_string
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Changes-ADAMK>

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
