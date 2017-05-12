package MooseX::Types::PIS;

use warnings;
use strict;

our $VERSION = '0.02';

use MooseX::Types -declare => ['PIS'];
use MooseX::Types::Moose qw(Str);
use Business::BR::PIS;

sub _validate_pis {
    my ($str) = @_;
    return test_pis($str);
}

subtype PIS,
  as Str, 
  where { _validate_pis($_) },
  message { 'PIS is invalid' };



42;
__END__
=encoding utf8

=head1 NAME

MooseX::Types::PIS - PIS type for Moose classes

=head1 SYNOPSIS

  package Class;
  use Moose;
  use MooseX::Types::PIS 'PIS';
  
  has 'pis' => ( is => 'ro', isa => PIS );

  package main;
  Class->new( pis => '121.51144.13-7' );

=head1 DESCRIPTION

This module lets you constrain attributes to only contain Brazilian 
PIS numbers. No coercion is attempted.

'PIS' stands for Brazil's I<< Programa de Integração Social >>. It 
is also referred to as 'PIS/PASEP'.

=head1 EXPORT

None by default, you'll usually want to request C<PIS> explicitly.

=head1 SEE ALSO

=over 4

=item * L<< MooseX::Types::CPF >>

=item * L<< MooseX::Types::CNPJ >>

=item * L<< Business::BR::Ids >>

=back


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-types-pis at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Types-PIS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Types::PIS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Types-PIS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Types-PIS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Types-PIS>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Types-PIS/>

=back


=head1 ACKNOWLEDGEMENTS

This module is just a simple wrapper around Adriano Ferreira's 
excellent L<< Business::BR::PIS >> validator. He did all the 
actual work :)

Also, thanks to Thiago Rondon for his other L<< MooseX::Types >> 
wrappers around L<< Business::BR::Ids >> - the idea for this, and 
several chunks of code, were shamelessly taken from those modules, 
nearly verbatim.


=head1 LICENSE AND COPYRIGHT

Copyright 2009 Breno G. de Oliveira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
