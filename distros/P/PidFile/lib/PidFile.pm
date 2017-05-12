#!/usr/bin/perl
#*
#* Name: PidFile
#* Info: simple read / write pidfile
#* Author: Lukasz Romanowski (roman) <lroman@cpan.org>
#*
use MooseX::Declare; # MooseX classes

use strict;
use warnings;

class PidFile {

    # --- version ---
    our $VERSION  = '1.04';

    #=------------------------------------------------------------------------( use, constants )

    # --- CPAN ---
    use Carp;                       # confess
    use FindBin;                    # script name
    use File::Slurp;                # read_file() / write_file()
    use File::Basename;             # basename()
    use MooseX::ClassAttribute;     # class attributes

    #=------------------------------------------------------------------------( class attributes )

    class_has 'Dir'    => ( is => 'rw', isa => 'Str', default => q{/var/run} ); # pid file dir
    class_has 'Suffix' => ( is => 'rw', isa => 'Str', default => q{}         ); # pid file suffix

    #=------------------------------------------------------------------------( class methods )
    # start every class function with Capital letter

    # default pidfile is /var/run/$PROGRAM_NAME.pid
    # default pid is $PID ($$)

    #=-------
    #  Path
    #=-------
    #* get path to pid file
    #* return path to pid file
    method Path( $class: Str :name( $p_name ) = $FindBin::Script ) {
        return $class->Dir . '/' . basename( $p_name ) . ( $class->Suffix && '_'.$class->Suffix ) . '.pid';
    }

    #=-------
    #  Read
    #=-------
    #* read pid from pid file
    #* return pid from pidfile or undef if pidfile not exists
    method Read( $class: Str :name( $p_name ) = $FindBin::Script ) {
        my $file = $class->Path( 'name' => $p_name );

        if ( not -f $file ) {
            carp "missing pid file: $file";
            return;
        }

        my $pid = read_file( $file );
        chomp $pid;

        return $pid;
    }

    #=--------
    #  Write
    #=--------
    #* write pid to pid file
    #* return 1 upon successfully writing the file or undef if it encountered an error
    method Write( $class: Int :pid( $p_pid ) = $$, :name( $p_name ) = $FindBin::Script ) {
        my $file = $class->Path( 'name' => $p_name );

        if ( -f $file ) {
            carp "find old pid file: $file";

            my $old_pid = $class->Read( 'name' => $p_name );
            return 1 if $old_pid == $p_pid;

            confess "old process (pid: $old_pid) arleady running!" if $class->Check( 'pid' => $old_pid );
            # or
            $class->Delete( 'name' => $p_name );
        }

        return write_file( $file, $p_pid );
    }

    #=---------
    #  Delete
    #=---------
    #* delete pid file
    #* return 1 if file successfully deleted, else 0
    method Delete( $class: Str :name( $p_name ) = $FindBin::Script ) {
        return unlink $class->Path( 'name' => $p_name );
    }

    #=--------
    #  Check
    #=--------
    #* check if process running
    #* return pid if proces exists, undef if error, else 0
    method Check( $class: Int :pid( $p_pid ) = $$, Str :name( $p_name ) = q{} ) {
        my $pid = $p_name ? $class->Read( 'name' => $p_name ) : $p_pid;
        return undef if not $pid;
        return +( kill 0, $pid ) ? $pid : 0;
    }

}

__END__

=pod

=head1 NAME

PidFile - simple read / write pidfile

=head1 SYNOPSIS

    use PidFile;

    # read pidfile
    my $pid = PidFile->Read;

    if ( $pid ) {
        # pid file for this script arealdy exists

        # check if script running
        if ( PidFile->Check( "pid" => $pid ) {

            # script running, so i die
            confess;
        }

        # script not running, delete old pidfile
        PidFile->Delete;
    }

    # save new pid file
    PidFile->Write;


    ## or you can run just only

    PidFile->Write;

    ## and this function check if old pidfile exists and if script running

=head1 DESCRIPTION

PidFile provide very simple class methods to manages a pidfile for the current or any process.

=head1 CLASS METHODS

=over 2

=item B<Path>

get path to pid file

input (hash):

C<name> => (str) script name [ default: C<$FindBin::Script> ]

return: path to pid file

=item B<Read>

read pid from pid file

input (hash):

C<name> => (str) script name [ default: C<$FindBin::Script> ]

return: pid from pidfile or undef if pidfile not exists

=item B<Write>

write pid to pid file

input (hash):

C<pid>  => (int) process id  [ default: C<$$> ]

C<name> => (str) script name [ default: C<$FindBin::Script> ]

return: 1 upon successfully writing the file or undef if it encountered an error

=item B<Delete>

delete pid file

input (hash):

C<name> => (str) script name [ default: C<$FindBin::Script> ]

return: 1 if file successfully deleted, else 0

=item B<Check>

check if process running

input (hash):

C<pid>  => (int) process id  [ default: C<$$> ]

C<name> => (str) script name [ optional ]

return: pid if proces exists, undef if error, else 0

=back

=head1 CLASS ATTRIBUTES

=over 2

=item B<Dir>

set / get pid file dir

default: /var/run

=item B<Suffix>

set / get pidfile suffix

default: empty sting

=back

=head1 AUTHOR

Lukasz Romanowski (roman) <lroman@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

