use Pod::Find qw(pod_find simplify_name);

# On VMS File::Find (as used by Pod::Find works better with 
# uniform /unix/style/paths rather than mixed PERL_ROOT:[000000]/paths/.
# Also remove the . so we don't recurse in the DEFAULT directory.

my @dirs = ();

if ($^O eq 'VMS') {
    @dirs = grep { !m/^\.$/ } map { VMS::Filespec::unixify($_) } @INC;
}
else {
    @dirs = grep { !m/^\.$/ } @INC;
}

# Try a bit to make things unique.
# Pod::Find will also address uniqueness.
my %dirs = ();
@dirs{@dirs} = @dirs;
@dirs = keys(%dirs);

#my %pods = pod_find({ '-verbose' => 1, '-inc' => 1 },@dirs);
#my %pods = pod_find({ '-verbose' => 1, '-perl' => 1, '-script' => 1 },@dirs);
#my %pods = pod_find({ '-verbose' => 1, '-perl' => 1 },@dirs);

my %pods = pod_find({ }, @dirs);

foreach(keys %pods) {
    print "`$pods{$_}' from $_ -> ",my_simplify($_,@dirs),"\n";
}

sub my_simplify {
    my $spec = shift;
    my @dirs = @_;
    # strip leading /perl_root/ stuff:
    for (@dirs) {
        if ($^O eq 'VMS') {
            $spec =~ s/$_//i;
        }
        else {
            $spec =~ s/$_//;
        }
    }
    # Convert and protect class hierarchy names (e.g. IO::File -> io_file.pm).
    $spec =~ s#\/#_#g;
    # Problem: Pod::Man.pm -> pod_man.pm but pod_perlsolaris.pod?
    # Solution: strip leading pod_ from non .pm files.
    $spec =~ s#^pod_## unless $spec =~ m/\.pm$/;
    $spec = simplify_name($spec);
    return($spec);
}

