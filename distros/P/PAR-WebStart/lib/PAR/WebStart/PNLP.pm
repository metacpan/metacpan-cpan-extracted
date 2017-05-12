package PAR::WebStart::PNLP;
use strict;
use warnings;
use XML::SAX::ExpatXS;
use XML::SAX;
use File::Basename;
use base qw(XML::SAX::Base);
our $VERSION = '0.20';

our %wantarray = map {$_ => 1} qw(par argument description module);

sub new {
  my ($class, %args)  = @_;
  my $file = $args{file};
  die "Please supply a valid pnlp file" unless ($file and -e $file);
  bless {file => $file, cfg => undef, ERROR => ''}, $class;
}

sub parse {
  my $self = shift;
  my $file = $self->{file};
  XML::SAX->add_parser(q(XML::SAX::ExpatXS));
  my $factory = XML::SAX::ParserFactory->new();
  my $handler = PNLPHandler->new();
  my $parser = $factory->parser( Handler => $handler);

  eval { $parser->parse_uri($file); };
  if ($@) {
    $self->{ERROR} = qq{Error in parsing $file};
    return;
  }
  my $cfg = $handler->{cfg};
  fix_args($cfg);
  fix_par($cfg);
  return $cfg;
}

sub fix_args {
  my $cfg = shift;
  my $args = [];
  foreach my $arg(@{$cfg->{argument}}) {
    my $value = $arg->{value};
    foreach my $entry(split ' ', $value) {
      push @$args, {value => $entry};
    }
  }
  $cfg->{argument} = $args;
}

sub fix_par {
  my $cfg = shift;
  my $pars = $cfg->{par};
  return if (scalar(@$pars) == 1);
  my $main = $cfg->{'application-desc'}->{'main-par'};
  return unless $main;
  my $par_main = $main . '.par';
  my $par_tmp = [];
  my $i = 1;
  foreach my $par (@$pars) {
    my $par_file = basename($par->{href}, qr{\.par});
    if ($par_file eq $par_main) {
      $par_tmp->[0] = {%$par};
    }
    else {
      $par_tmp->[$i] = {%$par};
      $i++;
    }
  }
  $cfg->{par} = $par_tmp;
}

# begin the in-line package
package PNLPHandler;
use strict;
use warnings;

my $curr_el = '';
my %array_count = map {$_ => 0} keys %wantarray;

sub new {
    my $type = shift;
    return bless {text => '', cfg => {}}, $type;
}

sub start_document {
  my ($self) = @_;
  # print "Starting document\n";
  $self->{text} = '';
}

sub start_element {
  my ($self, $element) = @_;
  # print "Starting $element->{Name}\n";
  my $cfg = $self->{cfg};
  $curr_el = $element->{Name};
  $cfg->{$curr_el}->{seen} = 1 unless $wantarray{$curr_el};
  $self->display_text();
  foreach my $ak (keys %{ $element->{Attributes} } ) {
    my $at = $element->{Attributes}->{$ak};
    my $name = $at->{Name};
    my $value = $at->{Value};
    if ($wantarray{$curr_el}) {
      $cfg->{$curr_el}->[$array_count{$curr_el}]->{$name} = $value;
    }
    else {
      $cfg->{$curr_el}->{$name} = $value;
    }
    # print qq(Attribute $at->{Name} = "$at->{Value}"\n);
  }
}

sub characters {
  my ($self, $characters) = @_;
  my $text = $characters->{Data};
  $text =~ s/^\s*//;
  $text =~ s/\s*$//;
  $self->{text} .= $text;
}

sub end_element {
  my ($self, $element) = @_;
  $self->display_text();
  # print "Ending $element->{Name}\n";
  $array_count{$curr_el}++;
}

sub display_text {
  my $self = shift;
  my $cfg = $self->{cfg};
  if ( defined( $self->{text} ) && $self->{text} ne "" ) {
    if ($wantarray{$curr_el}) {
      $cfg->{$curr_el}->[$array_count{$curr_el}]->{value} = $self->{text};
    }
    else {
      $cfg->{$curr_el}->{value} = $self->{text};
    }
    # print " text: [$self->{text}]\n";
    $self->{text} = '';
  }
}

sub end_document {
  my ($self) = @_;
  # print "Document finished\n";
}

1; #Ye Olde 'Return True' for the in-line package..


__END__

=head1 NAME

PAR::WebStart::PNLP - Parse pnlp files

=head1 SYNOPSIS

  my $file = 'hello.pnlp';
  my $obj = PAR::WebStart::PNLP->new(file => $file);
  my $cfg = $obj->parse();

=head1 Description

This module is used to parse C<PNLP> files, which are XML
files whose syntax
is described later in this document. The C<$cfg> data
structure returned is a hash reference, the key being
the XML elements encountered. The value associated with this
key are either

=over 4

=item *

a reference to an array of hash references, in the cases
of the C<par>, C<argument>, C<module>, or C<description>
elements,

=item *

a hash reference, for all other elements.

=back

The hash references involved in these values have keys
corresponding to the names of any attributes of the element, if found, as
well as a key of C<value>, if there is a value of the element.
The associated values of these keys are the corresponding
values of the attributes or the element's value, as applicable.
Except for the cases of C<par>, C<argument>, C<module>, 
and C<description>, the hash references associated with
all elements seen are guaranteed to have one key of
C<seen>, of value 1, even if no attribute or value are defined.
 
=head1 Syntax

The syntax for a C<PNLP> file is based
liberally on the Java Network
Launching Protocol and API (JNLP) Specification v1.0.1
L<http://java.sun.com/products/javawebstart/download-spec.html>.

The C<PNLP> file is an XML document; an example is as follows:

 <?xml version="1.0" encoding="utf-8"?>
 <!-- PNLP File for Demo Application -->
  <pnlp
    spec="1.0+"
    codebase="http://my_company.com/pnlp/apps"
    href="app.pnlp">
  <information>
    <title>App Demo Application</title>
    <vendor>Our Company</vendor>
    <homepage href="docs/help.html"/>
    <description>App Demo Application</description>
    <description kind="short">A demo of the capabilities</description>
    <icon href="images/image.jpg"/>
    <icon kind="splash" href="images/splash.gif"/>
  </information>
  <security>
      <allow-unsigned-pars />
  </security>
  <resources>
    <perlws version="0.2"/>
    <par href="lib/app.par"/>
    <par href="lib/helper.par"/>
  </resources>
  <application-desc main-par="app">
    <argument>arg1</argument>
    <argument>arg2</argument>
  </application>
 </pnlp>

This shows the basic outline of the document. The root element is
C<pnlp>, which has four subelements: C<information>, C<security>, 
C<resources>, and
C<application-desc>. The elements are described in
more detail below.

=head1 Elements

=head2 pnlp

The C<pnlp> element can have the following attributes.

=over 4

=item spec

This denotes the C<pnlp> specification used.

=item codebase 

All relative URLs specified in href
attributes in the PNLP file are using this URL as a base.

=item href

This is a URL pointing to the location of the
PNLP file itself.

=back

=head2 information

The following elements can be specified.

=over 4

=item title

The name of the application.

=item vendor

The name of the vendor of the application.

=item homepage

Contains a single attribute, href, which is a
URL locating the home page for the application. It is used
to point the user to a web page where more
information about the application can be found.

=item description

A short statement about the application.
Description elements are optional. The C<kind> attribute defines how
the description should be used. It can have one of the following
values:

=over 4

=item one-line

If a reference to the application is going to
appear on one row in a list or a table, this description will
be used.

=item short

If a reference to the application is going to be
displayed in a situation where there is room for a paragraph,
this description is used.

=item tooltip

If a reference to the application is going to
appear in a tooltip, this description is used.

=back

Only one description element of each kind can be specified. A
description element without a kind is used as a default value.
All descriptions contain plain text; no formatting, such as with
HTML tags, is supported.

At present C<perlws.pl> ignores the attribute of the description.
In the future different descriptions may be used in different
contexts.

=item icon

Contains an HTTP URL to an image file in either
GIF or JPEG format, used to represent the application.
The optional C<kind="splash"> attribute may be used in an icon element
to indicate that the image is to be used as a "splash" screen during
the launch of an application.

At present the C<perlws.pl> application only downloads
the image to the specified cache directory, for possible use
by the par application. In the future this image may be
used in the initial welcome screen that the user is presented with.

=back

=head2 security

Each jar file, by default, must be signed using C<Module::Signature>
before being used by the client. If an element
C<E<lt>allow-unsigned-pars /E<gt>> appears here,
such signing checks will be disabled. The client will
be warned that this has taken place.

=head2 resources

The resources element is used to specify the resources, normally as
C<PAR> files, that are
part of the application.  A resource definition can be restricted to
a specific operating system, architecture, or perl version
using the following attributes:

=over 4

=item os

This corresponds to  C<$Config{osname}>.

=item arch

This corresponds to  C<$Config{archname}>.

=item version

This denotes the minimal perl version required
(as given by C<$]>)
and I<must> be given in the form, for example,
C<5.008006> for perl-5.8.6.

=item perl_version

This corresponds to C<$Config{PERL_VERSION}>, and denotes
the C<PERL_VERSION> of Perl 5 the client must have.

=back

The C<resources> element has two different possible subelements: 
C<par> and C<perlws>.

=over 4

=item par

A C<par> element specifies a C<PAR> file that is part of the application.
The location is given by an C<href> attribute.
There must be an md5 checksum file, with the same name as the
C<par> file with an C<.md5> extension, present in the same location
as the C<par> file. This is used as a mild security check, as
well as a test if an update to a locally cached copy of the
C<par> file is available.

The C<par> element can optionally have any combination of
C<os>, C<arch>, C<version>, or C<perl_version>, as described for
the C<resource> element; if these are present, the C<PAR> file
specified will only be used if the client's Perl configuration
matches the specified attributes.

=item perlws

The C<perlws> element specifies, by a C<version> attribute,
which minimal version of C<PAR::WebStart> is required.

=back

=head2 application-desc

The C<application-desc> describes the application. It has
an an optional attribute, C<main-par>, which can be used to specify the
name of the C<par> file (without the C<.par> extension)
containing the C<main.pl> script to be
run. This attribute is not needed if only one C<PAR> file is
present. If it is not specified, it will be assumed that the
first C<par> file specified contains the C<main.pl> script.

Arguments can be specified to the application by including one or
more nested argument elements. For example:

  <application-desc main-par="A">
    <argument>arg1</argument>
    <argument>arg2</argument>
  </application-desc>

Additional perl modules needed by the client to run the
application may be specified as

  <application-desc main-par="A">
    <module>Tk</module>
    <module>Net::FTP</module>
  </application-desc>

The running of the application will abort if these modules
are not available.

For C<Win32>, specifying a C<E<lt>wperl /E<gt>> element within
C<application-desc> will cause the application to be
launched with C<wperl>. With this, no console window will
appear, meaning the application will not have access to
C<STDOUT>, C<STDIN>, nor C<STDERR>.

=head1 COPYRIGHT

Copyright, 2005, by Randy Kobes <r.kobes@uwinnipeg.ca>.
This software is distributed under the same terms as Perl itself.
See L<http://www.perl.com/perl/misc/Artistic.html>.

=head1 SEE ALSO

L<PAR::WebStart>

=cut



