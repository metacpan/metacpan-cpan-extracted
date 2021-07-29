package Perl::PrereqScanner::Scanner::TestNeeds;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moose;

with 'Perl::PrereqScanner::Scanner';

use PPIx::Literal ();
use version 0.77;

use namespace::autoclean;

sub scan_for_prereqs {
    my ( $self, $ppi_doc, $req ) = @_;

    # regular use, require, and no
    my $includes = $ppi_doc->find('Statement::Include') || [];

  NODE:
    for my $node ( @{$includes} ) {
        next NODE if $node->module ne 'Test::Needs';

        my @args = PPIx::Literal->convert( $node->arguments );
        next NODE if !@args;

        for my $arg (@args) {
            if ( ref $arg eq ref {} ) {
                for my $module ( keys %{$arg} ) {
                    if ( $module eq 'perl' ) {
                        $req->add_minimum( $module => version->parse( $arg->{$module} )->numify() );
                    }
                    else {
                        $req->add_minimum( $module => "$arg->{$module}" );
                    }
                }
            }
            else {
                $req->add_minimum( $arg => 0 );
            }
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::TestNeeds - scan for modules loaded with Test::Needs

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

    use Perl::PrereqScanner;
    my $scanner = Perl::PrereqScanner->new( { extra_scanners => ['TestNeeds'] } );
    my $prereqs = $scanner->scan_ppi_document($ppi_doc);
    my $prereqs = $scanner->scan_file($file_path);
    my $prereqs = $scanner->scan_string($perl_code);
    my $prereqs = $scanner->scan_module($module_name);

=head1 DESCRIPTION

This is a scanner for L<Perl::PrereqScanner> that finds modules used with
L<Test::Needs>.

Note: The scanner currently does not detect modules loaded with the
C<test_needs> sub, only modules used with a use statement are detected.

    use Test::Needs 'Some::Module';

=head1 SEE ALSO

L<Perl::PrereqScanner>, L<Test::Needs>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Perl-PrereqScanner-Scanner-TestNeeds/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Perl-PrereqScanner-Scanner-TestNeeds>

  git clone https://github.com/skirmess/Perl-PrereqScanner-Scanner-TestNeeds.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
