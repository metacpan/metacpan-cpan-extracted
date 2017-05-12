package Shell::GetEnv::Dumper;

use strict;
use warnings;

use Carp;
use Storable;

our $VERSION = '0.10';

# crazy, but avoids need to use YAML or evals of Data::Dumper
# or crazy shell escapes

# can be run directly or use()'d
write_envs() unless caller();


sub write_envs
{
    my $file = shift @ARGV;

    if ( ! store(\%ENV, $file) )
    {
	warn( "error storing environment to $file\n" );
	exit(1);
    }
}

sub read_envs
{
    my ( $file ) = @_;

    my $envs = retrieve( $file )
      or croak( "unable to retrieve environment from $file\n" );

    return $envs;
}


1;

__END__


=head1 NAME

Shell::GetEnv::Dumper - store and retrieve environment


=head1 SYNOPSIS

   # write environment to file
   perl /path/to/Shell/GetEnv/Dumper.pm file

   # read environment from file
   use Shell::GetEnv::Dumper;
   $envs = Shell::GetEnv::Dumper::read_envs( $filename );

=head1 DESCRIPTION

B<Shell::GetEnv::Dumper> is used by B<Shell::GetEnv> to store and
retrieve a subprocess's environment.  It uses B<Storable> to write
and read the B<%ENV> hash from and to disk.

Writing the environment is done from within the subshell by executing
this module as a Perl script.  The command line may be formed as
follows:

   # this loads the path to the module in %INC.
   use Shell::GetEnv::Dumper;

   # this invokes the module directly, using the Perl which was
   # used to invoke the parent process.  It uses the fact that we
   # use()'d Shell::GetEnv::Dumper and Perl stored the absolute path
   # to it in %INC;
   $cmd = qq{$^X '$INC{'Shell/GetEnv/Dumper.pm'}' $filename};

Retrieving the environment is done using the B<read_envs()> function.

Note that nothing is exportable from this module.


=head1 FUNCTIONS


=over

=item B<write_envs>

This function should never be invoked directly.  It is called when
this module is executed as a standalone Perl script.  It expects
that C<$ARGV[0]> contains the name of the file to which the environment
is to be written.  It exits with an error message and non-successful exit
status if there is an error.

=item B<read_envs>

  $envs = Shell::GetEnv::Dumper::read_envs( $filename );

Extract the environment from the given file.  The environment must have
been written using B<write_envs()>.

=back

=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

          http://www.gnu.org/licenses



=cut
