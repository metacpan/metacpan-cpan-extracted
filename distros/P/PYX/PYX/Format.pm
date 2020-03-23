package PYX::Format;

use strict;
use warnings;

our $VERSION = 0.06;

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::Format - PYX file format.

=head1 FILE FORMAT

 PYX is line oriented SGML/XML file format.

 Each line consists from character defining type and arguments.

=over 8

=item * Begin of element

 Begin character is '(' and argument is name of element.
 e.g. (html

=item * End of element

 Begin character is ')' and argument is name of element.
 e.g. )html

=item * Element attribute

 Begin character is 'A' and arguments are attribute key and value.
 e.g. Akey value

=item * Comment

 Begin character is '_' and argument is comment.
 e.g. _comment

=item * Data section

 Begin character is '-' and argument is data.
 e.g. -data

=item * Instruction

 Begin character is '?' and arguments are target and code.
 e.g. ?perl print "1";

=back

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2005-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
