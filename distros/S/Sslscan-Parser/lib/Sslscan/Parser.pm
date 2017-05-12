# $Id: Parser.pm 134 2009-10-16 18:21:38Z jabra $
package Sslscan::Parser;
{
    our $VERSION = '0.02';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use Sslscan::Parser::Session;
    my @session : Field : Arg(session) : Get(session) :
        Type(Sslscan::Parser::Session);

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
        return Sslscan::Parser->new(
            session => Sslscan::Parser::Session->parse( $parser, $doc ) );
    }

    sub parse_scan {
        my ( $self, $args, @ips ) = @_;
        my $FH;
        use File::Temp ();

        my $TEMP_FH    = File::Temp->new();
        my $temp_fname = $TEMP_FH->filename;

        if ( $args =~ /-output/ ) {
            die
                "[Sslscan-Parser] Cannot pass option '-output ' to parse_scan()";
        }
        elsif ( $args =~ /--xml/ ) {
            die
                "[Sslscan-Parser] Cannot pass option '--xml ' to parse_scan()";
        }
        else { }
        my $cmd
            = "sslscan --xml=\"$temp_fname\" "
            . ( join ', ', @ips )
            . " &> /dev/null";
        print "$cmd\n";
        system("$cmd");
        open $FH, "$temp_fname"
            || die "[Sslscan-Parser] Could not perform Sslscan scan - $!";
        my $p      = XML::LibXML->new();
        my $doc    = $p->parse_fh($FH);
        my $parser = Sslscan::Parser->new(
            session => Sslscan::Parser::Session->parse( $p, $doc ) );
        close $FH;
        close $TEMP_FH;
        return $parser;
    }

    sub get_session {
        my ($self) = @_;
        return $self->session;
    }

    sub get_host {
        my ( $self, $ip ) = @_;
        return $self->session->scandetails->get_host_ip($ip);
    }

    sub get_all_hosts {
        my ($self) = @_;
        my @all_hosts = $self->session->scandetails->all_hosts();
        return @all_hosts;
    }

    sub get_port {
        my ( $self, $port ) = @_;
        return $self->session->scandetails->get_port($port);
    }
}
1;

