#!/usr/bin/env perl

package Quiq::Pod::Generator::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Pod::Generator');
}

# -----------------------------------------------------------------------------

sub test_encoding : Test(1) {
    my $self = shift;

    my $pg = Quiq::Pod::Generator->new;
    
    my $pod = $pg->encoding('utf-8');
    $self->is($pod,"=encoding utf-8\n\n");
}

# -----------------------------------------------------------------------------

sub test_section : Test(2) {
    my $self = shift;

    my $pg = Quiq::Pod::Generator->new;
    
    my $pod = $pg->section(1,'Test');
    $self->is($pod,"=head1 Test\n\n");

    $pod = $pg->section(1,'Test',"Ein\nTest");
    $self->is($pod,"=head1 Test\n\nEin\nTest\n\n");
}

# -----------------------------------------------------------------------------

sub test_code : Test(1) {
    my $self = shift;

    my $pg = Quiq::Pod::Generator->new;
    
    my $pod = $pg->code("Ein\nTest");
    $self->is($pod,"    Ein\n    Test\n\n");
}

# -----------------------------------------------------------------------------

sub test_bulletList : Test(1) {
    my $self = shift;

    my $pg = Quiq::Pod::Generator->new;
    
    my $pod = $pg->bulletList(['Eins A','Zwei B']);
    $self->is($pod,
        "=over 4\n\n=item *\n\nEins A\n\n=item *\n\nZwei B\n\n=back\n\n");
}

# -----------------------------------------------------------------------------

sub test_orderedList : Test(1) {
    my $self = shift;

    my $pg = Quiq::Pod::Generator->new;
    
    my $pod = $pg->orderedList(['Eins A','Zwei B']);
    $self->is($pod,
        "=over 4\n\n=item 1.\n\nEins A\n\n=item 2.\n\nZwei B\n\n=back\n\n");
}

# -----------------------------------------------------------------------------

sub test_definitionList : Test(2) {
    my $self = shift;

    my $pg = Quiq::Pod::Generator->new;
    
    my $pod = $pg->definitionList([['A','Eins'],['B','Zwei']]);
    $self->is($pod,
        "=over 4\n\n=item A\n\nEins\n\n=item B\n\nZwei\n\n=back\n\n");

    $pod = $pg->definitionList([A=>'Eins',B=>'Zwei']);
    $self->is($pod,
        "=over 4\n\n=item A\n\nEins\n\n=item B\n\nZwei\n\n=back\n\n");
}

# -----------------------------------------------------------------------------

sub test_for : Test(2) {
    my $self = shift;

    my $pg = Quiq::Pod::Generator->new;
    
    my $pod = $pg->for('html','<img src="figure1.png" />');
    $self->is($pod,qq|=for html <img src="figure1.png" />\n\n|);

    $pod = $pg->for('html',qq|Ein Bild:\n<img src="figure1.png" />|);
    $self->is($pod,qq|=begin html\n\nEin Bild:\n|.
        qq|<img src="figure1.png" />\n\n=end html\n\n|);
}

# -----------------------------------------------------------------------------

sub test_pod : Test(1) {
    my $self = shift;

    my $pg = Quiq::Pod::Generator->new;
    
    my $pod = $pg->pod;
    $self->is($pod,"=pod\n\n");
}

# -----------------------------------------------------------------------------

sub test_cut : Test(1) {
    my $self = shift;

    my $pg = Quiq::Pod::Generator->new;
    
    my $pod = $pg->cut;
    $self->is($pod,"=cut\n\n");
}

# -----------------------------------------------------------------------------

sub test_fmt : Test(4) {
    my $self = shift;

    my $text = '$x';
    my $val = Quiq::Pod::Generator->fmt('C',$text);
    $self->is($val,"C<$text>");

    $text = '$class->new()';
    $val = Quiq::Pod::Generator->fmt('C',$text);
    $self->is($val,"C<< $text >>");

    $text = '<a>';
    $val = Quiq::Pod::Generator->fmt('C',$text);
    $self->is($val,"C<< $text >>");

    $text = '$x >> $y';
    $val = Quiq::Pod::Generator->fmt('C',$text);
    $self->is($val,"C<<< $text >>>");
}

# -----------------------------------------------------------------------------

package main;
Quiq::Pod::Generator::Test->runTests;

# eof
