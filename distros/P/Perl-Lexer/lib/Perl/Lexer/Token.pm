package Perl::Lexer::Token;
use strict;
use warnings;
use utf8;
use 5.010000;

sub inspect {
    my $self = shift;
    my $ret = '<Token: ';
    $ret .= $self->name . ' ' . lc($self->type_str);
    if (UNIVERSAL::isa($self->yylval, 'B::SVOP')) {
        $ret .= ' ' . $self->yylval_svop;
    } else {
        $ret .= ' ' . ($self->yylval || '-');
    }
    $ret .= '>';
    return $ret;
}

sub name {
    my $self = shift;
    _name($self->[0]);
}

sub type {
    my $self = shift;
    _type($self->[0]);
}

sub type_str {
    my $type = shift->type;
    +{
        Perl::Lexer::TOKENTYPE_NONE()  => 'NONE',
        Perl::Lexer::TOKENTYPE_IVAL()  => 'IVAL',
        Perl::Lexer::TOKENTYPE_OPNUM() => 'OPNUM',
        Perl::Lexer::TOKENTYPE_PVAL()  => 'PVAL',
        Perl::Lexer::TOKENTYPE_OPVAL() => 'OPVAL',
    }->{$type};
}

sub yylval {
    my $self = shift;
    return $self->[1];
}

sub yylval_svop {
    my $self = shift;
    Carp::croak("It's not SVOP") unless UNIVERSAL::isa($self->[1], 'B::SVOP');
    return _yylval_svop($self->[1]);
}


1;
__END__

=for stopwords yylval

=head1 NAME

Perl::Lexer::Token - Token

=head1 SYNOPSIS

=over 4

=item $token->inspect() : Str

Stringify the token as human readable format.

=item $token->name() :Str

Get a token name.

=item $token->type() :Int

Get a token type. It's one of the following:

    Perl::Lexer::TOKENTYPE_NONE()
    Perl::Lexer::TOKENTYPE_IVAL()
    Perl::Lexer::TOKENTYPE_OPNUM()
    Perl::Lexer::TOKENTYPE_PVAL()
    Perl::Lexer::TOKENTYPE_OPVAL()

=item $token->type_str() :Int

Get a string notation of the type.

=item $token->yylval() : B::OP|Int|Str

Get a yylval. The type of yylval is determined by C<< $token->type >>.

=item $token->yylval_svop() : SV

Extract SV from yylval if yylval is C<B::SVOP>.

=back

