package Parse::KeyValue::Shellish;
use 5.008005;
use strict;
use warnings;
use parent qw/Exporter/;
use Parse::KeyValue::Shellish::Parser;

our @EXPORT_OK = qw/parse_key_value/;
our $VERSION   = "0.01";

sub parse_key_value {
    my ($str) = @_;

    my $parser = Parse::KeyValue::Shellish::Parser->new($str);
    $parser->parse;
}

1;
__END__

=encoding utf-8

=for stopwords shellish

=head1 NAME

Parse::KeyValue::Shellish - Parses the key-value pairs like a shell script

=head1 SYNOPSIS

    use Parse::KeyValue::Shellish qw/parse_key_value/;

    my $str    = 'foo=bar hoge=(fuga piyo)';
    my $parsed = parse_key_value($str); # => is_deeply {foo => 'bar', hoge => ['fuga', 'piyo']}

=head1 DESCRIPTION

Parse::KeyValue::Shellish parses the key-value pairs like a shell script, means key and value are separated by '=' (for example C<foo=bar>).

This is just *** shellish ***, means this module doesn't emulates the shell completely, It's spec.  But I'm willing to support features if someone so wish it :)

=head1 FUNCTIONS

=over 4

=item * parse_key_value($str)

Parses C<$str> as shellish key-value and returns hash reference of parsed result.
If value is surrounded by parenthesis, it will be evaluated as array.
Blocks of key-value must be separated by white-space.

e.g.

    parse_key_value('foo=bar buz=q\ ux hoge=(fuga piyo)');
    # Result:
    #   {
    #       foo  => 'bar',
    #       buz  => 'q uz',
    #       hoge => ['fuga', 'piyo']
    #   }

This function will croak if it has given a string which cannot be parsed.

=back

=head1 NOTES

=head2 Value can contain '='

For example, this module can parse string like a C<foo=bar=buz>. Result of it will be C<{foo =E<gt> 'bar=buz'}>.

=head2 You can quote the value

Of course you can quote the value like a C<foo='bar buz'>. Result will be C<foo =E<gt> 'bar buz'>.

=head2 You can escape the character which in value

You can escape the character by backslash, for example C<foo=ba\ r buz=\(\)>. Result of parsing it will be C<foo =E<gt> 'ba r', buz =E<gt> '()'>.

=head3 You cannot escape the character if it is quoted by single quotes.

You cannot escape the character if it is quoted by single quotes. For example, C<foo='\'> will be parsed as C<for =E<gt> '\'>.

So it will be fail to parse C<foo='\''> because single quotes are unbalanced. As the reason for this, C<\'> isn't escaped.

=head3 Shell recognizes C<foo=\\> as C<foo =E<gt> '\'>, but this module doesn't

If you require an equivalent function, please give like so C<foo=\\\\>.

This notation unlike the shells one, this is not intuitive. But I have no ideas of the way to handle this well...

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

