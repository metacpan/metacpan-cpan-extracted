package Pistachio::Token::Transformer::Rule;
# ABSTRACT: express a token transformer rule as an object

use strict;
use warnings;
our $VERSION = '0.10'; # VERSION

# @param string $type    object type
# @param hash    object properties
# @return Pistachio::Token::Transformer::Rule
sub new {
    my $type = shift;
    my $this = bless {@_}, $type;
}

# Simple getters.
sub type  { shift->{type} }
sub prec  { shift->{prec} }
sub succ  { shift->{succ} }
sub value { shift->{val} }
sub into  { shift->{into} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pistachio::Token::Transformer::Rule - express a token transformer rule as an object

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 my $rule = Pistachio::Token::Transformer::Rule->new(
     type => 'Word',
     prec => [['Word::Reserved', 'package']],
     succ => [['Structure', ';']],
     into => 'Word::Package',
 );

 print $rule->type  # Word
 print $rule->into  # Word::Package
 print $rule->value # (Undef)

 print join ', ', @{$rule->prec}; # Word::Reserved, package
 print join ', ', @{$rule->succ}; # Structure, ;


 $rule = Pistachio::Token::Transformer::Rule->new(
     type => 'Symbol',
     val  => sub {shift =~ /^&/},
     into => 'Symbol::Sub'
 );

 print $rule->value->('&call_sub') # 1 (True)
 print $rule->value->('wtf&')      #   (False)

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
