package Socket::Class::Const;

# uncomment for debugging
#use strict;
#use warnings;

our( $VERSION, $ExportLevel );

BEGIN {
	$VERSION = '2.11';
	require Socket::Class unless $Socket::Class::VERSION;
	require XSLoader;
	XSLoader::load( __PACKAGE__, $VERSION );
	$ExportLevel = 0;
}

no warnings 'redefine';

1; # return

sub import {
	my $pkg = shift;
	if( $_[0] eq '-compile' ) {
		shift @_;
		&export( $pkg, @_ );
	}
	else {
		my $pkg_export = caller( $ExportLevel );
		&export( $pkg_export, @_ );
	}
}

sub compile {
	my $pkg_export = caller( $ExportLevel );
	&export( $pkg_export, @_ );
}

__END__
