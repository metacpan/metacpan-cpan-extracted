#!/usr/bin/perl
use Moose;
use Try::Tiny;
use Class::Load;
=head1 NAME

xxslt.pl - load Perl extension classes while performing XSLT transformations.

=head1 VERSION

version 1.140260

=head1 SYNOPSIS

xxslt.pl My::Extenstion::Class stylesheet xml

Example:

    xxslt.pl My::Extension::Class mystyle.xsl source.xml

Or, you can read the XML to be transformed from STDIN by substituting a dash '-' for the file path:

    generate_xml.sh | xxslt.pl My::Extension::Class mystyle.xsl -

=head1 DESCRIPTION

C<xxlt.pl> is a command-line interface to L<Role::LibXSLT::Extender>, which allows you to easily register classes of Perl extension functions for use from within your XSLT stylesheets..

=cut


my $extension_class = shift;
my $stylesheet_file = shift;
my $xml_file        = shift;
my %xml_args        = ();

# sanity checking
die usage() unless $extension_class && $stylesheet_file && $xml_file;

# use the typical convention for reading from STDIN
if ( $xml_file eq '-' ) {
    while( <STDIN> ) {
        $xml_args{string} .= $_;
    }
}
else {
    die "XML document '$xml_file' does not exist.\n" unless -f $xml_file;
    $xml_args{location} = $xml_file;
}

# load the extension class
try {
    Class::Load::load_class( $extension_class );
}
catch {
    die "Couldn't load extension class '$extension_class': $_ \n";
};

die "Styleheet file '$stylesheet_file' does not exist.\n" unless -f $stylesheet_file;

my $xslt = $extension_class->new();

my $style_dom = XML::LibXML->load_xml( location => $stylesheet_file );
my $input_dom = XML::LibXML->load_xml( %xml_args );
my $stylesheet = $xslt->parse_stylesheet($style_dom);


my $transd_input = $stylesheet->transform( $input_dom );
print $stylesheet->output_as_bytes($transd_input);

exit(0);

sub usage {
    die "$0 extension_class stylesheet_file xml_file\n";
}
