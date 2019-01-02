package OTRS::OPM::Analyzer::Role::Documentation;

# ABSTRACT: check if .pod, .pdf or .xml files are included

use Moose::Role;

with 'OTRS::OPM::Analyzer::Role::Base';

sub check {
    my ($self,$opm) = @_;
    
    my $has_documentation = 0;
    
    FILE:
    for my $file ( $opm->files ) {
        if ( $file->{filename} =~ m{ /doc/ .*?\.(?:xml|pod|pdf) \z } ) {
            $has_documentation = 1;
            last FILE;
        }
    }
    
    return $has_documentation;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Role::Documentation - check if .pod, .pdf or .xml files are included

=head1 VERSION

version 0.07

=head1 METHODS

=head2 check

Check if some kind of documentation is included

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
