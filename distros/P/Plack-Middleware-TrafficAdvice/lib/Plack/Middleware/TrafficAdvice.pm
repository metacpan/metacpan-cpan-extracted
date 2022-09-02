package Plack::Middleware::TrafficAdvice;

# ABSTRACT: handle requests for /.well-known/traffic-advice

use v5.8.5;

use strict;
use warnings;

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw/ data file /;

use Cwd;
use File::Temp qw/ tempfile /;
use HTTP::Date;
use HTTP::Status qw/ :constants /;
use JSON::MaybeXS 1.004000;

our $VERSION = 'v0.2.3';


sub prepare_app {
    my ($self) = @_;

    if (my $data = $self->data) {

        if ($self->file) {
            die "Cannot specify both data and file";
        }

        my ($fh, $filename) = tempfile('traffic-advice-XXXXXXXX', SUFFIX => '.json', UNLINK => 0, TMPDIR => 1);
        $self->file( $filename );

        if (ref($data)) {
            my $encoder = JSON::MaybeXS->new( { utf8 => 1 } );
            print {$fh} $encoder->encode($data)
                or die "Unable to write data";
        }
        else {
            print {$fh} $data
                or die "Unable to write data";
        }

        close $fh;


    }
    elsif (my $file = $self->file) {

        unless (-r $file) {
            die "Cannot read file: '$file'";
        }

    }
    else {
        die "Either data or file must be configured";
    }

}

sub call {
    my ( $self, $env ) = @_;

    unless ( $env->{REQUEST_URI} eq '/.well-known/traffic-advice' ) {
        return $self->app->($env);
    }

    unless ( $env->{REQUEST_METHOD} =~ /^(GET|HEAD)$/ ) {
        return $self->error( HTTP_METHOD_NOT_ALLOWED, "Not Allowed" );
    }

    my $file = $self->file;

    # Some of this is based on Plack::App::File.

    open my $fh, "<:raw", $file
        or return $self->error( HTTP_INTERNAL_SERVER_ERROR, "Internal Error" );

    my @stat = stat $file;

    Plack::Util::set_io_path($fh, Cwd::realpath($file));

    [
        HTTP_OK,
        [
         'Content-Type'   => 'application/trafficadvice+json',
         'Content-Length' => $stat[7],
         'Last-Modified'  => HTTP::Date::time2str( $stat[9] )
        ],
        $fh,
    ];

}


sub error {
    my ($self, $code, $message) = @_;
    return [ $code, [ 'Content-Type' => 'text/plain', 'Content-Length' => length($message) ], [ $message ] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::TrafficAdvice - handle requests for /.well-known/traffic-advice

=head1 VERSION

version v0.2.3

=head1 SYNOPSIS

  use JSON::MaybeXS 1.004000;
  use Plack::Builder;

  builder {

    enable "TrafficAdvice",
      data => [
        {
            user_agent => "prefetch-proxy",
            disallow   => JSON::MaybeXS->true,
        }
      ];

    ...

  };

=head1 DESCRIPTION

This middle provides a handler for requests for C</.well-known/traffic-advice>.

You must specify either a L</file> or L</data> containing the traffic
advice information. (There is no default value.)

=head1 ATTRIBUTES

=head2 data

This is either an array referece that corresponds to the traffic advice data structure,
or a JSON string to return.

The data will be saved as a temporary L</file>.

=head2 file

This is a file containing the JSON string to return.

=for Pod::Coverage error

=head1 KNOWN ISSUES

The C</.well-known/traffic-advice> specification is new and may be subject to change.

This does not validate that the L</data> string or L</file> contains
valid JSON, or that the JSON conforms to the specification.

=head1 SEE ALSO

L<https://github.com/buettner/private-prefetch-proxy/blob/main/traffic-advice.md>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Plack-Middleware-TrafficAdvice>
and may be cloned from L<git://github.com/robrwo/Plack-Middleware-TrafficAdvice.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Plack-Middleware-TrafficAdvice/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021-2022 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
