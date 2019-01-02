package OTRS::OPM::Analyzer::Role::BasicXMLCheck;

# ABSTRACT: Check if the .xml files can be parsed

use Moose::Role;
use XML::LibXML;

with 'OTRS::OPM::Analyzer::Role::Base';

sub check {
    my ( $self, $document ) = @_;
    
    return if $document->{filename} !~ m{ \.xml \z }xms;
    
    my $content = $document->{content};    
    my $check_result = '';
    
    eval {
        my $parser = XML::LibXML->new;
        $parser->parse_string( $content );
    } or $check_result = $@;
    
    return $check_result;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Role::BasicXMLCheck - Check if the .xml files can be parsed

=head1 VERSION

version 0.07

=head1 DESCRIPTION

All .xml files are checked if they can be parsed with C<XML::LibXML>

=head1 METHODS

=head2 check

Checks if the document can be parsed by L<XML::LibXML>

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
