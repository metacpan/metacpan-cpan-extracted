package Perl6::Pod::Directive::alias;

=pod

=head1 NAME

Perl6::Pod::Directive::alias - synonyms for longer Pod sequences

=head1 SYNOPSIS


    =alias PROGNAME    Earl Irradiatem Evermore
    =alias VENDOR      4D Kingdoms
    =alias TERMS_URLS  =item L<http://www.4dk.com/eie>
    =                  =item L<http://www.4dk.co.uk/eie.io/>
    =                  =item L<http://www.fordecay.ch/canttouchthis>

    The use of A<PROGNAME> is subject to the terms and conditions
    laid out by A<VENDOR>, as specified at:

        A<TERMS_URL>



=head1 DESCRIPTION

The C<=alias> directive provides a way to define lexically scoped
synonyms for longer Pod sequences, (meta)object declarators from the
code, or even entire chunks of ambient source. These synonyms can then
be inserted into subsequent Pod using the
L<C<A<> formatting code>|Alias placements>.

Note that C<=alias> is a fundamental Pod directive, like C<=begin> or
C<=for>; there are no equivalent paragraph or delimited forms.

There are two forms of C<=alias> directive: macro aliases and contextual
aliases. Both forms are lexically scoped to the surrounding Pod block.

=cut

use warnings;
use strict;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
our $VERSION = '0.01';

sub new {
    my ( $class, %args ) = @_;
    my $self = $class->SUPER::new( %args );
    $self->context->{_alias}->{$self->{alias_name} } = $self->{text}->[0];
    return undef;
}

sub start {
    my $self = shift;
    my ( $parser, $attr ) = @_;
    $self->delete_element->skip_content;
    my @lines = split( /[\n\r]/, $self->context->custom->{_RAW_} );
    my $first_line_ident;
    my @res = ();
    my $alias_name;

    foreach my $line (@lines) {
        unless ($first_line_ident) {

            #check lengh first line
            $line =~ m/^\s*(=alias\s+(\w+)\s+)(.*)/
              or die 'Bad =alias at line: '
              . $self->context->custom->{_line_num_};
            $first_line_ident = length($1);
            $alias_name       = $2;

            #save first line
            push @res, $3;
            next;
        }

        #not first line
        $line =~ m/^\s*(=\s+)(.*)/
          or die "Bad line in alias block "
          . $self->context->custom->{_line_num_};
        my $text = $2;

        #save ident
        if ( length($1) > $first_line_ident ) {
            $text = " " x ( length($1) - $first_line_ident ) . $text;
        }
        push @res, $text;
    }

    $parser->current_context->{_alias}->{$alias_name} = join "\n", @res;
}
1;
__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

