#
# Replacement of the java class eg.AllFilex$Expand, since
# $ is not a valid character in a perl package name
#
#
package Test::C2FIT::eg::AllFilesExpand;
use base 'Test::C2FIT::ColumnFixture';
use Test::C2FIT::eg::AllFiles;
use File::Basename qw(basename);

sub expansion {
    my $self = shift;
    my $path = $self->{path};
    my $af   = new Test::C2FIT::eg::AllFiles();
    return join( ",", grep { $_ = basename($_) } $af->expand($path) );
}

1;
