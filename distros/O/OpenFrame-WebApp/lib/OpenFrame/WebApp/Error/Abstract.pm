=head1 NAME

OpenFrame::WebApp::Error::Abstract - error thrown by abstract methods.

=head1 SYNOPSIS

  use Error;
  use OpenFrame::WebApp::Error::Abstract;
  throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );

=cut


package OpenFrame::WebApp::Error::Abstract;

use utf8;
use strict;
use warnings::register;

our $VERSION = (split(/ /, ' $Revision: 1.2 $ '))[2];

use base qw( Error );

sub new {
    my $class = shift;
    my %args  = @_;
    my $pkg   = $args{class};

    local $Error::Depth = $Error::Depth + 1;

    my ($sub, $d);
    ($d, $d, $d, $sub) = caller(2);

    my $text = "$pkg does not implement abstract method $sub\()!";

    $class->SUPER::new(-text => $text, @_);
}


1;


__END__

=head1 DESCRIPTION

This class inherits its interface from the C<Error> module.
On creation, '-text' is automatically set to a warning message containing the
unimplemented method name and the offending package.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

Inspired by C<Pipeline::Error::Abstract>, by James A. Duncan.

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Error>, L<OpenFrame::WebApp::Error>

=cut
