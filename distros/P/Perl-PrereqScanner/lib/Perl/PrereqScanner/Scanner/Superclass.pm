use strict;
use warnings;

package Perl::PrereqScanner::Scanner::Superclass;
# ABSTRACT: scan for modules loaded with superclass.pm
$Perl::PrereqScanner::Scanner::Superclass::VERSION = '1.023';
use Moose;
with 'Perl::PrereqScanner::Scanner';

#pod =head1 DESCRIPTION
#pod
#pod This scanner will look for dependencies from the L<superclass> module:
#pod
#pod     use superclass 'Foo', Bar => 1.23;
#pod
#pod =cut

my $mod_re = qr/^[A-Z_a-z][0-9A-Z_a-z]*(?:(?:::|')[0-9A-Z_a-z]+)*$/;

sub scan_for_prereqs {
    my ( $self, $ppi_doc, $req ) = @_;

    # regular use, require, and no
    my $includes = $ppi_doc->find('Statement::Include') || [];
    for my $node (@$includes) {
        # inheritance
        if ( $node->module eq 'superclass' ) {
            # rt#55713: skip arguments like '-norequires', focus only on inheritance
            my @meat = grep {
                     $_->isa('PPI::Token::QuoteLike::Words')
                  || $_->isa('PPI::Token::Quote')
                  || $_->isa('PPI::Token::Number')
            } $node->arguments;

            my @args = map { $self->_q_contents($_) } @meat;

            while (@args) {
                my $module = shift @args;
                my $version = ( @args && $args[0] !~ $mod_re ) ? shift(@args) : 0;
                $req->add_minimum( $module => $version );
            }
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::Superclass - scan for modules loaded with superclass.pm

=head1 VERSION

version 1.023

=head1 DESCRIPTION

This scanner will look for dependencies from the L<superclass> module:

    use superclass 'Foo', Bar => 1.23;

=head1 AUTHORS

=over 4

=item *

Jerome Quelin

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
