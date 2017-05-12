package Perl6::Pod::Parser::CustomCodes;

=pod

=head1 NAME

Perl6::Pod::Parser::CustomCodes - Filter for handle custom codes

=head1 SYNOPSIS


=head1 DESCRIPTION


DOCUMENTING !DOCUMENTING !DOCUMENTING !DOCUMENTING !DOCUMENTING !

=cut

use strict;
use warnings;
use Data::Dumper;
use base 'Perl6::Pod::Parser';
our $VERSION = '0.01';

sub on_start_element {
    my ( $self, $el ) = @_;
    my $lname = $el->local_name;
    return $el
      unless $lname eq 'M' and $el->isa('Perl6::Pod::FormattingCode::M');
    $el->{__CUSTOM_CODE_M} = '';
    $el->delete_element;
    return $el;
}

sub on_para {
    my ( $self, $el, $text ) = @_;
    return $text unless exists $el->{__CUSTOM_CODE_M};
    $el->{__CUSTOM_CODE_M} .= $text;
    return undef;
}

sub on_end_element {
    my ( $self, $el ) = @_;
    return $el unless exists $el->{__CUSTOM_CODE_M};
    my $str = $el->{__CUSTOM_CODE_M};
    my ( $custom_code_name, $para ) = $str =~ /\s*(\w+)\s*:\s*(.*)/s;
    if ( my $rootp = $el->context->{vars}->{root} ) {
#        warn "MAKE CODE $custom_code_name";
        my $custom_el = $self->mk_block($custom_code_name);
        $rootp->start_block($custom_el);
        $rootp->para($para);
        $rootp->end_block($custom_el);
    }
    return $el;
}

1;

