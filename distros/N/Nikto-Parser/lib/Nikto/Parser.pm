# $Id: Parser.pm 142 2009-10-16 19:13:45Z jabra $
package Nikto::Parser;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use Nikto::Parser::Session;
    my @session : Field : Arg(session) : Get(session) :
        Type(Nikto::Parser::Session);

    # parse_file
    #
    # Input:
    # argument  -   self obj    -
    # argument  -   xml         scalar
    #
    # Ouptut:
    #
    sub parse_file {
        my ( $self, $file ) = @_;
        my $parser = XML::LibXML->new();

        my $doc = $parser->parse_file($file);
        return Nikto::Parser->new(
            session => Nikto::Parser::Session->parse( $parser, $doc ) );
    }

    sub parse_scan {
        my ( $self, $ndir, $args, @ips ) = @_;
        my $FH;

        if ( $args =~ /-Format/ ) {
            die
                "[Nikto-Parser] Cannot pass option '-Format ' to parse_scan()";
        }

        if ( $args =~ /-output/ ) {
            die
                "[Nikto-Parser] Cannot pass option '-output ' to parse_scan()";
        }
        if ( -d $ndir ) {
            chdir $ndir or die "[Nikto-Parser] $ndir not a directory\n";
        }
        else {
            die "[Nikto-Parser] $ndir not a directory\n";
        }

        my $cmd = "./nikto.pl -Format xml -output \"-\" -host "
            . ( join ' ', @ips );
        print "$cmd\n";
        open $FH, "$cmd |"
            || die "[Nikto-Parser] Could not perform nikto scan - $!";
        my $p      = XML::LibXML->new();
        my $doc    = $p->parse_fh($FH);
        my $parser = Nikto::Parser->new(
            session => Nikto::Parser::Session->parse( $p, $doc ) );
        close $FH;
        return $parser;
    }

    # return the session information for the current nikto scan
    sub get_session {
        my ($self) = @_;
        my $session = $self->session;
        return $session;
    }

    # return the host obj based on an ip address
    sub get_host {
        my ( $self, $ip ) = @_;
        my $host_obj = $self->session->scandetails->get_host_ip($ip);
        return $host_obj;
    }

    # return an ArrayRef containing all of the host objs
    sub get_all_hosts {
        my ($self) = @_;
        my @all_hosts = $self->session->scandetails->all_hosts();
        return @all_hosts;
    }
}
1;

