package MooseX::Types::Locale::BR;
use strict;
use MooseX::Types -declare => [qw/State Code/];
use MooseX::Types::Common::String 'NonEmptySimpleStr';
use Locale::BR qw();

our $VERSION = '0.01';

subtype State,
  as NonEmptySimpleStr,
  where { Locale::BR::state2code($_) ? 1 : 0 },
  message { "Must be a valid state" };

subtype Code,
  as NonEmptySimpleStr,
  where { Locale::BR::code2state($_) ? 1 : 0 },
  message { "Must be a valid state's code" };

42;

__END__

=head1 NAME

MooseX::Types::Locale::BR - Brazilian locale validation type constraint for Moose.


=head1 SYNOPSIS

  package MyClass;
  use Moose;
  use MooseX::Types::Locale::BR;
  use namespace::autoclean;
  
  has state => ( is => 'rw', isa => 'MooseX::Types::Locale::BR::State' );
  has code  => ( is => 'rw', isa => 'MooseX::Types::Locale::BR::Code'  );
  
  package main;
  MyClass->new( state=> 'Acre', code => 'AC');


=head1 DESCRIPTION

Moose type constraints wich use L<Locale::BR> to check
brazilian locale.


=head1 SEE ALSO

=over

=item L<Moose::Util::TypeConstraints>

=item L<MooseX::Types>

=item L<Locale::BR>

=back



=head1 AUTHOR

Solli M. Honorio, C<< <shonorio at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-types-locale-br at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Types-Locale-BR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Types::Locale::BR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Types-Locale-BR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Types-Locale-BR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Types-Locale-BR>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Types-Locale-BR/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Solli M. Honorio.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
