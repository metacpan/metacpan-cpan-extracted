# ==============================================================================
# $Id: 01_app.pl 31 2006-09-19 18:17:09Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Application Frame - Example 01
# ==============================================================================

# --- (A) Pragmas/Modules
use strict;
use warnings;

use Getopt::Long 2.34;
use File::Basename;
use Module::Versions;

# *** Main *********************************************************************

# -- (B) Variables
my ( $copyright, $script, %opts );

$copyright = "Copyright (c) 2006 Thomas Walloschke. All rights reserved.";
( $script = basename($0) ) =~ s/\.[^.]+$//g;

# -- (C) Get options
get_options( \%opts );

if ( $opts{help} or ( $opts{verbose} and $opts{quiet} ) ) { syntax(); exit; }
if ( $opts{version} ) { version(); exit }   ### List versions ###

# -- (D) Console messages
print "[$script] Start.\n" if $opts{verbose};

print "[$script] No options: try -?\n" unless $opts{option};
map { print "[$script] Option: $_\n" } @{ $opts{option} }
    if $opts{option} and $opts{verbose};
map { print "[$script] ARGV:   $_\n" } @ARGV
    if @ARGV and $opts{verbose};

#
# ... (E) Do anything ...
#

print "[$script] Ready.\n" if $opts{verbose};
exit 0;

# *** Functions ****************************************************************

# -- (F) Get options
sub get_options {

    my $opts = shift;

    my $result = GetOptions( $opts,
        qw(option|o=s@ verbose|v quiet|q version|ver help|h|? ) );

    $opts->{help} = 1 unless ($result);
}

# -- (G) List all versions
sub version {

    print STDERR <<VERSION;
$copyright

Used modules:
VERSION

    open XML, ">", "${script}.xml";
    
    ###############################################################
    Module::Versions->list( *STDERR, '%5d %1s %-20s %10s %-16s' )
        ->list( *XML, 'XML' );
    ###############################################################

    close XML;
}

# -- (H) Help
sub syntax {

    my $line = "-" x length($script);

    print STDERR <<SYNTAX;
    $script
    $line
    
    $copyright
    Short Description of This Script
    
    Syntax: $script [[-option VALUE],...[-option VALUE]] [-verbose] [-quiet] [-version]
      
      -option|o.........Option...
                           
      -verbose|v........Print intermediate results.
      -quiet|q..........Be silent.
      -version|ver......Print version infos and stop.
      -help|h...........This help screen. 
      
        
SYNTAX
}

__END__

=head1 NAME

01_app - Example 01 - Module::Versions

=head1 SYNOPSIS

    > perl 01_app.pl -version -option value1

=head1 DESCRIPTION

Application frame with -version option.

=head1 AUTHOR

Thomas Walloschke E<lt>thw@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Thomas Walloschke (thw@cpan.org). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available. See
L<perlartistic>.

=head1 DATE

Last changed $Date: 2006-09-19 20:17:09 +0200 (Di, 19 Sep 2006) $.

=cut
