package Search::InvertedIndex::AutoLoader;

use strict;
use warnings;

=head1 NAME

Search::InvertedIndex::AutoLoader - A manager for autoloading Search::InvertedIndex modules 

=head1 SYNOPSIS

use Search::InvertedIndex::AutoLoader;

=head1 DESCRIPTION

Sets up the autoloader to load the modules in the Search::InvertedIndex
system on demand.

=cut

use vars qw($AUTOLOAD $VERSION);

$VERSION = "1.17";

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
use vars qw($AUTOLOAD);

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

Copyright 1999-2020, Jerilyn Franz and FreeRun Technologies, Inc. (<URL:http://www.freeruntech.com/>).
All Rights Reserved.

=head1 AUTHOR

Jerilyn Franz

=head1 TODO

Nothing.

=cut

1;
