use utf8;

package SemanticWeb::Schema::AutomatedTeller;

# ABSTRACT: ATM/cash machine.

use Moo;

extends qw/ SemanticWeb::Schema::FinancialService /;


use MooX::JSON_LD 'AutomatedTeller';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AutomatedTeller - ATM/cash machine.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

ATM/cash machine.

=head1 SEE ALSO

L<SemanticWeb::Schema::FinancialService>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
