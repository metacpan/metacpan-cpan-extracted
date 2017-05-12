package Perl::PrereqScanner::Lite::Scanner::Moose;
use strict;
use warnings;
use utf8;
use Perl::PrereqScanner::Lite::Constants;

sub scan {
    my ($class, $c, $token, $token_type) = @_;

    my $token_data = $token->data;
    if ($token_type == KEY && ($token_data eq 'extends' || $token_data eq 'with')) {
        $c->{is_in_moose_inherited} = 1;
        return 1;
    }

    if ($c->{is_in_moose_inherited}) {
        # to skip content which is is curly bracket -> { ... }
        {
            if ($token_type == LEFT_BRACE) {
                $c->{is_in_moose_role_def} = 1;
                return 1;
            }

            if ($token_type == RIGHT_BRACE) {
                $c->{is_in_moose_role_def} = 0;
                return 1;
            }

            if ($c->{is_in_moose_role_def}) {
                return 1;
            }
        }

        # For qw() notation
        # e.g.
        #   extends qw/Foo Bar/;
        #   with qw/Foo Bar/;
        if ($token_type == REG_LIST) {
            $c->{is_in_moose_inherited_reglist} = 1;
            return 1;
        }
        if ($c->{is_in_moose_inherited_reglist} && !$c->{does_exist_moose_garbage}) {
            if ($token_type == REG_EXP) {
                for my $_module_name (split /\s+/, $token_data) {
                    $c->add_minimum($_module_name => 0);
                }
                $c->{is_in_moose_inherited_reglist} = 0;
            }
            return 1;
        }

        # For simply list
        # e.g.
        #   extends ('Foo', 'Bar');
        #   with ('Foo', 'Bar');
        if ($token_type == LEFT_PAREN) {
            $c->{is_in_moose_inherited_list} = 1;
            return 1;
        }
        if ($token_type == RIGHT_PAREN) {
            $c->{is_in_moose_inherited_list} = 0;
            return 1;
        }
        if ($c->{is_in_moose_inherited_list}) {
            if (($token_type == STRING || $token_type == RAW_STRING) && !$c->{does_exist_moose_garbage}) {
                $c->add_minimum($token_data => 0);
            }
            return 1;
        }

        # For string
        # e.g.
        #   extends "Foo"
        #   with "Foo"
        if ((($token_type == STRING || $token_type == RAW_STRING)) && !$c->{does_exist_moose_garbage}) {
            $c->add_minimum($token_data => 0);
            return 1;
        }

        # End of extends or with
        if ($token_type == SEMI_COLON) {
            $c->{is_in_moose_inherited}         = 0;
            $c->{is_in_moose_inherited_reglist} = 0;
            $c->{is_in_moose_inherited_list}    = 0;
            $c->{does_exist_moose_garbage}      = 0;
            return 1;
        }

        # For
        #   extends 'Class1', 'Class2';
        if ($token_type != COMMA) {
            $c->{does_exist_moose_garbage} = 1;
        }

        return 1;
    }

    return;
}

1;

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::Lite::Scanner::Moose - Extra Perl::PrereqScanner::Lite Scanner for Moose Family

=head1 SYNOPSIS

    use Perl::PrereqScanner::Lite;

    my $scanner = Perl::PrereqScanner::Lite->new;
    $scanner->add_extra_scanner('Moose');

=head1 DESCRIPTION

Perl::PrereqScanner::Lite::Scanner::Moose is the extra scanner for Perl::PrereqScanner::Lite. This scanner supports C<extends> and C<with> notation for Moose family.

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

