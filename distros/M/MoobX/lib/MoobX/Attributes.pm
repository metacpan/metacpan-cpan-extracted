package MoobX::Attributes;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Attributes to annotate variables as MoobX observables
$MoobX::Attributes::VERSION = '0.1.2';


use 5.20.0;

use MoobX '!:attributes';

use Attribute::Handlers;

no warnings 'redefine';

sub Observable :ATTR(SCALAR) {
    my ($package, $symbol, $referent, $attr, $data) = @_;

    MoobX::observable_ref($referent);
}

sub Observable :ATTR(ARRAY) {
    my ($package, $symbol, $referent, $attr, $data) = @_;

    MoobX::observable_ref($referent);
}

sub Observable :ATTR(HASH) {
    my ($package, $symbol, $referent, $attr, $data) = @_;

    MoobX::observable_ref($referent);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Attributes - Attributes to annotate variables as MoobX observables

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

    use MoobX;

    my $foo :Observable;

=head1 DESCRIPTION

Used internally by L<MoobX>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
