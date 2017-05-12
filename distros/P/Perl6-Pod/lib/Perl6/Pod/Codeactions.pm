package Perl6::Pod::Codeactions;
use Perl6::Pod::Lex::FormattingCode;
use strict;
use warnings;
use Data::Dumper;
use Carp;
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
    $self;
}

sub tidy_format_codes_content {
    my @res = ();
    my $tmp = '';
    foreach my $c (@_) {
        if (ref($c)) {
            if ( $tmp )
            {
                push @res, $tmp;
                $tmp = '';
            }
            push @res, $c;

          } else {
            $tmp .= $c;
        }
    }
    push @res, $tmp if $tmp;
    @res;

}

sub Text {
    my $self = shift;
    my $rec  = shift;
    if ( my $content = $rec->{content} ) {
        $rec->{content} = [ tidy_format_codes_content(@$content) ];
    }
    return $rec->{content}
}

sub D_code {
    my $self = shift;
    my $rec  = shift;
    return Perl6::Pod::Lex::FormattingCode->new($rec);
}

sub C_code {
    my $self = shift;
    my $rec  = shift;
    return Perl6::Pod::Lex::FormattingCode->new($rec);
}

sub X_code {
    my $self = shift;
    my $rec  = shift;
    return Perl6::Pod::Lex::FormattingCode->new($rec);
}

sub L_code {
    my $self = shift;
    my $rec  = shift;
    return Perl6::Pod::Lex::FormattingCode->new($rec);
}

sub default_formatting_code {
    my $self = shift;
    my $rec  = shift;
    if ( my $content = $rec->{content} ) {
        $rec->{content} = [ tidy_format_codes_content(@$content) ];
    }
    return Perl6::Pod::Lex::FormattingCode->new($rec);
}
1;

