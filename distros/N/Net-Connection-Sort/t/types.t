#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

# The list of sort types exists in three places, the modules themselves, the
# POD in Net::Connection::Sort, and the README. A list that has quietly gone
# stale is worse than no list, so make sure the three agree.

sub slurp {
	my $file=$_[0];
	open( my $fh, '<', $file ) or BAIL_OUT( 'Could not read '.$file.'... '.$! );
	local $/;
	my $content=<$fh>;
	close( $fh );
	return $content;
}

my @from_modules;
opendir( my $dh, 'lib/Net/Connection/Sort' ) or BAIL_OUT( 'Could not read lib/Net/Connection/Sort... '.$! );
foreach my $entry ( readdir( $dh ) ){
	if ( $entry =~ /^(\w+)\.pm$/ ){
		push( @from_modules, $1 );
	}
}
closedir( $dh );
@from_modules=sort( @from_modules );

my @from_pod=sort( slurp( 'lib/Net/Connection/Sort.pm' ) =~ /^=item (\w+) - /mg );
my @from_readme=sort( slurp( 'README.md' ) =~ /^(\w+) - /mg );

ok( scalar( @from_modules ) > 0, 'found the sort modules') or BAIL_OUT('No sort modules were found');
is_deeply( \@from_pod, \@from_modules, 'the POD in Net::Connection::Sort lists every sort type');
is_deeply( \@from_readme, \@from_modules, 'README.md lists every sort type');

done_testing(3);
