# ABSTRACT: pack novel/bbs content to html / txt / web , etc
package  Novel::Robot::Packer;
use strict;
use warnings;
use Encode::Locale;
use Encode;

our $VERSION = 0.21;

sub new {
    my ( $self, %opt ) = @_;
    $opt{type} ||= 'html';
    my $module = "Novel::Robot::Packer::$opt{type}";
    eval "require $module;";
    bless {%opt}, $module;
}

sub suffix {
    return '';
}

sub main {
    my ($self, $bk, %opt) = @_;
    return $opt{output};
}

sub format_item_output {
    my ( $self, $bk, $o ) = @_;
    if ( ! $o->{output} ) {
        my $html = '';
        $o->{output} =
          exists $o->{output_scalar}
          ? \$html
          : $self->format_default_filename($bk, $o);
    }
    return $o->{output};
}

sub format_default_filename {
    my ( $self, $r, $o) = @_;

    my $item_info='';
    if(exists $o->{min_item_num} and $o->{min_item_num}>1){
        $item_info="-$o->{min_item_num}";
    }
    elsif(exists $o->{min_page_num} and $o->{min_page_num}>1){
        $item_info="-$o->{min_page_num}";
    }
    my $f =  "$r->{writer}-$r->{book}$item_info." . $self->suffix();
    $f =~ s{[\[\]/><\\`;'\$^*\(\)\%#@!"&:\?|\s^,~]}{}g;
    return encode( locale => $f );
}

1;
