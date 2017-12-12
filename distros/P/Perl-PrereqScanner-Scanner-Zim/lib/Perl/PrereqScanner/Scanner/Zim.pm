
use 5.010;
use strict;
use warnings;

package Perl::PrereqScanner::Scanner::Zim;
$Perl::PrereqScanner::Scanner::Zim::VERSION = '0.2.0';
# ABSTRACT: Scan for modules loaded with Importer::Zim

use Moose;
with 'Perl::PrereqScanner::Scanner';

use PPIx::Literal ();

sub scan_for_prereqs {
    my ( $self, $ppi_doc, $req ) = @_;

    # regular use, require, and no
    my $includes = $ppi_doc->find('Statement::Include') || [];
    for my $node (@$includes) {

        if ( $self->_is_base_module( $node->module ) ) {

            my @args = PPIx::Literal->convert( $node->arguments );

            if (@args) {
                my $module = shift @args;
                my $opts = ref $args[0] eq 'HASH' ? shift @args : {};
                my $version =
                  exists $opts->{-version} ? $opts->{-version} : '0';
                $req->add_minimum( $module => $version );
            }
        }
    }
}

sub _is_base_module {
    state $IS_BASE = {
        map { $_ => 1 }
          qw(
          zim
          Importer::Zim
          Importer::Zim::Lexical
          Importer::Zim::EndOfScope
          Importer::Zim::Unit
          Importer::Zim::Bogus
          )
    };
    return $IS_BASE->{ $_[1] };
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Perl::PrereqScanner;
#pod     my $scanner = Perl::PrereqScanner->new( { extra_scanners => ['Zim'] } );
#pod     my $prereqs = $scanner->scan_ppi_document($ppi_doc);
#pod     my $prereqs = $scanner->scan_file($file_path);
#pod     my $prereqs = $scanner->scan_string($perl_code);
#pod     my $prereqs = $scanner->scan_module($module_name);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This scanner will look for dependencies from the L<Importer::Zim> module:
#pod
#pod     use zim 'Carp' => 'croak';
#pod
#pod     use Importer::Zim 'Scalar::Util' => qw(blessed);
#pod
#pod     use zim 'Test::More' => { -version => 0.88 } => qw(ok done_testing);

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::Zim - Scan for modules loaded with Importer::Zim

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    use Perl::PrereqScanner;
    my $scanner = Perl::PrereqScanner->new( { extra_scanners => ['Zim'] } );
    my $prereqs = $scanner->scan_ppi_document($ppi_doc);
    my $prereqs = $scanner->scan_file($file_path);
    my $prereqs = $scanner->scan_string($perl_code);
    my $prereqs = $scanner->scan_module($module_name);

=head1 DESCRIPTION

This scanner will look for dependencies from the L<Importer::Zim> module:

    use zim 'Carp' => 'croak';

    use Importer::Zim 'Scalar::Util' => qw(blessed);

    use zim 'Test::More' => { -version => 0.88 } => qw(ok done_testing);

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
