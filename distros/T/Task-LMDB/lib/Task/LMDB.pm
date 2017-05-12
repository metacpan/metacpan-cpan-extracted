package Task::LMDB;

our $VERSION = '0.100';

1;



__END__

=encoding utf-8

=head1 NAME

Task::LMDB - Stub module to depend on Alien::LMDB and LMDB_File

=head1 SYNOPSIS

In your module's C<Makefile.PL>, depend on L<Task::LMDB> instead of L<LMDB_File>:

    PREREQ_PM => {
        'Task::LMDB' => 0,  ## provides LMDB_File
    },

Same goes for C<Build.PL>:

    requires => {
        'Task::LMDB' => 0,  ## provides LMDB_File
    },

=head1 DESCRIPTION

Since L<LMDB_File> stopped bundling the L<LMDB|https://symas.com/products/lightning-memory-mapped-database/> source code, you must provide your own copy of C<liblmdb.so> and its header files. Keeping them de-coupled allows the development of L<LMDB_File> to not be tied to LMDB releases.

Because L<LMDB_File> needs to compile and link against LMDB, you must provide a working LMDB installation prior to installing L<LMDB_File>. This can be accomplished by compiling LMDB from source code, using your operating system's package manager, or by installing the L<Alien::LMDB> package. L<Alien::LMDB> will attempt to use a system LMDB if it is installed, otherwise will compile its own bundled copy.

L<Task::LMDB> is just a stub module that depends on L<Alien::LMDB> as a configure time dependency, and on L<LMDB_File> as a regular dependency. This ordering ensures that L<Alien::LMDB> will be installed prior to compiling L<LMDB_File>. In this way, CPAN modules that don't care where the LMDB library comes from can depend on L<LMDB_File> purely by adding a CPAN dependency on L<Task::LMDB>.

=head1 SEE ALSO

L<Task::LMDB github repo|https://github.com/hoytech/Task-LMDB>

L<Symas Lightning Memory-mapped Database|https://symas.com/products/lightning-memory-mapped-database/>

L<LMDB_File>

L<Alien::LMDB>

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2016 Doug Hoyte.

This module is licensed under the same terms as perl itself.
