use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Module::Build::Xilinx',
    license => 'mit',
    dist_author => 'Vikas N Kumar <vikas@cpan.org>',
    dist_abstract => 'Xilinx ISE Webpack based FPGA Development using commandline',
    create_readme => 1,
    create_license => -e 'LICENSE' ? 0 : 1,
    configure_requires => {
        'Module::Build' => 0,
        'Software::License' => 0,
        'Pod::Readme' => 0,
    },
    build_requires => {
        'Module::Build' => 0,
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.0008,
        'Module::Build' => 0,
        'File::Basename' => 0,
        'File::Spec' => 0,
        'File::HomeDir' => 0,
        'Data::Dumper' => 0,
        'Config' => 0,
        'Cwd' => 0,
        'YAML' => 0,
    },
    dynamic_config => 1,
    share_dir => 'share',
    recurse_into => undef,
    add_to_cleanup => [ 'Module-Build-Xilinx-*'],
);

$build->create_build_script;
$build->dispatch('clean');
$build->dispatch('distmeta');
$build->dispatch('manifest');

#to update changelog do the following:
#UPDATING CHANGELOG:
#    $ svn2cl --group-by-day --reparagraph
__END__
#### COPYRIGHT: 2014. Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 30th June 2014
#### LICENSE: Refer LICENSE file.
