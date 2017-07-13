package Nuspec::Reader;

our $VERSION = '0.1.0';

use 5.012;
use strict;
use warnings;
use Class::Tiny qw( nuspec_filename );
use XML::LibXML;
use XML::LibXML::XPathContext;

sub get_dependencies {
    my ($self) = @_;

    my $dom = XML::LibXML->load_xml(location => $self->nuspec_filename);
    my $xpath_context = XML::LibXML::XPathContext->new($dom->documentElement);
    $xpath_context->registerNs(
        ns => 'http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd'
    );
    my $dependency_xpath =
        '/ns:package' .
        '/ns:metadata' .
        '/ns:dependencies' .
        '/ns:dependency';

    return [
        map {
            {
                id      => $_->findvalue('@id'),
                version => $_->findvalue('@version'),
            }
        } $xpath_context->findnodes($dependency_xpath)
    ]
}

sub get_files {
    ...
}

sub get_version {
    ...
}

sub get_package_id {
    ...
}


1;
__END__

=encoding utf-8

=head1 NAME

Nuspec::Reader - Parse .nuspec file and get access to different parts.

=head1 SYNOPSIS

    use Nuspec::Reader;

=head1 DESCRIPTION

Nuspec::Reader is ...

=head1 LICENSE

Copyright (C) Avast Software

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Miroslav Tynovsky E<lt>tynovsky@avast.comE<gt>

=cut

