package Parse::CPAN::MirroredBy;

=pod

=head1 NAME

Parse::CPAN::MirroredBy - Parse MIRRORED.BY

=head1 DESCRIPTION

Like the other members of the Parse::CPAN family B<Parse::CPAN::MirroredBy>
parses and processes the CPAN meta data file F<MIRRORED.BY>.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use Carp         'croak';
use IO::File     ();
use Params::Util qw{ _CODELIKE _HANDLE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

Creates a new, simple, parser object.

=cut

sub new {
	my $class = shift;
	my $self  = bless { filters => [] }, $class;
	return $self;
}

=pod

=head2 add_map

  # Instead of the full hash just read the hostname
  $parser->add_map( sub { $_[0]->{hostname} } );

The C<add_map> method adds a map stage to the filter pipeline.

A single element is passed into the provided function from the previous
pipeline phase, and one or more values can be returned which will be
passed on to the next pipeline phase.

Returns true if added, or throws an exception if a non-CODE reference
is provided.

=cut

sub add_map {
	my $self = shift;
	my $code = _CODELIKE(shift);
	unless ( $code ) {
		croak("add_map: Not a CODE reference");
	}
	push @{$self->{filters}}, [ 'map', $code ];
	return 1;
}

=pod

=head2 add_grep

  # We only want the daily mirrors
  $parser->add_grep( sub { $_[0]->{frequency} eq 'daily' } );

The C<add_grep> method adds a grep phase to the filter pipeline.

A single value is passed into the provided function, and the function
should return true if the value is to be kept, or false if not.

Returns true if added, or throws an exception if a non-CODE reference
is provided.

=cut

sub add_grep {
	my $self = shift;
	my $code = _CODELIKE(shift);
	unless ( $code ) {
		croak("add_grep: Not a CODE reference");
	}
	push @{$self->{filters}}, [ 'grep', $code ];
	return 1;
}

=pod

=head2 add_bless

  # Bless into whatever objects
  $parser->add_bless( 'Foo::Whatever' );

For situations in which you wish to convert the pipeline values into
objects directly, and don't want to do it via a map phase that passes
values into a contructor, the C<add_bless> method allows you to provide
a class name that the elements of the pipe will be passed to.

=cut

sub add_bless {
	my $self  = shift;
	my $class = _DRIVER(shift, 'UNIVERSAL');
	unless ( $class ) {
		croak("add_bless: Not a valid class");
	}
	push @{$self->{filters}}, [ 'map', sub { bless $_, $class } ];
	return 1;
}





#####################################################################
# Parsing Methods

=pod

=head2 parse_file

  my @mirrors = $parser->parse_file( 'MIRRORED.BY' );

Once the parser is ready to process the file, the C<parse_file> method
can be provided a file name to read. It will read the file, passing the
contents through the filter pipeline, and returning the resulting values
as a list of results.

=cut

sub parse_file {
	my $self   = shift;
	my $handle = IO::File->new( $_[0], 'r' ) or croak("open: $!");
	return $self->parse( $handle );
}

=pod

=head2 parse

  my @mirrors = $parser->parse( $file_handle );

Once the parser is ready to process the file, the C<parse> method
can be provided a file handle to read. It will read from the file handle,
passing the contents through the filter pipeline, and returning the
resulting values as a list of results.

=cut

sub parse {
	my $self   = shift;
	my $handle = _HANDLE(shift) or croak("Missing or invalid file handle");
	my $line   = 0;
	my $mirror = undef;
	my @output = ();

	while ( 1 ) {
		# Next line
		my $string = <$handle>;
		last if ! defined $string;
		$line = $line + 1;

		# Remove the useless lines
		chomp( $string );
		next if $string =~ /^\s*$/;
		next if $string =~ /^\s*#/;

		# Hostname or property?
		if ( $string =~ /^\s/ ) {
			# Property
			unless ( $string =~ /^\s+(\w+)\s+=\s+\"(.*)\"$/ ) {
				croak("Invalid property on line $line");
			}
			$mirror ||= {};
			$mirror->{"$1"} = "$2";

		} else {
			# Hostname
			unless ( $string =~ /^([\w\.-]+)\:\s*$/ ) {
				croak("Invalid host name on line $line");
			}
			my $current = $mirror;
			$mirror     = { hostname => "$1" };
			if ( $current ) {
				push @output, $self->_process( $current );
			}
		}
	}
	if ( $mirror ) {
		push @output, $self->_process( $mirror );
	}
	return @output;
}

sub _process {
	my $self   = shift;
	my @mirror = shift;
	foreach my $op ( @{$self->{filters}} ) {
		my $name = $op->[0];
		my $code = $op->[1];
		if ( $name eq 'grep' ) {
			@mirror = grep { $code->($_) } @mirror;
		} elsif ( $name eq 'map' ) {
			@mirror = map { $code->($_) } @mirror;
		}
	}
	return @mirror;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-CPAN-MirroredBy>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Parse::CPAN::Authors>, L<Parse::CPAN::Packages>,
L<Parse::CPAN::Modlist>, L<Parse::CPAN::Meta>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
