
use 5.010;
use strict;
use warnings;

package Perl::PrereqScanner::Scanner::Jojo;
$Perl::PrereqScanner::Scanner::Jojo::VERSION = '0.3.0';
# ABSTRACT: Scan for modules loaded with Jojo::Base

use Moose;
extends 'Perl::PrereqScanner::Scanner::Mojo';

sub _is_base_module { $_[1] eq 'Jojo::Base' }

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Perl::PrereqScanner;
#pod     my $scanner = Perl::PrereqScanner->new( { extra_scanners => ['Jojo'] } );
#pod     my $prereqs = $scanner->scan_ppi_document($ppi_doc);
#pod     my $prereqs = $scanner->scan_file($file_path);
#pod     my $prereqs = $scanner->scan_string($perl_code);
#pod     my $prereqs = $scanner->scan_module($module_name);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This scanner will look for dependencies from the L<Jojo::Base> module:
#pod
#pod     use Jojo::Base 'SomeBaseClass';

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::Jojo - Scan for modules loaded with Jojo::Base

=head1 VERSION

version 0.3.0

=head1 SYNOPSIS

    use Perl::PrereqScanner;
    my $scanner = Perl::PrereqScanner->new( { extra_scanners => ['Jojo'] } );
    my $prereqs = $scanner->scan_ppi_document($ppi_doc);
    my $prereqs = $scanner->scan_file($file_path);
    my $prereqs = $scanner->scan_string($perl_code);
    my $prereqs = $scanner->scan_module($module_name);

=head1 DESCRIPTION

This scanner will look for dependencies from the L<Jojo::Base> module:

    use Jojo::Base 'SomeBaseClass';

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
