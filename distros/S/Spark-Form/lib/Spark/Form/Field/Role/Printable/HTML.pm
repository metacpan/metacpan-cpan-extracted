package Spark::Form::Field::Role::Printable::HTML;
our $VERSION = '0.2102';


# ABSTRACT: a HTML4-printable form field role

use Moose::Role;
with 'Spark::Form::Field::Role::Printable';

requires 'to_html';

1;



=pod

=head1 NAME

Spark::Form::Field::Role::Printable::HTML - a HTML4-printable form field role

=head1 VERSION

version 0.2102

=head1 SYNOPSIS

 package MyApp::Form::Field::CustomText;
 use Moose;
 extends 'Spark::Form::Field';
 with 'Spark::Form::Field::Role::Printable::HTML';
 use HTML::Tiny;

 sub to_html {
     my ($self) = @_;
     my $html = HTML::Tiny->new( mode => 'html' );
     $html->input({type => 'text', value => $self->value});
 }

=head1 METHODS

=head2 to_html :: Undef => Str

This function should return a HTML string representing your control

=head1 SEE ALSO

=over 4

=item L<Spark::Form::Field>

=back 



=head1 AUTHOR

  James Laver L<http://jameslaver.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by James Laver C<< <sprintf qw(%s@%s.%s cpan jameslaver com)> >>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

