# -*- mode: cperl; cperl-indent-level: 4; -*-
# vi:ai:sm:et:sw=4:ts=4

# $Id: Procmail.pm,v 1.3 2004/11/12 06:11:27 paulv Exp $

package POE::Filter::Log::Procmail;

use strict;
use warnings;
use Data::Dumper;
use POE::Filter::Line;
use Carp qw(croak);

our $VERSION = '0.03';

# sub get_one_start {
#     my $self = shift;
#     my $chunk = shift;
#
#     my $lines = $self->{line}->get($chunk);
#    
#     foreach my $line (@$lines) {
#         $self->_debug("line is *$line*");
#
#         if ($self->_wantLine($line)) {
#             push(@{$self->{queue}}, $line);
#         } else {
#             $self->_debug("got a bad line: $line");
#         }
#     }
# }
# sub get_one {  $self->_debug("get_one"); return []; }
# sub put { $self->_debug("put"); return; }
# sub get_pending { }

sub new {
    my $class = shift;

    croak "$class requires an even number of parameters" if @_ and @_ & 1;

    my %params = @_;

    my $self = {};

    if (defined $params{Debug} and $params{Debug} > 0) {
        $self->{debug} = 1;
    } else {
        $self->{debug} = 0;
    }
    
    $self->{line} = POE::Filter::Line->new();
    $self->{queue} = [];
    $self->{count} = 0;
    
    $self->{dow} = qr/(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)/o;
    $self->{mon} = qr/(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/o;

    # the regexps in $self->{match} match the following lines of procmail log
    #
    # From paulv@cpan.org  Tue Oct 19 13:00:02 2004
    #  Subject: whatever
    #   Folder: mail/paulv                                                 6809
    
    $self->{match} = [
                      qr/^From (.+)\s\s($self->{dow}) ($self->{mon}) ([ \d]\d) (\d{2}:\d{2}:\d{2}) (\d{4})$/,
                      qr/^\sSubject: ?(.+)?$/i,
                      qr/^\s\sFolder: (.+?)\s+(\d+)$/,
                     ];
    
    bless ($self, $class);
    return $self;
}

sub get {
    my $self = shift;
    my $chunk = shift;
    my @objects;
    
    my $lines = $self->{line}->get($chunk);

    foreach my $line (@$lines) {
        $self->_debug("line is *$line*");

        my $test = $self->_wantLine($line);

        if ($test == 1) {
            push(@{$self->{queue}}, $line);
        } elsif ($test == 2) {
            # if test is 2, it means we need to fake a Subject line.
            push(@{$self->{queue}}, "Subject:\n");
            push(@{$self->{queue}}, $line);
        } else {
            $self->_debug("got a bad line: $line");
        }
    }

    # loop while there are 3 or more elements in the queue
    while (@{$self->{queue}} > 2) {
        push(@objects, $self->_makeHRef());
    }

    return \@objects;
}

sub _wantLine {
    my $self = shift;
    my $line = shift;

    my $count = $self->{count};
    
    if ($line =~ /^$/) {
        $self->_debug("Skipping: blank line");
        return 0;
    }

    if ($line =~ $self->{match}->[$count]) {
        $self->{count} = ($count == 2) ? 0 : ++$count;
        $self->_debug("$line matched $self->{match}->[$count]");
        $self->_debug("setting count to $self->{count}");
        return 1;
    } elsif ($count == 1 and
             $line !~ $self->{match}->[$count] and
             $line =~ $self->{match}->[$count + 1])
    {
        # this is if we get a non-existant Subject line.
        $self->_debug("No Subject!");
        $self->{count} = 0;
        return 2;
    } else {
        $self->_debug("$line didn't match $self->{match}->[$self->{count}]");
        return 0;
    }
}

sub _makeHRef {
    my $self = shift;
    my $href;
    
    my @lines = ( shift(@{$self->{queue}}),
                  shift(@{$self->{queue}}),
                  shift(@{$self->{queue}}),
                );

    if ($lines[0] =~ $self->{match}->[0]) {
        $href->{from} = $1;
        $href->{dow} = $2;
        $href->{mon} = $3;
        $href->{date} = $4;
        $href->{time} = $5;
        $href->{year} = $6;

        # date could be ' 1'
        $href->{date} =~ s/\s+//g;
    }

    if ($lines[1] =~ $self->{match}->[1]) {
        $href->{subject} = $1;
    }

    if ($lines[2] =~ $self->{match}->[2]) {
        $href->{folder} = $1;
        $href->{size} = $2;
    } 

    return $href;
}

sub _debug {
    my $self = shift;
    my @args = @_;

    print STDERR "@args\n" if $self->{debug};
}

1;

__END__

=head1 NAME

POE::Filter::Log::Procmail - filter for processing procmail logs

=head1 SYNOPSIS

  use POE::Filter::Log::Procmail;

  $filter = POE::Filter::Log::Procmail->new(Debug => 1);
  $arrayref_of_hashrefs = $filter->get($arrayref_of_raw_chunks_from_driver);

=head1 DESCRIPTION

The Log::Procmail filter translates procmail record streams to hashrefs.

=head1 PUBLIC FLITER METHODS

=over 2

=item new

new() creates and initializes a new POE::Filter::Log::Procmail filter.
You can pass it "Debug => 1" to turn debugging on.

=item get ARRAYREF

get() translates procmail log lines into hashrefs. The hashref looks like

 $VAR1 = {                                
           'subject' => 'Re: use XML::Simple breaks my PoCo::IKC::Server',
           'time' => '12:22:50',
           'date' => '1',
           'size' => '1726',
           'folder' => 'mail/perl/poe',
           'from' => 'poe-return-2605-paulv=cpan.org.org',
           'dow' => 'Thu',
           'mon' => 'Nov',
           'year' => '2004'
         };

=back

=head1 SEE ALSO

POE::Filter.

=head1 BUGS

Doesn't support get_one(), get_one_start(), or get_pending(). This means
switching from this filter to another filter probably won't work, but I
haven't tried it.

Doesn't support put().

Ignores verbose lines if VERBOSE is set in .procmailrc.

=head1 AUTHOR

Paul Visscher, E<lt>paulv@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Paul Visscher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
