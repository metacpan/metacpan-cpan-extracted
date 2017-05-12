package Regexp::MinLength;

use 5.10.1;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	MinLength
);

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Regexp::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Regexp::MinLength', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Regexp::MinLength - Perl extension for determining the minimum matching length for a regular expression

=head1 SYNOPSIS

  use Regexp::MinLength qw(MinLength);
  my $min = MinLength($regex);

=head1 DESCRIPTION

This module determines the minimum matching length for a regular expression.


=head1 USAGE 

=head2 MinLength(regular_expression)

Returns the minimum matching length, that is, the length of the shortest string that will match the given regular expression.  

=head1 EXAMPLE

my $regex = "\\d";
my $min = MinLength($regex);


=head1 SEE ALSO

See Regexp::Parser

=head1 AUTHOR

Leigh  Metcalf, E<lt>leigh@fprime.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Leigh Metcalf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
