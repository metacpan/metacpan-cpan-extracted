package PPI::App::ppi_version::BDFOY;
use base qw(PPI::App::ppi_version);

=pod

=head1 NAME

PPI::App::ppi_version::BDFOY - brian d foy's rip off of Adam's ppi_version

=head1 SYNOPSIS

	# call it like PPI::App::ppi_version
	% ppi_version show

	% ppi_version change 1.23 1.24

	# call it with less typing. With no arguments, it assumes 'show'.
	% ppi_version show

	# with arguments that are not 'show' or 'change', assume 'change'
	% ppi_version 1.23 1.24

=head1 DESCRIPTION

I like what PPI::App::Version does, mostly, but I had to be different.
Life would just be easier if Adam did things my way from the start.

=cut

=begin private

=head2 Methods

=over 4

=cut

use 5.008;
use strict;
use version;
use File::Spec             ();
use PPI::Document          ();
use File::Find::Rule       ();
use File::Find::Rule::Perl ();
use Term::ANSIColor;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.14';
	}

#####################################################################
# Main Methods

=item main

=cut

BEGIN {
my %commands = map { $_, 1 } qw( show change );

sub main
	{
	my( $class, @args ) = @_;

	my $command = do {
		no warnings 'uninitialized';
		if( exists $commands{ $args[0] } ) { shift @args }
		elsif( @args == 0 )                { 'show' }
		else                               { 'change' }
		};


	$class->$command( @args );
	}
}

=item print_my_version

=cut

sub print_my_version
	{
	print "brian's ppi_version $VERSION - Copright 2009 brian d foy\n";
	}

=item print_file_report

=cut

sub print_file_report
	{
	my $class = shift;
	my( $file, $version, $message, $error ) = @_;

	if( defined $version )
		{
		$class->print_info(
			colored( ['green'], $version ),
			  " $file" );
		}
	elsif( $error )
		{
		$class->print_info( "$file... ", colored ['red'], $message );
		}
	else
		{
		$class->print_info( "$file... ", $message );
		}
	}

=item print_info

=cut

sub print_info
	{
	my $class = shift;

	print @_, "\n";
	}

=item get_file_list

=cut

sub get_file_list
	{
	my( $class, $dir ) = @_;

	my @files = grep { ! /\bblib\b/ } File::Find::Rule->perl_file
	               ->in( $dir || File::Spec->curdir );

	print  "Found " . scalar(@files) . " file(s)\n";

	return \@files;
	}

=item show

=cut

sub show {
	my $class = shift;

	my @args = @_;

	my $files = $class->get_file_list( $args[0] );

	my $count = 0;
	foreach my $file ( @$files )
		{
		my( $version, $message, $error_flag ) = $class->get_version( $file );
		$class->print_file_report( $file, $version, $message, $error_flag );
		$count++ if defined $version;
		}

	$class->print_info( "Found $count versions" );
	}

=item get_version

=cut

sub get_version {
	my( $class, $file ) = @_;

	my $Document = PPI::Document->new( $file );

	return ( undef, " failed to parse file", 1 ) unless $Document;

	# Does the document contain a simple version number
	my $elements = $Document->find( sub {
		# Find a $VERSION symbol
		$_[1]->isa('PPI::Token::Symbol')           or return '';
		$_[1]->content =~ m/^\$(?:\w+::)*VERSION$/ or return '';

		# It is the first thing in the statement
		if( my $sib = $_[1]->sprevious_sibling ) {
			return 1 if $sib->content eq 'our';
			return '';
			}

		# Followed by an "equals"
		my $equals = $_[1]->snext_sibling          or return '';
		$equals->isa('PPI::Token::Operator')       or return '';
		$equals->content eq '='                    or return '';

		# Followed by a quote
		my $quote = $equals->snext_sibling         or return '';
		$quote->isa('PPI::Token::Quote')           or return '';

		# ... which is EITHER the end of the statement
		my $next = $quote->snext_sibling           or return 1;

		# ... or is a statement terminator
		$next->isa('PPI::Token::Structure')        or return '';
		$next->content eq ';'                      or return '';

		return 1;
		} );

	return ( undef, "no version", 0 ) unless $elements;

	if ( @$elements > 1 )
		{
		$class->error("$file contains more than one \$VERSION = 'something';");
		}

	my $element = $elements->[0];
	my $version = $element->snext_sibling->snext_sibling;
	my $version_string = $version->string;

	$class->error("Failed to get version string")
		unless defined $version_string;

	return ( $version_string, undef, undef );
	}

=item change

=cut

sub change {
	my $class = shift;

	my $from = shift @_;

	unless ( $from and $from =~ /^[\d\._]+$/ )
		{
		$class->error("From version is not a number [$from]");
		}

	my $to = shift @_;
	unless ( $to and $to =~ /^[\d\._]+$/ )
		{
		$class->error("Target to version is not a number [$to]");
		}

	# Find all modules and scripts below the current directory
	my $files = $class->get_file_list;

	my $count = 0;
	foreach my $file ( @$files )
		{
		if ( ! -w $file )
			{
			$class->print_info( colored ['bold red'], " no write permission" );
			next;
			}

		my $rv = $class->changefile( $file, $from, $to );

		if ( $rv )
			{
			$class->print_info(
				colored( ['cyan'], $from ),
				" -> ",
				colored( ['bold green'], $to ),
				" $file"
				);
			$count++;
			}
		elsif ( defined $rv )
			{
			$class->print_info( colored( ['red'], " skipped" ), " $file" );
			}
		else
			{
			$class->print_info( colored( ['red'], " failed to parse" ), " $file" );
			}
		}

	$class->print_info( "Updated " . scalar($count) . " file(s)" );
	$class->print_info( "Done." );
	return 0;
	}

=item changefile

=cut

sub changefile {
	my( $self, $file, $from, $to ) = @_;

	my $document = eval { PPI::Document->new($file) };
	unless( $document )
		{
		error( "Could not parse $file!" );
		return '';
		}

	my $rv = PPI::App::ppi_version::_change_document( $document, $from => $to );

	error("$file contains more than one \$VERSION assignment") unless defined $rv;

	return '' unless $rv;

	error("PPI::Document save failed") unless $document->save($file);

	return 1;
	}

=item error

=cut

sub error
	{
	no warnings 'uninitialized';
	print "\n", colored ['red'], "  $_[1]\n\n";
	return 255;
	}

1;

=end private

=head1 SOURCE AVAILABILITY

This source is part of a Github project:

	git@github.com:briandfoy/PPI-App-ppi_version-BDFOY.git

=head1 AUTHOR

Adam Kennedy wrote the original, and I stole some of the code. I even
inherit from the original.

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2008-2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut
