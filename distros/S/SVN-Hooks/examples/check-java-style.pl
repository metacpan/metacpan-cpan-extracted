# Check if every added/changed Java file passes our code quality
# standards.

PRE_COMMIT {
    my ($svnlook) = @_;

    # CONFIG: Uncomment the following return to disable all checks
    # return;

    use autodie qw(:all);
    use Cwd;
    use File::Temp;
    use IO::Handle;

    my @javas = grep {/\.java$/} ($svnlook->added(), $svnlook->updated());
    return unless @javas;

    # CONFIG: Set $limit to 0 to have no limits on the number of files to be checked.
    if (my $limit = 10) {
	splice @javas, $limit if @javas > $limit;
    }

    # Create a copy of each java file in a temporary directory.
    my $dir = File::Temp->newdir();
    foreach my $java (@javas) {
	(my $file = $java) =~ tr:/:_:; # flaten the java file name
	open my $fh, '>', "$dir/$file";
	$fh->print($svnlook->cat($java));
    }

    my $cwd = cwd();
    chdir '/ha/subversion/admin/hooks/dsb';

    # Invoke the code quality tool on all saved java files
    system('java', '-jar', 'code-quality-hook-1.0-SNAPSHOT.jar', glob("$dir/*.java"));

    chdir $cwd;
};

1;
