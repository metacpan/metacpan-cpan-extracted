use strict;

package Salvation::Stuff;

require Exporter;

our @ISA 	 = ( 'Exporter' );
our @EXPORT 	 = ();

our @EXPORT_OK 	 = ( '&full_pkg',
		     '&load_class',
		     '&package_name_or_die',
		     '&is_namespace_present' );

our %EXPORT_TAGS = ( all => \@EXPORT_OK );
our $VERSION 	 = 1.01;

sub full_pkg
{
	return join( '::', @_ );
}

sub load_class
{
	my $class = &package_name_or_die( shift );

	return 1 if &is_namespace_present( $class ) and $class -> can( 'new' );

	require Module::Load;

	eval{ &Module::Load::load( $class ) };

	return 1 if &is_namespace_present( $class );

	require Module::Loaded;

	return ( &Module::Loaded::is_loaded( $class ) ? 1 : 0 );
}

sub is_namespace_present
{
	my $ns = shift;

	my @parts = split( /\:\:/, $ns );
	my $ok    = 0;
	my $node  = undef;

	foreach my $part ( @parts )
	{	
		if( $node = ( $node //= *::{ 'HASH' } ) -> { sprintf( '%s::', $part ) } )
		{
			++$ok;

		} else
		{
			last;
		}
	}

	return ( scalar( @parts ) == $ok );
}

sub package_name_or_die
{
        my $orig_str = shift;

	die 'Reference could not be package name' if ref $orig_str;

	( my $str = $orig_str ) =~ s/\:\://g;

	unless( $str =~ m/^[a-z_][0-9a-z_]*$/i )
	{
		eval
		{
			require URI::Escape;

			$orig_str = &URI::Escape::uri_escape( $orig_str );
		};

		die sprintf( 'Invalid package name: %s', $orig_str );
	}

	return $orig_str;
}

-1;

