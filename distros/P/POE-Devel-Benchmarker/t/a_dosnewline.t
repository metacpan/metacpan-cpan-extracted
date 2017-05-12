#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "use File::Find::Rule";
	if ( $@ ) {
		plan skip_all => 'File::Find::Rule required for checking for presence of DOS newlines';
	} else {
		plan tests => 1;

		# generate the file list
		my $rule = File::Find::Rule->new;
		$rule->grep( qr/\r\n/ );
		my @files = $rule->in( qw( lib t ) );

		# FIXME read in MANIFEST.SKIP and use it!
		# for now, we skip SVN + git stuff
		@files = grep { $_ !~ /(?:\/\.svn\/|\/\.git\/)/ } @files;

		# do we have any?
		if ( scalar @files ) {
			fail( 'newline check' );
			diag( 'DOS newlines found in these files:' );
			foreach my $f ( @files ) {
				diag( ' ' . $f );
			}
		} else {
			pass( 'newline check' );
		}
	}
}
