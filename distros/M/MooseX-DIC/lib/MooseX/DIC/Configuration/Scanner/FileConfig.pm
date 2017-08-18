package MooseX::DIC::Configuration::Scanner::FileConfig;

use File::Find;
use File::Slurp;

require Exporter;
@ISA       = qw/Exporter/;
@EXPORT_OK = qw/fetch_config_files_from_path/;

sub fetch_config_files_from_path {
    my $path = shift;

    my @config_files = ();
    find(
        sub {
            my $file_name = $File::Find::name;
            push @config_files, $file_name
                if is_config_file($file_name);
        },
        @$path
    );

    return @config_files;
}

sub is_config_file {
    my $file_name = shift;

    # Must be a file
    return 0 unless -f $file_name;

    # Must have a specific name
    return 0 if index( $file_name, '/moosex-dic-wiring.yml' ) == -1;

    return 1;
}


1;
