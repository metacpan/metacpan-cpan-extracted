#!/usr/bin/perl

use 5.8.0;
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use RTF::HTMLConverter;

my %opts;
GetOptions(
  "help|h|?"     => \$opts{help},
  "man|m"        => \$opts{man},
  "dom=s"        => \$opts{dom},
  "noimages|n"   => \$opts{noimages},
  "imagedir|d=s" => \$opts{imagedir},
  "imageuri|u=s" => \$opts{imageuri},
  "encoding|e=s" => \$opts{encoding},
  "indented|i=i" => \$opts{indented},
);

pod2usage(-verbose => 1, -exitval => 0) if $opts{help};
pod2usage(-verbose => 2, -exitval => 0) if $opts{man};

my %params;
if($opts{dom}){
  eval "require $opts{dom}";
  die $@ if $@;
  $params{DOMImplementation} = $opts{dom};
}else{
  eval { require XML::GDOME };
  if($@){
    eval { require XML::DOM };
    die "Can't load either XML::GDOME or XML::DOM\n" if $@;
    $params{DOMImplementation} = 'XML::DOM';
  }
}

if($opts{noimages}){
  $params{discard_images} = 1;
}else{
  $params{image_dir} = $opts{imagedir} if defined $opts{imagedir};
  $params{image_uri} = $opts{imageuri} if defined $opts{imageuri};
}

$params{codepage} = $opts{encoding} if $opts{encoding};
$params{formatting} = $opts{indented} if defined $opts{indented};

if(defined $ARGV[0]){
  open(FR, "< $ARGV[0]") or die "Can't open '$ARGV[0]': $!!\n";
  $params{in} = \*FR;
  if(defined $ARGV[1]){
    open(FW, "> $ARGV[1]") or die "Can't open '$ARGV[1]': $!!\n";
    $params{out} = \*FW;
  }
}

my $parser = RTF::HTMLConverter->new(%params);
$parser->parse();

__END__

=head1 NAME

rtf2html.pl - Simple RTF to HTML converter

=head1 SYNOPSIS

rtf2html.pl [options] [in.rtf [out.html]]

=head1 OPTIONS

=over 4

=item B<help>,B<h>,B<?>

Print usage information and exit.

=item B<man>,B<m>

Print manual page and exit.

=item B<dom>

DOM implementation name. Default: C<XML::GDOME>.

=item B<noimages>,B<n>

Do not process images.

=item B<imagedir>,B<d> I<path>

Directory where to store images if any. Default: current directory.

=item B<imageuri>,B<u> I<uri>

Image url prefix.

=back

C<XML::GDOME> specific options:


=over 4

=item B<encoding>, B<e> I<name>

The encoding of resulted HTML page. Default: C<UTF-8>.

=item B<indented>, B<i> I<1|0>

Can be C<1> or C<0>. If the value specified is C<1> the
resulted HTML tags will be indented to make the code more
readable. If the value specified is C<0> there will be no
indentation. Default: C<1>.

=back

=head1 DESCRIPTION

This is a simple RTF to HTML converter. It reads RTF from C<in.rtf> (or
C<STDIN> by default) and writes HTML to C<out.html> (or C<STDOUT>). If RTF
contains images, they will be stored in directory specified by B<imagedir>
(or B<d>) option and their URLs in HTML will be started with whatever
specified by B<imageuri> (or B<u>) option.

=head1 EXAMPLES

  rtf2html.pl < in.rtf > out.html
  rtf2html.pl -n -e 'KOI8-R' in.html
  rtf2html.pl -d /opt/www/images \
              -u http://www.somewhere.net/images \
              -dom 'XML::DOM' in.rtf /opt/www/out.html

=cut

