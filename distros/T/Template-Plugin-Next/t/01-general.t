#!perl
#
# This file is part of Template-Plugin-Next
#
# This software is copyright (c) 2017 by Alexander Kühne.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use lib qw( ./lib ../blib );
use strict;
use warnings;
use Template::Test;
use Cwd ();
use File::Spec ();

$Template::Test::DEBUG = 1;
$Template::Test::PRESERVE = 1;

sub _concat_path {
    my ( $base_path, $append_dirs ) = @_;
    # $base_dir: base path (no filename) as string
    # $append_dirs: directories to append as string or an array reference
    
    my ($base_volume, $base_directories, $base_file) = File::Spec->splitpath( $base_path, 1 );
    File::Spec->catpath(
    	$base_volume,
		File::Spec->catdir( 
			File::Spec->splitdir( $base_directories ),
			( ref($append_dirs) ? @{$append_dirs} : File::Spec->splitdir( $append_dirs ) )
		) 
    	,
	$base_file
    );
}

my $config = {
       INCLUDE_PATH => [ map { _concat_path( Cwd::cwd(), [ 't', 'tt', $_ ] ) } qw( d c b a ) ],
#       INCLUDE_PATH => ( join ':', map { _concat_path( Cwd::cwd(), [ 't', 'tt', $_ ] ) } qw( d c b a ) ),
       POST_CHOMP   => 1
};

test_expect(\*DATA, $config);

__END__
# 1 - plugin loading
-- test --
[% USE Next; %]
-- expect --
-- test -- 
# 2 - decorating 'next' templates
[% 
   USE Next;
   INCLUDE test.tt;
%]
-- expect --
c
b
aa
b
c
