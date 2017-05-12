package Perl6::PVIP;
use 5.008005;
use strict;
use warnings;
use parent qw(Exporter);

our $VERSION = "0.12";

use Perl6::PVIP::_consts;
use Perl6::PVIP::Node;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my $class = shift;
    return bless {
    }, $class;
}

sub parse_string {
    my ($self, $code) = @_;
    my ($node, $err) = Perl6::PVIP::_parse_string($code);
    $self->{errstr} = $err;
    return $node;
}

sub errstr {
    my $self = shift;
    $self->{errstr};
}

1;
__END__

=for stopwords pvip

=encoding utf-8

=head1 NAME

Perl6::PVIP - Perl5 bindings for pvip

=head1 SYNOPSIS

    use Perl6::PVIP;

    my $pvip = Perl6::PVIP->new();
    my $node = $pvip->parse_string('say(1)');
    say $node->as_sexp();

=head1 DESCRIPTION

Perl6::PVIP is a wrapper module for PVIP. PVIP is a parser library for Perl6 syntax.

PVIP covers 32% of perl6 syntax. Current development status is here: http://hf.64p.org/list/perl6/pvip.

B<This library is BETA quality. Any interface will change without notice>.

=head1 METHODS

=over 4

=item my $pvip = Perl6::PVIP->new();

Create new instance of this module.

=item my $node = $pvip->parse_string($code: Str) : Perl6::PVIP::Node

Parse string and generate Perl6::PVIP::Node object.

=item $pvip->errstr() : Str

Get the error message from last parsing result.

=back

=head1 CONSTANTS

The constants named C<PVIP_NODE_*> and C<PVIP_CATEGORY_*> was exported by default.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

PVIP repository is here: L<https://github.com/tokuhirom/pvip/>

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

