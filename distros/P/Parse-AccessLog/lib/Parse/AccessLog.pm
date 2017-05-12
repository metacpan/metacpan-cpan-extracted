package Parse::AccessLog;

use 5.006;
use strict;
use warnings;

=head1 NAME

Parse::AccessLog - Parse Nginx/Apache access logs in "combined" format.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Parses web server logs created by Apache/nginx in combined format. Assumes no knowledge of the server which creates the log entries.

Following the UNIX philosophy of "write programs that do one thing and do it well", this module does not attempt to validate any of the data/fields (e.g. match the IP address via a regex or some other method). This module assumes that the logs are already written by a web server daemon, and whether the data are "correct" or not is up to the end user. This module just parses it.

    use Parse::AccessLog;

    my $p = Parse::AccessLog->new;

    # returns one hashref
    my $log_line = q{127.0.0.1 - - [11/Jan/2013:17:31:36 -0600] "GET / HTTP/1.1" 200 612 "-" "HTTP-Tiny/0.022"};
    my $rec = $p->parse($log_line);

    ...

    # returns two hashrefs...
    my @log_lines = (
        q{127.0.0.1 - - [11/Jan/2013:17:31:36 -0600] "GET / HTTP/1.1" 200 612 "-" "HTTP-Tiny/0.022"},
        q{127.0.0.1 - - [11/Jan/2013:17:31:38 -0600] "GET / HTTP/1.1" 200 612 "-" "HTTP-Tiny/0.022"},
    );
    my @recs = $p->parse( @log_lines );

    ...

    # returns a hashref for each line in 'access.log'...
    my @recs = $p->parse( '/var/log/nginx/access.log' );

=head1 METHODS

=head2 new()

Constructor, creates a Parse::AccessLog parser object. Use of new() is
optional, since the parse() method can be called as a class method also.

=cut 

sub new {
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

=head2 parse()

This is the only method (other than the constructor new()), and can be called
as a class method or as an object method. It Does What You Want (probably).

Accepts a scalar or a list. If a scalar, can be either one line of an access
log file, or can be the full path (absolute or relative) to an access log (e.g.
/var/log/apache2/access.log). If a list, expects each element to be a line from
an access log file. Will return either a single hashref or a list of hashrefs
with the following keys:

    remote_addr
    remote_user
    time_local
    request
    status
    bytes_sent
    referer
    user_agent

=cut

sub parse {
    # don't parse anything in void context
    return unless defined wantarray;

    my $self    = shift;
    my $class   = ref($self) || $self;

    # output determined by input data

    # array
    if ( 0 < $#_) {
        return map { $self->parse($_) } @_;
    }

    my $line = shift;
    chomp $line;

    if ( -f $line ) {
        my $filename = $line;
        open(my $fh, '<', $filename);
        chomp(my @lines = <$fh>);
        close($fh);
        return map { $self->parse($_) } @lines;
    }

    my $hr;

    # this is where the magic happens...
    if ( $line =~ /^ (\S+)         # remote_addr
                   \ \-\ (\S+)     # remote_user
                   \ \[([^\]]+)\]  # time_local
                   \ "(.*?)"       # request
                   \ (\d+)         # status
                   \ (\-|(?:\d+))  # bytes_sent
                   \ "(.*?)"       # referer
                   \ "(.*?)"       # user_agent
                   $ /x ) {

        my @fields = qw(remote_addr remote_user time_local request
                        status bytes_sent referer user_agent);
        my $c = 0;
        {   no strict 'refs';
            for ( @fields ) {
                $hr->{ $_ } = ${ ++$c };
            }
        };
    }

    return $hr;
}

=head1 SEE ALSO

http://en.wikipedia.org/w/index.php?title=Unix_philosophy&oldid=525612531

=head1 AUTHOR

Nathan Marley, C<< <nathan.marley at gmail.com> >>

=head1 BUGS

Please report any bugs through github at https://github.com/nmarley/Parse-AccessLog.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::AccessLog

You can also look for information at:

=over 3

=item * MetaCPAN

L<https://metacpan.org/module/Parse::AccessLog>

=item * GitHub

L<https://github.com/nmarley/Parse-SSH2-PublicKey>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-AccessLog/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nathan Marley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;

