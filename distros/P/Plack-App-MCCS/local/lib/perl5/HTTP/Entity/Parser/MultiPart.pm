package HTTP::Entity::Parser::MultiPart;

use strict;
use warnings;
use HTTP::MultiPartParser;
use File::Temp qw/tempfile/;
use Carp qw//;
use Fcntl ":seek";

#
# copy from https://gist.github.com/chansen/7163968
#
sub extract_form_data {
    local $_ = shift;
    # Fast exit for common form-data disposition
    if (/\A form-data; \s name="((?:[^"]|\\")*)" (?: ;\s filename="((?:[^"]|\\")*)" )? \z/x) {
        return ($1, $2);
    }

    # disposition type must be form-data
    s/\A \s* form-data \s* ; //xi
      or return;

    my (%p, $k, $v);
    while (length) {
        s/ ^ \s+   //x;
        s/   \s+ $ //x;

        # skip empty parameters and unknown tokens
        next if s/^ [^\s"=;]* \s* ; //x;

        # parameter name (token)
        s/^ ([^\s"=;]+) \s* = \s* //x
          or return;
        $k = lc $1;
        # quoted parameter value
        if (s/^ "((?:[^"]|\\")*)" \s* (?: ; | $) //x) {
            $v = $1;
        }
        # unquoted parameter value (token)
        elsif (s/^ ([^\s";]*) \s* (?: ; | $) //x) {
            $v = $1;
        }
        else {
            return;
        }
        if ($k eq 'name' || $k eq 'filename') {
            return () if exists $p{$k};
            $p{$k} = $v;
        }
    }
    return exists $p{name} ? @p{qw(name filename)} : ();
}

sub new {
    my ($class, $env, $opts) = @_;

    my $self = bless { }, $class;

    my @uploads;
    my @params;

    unless (defined $env->{CONTENT_TYPE}) {
        Carp::croak("Missing CONTENT_TYPE in PSGI env");
    }
    unless ( $env->{CONTENT_TYPE} =~ /boundary=\"?([^\";]+)\"?/ ) {
        Carp::croak("Invalid boundary in content_type: $env->{CONTENT_TYPE}");
    }
    my $boundary = $1;


    my $part;
    my $parser = HTTP::MultiPartParser->new(
        boundary => $boundary,
        on_header => sub {
            my ($headers) = @_;

            my $disposition;
            foreach (@$headers) {
                if (/\A Content-Disposition: [\x09\x20]* (.*)/xi) {
                    $disposition = $1;
                    last;
                }
            }

            (defined $disposition)
                or die q/Content-Disposition header is missing in part/;

            my ($disposition_name, $disposition_filename) = extract_form_data($disposition);
            defined $disposition_name
                or die q/Parameter 'name' is missing from Content-Disposition header/;

            $part = {
                name    => $disposition_name,
                headers => $headers,
            };

            if ( defined $disposition_filename ) {
                $part->{filename} = $disposition_filename;
                $self->{tempdir} ||= do {
                    my $dir = File::Temp->newdir('XXXXX', TMPDIR => 1, CLEANUP => 1);
                    # Temporary dirs will remove after the request.
                    push @{$env->{'http.entity.parser.multipart.tempdir'}}, $dir;
                    $dir;

                };
                my ($tempfh, $tempname) = tempfile(UNLINK => 0, DIR => $self->{tempdir});
                $part->{fh} = $tempfh;
                $part->{tempname} = $tempname;
            }
        },
        on_body => sub {
            my ($chunk, $final) = @_;

            my $fh = $part->{fh};
            if ($fh) {
                print $fh $chunk
                    or die qq/Could not write to file handle: '$!'/;
                if ($final && $part->{filename} ne "" ) { # compatible with HTTP::Body
                    seek($fh, 0, SEEK_SET)
                        or die qq/Could not rewind file handle: '$!'/;

                    my @headers = map { split(/\s*:\s*/, $_, 2) }
                        @{$part->{headers}};
                    push @uploads, $part->{name}, {
                        name     => $part->{name},
                        headers  => \@headers,
                        size     => -s $part->{fh},
                        filename => $part->{filename},
                        tempname => $part->{tempname},
                    };
                }
            } else {
                $part->{data} .= $chunk;
                if ($final) {
                    push @params, $part->{name}, $part->{data};
                }
            }
        },
        $opts->{on_error} ? (on_error => $opts->{on_error}) : (),
    );

    $self->{parser}  = $parser;
    $self->{params}  = \@params;
    $self->{uploads} = \@uploads;

    return $self;
}

sub add {
    my $self = shift;
    $self->{parser}->parse($_[0]) if defined $_[0];
}

sub finalize {
    my $self = shift;
    (delete $self->{parser})->finish();
    return ($self->{params}, $self->{uploads});
}


1;

__END__

=encoding utf-8

=head1 NAME

HTTP::Entity::Parser::MultiPart - parser for multipart/form-data

=head1 SYNOPSIS

    use HTTP::Entity::Parser;
    
    my $parser = HTTP::Entity::Parser->new;
    $parser->register('multipart/form-data','HTTP::Entity::Parser::MultiPart');

=head1 DESCRIPTION

This is a parser class for multipart/form-data.

MultiPart parser use L<HTTP::MultiPartParser>.

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=cut


