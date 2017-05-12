package OneTool::Configuration;

=head1 NAME

OneTool::Configuration - OneTool Configuration module

=cut

use strict;
use warnings;

use FindBin;
use File::Slurp;
use JSON;

my $DIR_CONFIG = "$FindBin::Bin/../conf";

=head1 FUNCTIONS

=head2 Directory($directory)

Sets (if $directory provided) and returns $DIR_CONFIG value

=cut

sub Directory
{
    my $directory = shift;

    if (defined $directory)
    {
        $DIR_CONFIG = $directory;
    }

    return ($DIR_CONFIG);
}

=head2 Get($param)

Gets configuration from file $param->{file} or for module $param->{module}

=cut

sub Get
{
    my $param = shift;

    my $file = (
        defined $param->{module}
        ? "$DIR_CONFIG/$param->{module}.conf"
        : (defined $param->{file} ? $param->{file} : undef)
    );

    if ((defined $file) && (-r $file))
    {
        my $json_str = read_file($file);
        my $conf     = from_json($json_str);

        return ($conf);
    }

    return (undef);
}

1;

=head1 AUTHOR

Sebastien Thebert <contact@onetool.pm>

=cut
