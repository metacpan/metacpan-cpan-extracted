
# $Id: 001_load.t,v 1.8 2010-05-08 12:59:43 Martin Exp $

use blib;
use IO::CaptureOutput qw( capture ); # ); # Emacs bug
use Test::More 'no_plan';

my ($sStderr, $sWarn);
$SIG{__WARN__} = sub { $sWarn .= $_[0] };
capture { eval "use RDF::Simple::Parser; my $o = new RDF::Simple::Parser" } undef, \$sStderr;
$sStderr .= $@;
$sStderr .= $sWarn;
if ($sStderr =~ m/UNABLE\ TO\ PROVIDE\ REQUIRED\ FEATURE/i)
  {
  diag(q{XML::SAX and/or XML::SAX::Expat is/are not installed properly.});
  diag(q{Please use cpan (or cpanp) to install XML::SAX and XML::SAX::Expat.});
  diag(q{Or, you could try something like this:});
  diag(qq{ln -s /usr/lib/perl/XML/SAX/ParserDetails.ini /usr/local/lib/perl/site/5.10.0/XML/SAX/ParserDetails.ini});
  diag(q{See http://perl-xml.sourceforge.net/faq/#parserdetails.ini for more information.});
  BAIL_OUT(q{XML::SAX and/or XML::SAX::Expat is/are not installed properly});
  } # if

pass;

__END__
