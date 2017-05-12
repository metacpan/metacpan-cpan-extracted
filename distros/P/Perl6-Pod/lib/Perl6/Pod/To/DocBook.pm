package Perl6::Pod::To::DocBook;

=head1 NAME

Perl6::Pod::To::DocBook - DocBook formater 

=head1 SYNOPSIS

    my $p = new Perl6::Pod::To::DocBook:: 
                header => 0, doctype => 'chapter';


=head1 DESCRIPTION

Process pod to docbook

Sample:

        =begin pod
        =NAME Test chapter
        =para This is a test para
        =end pod

Run converter:

        pod6docbook test.pod > test.xml

Result xml:

        <?xml version="1.0"?>
        <chapter>
          <title>Test chapter
        </title>
          <para>This is a test para
        </para>
        </chapter>


=cut

use strict;
use warnings;
use Perl6::Pod::To;
use base 'Perl6::Pod::To';
use Perl6::Pod::Utl;
our $VERSION = '0.01';

sub new {
    my $class =  shift;
    my $self = $class->SUPER::new(@_);
#    $self->{doctype} ||= 'chapter';
    return $self;
}
sub block_NAME {
    my $self = shift;
    my $el   = shift;
    my $w  = $self->w;
    $w->raw('<title>');
    $el->{content} = Perl6::Pod::Utl::parse_para($el->childs->[0]->{content}->[0]);
    $self->visit_childs($el);
    $w->raw('</title>');
}

sub start_write {
    my $self = shift;
    my $w    = $self->writer;
    if ( $self->{header} ) {
        $w->say(
q@<!DOCTYPE chapter PUBLIC '-//OASIS//DTD DocBook V4.2//EN' 'http://www.oasis-open.org/docbook/xml/4.2/docbookx.dtd' >@);
    }
    $self->w->raw_print( '<' . $self->{doctype} . '>' ) if $self->{doctype};
}

sub switch_head_level {
    my $self = shift;
    my $level = shift;
    my $no_start_next_flag = shift;
    my $w = $self->w;
    my $prev = $self->SUPER::switch_head_level($level);
    if ($level && $level == $prev ) {
        $w->raw('</section><section>')
    } elsif ( $prev < $level  ) {
        $w->raw('<section>') for ( 1..$level-$prev);
    } else #$prev > $level
     { 
        my $count_to_close = $level * 1 + $prev-$level;
        $w->raw('</section>') for ( 1..$count_to_close);
        $w->raw('<section>') unless $no_start_next_flag or !$level;
     
     }
}

sub end_write {
    my $self = shift;
    $self->switch_head_level(0,'no_start_next');
    $self->w->raw_print( '</' .  $self->{doctype} . '>' ) if $self->{doctype};
}



1;
__END__


=head1 SEE ALSO

L<http://perlcabal.org/syn/S26.html>

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

