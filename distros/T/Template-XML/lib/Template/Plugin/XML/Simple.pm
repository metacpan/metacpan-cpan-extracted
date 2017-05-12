#============================================================= -*-Perl-*-
#
# Template::Plugin::XML::Simple
#
# DESCRIPTION
#   Template Toolkit plugin interfacing to the XML::Simple.pm module.
#
# AUTHOR
#   Andy Wardley   <abw@cpan.org>
#
# COPYRIGHT
#   Copyright (C) 2001-2006 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::XML::Simple;

use strict;
use warnings;
use base 'Template::Plugin';
use XML::Simple;

our $VERSION = 2.66;


#------------------------------------------------------------------------
# new($context, $file_or_text, \%config)
#------------------------------------------------------------------------

sub new {
    my $class   = shift;
    my $context = shift;
    my $input   = shift;
    my $args    = ref $_[-1] eq 'HASH' ? pop(@_) : { };

    if (defined($input)) {  
        # an input parameter can been be provided and can contain 
        # XML text or the filename of an XML file, which we load
        # using insert() to honour the INCLUDE_PATH; then we feed 
        # it into XMLin().
        $input = $context->insert($input) unless ( $input =~ /</ );
        return XMLin($input, %$args);
    } 
    else {
        # otherwise return a XML::Simple object
        return new XML::Simple;
    }
}



#------------------------------------------------------------------------
# _throw($errmsg)
#
# Raise a Template::Exception of type XML.Simple via die().
#------------------------------------------------------------------------

sub _throw {
    my ($self, $error) = @_;
    die (Template::Exception->new('XML.Simple', $error));
}


1;

__END__

=head1 NAME

Template::Plugin::XML::Simple - Plugin interface to XML::Simple

=head1 SYNOPSIS

    # load plugin and specify XML file to parse
    [% USE xml = XML.Simple(xml_file_or_text) %]

=head1 DESCRIPTION

This is a Template Toolkit plugin interfacing to the XML::Simple
module.

=head1 AUTHORS

This plugin wrapper module was written by Andy Wardley.

The XML::Simple module which implements all the core functionality was
written by Grant McLean.

=head1 COPYRIGHT

Copyright (C) 1996-2006 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin>, L<XML::Simple>, L<XML::Parser>

