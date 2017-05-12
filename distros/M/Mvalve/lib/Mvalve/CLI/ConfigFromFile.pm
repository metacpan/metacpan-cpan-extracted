# $Id: /mirror/coderepos/lang/perl/Mvalve/trunk/lib/Mvalve/CLI/ConfigFromFile.pm 66262 2008-07-16T05:50:26.279608Z daisuke  $

package Mvalve::CLI::ConfigFromFile;
use Moose::Role;
use Config::Any;

with 'MooseX::Getopt';
with 'MooseX::ConfigFromFile';

requires 'run';

no Moose;

sub get_config_from_file {
    my( $class, $file ) = @_;

    if (! $file || ! -f $file) {
        return {};
    }

    my $cfg = Config::Any->load_files({
        files => [ $file ],
        use_ext => 1,
        driver_args => {
            General => {
                -LowerCaseNames => 1
            }
        }
    });

    return $cfg->[0]->{$file} or die "Could not load $file";
}

1;
