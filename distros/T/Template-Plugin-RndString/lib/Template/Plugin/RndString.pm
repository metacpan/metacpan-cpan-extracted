package Template::Plugin::RndString;
use 5.008001;
use strict;
use warnings;
use base 'Template::Plugin';
use Crypt::GeneratePassword qw(chars);

our $VERSION = "0.02";

sub new {
    my ($class, $context, $args) = @_;

    my $chrset = [0..9, 'A'..'Z', 'a'..'z'];
    if ($args && (ref $args eq 'HASH')) {
        if (defined $args->{chrset}) {
            if (ref $args->{chrset} eq 'ARRAY') {
                $chrset = $args->{chrset};
            }
            elsif (!ref $args->{chrset}) {
                my @s = split '', $args->{chrset};
                $chrset = \@s;
            }
        }
    }

    bless { 
        context => $context,
        chrset  => $chrset,
    }, $class;
}

sub make {
    my ($self, $minlen, $maxlen) = @_;
    my $fs = "";

    if ($minlen && $maxlen) {
        unless (($minlen =~ m/^\d+$/) && ($maxlen =~ m/^\d+$/) && ($minlen <= $maxlen)) {
            $minlen = $maxlen = 32;
        }
    }
    else {
        $minlen = $maxlen = 32;
    }

    srand;

    my @letters = grep {m/^[A-Z]$/i} @{$self->{chrset}};

    if (@letters) {
        --$minlen; --$maxlen;
        $fs = chars(1,1, \@letters);
    }

    my $len = int($minlen + (1+$maxlen-$minlen)*rand);
    return $fs . chars($len,$len, $self->{chrset});
}
1;

__END__

=encoding utf-8

=head1 NAME

Template::Plugin::RndString - Plugin to create random strings

=head1 SYNOPSIS

    [% USE RndString(chrset => ['a'..'z']) %]

    Result: [% RndString.make(min_length,max_length) %]

=head1 OPTIONS 

=over

=item chrset

Optional. It must be an array ref of characters to use or a string (e.g 'abcdefgh'). If not defined, default is an alphanumeric symbols from ascii table. If possible, first symbol of output string always will be a letter.

=back

=head1 SEE ALSO

Template Toolkit is a fast, flexible and highly extensible template processing system L<http://template-toolkit.org/>
Crypt::GeneratePassword - generate secure random pronounceable passwords L<http://search.cpan.org/~neilb/Crypt-GeneratePassword/lib/Crypt/GeneratePassword.pm>

=head1 LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

bbon E<lt>bbon@mail.ruE<gt>

=cut

