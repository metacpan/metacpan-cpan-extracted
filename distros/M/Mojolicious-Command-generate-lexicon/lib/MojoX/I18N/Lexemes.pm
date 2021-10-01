package MojoX::I18N::Lexemes;

use strict;
use warnings;

use base 'Mojo::Base';

our $VERSION = 0.995;

use Mojo::Template;
use Mojo::Server;

__PACKAGE__->attr(renderer  => sub { Mojo::Template->new });
__PACKAGE__->attr(helper    => sub {'l'});
__PACKAGE__->attr(helper_re => sub {qr/l\s*(\([^\)]+\))/});

sub parse {
    my ($self, $template) = @_;

    my $mt = $self->renderer;
    $mt->parse($template);

    my $lexemes = [];

    my $multiline = 0;
    my $args      = '';
    foreach my $line (@{$mt->tree}) {
        for (my $j = 0; $j < @{$line}; $j += 2) {
            my $type  = $line->[$j];
            my $value = $line->[$j + 1] || '';
            if ($value) {
                $value =~ s/^\s*//;
            }

            if ($multiline) {
                if ($type eq 'expr' || $type eq 'escp' || $type eq 'line') {
                    $args .= $value;
                }
                else {
                    $multiline = 0;
                }
            }
            elsif (($type eq 'expr' or $type eq 'escp')
                && $value
                && substr($value, 0, length($self->helper) + 1) eq
                $self->helper . ' ')
            {

                $args = substr $value, length($self->helper) + 1;

                unless (($line->[$j + 2] || '') eq 'text') {

                    $multiline = 1;
                }

            }
            elsif (($type eq 'expr' or $type eq 'escp')
                && $value
                && $value =~ $self->helper_re)
            {
                $args = $1;
            }

            if ($args && !$multiline) {
                my ($lexem) = (eval $args);
                push @$lexemes, $lexem if $lexem;

                $args = '';
            }

        }
    }
    return $lexemes;
}

1;
__END__

=head1 NAME

L<MojoX::I18N::Lexemes> - parse lexemes from Mojolicious template

=head1 SYNOPSIS

    use MojoX::I18N::Lexemes;

    my $l = MojoX::I18N::Lexemes->new;
    my $lexemes = $l->parse(q|Simple <%=l 'lexem' %>|);

=head1 DESCRIPTION

L<MojoX::I18N::Lexemes> parses internatinalized lexemes from Mojolicious
templates.

=head1 ATTRIBUTES

L<MojoX::I18N::Lexemes> implements the following attributes.

=head2 C<helper>

    my $helper = $l->helper;
    $l         = $l->helper('l');

I18N template helper, defaults to 'l'.

=head2 C<renderer>

    my $renderer = $l->renderer;
    $l           = $l->renderer(Mojo::Template->new);

Template object to use for parsing operations, by default a L<Mojo::Template>
object will be used;

=head1 METHODS

L<MojoX::I18N::Lexemes> inherits all methods from L<Mojo::Base> and
implements the following ones.

=head2 C<parse>

    my $lexemes = $l->parse($template);

Parses template and returns arrayref of found lexemes.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/und3f/mojoliciousx-lexicon

=head1 AUTHOR

Sergey Zasenko, C<undef@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2015-2021, Serhii Zasenko

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=cut

