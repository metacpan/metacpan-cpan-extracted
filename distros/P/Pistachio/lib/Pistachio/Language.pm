package Pistachio::Language;
# ABSTRACT: provides an API for plugging arbitrary language tokenizers and stylizers into Pistachio

use strict;
use warnings;
our $VERSION = '0.10'; # VERSION

# @param string $type Object type.
# @param string $lang A language identifier. E.g., 'Perl5'.
# @param hash %subs Map of {string => coderef}.
# @return Pistachio::Language
sub new {
    my ($type, $lang, %subs) = (shift, shift, @_);
    bless [
        $lang, 
        $subs{tokens},
        $subs{type_to_style},
        $subs{transform_rules} || sub {[]}
        ], $type;
}

# @param Pistachio::Language $this
# @return string A language identifier. E.g., 'Perl5'.
sub language { my $this = shift; $this->[0] }

# @param Pistachio::Language $this
# @param scalar/ref Input text.
# @return arrayref Array of Pistachio::Tokens.
sub tokens { my $this = shift; $this->[1]->(shift) }

# @param Pistachio::Language $this
# @param string A Pistachio::Token type.
# @return string CSS style definition, per token type.
sub type_to_style { my $this = shift; $this->[2]->(shift) }

# @param Pistachio::Language $this
# @return arrayref Transform rules (possibly empty).
sub transform_rules { my $this = shift; $this->[3]->() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pistachio::Language - provides an API for plugging arbitrary language tokenizers and stylizers into Pistachio

=head1 VERSION

version 0.10

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
