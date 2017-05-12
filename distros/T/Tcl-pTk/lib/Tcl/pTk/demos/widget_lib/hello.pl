# hello.pl

use Config;
use Tcl::pTk::widgets qw/ ROText /;
use vars qw/ $TOP /;
use strict;

use IO::Handle;

sub hello {

    my( $demo ) = @_;

    $TOP = $MW->WidgetDemo(
        -name             => $demo,
        -text             => [ "This demonstration describes the basics of Perl/Tk programming. Besides this small user guide, there are various FAQs and other resources and tutorials available on the web, such as:

http://phaseit.net/claird/comp.lang.perl.tk/ptkFAQ.html
http://www.perltk.org
http://user.cs.tu-berlin.de/~eserte
http://www.lehigh.edu/sol0/ptk
", -wraplength => '7i' ],
        -title            => 'Perl/Tk User Guide',
        -iconname         => 'hello',
    );

    # Pipe perldoc help output via fileevent() into a Scrolled ROText widget.

    my $t = $TOP->Scrolled(
        qw/ ROText -width 80 -height 25 -wrap none -scrollbars osoe/,
    );
    $t->focus;
    my $cmd = $Config{installbin} . '/perldoc -t Tk::UserGuide';
    $t->pack( qw/ -expand 1 -fill both / );

    my $fileH = IO::Handle->new();
    open( $fileH, "$cmd|" ) or die "Cannot get pTk user guide: $!";
    binmode $fileH;
    $TOP->fileevent( $fileH, 'readable' => [ \&hello_fill, $t, $fileH ] );

} # end hello

sub hello_fill {

    my( $t, $fileH ) = @_;

    my $stat = sysread $fileH, my $data, 4096;
    die "sysread error:  $!" unless defined $stat;
    if( $stat == 0 ) {		# EOF
	$TOP->fileevent( $fileH, 'readable' => '' );
	return;
    }
    # Get rid of any dos CRs
    $data =~ s/\r//g;
    $t->insert( 'end', $data );

} # end hello_fill
