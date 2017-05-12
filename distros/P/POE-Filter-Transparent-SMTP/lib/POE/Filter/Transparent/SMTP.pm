# Copyright (c) 2008-2009 George Nistorica
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	($rcs) = (' $Id: SMTP.pm,v 1.11 2009/01/28 12:45:15 george Exp $ ' =~ /(\d+(\.\d+)+)/);

package POE::Filter::Transparent::SMTP;
use strict;
use warnings;

use POE::Filter::Line;
use Data::Dumper;
use Carp;

our $VERSION = q{0.2};
my $EOL = qq{\015\012};

sub new {
    my $class   = shift;
    my @options = @_;
    my %options = @options;

    my ( $filter, $self, %filter_line_opts );
    if ( ref $class ) {
        croak q{->new() is a class method!};
    }

    foreach (qw/InputLiteral OutputLiteral/) {
        if ( exists $options{$_} and defined $options{$_} ) {
            $filter_line_opts{$_} = $options{$_};
        }
    }

    # we need this when outputing data prefixed by dot
    if ( not exists $filter_line_opts{'OutputLiteral'} ) {
        $self->{'OutputLiteral'} = $EOL;
    }
    else {
        $self->{'OutputLiteral'} = $filter_line_opts{'OutputLiteral'};
    }

    if (    exists $options{'Warn'}
        and defined $options{'Warn'}
        and $options{'Warn'} )
    {
        $self->{'Warn'} = 1;
    }
    else {
        $self->{'Warn'} = 0;
    }

    # check for EscapeSingleInputDot
    # defaults to no
    # useful for escaping Single Dot on a line in message bodies (not
    # entire SMTP transaction logs, that include the message body as
    # well)

    if (    exists $options{'EscapeSingleInputDot'}
        and defined $options{'EscapeSingleInputDot'}
        and $options{'EscapeSingleInputDot'} )
    {
        $self->{'EscapeSingleInputDot'} = 1;
    }
    else {
        $self->{'EscapeSingleInputDot'} = 0;
    }

    # create the POE::Filter::Line filter to store inside our little so
    # called object
    $filter = POE::Filter::Line->new(%filter_line_opts);
    $self->{'filter_line'} = $filter;
    bless $self, $class;
    return $self;
}

sub clone {
    my $self = shift;
    my $filter;
    if ( not ref $self ) {
        croak q{->clone() is not a package method!};
    }
    my $new_obj = $self;
    $filter                   = $new_obj->{'filter_line'};
    $filter                   = $filter->clone;
    $new_obj->{'filter_line'} = $filter;
    return $new_obj;
}

sub get_one_start {
    my $self = shift;
    my $arg  = shift;
    if ( ref $arg ne q{ARRAY} ) {
        croak q{->get_one_start() accepts an array ref as argument};
    }
    my $filter = $self->{'filter_line'};
    $filter->get_one_start($arg);
    return;
}

sub get_one {
    my $self = shift;
    my $data;
    my $filter = $self->{'filter_line'};
    $data = $filter->get_one();

    # remove the leading transparent dot
    for ( my $i = 0 ; $i < scalar @{$data} ; $i++ ) {
        if ( $data->[$i] =~ /^\.(\..*)$/os ) {
            $data->[$i] = $1;
        }
        if ( $self->{'Warn'} and $data->[$i] =~ /^\..+$/os ) {
            carp q{Data contains a single leading dot }
              . q{and is not conforming to RFC 821 Section }
              . q{4.5.2. TRANSPARENCY};
        }
    }
    return $data;
}

sub get {
    my $self     = shift;
    my $raw_data = shift;

    if ( ref $raw_data ne q{ARRAY} ) {
        croak q{->get() accepts an array ref as argument};
    }
    my $data = [];
    my $temp;

    $self->get_one_start($raw_data);
    $temp = $self->get_one();
    while ( scalar @{$temp} ) {
        push @{$data}, $temp->[0];
        $temp = $self->get_one();
    }

    return $data;
}

sub put {
    my $self     = shift;
    my $raw_data = shift;
    if ( ref $raw_data ne q{ARRAY} ) {
        croak q{->get_one_start() accepts an array ref as argument};
    }
    my ( $filter, $lines, $literal );
    $literal = $self->{'OutputLiteral'};
    $filter  = $self->{'filter_line'};
    $lines   = $filter->put($raw_data);

    # add an extra leading dot on lines starting with a dot
    for ( my $i = 0 ; $i < scalar @{$lines} ; $i++ ) {
        if ( $lines->[$i] =~ /^\..+$literal$/s ) {
            $lines->[$i] = q{.} . $lines->[$i];
        }

        # do we escape single dot? (for filtering message bodies, not
        # entire SMTP transaction
        if ( $self->{'EscapeSingleInputDot'}
            and ( $lines->[$i] =~ /^\.$/so or $lines->[$i] =~ /^\.$literal$/so )
          )
        {
            $lines->[$i] = q{.} . $lines->[$i];
        }
    }

    return $lines;
}

sub get_pending {
    my $self   = shift;
    my $filter = $self->{'filter_line'};
    return $filter->get_pending();
}

1;

__END__

=pod

=head1 NAME

POE::Filter::Transparent::SMTP - Make SMTP transparency a breeze :)

=head1 VERSION

VERSION: 0.2

=head1 SYNOPSIS

 use POE::Filter::Transparent::SMTP;

 my @array_of_things = (
     q{.first thing(no new line)},
     qq{.second thing (with new line)\n},
     q{.third thing (no new line},
     q{.}, # this is the message terminator, so it shouldn't be
           # prepended with an extra dot
 );
 my $filter = POE::Filter::Transparent::SMTP->new( );
 my $lines = $filter->put( \@array_of_things );

=head1 DESCRIPTION

The filter aims to make SMTP data transparent just before going onto
the wire as per RFC 821 Simple Mail Transfer Protocol Section
4.5.2. TRANSPARENCY. See L<http://www.faqs.org/rfcs/rfc821.html> for
details.

Conversely the filter takes transparent data from the wire and
converts it to the original format.

The main purpose of this filter is to help
L<POE::Component::Client::SMTP> create transparent messages when
comunicating with an SMTP server. However the filter can be used by
any Perl SMTP client or server.

Internally it uses L<POE::Filter::Line> in order to split messages
into lines. Also as stated in the RFC every line it puts on the wire
is ended by <CRLF>.

When receiving data from the wire (as it is the case for an SMTP
server), lines should be separated with <CRLF> as the RFC
specifies. However this is not always true as some SMTP clients are
broken. So if you are using the filter on the receiving end maybe you
would like to specify a regular expression that is more flexible for
the line terminator.

=head1 METHODS

All methods are conforming to L<POE::Filter> specs. For more details
have a look at L<POE::Filter> documentation.

=head2 new HASHREF_OF_PARAMETERS

 my $filter = POE::Filter::Transparent::SMTP->new(
     InputLiteral => qq{\015\012},
      OutputLiteral => qq{\015\012},
 );

Creates a new filter.

It accepts four optional arguments:

=over 4

=item InputLiteral

InputLiteral is the same as InputLiteral for L<POE::Filter::Line>

It defaults to whatever L<POE::Filter::Line> is defaulting. Currently
L<POE::Filter::Line> tries to auto-detect the line separator, but that
may lead to a race condition, please consult the L<POE::Filter::Line>
documentation.

=item OutputLiteral

OutputLiteral is the same as OutputLiteral for L<POE::Filter::Line>

It defaults to B<CRLF> if not specified otherwise.

=item Warn

In case L</get_one> receives lines starting with a leading dot and
L</Warn> is enabled it issues a warning about this. By default the
warning is disabled.

=item EscapeSingleInputDot

In case you want to escape the single dot when reading data.

The parameter is useful for escaping single dots on a line when
reading message bodies. Don't use this for filtering entire SMTP
transaction logs as it will ruin your command '.'

B<Defaults> to false

=back

=head2 get_one_start ARRAYREF

 $filter->get_one_start( $array_ref_of_formatted_lines );

Accepts an array reference to a list of unprocessed chunks and adds
them to the buffer in order to be processed.

=head2 get_one

 my $array_ref = $filter->get_one(); my $line = $array_ref->[0];

Returns zero or one processed record from the raw data buffer. The
method is not greedy and is I<the preffered> method you should use to
get processed records.

=head2 get ARRAY_REF

 my $lines = $filter->get( $array_ref_of_formatted_lines );
 for (my $i = 0; $i < scalar @{$lines}; $i++ ) {
     # do something with $lines->[$i];
 }

L</get> is the greedy form of L</get_one> and internally is
implemented as one call of L</get_one_start> and a loop of
L</get_one>.

Normally you shouldn't use this as using L</get_one_start> and
L</get_one> would make filter swapping easyer.

=head2 put ARRAYREF

 my @array_of_things = (
     q{.first thing(no new line)},
     qq{.second thing (with new line)\n},
     q{.third thing (no new line}, q{.},
 );
 my $lines = $filter->put( \@array_of_things );
 print Dumper( $lines );

would return something similar as below

 $VAR1 = [
          '..first thing(no new line)
 ',
          '..second thing (with new line)

 ',
          '..third thing (no new line
 ',
          '.
 '
        ];

L</put> takes an array ref of unprocessed records and prepares them to
be put on the wire making the records SMTP Transparent.

=head2 get_pending

Returns a list of data that is in the buffer (without clearing it) or
undef in case there is nothing in the buffer.

=head2 clone

 my $new_filter = $filter->clone();

Clones the current filter keeping the same parameters, but with an
empty buffer.

=head1 SEE ALSO

L<POE> L<POE::Filter> L<POE::Filter::Line>
L<POE::Component::Client::SMTP> L<POE::Component::Server::SimpleSMTP>

=head1 KNOWN ISSUES

By default, InputLiteral is set to the default L<POE::Filter::Line>
which can become an issue if you are using the filter on the receiving
end.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-filter-transparent-smtp at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Filter-Transparent-SMTP>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Filter::Transparent::SMTP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Filter-Transparent-SMTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Filter-Transparent-SMTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Filter-Transparent-SMTP>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Filter-Transparent-SMTP>

=back

=head1 ACKNOWLEDGMENTS

Thanks to Jay Jarvinen who pointed out that
L<POE::Component::Client::SMTP> is not doing SMTP transparency as it
should (RFC 821, Section 4.5.2.  TRANSPARENCY)

=head1 AUTHOR

George Nistorica, ultradm __at cpan __dot org

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 George Nistorica, all rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
