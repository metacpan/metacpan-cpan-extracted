package Search::InvertedIndex::AutoLoader;

# $RCSfile: AutoLoader.pm,v $ $Revision: 1.2 $ $Date: 1999/06/15 22:31:07 $ $Author: snowhare $

=head1 NAME

Search::InvertedIndex::AutoLoader - A manager for autoloading Search::InvertedIndex modules 

=head1 SYNOPSIS

use Search::InvertedIndex::AutoLoader;

=head1 DESCRIPTION

Sets up the autoloader to load the modules in the Search::InvertedIndex
system on demand.

=head1 CHANGES

1.01 Added Search::InvertedIndex::DB::Mysql to the list of autoloaded modules

=cut

$VERSION = "1.01";

my $_autoloaded_functions = {};

my (@packageslist) =(
	'Search::InvertedIndex',
	'Search::InvertedIndex::DB::DB_File_SplitHash',
	'Search::InvertedIndex::DB::Mysql',
	'Search::InvertedIndex::Update',
	'Search::InvertedIndex::Query',
	'Search::InvertedIndex::Query::Leaf',
	'Search::InvertedIndex::Result',
);

my ($autoloader) =<<'EOF';
package ----packagename----;
sub AUTOLOAD {
	return if ($AUTOLOAD =~ m/::(END|DESTROY)$/o);
    if (exists $_autoloaded_functions->{$AUTOLOAD}) {
        die("Attempted to autoload function '$AUTOLOAD' more than once - does it exist?\n");
    }
    $_autoloaded_functions->{$AUTOLOAD} = 1;
    my ($packagename) = $AUTOLOAD =~ m/^(.*)::[A-Z_][A-Z0-9_]*$/ois;
    eval ("use $packagename;");
    if ($@ ne '') {
        die ("Unable to use packagename: $@\n");
    }
    goto &$AUTOLOAD;
}

EOF
my ($fullload) ='';
my ($packagename);
foreach $packagename (@packageslist) {
	my ($loader) = $autoloader;
	$loader =~ s/(----packagename----)/$packagename/;
	$fullload .= $loader;
}
eval ($fullload);
if ($@ ne '') {
   die ("Failed to initialize AUTOLOAD: $@\n");
}

=head1 COPYRIGHT

Copyright 1999, Benjamin Franz (<URL:http://www.nihongo.org/snowhare/>) and 
FreeRun Technologies, Inc. (<URL:http://www.freeruntech.com/>). All Rights Reserved.
This software may be copied or redistributed under the same terms as Perl itelf.

=head1 AUTHOR

Benjamin Franz

=head1 TODO

Nothing.

=cut

1;
