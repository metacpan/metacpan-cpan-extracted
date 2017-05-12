#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 10;

use File::Slurp;
use File::Temp qw/ tempfile /;

#-----------------------------------------------------------------
# Return a fully qualified name of the given file in the test
# directory "t/data" - if such file really exists. With no arguments,
# it returns the path of the test directory itself.
# -----------------------------------------------------------------
use FindBin qw( $Bin );
use File::Spec;
sub test_file {
    my $file = File::Spec->catfile ('t', 'data', @_);
    return $file if -e $file;
    $file = File::Spec->catfile ($Bin, 'data', @_);
    return $file if -e $file;
    return File::Spec->catfile (@_);
}

#-----------------------------------------------------------------
# Return a configuration extracted from the given file.
# -----------------------------------------------------------------
sub get_config {
    my $filename = shift;
    my $config_file = test_file ($filename);
    my $config = Monitor::Simple::Config->get_config ($config_file);
    ok ($config, "Failed configuration taken from '$config_file'");
    return $config;
}

# -----------------------------------------------------------------
# Tests start here...
# -----------------------------------------------------------------
ok(1);
use Monitor::Simple;
use Monitor::Simple::Output;
diag( "Testing outputters" );

my $config = get_config ('config.xml');

# instantiate an outputter
{
    my $notifier = Monitor::Simple::Output->new (config => $config, format => 1, b => 2, c => 3);
    isnt ($notifier->{format}, 1, "Changing format to default value");
    is ($notifier->{b}, 2, "Init arguments for an outputter (b)");
    is ($notifier->{c}, 3, "Init arguments for an outputter (c)");
}

# list all formats
{
    my $formats = Monitor::Simple::Output->list_formats;
    is (ref ($formats), 'HASH', "List of available formats");
    ok (exists $formats->{human}, "Format 'human' exists");
    ok (exists $formats->{tsv},   "Format 'tsv' exists");
    ok (exists $formats->{html},  "Format 'html' exists");
}

# escaping HTML
{
    is (Monitor::Simple::Output->escapeHTML ("<\"&\">"), '&lt;&#34;&amp;&#34;&gt;', "Escaping HTML");
}

__END__
