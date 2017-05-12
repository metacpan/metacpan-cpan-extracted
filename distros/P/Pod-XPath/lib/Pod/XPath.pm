package Pod::XPath;

# ----------------------------------------------------------------------
# $Id: XPath.pm,v 1.4 2003/09/12 16:04:38 dlc Exp $ 
# ----------------------------------------------------------------------
# Pod::XPath -- use XPath expressions to navigate a POD document.
# Copyright (C) 2003 darren chamberlain <darren@cpan.org>
# ----------------------------------------------------------------------

use strict;
use vars qw($VERSION $REVISION $XPATH_CLASS);

$VERSION = "1.00";
$REVISION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;
$XPATH_CLASS = 'XML::XPath' unless defined $XPATH_CLASS;

use Carp qw(carp);
use IO::Handle qw(SEEK_SET);
use IO::String;
use Pod::XML;
use UNIVERSAL::require;

sub new {
    my ($class, $pod) = @_;
    my ($parser, $data, $string);

    $string = IO::String->new;
    $parser = Pod::XML->new();

    if (UNIVERSAL::isa($pod, 'GLOB')) {
        # Filehandle
        $parser->parse_from_filehandle($pod, $string);
    }
    elsif (-f $pod) {
        # Given a filename
        $parser->parse_from_file($pod, $string);
    }
    elsif ($pod =~ /::/) {
        # A module name
        $pod->require
            || die $UNIVERSAL::require::ERROR;

        my $podfile = $pod;
        $podfile =~ s#::#/#g;
        $podfile .= '.pm';
        $parser->parse_from_file($INC{$podfile}, $string);
    }
    else {
        my $stuff = ref($pod)  || substr($pod, 0, 32) . "...";
        warn "$class can't use '$stuff' as input.\n"
           . "Sorry it didn't work out.\n";
    }

    {   # Turn the IO::String into a string
        local $/;
        $string->seek(0, SEEK_SET);
        $string = <$string>;
    }

    $XPATH_CLASS->require;

    return $XPATH_CLASS->new(ioref => $string);
}

1;
__END__

=head1 NAME

Pod::XPath - use XPath expressions to navigate a POD document

=head1 SYNOPSIS

    use Pod::XPath;
    my $pod = Pod::XPath->new($podfile);

    my $head1nodes = $pod->find("/pod/sect1");

=head1 DESCRIPTION

C<Pod::XPath> allows accessing elements of a POD document using XPath
expressions.  The document or string is first turned into XML using
C<Pod::XML>, and then passed to C<XML::XPath> to parse.

All standard XPath expressions can be used to retrieve data from the
document.  See L<Pod::XML> for a description of the document produced
from the POD document.  The object returned from C<new> is an instance
of C<XML::XPath>; see L<XML::XPath>.

C<Pod::XPath> can be invoked with any one of the following:

=over 4

=item /path/to/file.pod

A path to a POD document.  If the path is relative, it is taken as
relative to the current working directory.

    my $pod = Pod::XPath->new("$ENV{HOME}/lib/MyDoc.pod");

=item Module::Name

A module name.  This has to contain I<::>.

    my $pod = Pod::XPath->new("Pod::XPath");

=item GLOB ref

A filehandle.

    my $pod = Pod::XPath->new(\*STDIN);

=back

=head1 EXAMPLES

To get all the major sections of a document (i.e., all the C<head1>
sections), use:

    my $head1_nodeset = $pod->find("/pod/sect1");

From there, to get subsections:

    for my $head1 ($head1_nodeset->get_nodelist) {
        print $head1->find("title/text()"), "\n";
        $head2_nodeset = $head1->find("sect2");
        
        for $head2 ($head2_nodeset->get_nodelist) {
            print "\t", $head2->find("title/text()"), "\n"
        }
    }

To get the SYNOPSIS:

    $synopsis = $pod->find('/pod/sect1[title/text() = "SYNOPSIS"]');

Or the SEE ALSO list:

    $see_also = $pod->find('/pod/sect1[title/text() = "SEE ALSO"]');

The author's name:

    print $pod->find('/pod/sect1[title/text() = "AUTHOR"]/para[1]/text()');

To get the name of the version of C<Data::Dumper>:

    use Data::Dumper;
    my $pod = Pod::XPath->new($INC{'Data/Dumper.pm'});

    print $pod->find('/pod/sect1[title/text() = "VERSION"]/para[1]/text()');

=head1 SUPPORT

C<Pod::XPath> is supported by the author.

=head1 VERSION

This is C<Pod::XPath>, revision $Revision: 1.4 $.

=head1 AUTHOR

darren chamberlain E<lt>darren@cpan.orgE<gt>

=head1 COPYRIGHT

(C) 2003 darren chamberlain

This library is free software; you may distribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Perl>, L<XML::XPath>, L<Pod::XML>
