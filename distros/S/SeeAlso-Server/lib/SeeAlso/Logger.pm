use strict;
use warnings;
package SeeAlso::Logger;
{
  $SeeAlso::Logger::VERSION = '0.71';
}
#ABSTRACT: log requests to a SeeAlso Simple service

use Carp qw(croak);
use POSIX qw(strftime);
use CGI;


sub new {
    my $class = shift;
    $class = ref $class || $class;
    my ($file, %param);

    if (@_ % 2) {
        ($file, %param) = @_;
    } else {
        %param = @_;
    }
    $file = $param{file} unless defined $file;

    my $self = bless {
        counter => 0,
        filename => "",
        handle => undef,
        privacy => $param{privacy} || 0,
        filter => $param{filter} || undef,
    }, $class;

    croak("Filter parameter must be a code reference")
        if ($param{filter} and ref($param{filter}) ne 'CODE');

    $self->set_file($file) if defined $file;

    return $self;
}



sub set_file {
    my $self = shift;
    my $file = shift;

    if (ref($file) eq "GLOB" or eval { $file->isa("IO::Handle") }) {
        $self->{filename} = "";
        $self->{handle} = $file;
    } else {
        $self->{filename} = $file;
        $self->{handle} = eval {
            my $fh; open( $fh, ">>", $file ) or die; binmode $fh, ":encoding(UTF-8)"; $fh;
        };
        undef $self->{handle} if ( $@ ); # failed to open file
    }
    return $self->{handle};
}



sub log {
    my ( $self, $cgi, $response, $service ) = @_;
    $self->{counter}++; # count every call (no matter if printed or not)

    return unless defined $self->{handle} || defined $self->{filter};

    my $datetime = strftime("%Y-%m-%dT%H:%M:%S", localtime);
    my $host = $cgi->remote_host() || "";
    my $referer = $cgi->referer() || "";
    # my $ident = $cgi->remote_ident() || "-";
    # my $user =  $cgi->remote_user() || "-";
    # my $user_agent = $cgi->user_agent();
    $service ||= "";

    my $id = (defined $cgi ? $cgi->param('id') : CGI::param('id')) || '';

    my $valid = $response->query() eq "" ? '0' : '1';
    my $size = $response->size();

    my @values = (
        $datetime,
        $host,
        $referer,
        $service,
        $id,
        $valid,
        $size
    );

    if ( defined $self->{filter} ) {
        @values = $self->{filter}(@values);
    }
    if ( @values and defined $self->{handle} ) {
        print { $self->{handle} } join("\t", @values) . "\n";
    }

    return 1;
}


use Date::Parse;

sub parse {
    chomp;
    my @values = split /\t/;
    return unless $#values == 6;
    eval { $values[0] = str2time($values[0]); };
    return if $@;
    return @values;
}

1;

__END__
=pod

=head1 NAME

SeeAlso::Logger - log requests to a SeeAlso Simple service

=head1 VERSION

version 0.71

=head1 DESCRIPTION

This class provides the log method to log successful requests to a
SeeAlso Simple service. You can write logs to a file and/or handle
them by a filter method.

=head1 USAGE

To log requests to your SeeAlso services, create a logfile directory
that is writeable for the user your services runs as. If you run SeeAlso
as cgi-script, this script may help you to find out:

  #!/usr/bin/perl
  print "Content-Type: text/plain;\n\n" . `whoami`;

Create a L<SeeAlso::Logger> object with a filename of your choice and
assign it to the L<SeeAlso::Server> object:

   my $logger = SeeAlso::Logger->new("/var/log/seealso/seealso.log");
   $server->logger($logger);

To rotate logfiles you should use logrotate which is part of every linux
distribution. Specify the configuration for your seealso logfiles in a
configuration file where logrotate can find in (/etc/logrotate.d/seealso).

  # example logrotate configuration for SeeAlso
  /var/log/seealso/*.log {
      compress
      daily
      dateext
      ifempty
      missingok
      rotate 365
  }

The constructor of this class does not throw an error if the file you
specified for logging could not be opened. Instead test the 'handle'
property whether it is defined.

=head1 METHODS

=head2 new ( [ $file-or-handle ] {, $option => $value } )

Create a new parser. Gets a a reference to a file handle or a
file name or a handler function. You can specify the following options:

=over 4

=item file

Filename or reference to a file handle. If you give a file name, it
will immediately be opened (this may throw an error).

=item filter

Reference to a filter method. The methods gets an array
(datetime, host, referer, service, id, valid, size) for each
log event and is expected to return an array of same size.
If the filter method returns undef, the log message
will not be written to the log file.

Here is an example of a filter method that removes the query
part of each referer:

  my $logger = SeeAlso::Logger->new(
      file => "/var/log/seealso/seealso.log",
      filter => sub { $_[1] =~ s/\?.*$//; @_; }
  } );

=item privacy

Do not log remote host (remote host is always '-').
To also hide the referer, use a filter method.

=back

=head2 set_file ( $file-or-handle )

Set the file handler or file name or function to log to.
If you specify a filename, the filename property of this
object is set. Returns the file handle on success.

=head2 log ( $cgi, $response, $service )

Log a request and response. The response must be a L<SeeAlso::Response> object,
the service is string. Each logging event is a line of tabulator seperated
values. Returns true if something was logged.

=over 4

=item datetime

An ISO 8601 timestamp (YYYY-MM-DDTHH:MM:SS).

=item host

The remote host (usually an IP address) unless privacy is enabled.

=item referer

HTTP Referer.

=item service

Name of a service.

=item id

The requested search term (CGI parameter 'id')

=item valid

Whether the search term was a valid identifier (1) or not (0).
This will only give meaningful values of your query method does
not put invalid identifiers in the response.

=item size

Number of entries in the response content

=back

=head1 ADDITIONAL FUNCTIONS

=head2 parse ( $line )

Parses a line of of seven tabulator seperated values. The first value must be a
ISO 8601 timestamp.
as

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

