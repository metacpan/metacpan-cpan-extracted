package Spark::Form::Printer::XHTML;
our $VERSION = '0.2102';


# ABSTRACT: the interface an XHTML-printing form printer needs to implement

use Moose::Role;
with 'Spark::Form::Printer';

requires 'to_xhtml';

1;



=pod

=head1 NAME

Spark::Form::Printer::XHTML - the interface an XHTML-printing form printer needs to implement

=head1 VERSION

version 0.2102

=head1 SEE ALSO

=over 4

=item L<Spark::Form> - The forms module that started it all

=item L<SparkX::Form::BasicPrinters> - Set of pre-canned form printers

=back 



=head1 AUTHOR

  James Laver L<http://jameslaver.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by James Laver C<< <sprintf qw(%s@%s.%s cpan jameslaver com)> >>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

