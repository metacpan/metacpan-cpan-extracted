
package Net::IdentServer;

use strict;
use warnings;
use POSIX;
use Carp;
use base qw(Net::Server::Fork);

our $VERSION  = "0.604";

1;

# run {{{
sub run {
    my $this = shift;
    $0 = ref $this;
    $this->SUPER::run( @_ );
}
# }}}

# print_error {{{
sub print_error {
    my $this = shift;
    my $type = lc(pop);
    my @p = @_;
       @p = (0, 0) unless @p == 2;

    my $txt;
    unless( $txt = {'u'=> "UNKNOWN-ERROR", 'h' => "HIDDEN-USER", 'n' => "NO-USER", 'i' => "INVALID-PORT"}->{$type} ) {
        die "bad type given to print_error";
    }

    $this->print_response(@p, "ERROR", $txt);
}
# }}}
# print_response {{{
sub print_response {
    my ($this, $port_on_server, $port_on_client, $os_name, $add_info) = @_;

    $os_name = "USERID : $os_name" unless $os_name eq "ERROR";

    printf '%d , %d : %s : %s'."\x0d\x0a", $port_on_server, $port_on_client, $os_name, $add_info;
}
# }}}
# do_lookup {{{
sub do_lookup {
    my $this = shift;
    my ($local_addr, $local_port, $rem_addr, $rem_port) = @_;

    my $translate_addr = sub { my $a = shift; my @a = (); push @a, $1 while $a =~ m/(..)/g; join(".", map(hex($_), reverse @a)) };
    my $translate_port = sub { hex(shift) };

    my $found = $this->alt_lookup(@_);

    if( $found =~ m/^JP:(.+)/ ) {
        my $name = $1;

        $this->log(1, "lookup from $rem_addr for $local_port, $rem_port: alt string found $name");
        $this->print_response($local_port, $rem_port, "UNIX", $name);

        return;
    }

    if( $found < 0 ) {
        open my $tcp, "<", "/proc/net/tcp" or die "couldn't open proc/net/tcp for read: $!";
        while(<$tcp>) {
            if( m/^\s+\d+:\s+([A-F0-9]{8}):([A-F0-9]{4})\s+([A-F0-9]{8}):([A-F0-9]{4})\s+(\d+)\s+\S+\s+\S+\s+\S+\s+(\d+)/ ) {
                my ($la, $lp, $ra, $rp, $state, $uid) = ($1, $2, $3, $4, $5, $6);

                if( $state == 1 ) {
                    $la = $translate_addr->($la); $lp = $translate_port->($lp);
                    $ra = $translate_addr->($ra); $rp = $translate_port->($rp);

                    if( $local_port eq $lp and $rem_port eq $rp ) {
                        $found = $uid;
                        last;
                    }
                }
            }
        }
        close $tcp;
    }

    if( $found < 0 ) {
        $this->not_found(@_);

        return;
    }

    my $name = getpwuid( $found );
    unless( $name =~ m/\w/ ) {
        # This can happen if a deleted user has a socket open.  'u' might be a better choice. 
        # I happen to think hidden user is a nice choice here.  

        $this->log(2, "lookup from $rem_addr for $local_port, $rem_port: found uid, but no pwent");
        $this->print_error($local_port, $rem_port, 'h'); 
        return;
    }

    $this->log(1, "lookup from $rem_addr for $local_port, $rem_port: found $name");
    $this->print_response($local_port, $rem_port, "UNIX", $name);

    return 1;
}
# }}}
# not_found {{{
sub not_found {
    my $this = shift;
    my ($local_addr, $local_port, $rem_addr, $rem_port) = @_;

    $this->log(2, "lookup from $rem_addr for $local_port, $rem_port: not found");
    $this->print_error($local_port, $rem_port, 'n'); # no user for when we find no sockets!
}
# }}}
# alt_lookup {{{
sub alt_lookup {
    return -1;
}
# }}}

# process_request {{{
sub process_request {
    my $this = shift;

    my $master_alarm = alarm 10;
    local $SIG{ALRM} = sub { die "\n" };
    eval {
        while( my $input = <STDIN> ) {
           $input = "" unless $input; # to deal with stupid undef warning
           $input =~ s/[\x0d\x0a]+\z//;

            unless( $input =~ m/^\s*(\d+)\s*,\s*(\d+)\s*$/ ) {
                $this->log(3, "Malformated request from $this->{server}{peeraddr}");
                $this->print_error("u");
                return;
            }
            my ($s, $c) = ($1, $2);

            $this->do_lookup($this->{server}{sockaddr}, $s, $this->{server}{peeraddr}, $c);
        }
    };
    alarm $master_alarm;

    if( $@ eq "\n" ) {
        # print "500 too slow...\n";
        # on timeout, ident just closes the connection ...

    } elsif( $@ ) {
        $this->log(3, "ERROR during main while() { do_lookup() } eval: $@");

    }
}
# }}}

__END__

=encoding UTF-8
=head1 NAME

Net::IdentServer - An rfc 1413 Ident server using L<Net::Server::Fork>.

=head1 SYNOPSIS

    use Net::IdentServer;

    my $nis = Net::IdentServer->new();

    run $nis;
    # This is a working identd …
    # though, you probably need to be root

=head1 DESCRIPTION

Although you can run this as you see in the SYNOPSIS, you'll
probably want to rewrite a few things.

L<Net::IdentServer> inherits L<Net::Server>, so click through
to that module for a description of the arguments to new() and
for how it reads @ARGV.

An example random fifteen-letter-word ident server follows:

    package main;

    RandomIdentServer->new( user=>'nobody', group=>'nobody' )->run;

    package RandomIdentServer;

    use strict;
    use base qw(Net::IdentServer);

    1;

    sub new {
        my $class = shift;
        my $this = $class->SUPER::new( @_ );

        open IN, "/usr/share/dict/words" or die "couldn't open dictionary: $!";
        while(<IN>) {
            if( /^(\S{15})$/ ) {
                push @{ $this->{words} }, $1;
            }
        }
        close IN;

        return $this;
    }

    sub choice {
        my $this = shift;

        my $i = int rand @{ $this->{words} };

        return $this->{words}->[$i];
    }

    sub print_response {
        my $this = shift;
        my ($local, $remote, $type, $info) = @_;

        if( $type eq "UNIX" ) {
            # intercept these valid responses and randomize them

            $info = $this->choice;
        }

        # Do what we would have done
        $this->SUPER::print_response( $local, $remote, $type, $info );
    }

=head1 Overridable Functions

=head2 print_response

See the L</DESCRIPTION> for an actual example.  This is the function that prints
the reponse to the client.  As arguments, it receives $local port, $remote
port, result $os_name (in caps) and the extended $info (usually a username or
error).

=head2 alt_lookup

∃ a function that receives $local_addr, $local_port, $rem_addr, and $rem_port
as arguments.  Confusingly, the $local_addr and $rem_addr refer to the present
socket connection, and the $local_port and $rem_port refer to the ports being
queried.

You can do whatever lookups you like on this data and return a $uid.  If you
return a negative $uid, do_lookup will perform the standard lookup.

The default alt_lookup just returns a -1.

Lastly, if you return a string that matches m/^JP:(.+)/, then $1 will be
printed as the username.

Example:

    sub alt_lookup() {
        my $this = shift;

        # You could use this _instead_ of the
        # print_response() in the DESCRIPTION section.  The
        # advantage of the print_response is that it only
        # returns a "username" when the queried connection
        # actually exists.

        return "JP: " . $this->choice;
    }

=head2 not_found

not_found receives as arguments [see alt_lookup for
description]: $local_addr, $local_port, $rem_addr, $rem_port

by default it logs a level 2 not found message and then
prints the NO-USER error message

[for more info on the log() see the Net::Server docs]

The idea here is that you can do an additional lookup of the
standard TCP lookup fails.  For instance, you could do a lookup 
on a NAT'd machine in the local net.

=head1 print_error

There are only a couple choices of error messages in rfc1413

    $this->print_error($local_port, $rem_port, 'u'); # UNKNOWN-ERROR
    $this->print_error($local_port, $rem_port, 'h'); # HIDDEN-USER
    $this->print_error($local_port, $rem_port, 'n'); # NO-USER
    $this->print_error($local_port, $rem_port, 'i'); # INVALID-PORT

You could, of course, write your own by overriding this
function entirely.  But otherwise picking something besides
the four examples shown will earn you an error and an
exit(1).

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I'm using this in my own projects.  If you like it or hate me or something,
drop me a line.  I usually answer my email.

=head1 COPYRIGHT

© 2014 Paul Miller

=head1 BUGS

Of course. But lemme know what they are?

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net::IdentServer>

(maybe the name is one? Net::Ident::Server maybe? meh…)

There's no way this old code works with IPv6 ... it reads several bytes from
/proc/net/somewhere and probably the whole mess needs to be redone.

=head1 LICENSE

Perl Artisitic License — use this like any other Perl thing.

(This was previously licensed under GPL v2, assume that's still the case if you
like.)

=head1 SEE ALSO

Consider using L<POE::Component::Server::Ident>. I haven't personally checked
it out, but L<BINGOS|http://search.cpan.org/~bingos/> wrote it so it's probably
a better choice than this.

perl(1), L<Net::Server>, L<RFC 1413|http://www.ietf.org/rfc/rfc1413.txt>

=cut
