package Perl::PrereqScanner::Lite::Scanner::Version;
use strict;
use warnings;
use utf8;
use Perl::PrereqScanner::Lite::Constants;

sub scan {
    my ($class, $c, $token, $token_type) = @_;

    if ($token_type == KEY || $token_type == NAMESPACE || $token_type == NAMESPACE_RESOLVER) {
        $c->{not_decl_module_name} .= $token->{data};
        return 1;
    }

    if ($token_type == METHOD && $token->{data} eq 'VERSION') {
        $c->{is_version_decl} = 1;
        return 1;
    }

    if ($c->{is_version_decl} && $token_type == INT || $token_type == DOUBLE || $token_type == VERSION_STRING) {
        if ($c->{module_reqs}->{requirements}->{$c->{not_decl_module_name}}) {
            $c->add_minimum($c->{not_decl_module_name} => $token->{data});
        }
        $c->{is_version_decl} = 0;
        $c->{not_decl_module_name} = '';
        return 1;
    }

    if ($token_type == SEMI_COLON) {
        $c->{is_version_decl} = 0;
        $c->{not_decl_module_name} = '';
        return 1;
    }
}

1;

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::Lite::Scanner::Version - Extra Perl::PrereqScanner::Lite Scanner for VERSION method

=head1 SYNOPSIS

    use Perl::PrereqScanner::Lite;

    my $scanner = Perl::PrereqScanner::Lite->new;
    $scanner->add_extra_scanner('Version');

=head1 DESCRIPTION

Perl::PrereqScanner::Lite::Scanner::Version is the extra scanner for Perl::PrereqScanner::Lite.
This scanner supports C<VERSION> method. It retrieves version from the argument of C<VERSION>.

For example,

    require Foo::Bar;
    Foo::Bar->VERSION(1.00);

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

