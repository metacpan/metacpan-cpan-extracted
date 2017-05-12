package Perl6::Pod::To::XHTML;

=pod

=head1 NAME

 Perl6::Pod::To::XHTML - XHTML formater 

=head1 SYNOPSIS

    my $p = new Perl6::Pod::To::XHTML:: 

add root <html> tag
    my $p = new Perl6::Pod::To::XHTML:: 
                 doctype => 'html',
    

=head1 DESCRIPTION

Process pod to xhtml

Sample:

        =begin pod
        =NAME Test chapter
        =para This is a test para
        =end pod

Run converter:

        pod6xhtml test.pod > test.xhtml

Result xml:

        <html xmlns='http://www.w3.org/1999/xhtml'>
          <head>
            <title>Test chapter</title>
          </head>
          <para>This is a test para</para>
        </html>

=cut

use strict;
use warnings;
use Perl6::Pod::To;
use base 'Perl6::Pod::To';
use Perl6::Pod::Utl;
use Data::Dumper;
our $VERSION = '0.01';


sub start_write {
    my $self = shift;
    my $w    = $self->writer;
    $self->w->raw_print( '<' . $self->{doctype} . ' xmlns="http://www.w3.org/1999/xhtml">') if $self->{doctype};
}


sub end_write {
    my $self = shift;
    #export N<> notes
    my $notes = $self->{CODE_N}||[];
    if (my $count = scalar(@$notes)) {
        my $w =  $self->w;
       $w->raw('<div class="footnote">')
       ->raw('<p>NOTES</p>');
       my $nid = 1;
       foreach my $n (@$notes) {
            $w->raw(qq!<p><a name="ftn.nid${nid}" href="#nid${nid}"><sup>${nid}.</sup></a> !);
            $self->visit_childs($n);
            $w->raw('</p>');
            $nid++;
       }
       $self->w->raw('</div>');
    }
    $self->w->raw_print( '</' .  $self->{doctype} . '>' ) if $self->{doctype};
}


1;
__END__


=head1 SEE ALSO

L<http://perlcabal.org/syn/S26.html>

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


