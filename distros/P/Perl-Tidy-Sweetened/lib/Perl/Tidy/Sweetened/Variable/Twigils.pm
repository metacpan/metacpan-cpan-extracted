package Perl::Tidy::Sweetened::Variable::Twigils;

# ABSTRACT: Perl::Tidy::Sweetened filter plugin to handle twigls

use 5.010;    # Needed for balanced parens matching with qr/(?-1)/
use strict;
use warnings;
use Carp;
$|++;

our $VERSION = '1.16';

sub new {
    my ( $class, %args ) = @_;
    croak 'twigil not specified' if not exists $args{twigil};
    croak 'marker not specified' if not exists $args{marker};
    $args{clauses} = [] unless exists $args{clauses};
    return bless {%args}, $class;
}

sub twigil { return $_[0]->{twigil} }
sub marker { return $_[0]->{marker} }

sub emit_placeholder {
    my ( $self, $varname ) = @_;

    # Store the signature and returns() for later use
    my $id = $self->{counter}++;
    $self->{store}->{$id} = $varname;

    return sprintf '$__%s_%s', $self->marker, $id;
}

sub emit_twigil {
    my ( $self, $id ) = @_;

    # Get the signature and returns() from store
    my $varname = $self->{store}->{$id};

    return sprintf '%s%s', $self->twigil, $varname;
}

sub prefilter {
    my ( $self, $code ) = @_;
    my $twigil = '\\' . $self->twigil;

    $code =~ s{
        (?: ^|\s)\K               # needs to be sperated by a space
        $twigil                   # the twigil (ie, $!)
        (?<varname> \w+)          # the variable name
    }{
        $self->emit_placeholder( $+{varname} )
    }egmx;

    return $code;
}

sub postfilter {
    my ( $self, $code ) = @_;
    my $marker = $self->marker;

    # Convert back to method
    $code =~ s{
        (?: ^|\s)\K            # needs to be sperated by a space
        \$ __ $marker          # keyword was convert to package
        _ (?<id> \d+ ) \b      # the method name and a word break
    }{
        $self->emit_twigil( $+{id} );
    }egmx;

    # Check to see if tidy turned it into "sub name\n{ #..."
    $code =~ s{
        ^\s*\K                   # preserve leading whitespace
        package             \s+  # method was converted to sub
        (?<subname> \w+)\n  \s*  # the method name and a newline
        (?<brace> \{ .*?)   [ ]* # opening brace on newline followed orig comments
        \#__$marker         \s+  # our magic token
        (?<id> \d+)              # our sub identifier
        [ ]*                     # trailing spaces (not all whitespace)
    }{
        $self->emit_keyword( $+{subname}, $+{brace}, $+{id} );
    }egmx;

    return $code;
}

1;

__END__

=pod

=head1 NAME

Perl::Tidy::Sweetened::Variable::Twigils - Perl::Tidy::Sweetened filter plugin to handle twigls

=head1 VERSION

version 1.16

=head1 SYNOPSIS

    our $plugins = Perl::Tidy::Sweetened::Pluggable->new();

    $plugins->add_filter(
        Perl::Tidy::Sweetened::Variable::Twigils->new(
            twigil => '$!',
            marker => 'TWG_BANG',
        ) );

=head1 DESCRIPTION

This is a Perl::Tidy::Sweetened filter which enables the use of twigils as
defined by the L<Twigils> module.  New accepts:

=over 4

=item twigil

    twigil => '$!'

Declares a new twigil. In this case to be used as C<$!variable>.

=item marker

    marker => 'TWG_BANG'

Provides a text marker to be used to flag the new keywords during
C<prefilter>. The source code will be filtered prior to formatting by
Perl::Tidy such that:

    $!class_attribute

is turned into:

    $__TWG_BANK_1

Then back into the original twigiled variable in the C<postfilter>.

=back

=head1 AUTHOR

Mark Grimes E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/Perl-Tidy-Sweetened>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/Perl-Tidy-Sweetened/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Grimes E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
