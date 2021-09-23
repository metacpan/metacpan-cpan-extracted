package Stats::Fermi;

use 5.028002;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Stats::Fermi ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.1.7';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Stats::Fermi - Perl extension for Fermi, Boltzmann potentials

=head1 SYNOPSIS

  use Stats::Fermi;


=head1 DESCRIPTION

=head2 EXPORT

=head1 SEE ALSO

=head1 AUTHOR

koboldwiz, E<lt>koboldwiz@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by koboldwiz 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
