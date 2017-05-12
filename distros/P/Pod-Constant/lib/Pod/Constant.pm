package Pod::Constant;
our $VERSION = 0.1;
#PODNAME: Pod::Constant
#ABSTRACT: source constants from POD to avoid repetition


use 5.005;
use warnings;
use strict;
use Carp;
use Scalar::Util qw(looks_like_number);
use Text::Balanced qw(extract_delimited);

BEGIN {
    use Pod::Parser;
    our @ISA = qw(Pod::Parser);
};

sub import {
    my $caller = caller;
    my ($class, @args) = @_;
    my $pod_source = $0;

    my $parser = $class->new;
    $parser->{vars} = {};
    $parser->parse_from_file($pod_source, undef);

    my %vars = %{$parser->{vars}};
    my @export = (@args && lc $args[0] eq ':all') ? keys %vars : @args;

    for my $sym (@export) {
        $sym =~ /^[\w\$]/ or croak "Pod::Constant only supports scalar values";
        $sym =~ s/^(\$)//;
        my $sigil = $1 || '$';
        no strict 'refs';
        exists $vars{$sigil.$sym} or croak "No such constant '$sigil$sym' in POD";
        *{$caller . '::' . $sym} = \$vars{$sigil . $sym};
    }

    return;
}

# Pod::Parser hooks
sub textblock {
    my ($self, $block) = @_;
    my $tree = $self->parse_text($block);
    my @children = $tree->children;
    while ( my $item = shift @children ) {
        next unless ref $item && ref $item eq 'Pod::InteriorSequence';
        next unless $item->cmd_name eq 'X';

        my @ichildren = $item->parse_tree->children;
        next unless @ichildren == 1;
        next unless $ichildren[0] =~ /^\s*([\$\@%])?(\w*)\s*=\s*(.*)$/;
        my ($sigil, $var, $trailing) = ($1, $2, $3);
        $sigil ||= '$';
        $sigil eq '$' or croak "Pod::Constant only supports scalar values";
        $var = $sigil . $var;
        $trailing eq '' or croak "X<> tag should not include value";
        my $text = shift @children;
        ref $text eq '' or croak "Invalid POD: X<> followed by another POD construct";
        my $value = '';

        if ( $text =~ /^\s*(['"`])/ ) {
            $value = extract_delimited( $text, $1 );
            $value = substr $value, 1, -1;  # strip quotes
        }
        elsif ($text =~ /^\s*(\S+)/) {
            $value = $1;
            # This is a manual list because [[:punct:]] includes / and _
            $value =~ s/[!?,.:;]+$//;

            # If it looks like a number, strip commas 
            my $number = $value;
            $number =~ tr/,//d;
            if (looks_like_number($number)) {
                $value = $number;
            }
        }
        else {
            croak "No value provided for '$var'";
        }

        if ( exists $self->{vars}{$var} ) {
            $self->{vars}{$var} eq $value
                or croak "Variable '$var' specified twice with two different values";
        }
        else {
            $self->{vars}{$var} = $value;
        }
    }
}

1;

__END__
=pod

=head1 NAME

Pod::Constant - source constants from POD to avoid repetition

=head1 VERSION

version 0.1

=head1 SYNOPSIS

 In your POD:

     =head1 DESCRIPTION
 
     The maximum number of flarns is X<$MAX_FLARNS=>4,096.

 In your code:

     use Pod::Constant qw($MAX_FLARNS);

     # Use $MAX_FLARNS all over the place

=head1 DESCRIPTION

It is often neccessary to refer to 'default values' or important constant
values in your POD, but then you have to put them in your code as well, and
they can easily get out of sync. C<use> this module and you can import
variables from the POD directly, avoiding repetition.

The lazy may C<use Pod::Constant ':all'> to import any and all variables
from POD.

=head1 USAGE

The C<XE<lt>...E<gt>> syntax allows you to place variable names next to any use
of a constant in your POD, e.g.

  The maximum number of hops is X<$MAX_HOPS=>4,096.

These C<XE<lt>...E<gt>> hints are rendered as an empty string by POD readers,
but can be seen by C<Pod::Constant>. The value following the C<XE<lt>...E<gt>>
construct may be:

=over

=item *

A quoted string (single, double or backticks) - quotes will be removed.
Special characters (e.g. "\n") are B<not> treated specially.

=item *

An unquoted number. Commas and trailing punctuation are removed.

=item *

An unquoted string. Trailing punctuation is removed, and the string will
be read up to the first whitespace character. Not recommended but works
OK for file paths, etc.

=back

Whitespace is ignored, so for example C<XE<lt>$foo = E<gt>  123> is
permissible.

"Trailing punctuation" is defined as the ASCII characters '.', ',',
':', ';', '!' and '?'.

=head1 LIMITATIONS

Currently only scalar values are supported.

=head1 AUTHOR

Richard Harris <RJH@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Richard Harris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

