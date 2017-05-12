package My::TestUtils;
use strict;
use Exporter;
use Test::More;
use Archive::Zip qw(:ERROR_CODES);
use Carp qw(croak);
use File::Spec;
use File::Path qw(mkpath);
use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);

@EXPORT = qw(slurp eq_or_diff create_archive_ok);


# this creates an alias for one assertion to a list of fallback
# assertion functions to use if available, in order of preference.
sub alias_assertion
{
    no strict 'refs';
    my $subname = shift;
    my @syms = @_;
    my $sub = sub {
        foreach my $sym (@syms)
        {
            my $alternative = ref $sym? $sym : \&$sym;
            goto $alternative if defined &$alternative;
        }
        my $why = @syms>1? "None of @syms are available" : "@syms is not available";
    SKIP: { skip $why, 1; }
    };

    *{ caller() . "::$subname" } = $sub;
}

BEGIN
{
    # use Test::Differences if it's available, else alias eq_or_diff() to is()
    eval 'use Test::Differences ()';

    alias_assertion eq_or_diff => 'Test::Differences::eq_or_diff', 'Test::More::is';
}


sub slurp($)
{
    my $file = shift;
    open my $fh, "<", $file or croak "Error opening $file: $!";  
    my $str = eval { local $/ = undef; <$fh> };
    close $fh;
    croak "error reading $file: $@" if $@;
    return $str;
}



sub create_archive_ok
{
    my $zipname = shift;
    unlink $zipname if -e $zipname;
    my $zip = Archive::Zip->new();
    $zip->addTree('t/data/templates', 'templates');

    # create the target directory
    my ($vol, $dir, $file) = File::Spec->splitpath($zipname);
    mkpath( File::Spec->catpath($vol, $dir, '') );

    is($zip->writeToFileNamed($zipname), AZ_OK, "created zip archive");
    return $zip;
}
1;
