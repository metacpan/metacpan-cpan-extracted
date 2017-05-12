package Perl6::Pod::FormattingCode::P;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::P - handle "P" formatting code

=head1 SYNOPSIS


    This module needs the LAME library
    (available from L<http://www.mp3dev.org/mp3/>)

    P<xref: ../filetest.pod@ table :!public , head1 , head2 >


=head1 DESCRIPTION

Instead of directing focus out to another document, it allows you to draw the contents of another document into your own. 

=cut

use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

sub start {
    my $self = shift;
    my $parser = shift;
    my $attr = shift;
    my $block= $parser->current_element;
#    $block->attrs_by_name->{PIN}=1;
    #$block->delete_element;
#    warn "START!" . $parser->current_element;
}
sub on_para {
    my ($self , $parser, $txt) = @_;
    #extract linkname and content
    my ( $lname, $lcontent ) = ('', defined $txt ? $txt : '');
    if  ($lcontent =~ /\|/ ) {
        my @all;
        ($lname, @all) =  split( /\s*\|\s*/, $lcontent );
        $lcontent = join "",@all
    } 
    my $attr = $self->attrs_by_name;
    #clean whitespaces
    $lname =~s/^\s+//;    $lname =~s/\s+$//;
    $attr->{name} = $lname;
    my ($scheme, $address , $section)  = $lcontent =~ /\s*(\w+)\s*\:([^\#]*)(?:\#(.*))?/;
    $attr->{scheme} = $scheme;
    $address = '' unless defined $address;
    $attr->{is_external} = $address =~ s/^\/\///;
    #clean whitespaces
    $address =~s/^\s+//;    $address =~s/\s+$//;
    $attr->{address} = $address;
    #fix L<doc:#Special Features>
    $attr->{section} = defined $section ? $section : '';
    if ( $scheme eq 'xref') {
        #t/data/P_test1.pod(head2)
        my ($path, $exp) = $address =~ /\s*(.*)\((.*)\)/;
#    warn Dumper {'attr'=>$attr, 'path'=>$path, 'exp'=>$exp};
    my @expressions = ();
    my @patterns = ();
    foreach  my $ex ( split ( /\s*,\s*/,$exp ) ) { 
        #head2 : !value
        #make filter element
        my ($name, $opt) = $ex =~ /\s*(\w+)\s*(.*)/;
    #    warn "$ex ->  $name|$opt";
        #make element filter for
        my $blk = $self->mk_block($name, $opt);
        push @patterns, $blk
    }
    if ( @patterns ) {
        push @expressions, new Perl6::Pod::Parser::FilterPattern:: patterns => \@patterns;
    }
    my $p = create_pipe( @expressions, $parser );
    $p->parse($path);
    }
    return undef;
#     $parser->parse()
    $txt;
}

sub to_xhtml {
    my ($self , $parser, @in) = @_;
    my $attr = $self->attrs_by_name();
    $attr->{2}=2;
    #$in[0]->delete_element;
    return \@in;
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

