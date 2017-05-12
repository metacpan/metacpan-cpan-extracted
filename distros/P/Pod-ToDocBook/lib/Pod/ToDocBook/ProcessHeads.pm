package Pod::ToDocBook::ProcessHeads;

#$Id: ProcessHeads.pm 443 2009-02-08 14:51:33Z zag $

=head1 NAME

Pod::ToDocBook::ProcessHeads - Converter head tags to section.

=head1 SYNOPSIS


    use Pod::ToDocBook::Pod2xml;
    use XML::ExtOn ('create_pipe');
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p =
      create_pipe( $px, qw( Pod::ToDocBook::ProcessHeads ),
        $w );
    $p->parse($text);

=head1 DESCRIPTION

Pod::ToDocBook::ProcessHeads - Converter head tags to section.

=cut

use warnings;
use strict;
use Data::Dumper;
use Test::More;
use XML::ExtOn;
use base 'XML::ExtOn';

sub _on_start_document {
    my ( $self, $data ) = @_;
    $self->SUPER::on_start_document($data);
}

sub on_start_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;
    my $attr  = $el->attrs_by_name;

    if ( $lname eq 'head1' and $el->{TITLE} =~ /\s*NAME\s*/ ) {

        $self->{NAME}++;
        $el->delete_element;

        $el->{NAME}++;
    }
    elsif ( $lname eq 'title' ) {
        $el->delete_element->skip_content
          if exists $self->current_element->{NAME};
    }
    elsif ( $lname eq 'para' and exists $self->{NAME} ) {
        $el->local_name('title');
        delete $self->{NAME};
    }
    elsif ( $lname =~ m/head(\d)/ ) {

        #set id
        $el->attrs_by_name->{'id'} = $el->{ID};
        $el->local_name('section');
    }
    $el;
}

sub on_end_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;
    if ( $lname eq 'head1' and exists $el->{NAME} ) {

        #diag 'END NAME';
    }
    $el;
}

1;
__END__

=head1 SEE ALSO

XML::ExtOn,  Pod::2::DocBook

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

