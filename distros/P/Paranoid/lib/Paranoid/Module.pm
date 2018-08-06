# Paranoid::Module -- Paranoid Module Loading Routines
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/Module.pm, 2.06 2018/08/05 01:21:48 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Module;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::Input;
use Carp;

($VERSION) = ( q$Revision: 2.06 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT      = qw(loadModule);
@EXPORT_OK   = @EXPORT;
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

#####################################################################
#
# Module code follows
#
#####################################################################

{
    my %modules;    # List of modules compiled
                    #       {modules} => boolean
    my %imports;    # List of modules/tagsets imported from callers
                    #       {module*tagset*caller} => boolean

    sub loadModule {

        # Purpose:  Attempts to load a module via an eval.  Caches the
        #           result
        # Returns:  True (1) if the module was successfully loaded,
        #           False (0) if there are any errors
        # Usage:    $rv = loadModule($moduleName);

        my $module = shift;
        my @args   = @_;
        my $rv     = 0;
        my $caller = scalar caller;
        my $a      = @args ? 'qw(' . ( join ' ', @args ) . ')' : '';
        my ( $m, $cm );

        croak 'Mandatory first argument must be a defined module name'
            unless defined $module;

        pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $module, @args );
        pIn();

        # Check to see if module has been loaded already
        unless ( exists $modules{$module} ) {

            # First attempt at loading this module, so
            # detaint and require
            if ( detaint( $module, 'filename', $m ) ) {
                $module = $m;
            } else {
                Paranoid::ERROR =
                    pdebug( 'failed to detaint module name (%s)',
                    PDLEVEL1, $module );
                $modules{$module} = 0;
            }

            # Skip if the detainting failed
            unless ( exists $modules{$module} ) {

                # Try to load it
                $modules{$module} = eval "require $module; 1;" ? 1 : 0;
                pdebug( 'attempted load of %s: %s',
                    PDLEVEL2, $module, $modules{$module} );

            }
        }

        # Define the module/tagset/caller
        if (@args) {
            $a = '()' if $a eq 'qw()';
        } else {
            $a = '';
        }
        $cm = "$module*$a*$caller";

        # Check to see if this caller has imported these symbols
        # before
        if ( $modules{$module} ) {
            if ( exists $imports{$cm} ) {

                pdebug( 'previous attempt to import to %s',
                    PDLEVEL2, $caller );

            } else {

                pdebug( 'importing symbols into %s', PDLEVEL2, $caller );
                $imports{$cm} = eval << "EOF";
{
  package $caller;
  import $module $a;
  1;
}
EOF

            }

            $rv = $imports{$cm};
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL1, $modules{$module} );

        # Return result
        return $modules{$module};
    }
}

1;

__END__

=head1 NAME

Paranoid::Module -- Paranoid Module Loading Routines

=head1 VERSION

$Id: lib/Paranoid/Module.pm, 2.06 2018/08/05 01:21:48 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Module;

  $rv = loadModule($module, qw(:all));

=head1 DESCRIPTION

This provides a single function that allows you to do dynamic loading of
modules at runtime, along with importation of the exported symbol table.
Specific functions and/or tag sets can be declared, just as you would in a
normal B<use> or B<import> statement.

=head1 SUBROUTINES/METHODS

=head2 loadModule

  $rv = loadModule($module, qw(:all));

Accepts a module name and an optional list of arguments to 
use with the import function.  Returns a true or false depending
whether the require was successful.

=head1 DEPENDENCIES

=over

=item o

L<Carp>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Input>

=back

=head1 BUGS AND LIMITATIONS

The B<loadModule> cannot be used to require external files, it can only be
used to load modules in the existing library path.  In addition, while we
track what symbol sets (if any) were imported to the caller's name space the
return value doesn't reflect the value of the B<import> method.  This is
intentional because not every module out there offers a properly coded
B<import> function or inherits it from L<Exporter(3)>).  The return value 
from B<import> is ignored.

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

