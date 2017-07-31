package MooseX::DIC::Scanner::FolderScanner;

use File::Find;
use File::Slurp;

require Exporter;
@ISA       = qw/Exporter/;
@EXPORT_OK = qw/fetch_injectable_packages_from_path/;

sub fetch_injectable_packages_from_path {
    my $path = shift;

    my @injectable_packages = ();
    find(
        sub {
            my $file_name = $File::Find::name;
            push @injectable_packages,
                extract_package_name_from_filename($file_name)
                if is_injectable($file_name);
        },
        @$path
    );

    return @injectable_packages;
}

sub is_injectable {
    my $file_name = shift;

    # Must be a file
    return 0 unless -f $file_name;

    # Must be a perl module
    return 0 if index( $file_name, '.pm' ) == -1;

    # Must have the injectable role applied
    my $file_content = read_file( $file_name, err_mode => 'quiet' );
    return 0
        unless ( $file_content
        and ( index( $file_content, 'MooseX::DIC::Injectable' ) != -1 ) );

    return 1;
}

# This method assumes there's only one package per file
sub extract_package_name_from_filename {
    my $file_name = shift;

    my $package_name;
    my $file_content = read_file( $file_name, err_mode => 'quiet' );
    if ($file_content) {
        $file_content =~ /package\ +([a-zA-Z0-9]+)/;
        $package_name = $1;
    }

    return $package_name;
}

1;
