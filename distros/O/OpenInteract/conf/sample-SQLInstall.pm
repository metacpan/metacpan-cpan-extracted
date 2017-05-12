package OpenInteract::SQLInstall::%%UC_FIRST_NAME%%;

# Do installation of SQL for this package

use strict;
use vars qw( %HANDLERS );

@OpenInteract::SQLInstall::%%UC_FIRST_NAME%%::ISA = qw( OpenInteract::SQLInstall );


# List the files you wish to use to install the structures for your
# data, initial data and security for the data. Typically you install
# data to the structures in your package, but you can also install
# other types of data. For instance, if your package comes with theme
# properties you wish to have available you can install
# 'OpenInteract::ThemeProp' objects.
#
# Note that all files will be processed in the order you list them, so
# be careful of any inter-dependencies.

my %files = (

 # List your table files here -- these are found in the 'struct/'
 # directory of your package and will typically be normal SQL 'CREATE
 # TABLE' statements. Each file listed should contain only one
 # statement and you should not use any trailing execution directives
 # (e.g. ';', 'go', '\g')
 # 
 # Example: 
 #  tables => [ 'mytable.sql', 'mylinktable.sql' ],

 tables   => [],


 # List your data files here -- these are found in the 'data/'
 # directory of your package and will be formatted according to the
 # specification in OpenInteract::SQLInstall
 # 
 # Example:
 #  data => [ 'myinitialdata.dat' ],

 data     => [],


 # List the files needed for security -- these are found in the
 # 'data/' directory of your package and will be formatted according
 # to the specification in OpenInteract::SQLInstall
 # 
 # Example:
 #  security => [ 'install_security.dat' ],

 security => [],

);


# Default setup is for all databases to use the same files -- to
# change this, add a new entry similar to '_default_' using a
# database-specific driver name such as 'Oracle' or 'Sybase' or mysql'
# or whatever.

%HANDLERS = (

 create_structure => { '_default_' => [ 'create_structure', 
                                        { table_file_list => $files{tables} } ] },

 install_data     => { '_default_' => [ 'install_data',
                                        { data_file_list => $files{data} } ] },

 install_security => { '_default_' => [ 'install_data',
                                        { data_file_list => $files{security} } ] },

);

1;

__END__

=pod

=head1 NAME

OpenInteract::SQLInstall::%%UC_FIRST_NAME%% - SQL installer for this package

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS 

=head1 TO DO

=head1 SEE ALSO

=head1 AUTHORS

=cut
