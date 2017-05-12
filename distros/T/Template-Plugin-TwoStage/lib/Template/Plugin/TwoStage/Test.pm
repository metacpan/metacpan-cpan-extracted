#
# This file is part of Template-Plugin-TwoStage
#
# This software is copyright (c) 2014 by Alexander Kühne.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package # hide from pause
	Template::Plugin::TwoStage::Test;
# ABSTRACT: derived class for self-tests only

use strict;
use warnings;
use base qw( Template::Plugin::TwoStage );
use File::Temp 'tempdir';
use Cwd ();

Template::Plugin::TwoStage->caching_dir( tempdir( "TT_P_TwoStage_XXXXXX", TMPDIR => 1, CLEANUP => 1 ) );
__PACKAGE__->caching_dir( tempdir( "TT_P_TwoStage_XXXXXX", TMPDIR => 1, CLEANUP => 1 ) );


sub read_test_file { 
	my ( $class, $test_file ) = @_;
	local $/;
	open( my $fh, "<", Template::Plugin::TwoStage::_concat_path( Cwd::cwd(), [ 't', $test_file ] ) ) or die $!;
	my $tests = <$fh>;
	close $fh;
	$tests;
}


sub tt_config {
 	my ( $class, $config ) = @_;

	return( 
	  {	INCLUDE_PATH => [ Template::Plugin::TwoStage::_concat_path( Cwd::cwd(), [ 't', 'tt' ] ) ], 
		POST_CHOMP => 1,
		PLUGIN_BASE => 'Template::Plugin',
		EVAL_PERL => 1,
		( defined $config ? %{$config} : () )
	  }
	);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::TwoStage::Test - derived class for self-tests only

=head1 VERSION

version 0.08

=head2 METHODS

=head3 read_test_file

Pass name of text file containing test definitions suitable to be fed to Template::Test . Files are expected to reside in the t/ directory of this distribution.

=head3 tt_config

Returns a reference to a configuration hash with reasonable defaults suitable to be passed straight on to the TT constructor for working with test files included in this distribution. Accepts a reference to a configuration hash as first parameter that will be merged into the default configuration hash.

=for Pod::Coverage read_test_file tt_config

=head1 AUTHOR

Alexander Kühne <alexk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alexander Kühne.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
