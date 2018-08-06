package SemanticWeb::Schema::Corporation;

# ABSTRACT: Organization: A business corporation.

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'Corporation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has ticker_symbol => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'tickerSymbol',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Corporation - Organization: A business corporation.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

Organization: A business corporation.

=head1 ATTRIBUTES

=head2 C<ticker_symbol>

C<tickerSymbol>

The exchange traded instrument associated with a Corporation object. The
tickerSymbol is expressed as an exchange and an instrument name separated
by a space character. For the exchange component of the tickerSymbol
attribute, we reccommend using the controlled vocaulary of Market
Identifier Codes (MIC) specified in ISO15022.

A ticker_symbol should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
