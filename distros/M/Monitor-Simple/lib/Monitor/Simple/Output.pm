#-----------------------------------------------------------------
# Monitor::Simple::Output
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see Monitor::Simple.
#
# ABSTRACT: See documentation in Monitor::Simple
# PODNAME: Monitor::Simple::Output
#-----------------------------------------------------------------
use warnings;
use strict;

package Monitor::Simple::Output;
use Monitor::Simple;
use Log::Log4perl qw(:easy);

our $VERSION = '0.2.8'; # VERSION

my @Headers = ('DATE', 'SERVICE', 'STATUS', 'MESSAGE');

my $Formats = { tsv    => 'TAB-separated (good for machines)',
                human  => 'Easier readable by humans',
                html   => 'Formatted as an HTML document',
};

#-----------------------------------------------------------------
# Recognized arguments:            Default value:
#    outfile => <file>             none
#    onlyerr => boolean            false
#    format  => tsv | human | html human
#    cssurl  => <url>              content taken from 'monitor-default.css'
#    config  => <config>
#-----------------------------------------------------------------
sub new {
    my ($class, %args) = @_;

    # create an object and fill it from $args
    my $self = bless {}, ref ($class) || $class;
    foreach my $key (keys %args) {
        $self->{$key} = $args {$key};
    }
    LOGDIE ("outputter: Missing argument 'config'. Cannot do anything.\n")
        unless $self->{config};

    # assign some default values
    $self->{format} = 'human'  unless $self->{format};
    $self->{format} = 'human'  unless exists $Formats->{ $self->{format} };

    # compute the longest service name (needed only for 'human' format)
    if ($self->{format} eq 'human') {
        my $longest_name_len = length ($Headers[1]);
        map {
            my $len = length ($_->{name} || $_->{id});
            $longest_name_len = $len if $len > $longest_name_len } @{ $self->{config}->{services} };
        $self->{report_format} = "%-30s %-${longest_name_len}s  %6s  %s\n";
    }

    # prepare output
    if ($self->{outfile}) {
        open ($self->{fhout}, '>', $self->{outfile})
            or LOGDIE ("Cannot open file '$self->{outfile}' for writing: $!\n");
        close ($self->{fhout});
    } else {
        $self->{fhout} = *STDOUT;
        my $oldfh = select ($self->{fhout}); $| = 1; select ($oldfh);  # turn autoflush on
    }

    # done
    return $self;
}

#-----------------------------------------------------------------
# Return a hashref with all available formats: keys are format
# identifiers and values their descriptions.
# -----------------------------------------------------------------
sub list_formats {
    my $self = shift;
    return $Formats;
}

#-----------------------------------------------------------------
# Join and return @fields into a string, depending on
# $self->{format}. $service_config may be useful for some formatting.
# -----------------------------------------------------------------
sub create_report {
    my ($self, $service_config, @fields) = @_;
    if ($self->{format} eq 'tsv') {
        return join ("\t", @fields) . "\n";

    } elsif ($self->{format} eq 'html') {
        return $self->html_line ($service_config, @fields);

    } else {
        return sprintf ($self->{report_format}, @fields);
    }
}

sub html_header {
    my ($self, @fields) = @_;
    my ($link, $style);
    if ($self->{cssurl}) {
        $link = qq{<link href="$self->{cssurl}" rel="stylesheet" type="text/css">};
        $style = '';
    } else {
        $link = '';
        $style = <<'END_OF_STYLE';
<style>
.mon-line, .mon-header-line {
   vertical-align:text-top;
}
.mon-header-line {
   font-weight: bold;
   background: grey;
}
.mon-line-ok {
   background: lightgreen;
}
.mon-line-warning {
   background: lightblue;
}
.mon-line-critical, .mon-line-unknown, .mon-line-fatal {
   background: red;
   color: yellow;
}
.mon-date {
   white-space: nowrap;
}
.mon-date, .mon-service, .mon-code, .mon-msg, .mon-header-date, .mon-header-service, .mon-header-code, .mon-header-msg {
   padding: 3px;
}
.mon-caption {
   color: brown;
   font-style: italid;
   font-size: 80%;
}
</style>
END_OF_STYLE
    }

    my $current_date = localtime;
    return <<"END_OF_HEADER";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    $link
  </head>
  <body>
$style
<table border="0" class="mon-table">
<caption class="mon-caption">Created: $current_date</caption>
<tr class="mon-header-line">
   <td class="mon-header-date">$fields[0]</td>
   <td class="mon-header-service">$fields[1]</td>
   <td class="mon-header-code">$fields[2]</td>
   <td class="mon-header-msg">$fields[3]</td>
</tr>
END_OF_HEADER
}

my $Status = {
    Monitor::Simple::RETURN_OK       => 'OK',
    Monitor::Simple::RETURN_WARNING  => 'WARNING',
    Monitor::Simple::RETURN_CRITICAL => 'CRITICAL',
    Monitor::Simple::RETURN_UNKNOWN  => 'UNKNOWN',
    Monitor::Simple::RETURN_FATAL    => 'FATAL',
};

sub html_line {
    my ($self, $service_config, @fields) = @_;
    my $status = $Status->{$fields[2]} || "Unrecognized";
    my $class_suffix = lc ($status);
    my $title = $service_config->{description};
    if ($title) {
        $title = 'title="' . $self->escapeHTML ($title) . '"';
    } else {
        $title = '';
    }
    my $service_name = $self->escapeHTML ($fields[1]);
    my $message = $self->escapeHTML ($fields[3]);

    return <<"END_OF_LINE";
<tr class="mon-line mon-line-$class_suffix">
   <td class="mon-date mon-date-$class_suffix">$fields[0]</td>
   <td class="mon-service mon-service-$class_suffix" $title>$service_name</td>
   <td class="mon-code mon-code-$class_suffix">$status</td>
   <td class="mon-msg mon-msg-$class_suffix">$message</td>
</tr>
END_OF_LINE
}

sub html_footer {
    return "</table>\n";
}

sub escapeHTML {
    my ($self, $value) = @_;
    $value =~ s{&}{&amp;}gso;
    $value =~ s{<}{&lt;}gso;
    $value =~ s{>}{&gt;}gso;
    $value =~ s{"}{&#34;}gso;
    return $value;
}

#------------------------------------------------------------------
# An atomic output, protected by file locking. All output goes through
# here.
# -----------------------------------------------------------------
sub _out {
    my ($self, $msg) = @_;
    if ($self->{outfile}) {
        local *DATA;
        open (my $data, "+<", $self->{outfile})
            or LOGDIE "Cannot open " . $self->{outfile} . ": $!\n";
        lock_file ($data);
        print $data $msg or LOGDIE ("Output missed: $msg");
        close $data;
    } else {
        print STDOUT $msg or LOGDIE ("Output missed: $msg");
    }
}

#-----------------------------------------------------------------
# Output header-line in a format given in $self->{format}, or given by
# (otherwise optional) $header.
# -----------------------------------------------------------------
sub header {
    my ($self, $header) = @_;
    return if $self->{format} eq 'tsv';   # no headers for machines

    if ($self->{outfile} or not $self->{onlyerr}) {
        if ($header) {
            # print whatever header was sent here
            $self->_out ($header);

        } else {
            # ...or make a default header (which depends on the format)
            if ($self->{format} eq 'html') {
                $self->_out ($self->html_header (@Headers));
            } else {
                $self->_out ($self->create_report ({}, @Headers));
            }
        }
    }
}

# using header() to do the printing
sub footer {
    my ($self, $footer) = @_;
    return $self->header ($footer) if $footer;
    return $self->header ($self->html_footer()) if $self->{format} eq 'html';
    return;
}

#-----------------------------------------------------------------
# Format and output one message about a just finished service check
# (with an additional date field):
#    $service_id ... what service is the report about
#    $code ... error or not error? (see $Monitor::Simple::RETURN*)
#    $msg ... the real message
#
# Here are various conditions and their combinations:
#
#    outfile    onlyerr    what will be done
#    ---------------------------------------------
#    yes        no         - all output to file
#    yes        yes        - all output to file
#                          - errors also on STDOUT
#    no         no         - all output to STDOUT
#    no         yes        - only errors to STDOUT
#
# Note that additionally to the above the STDERR can also be printed
# to - if a plugin chooses to produce some. The STDERR is not
# controlled by this module.
# -----------------------------------------------------------------
sub out {
    my ($self, $service_id, $code, $msg) = @_;
    my $service_config =
        ( Monitor::Simple::Config->extract_service_config ($service_id, $self->{config}) ||
          { id   => $service_id, name => $service_id } );
    my $service_name = ($service_config->{name} or $service_config->{id});
    my $doc = $self->create_report ($service_config, scalar localtime(), $service_name, $code, $msg);
    if ($self->{outfile} or not $self->{onlyerr}) {
        $self->_out ($doc);
    }
    if ($code ne Monitor::Simple::RETURN_OK and $self->{onlyerr}) {
        print STDOUT $doc or LOGDIE ("Output missed: $doc");
    }
}

use Fcntl qw(:flock SEEK_END); # import LOCK_* and SEEK_END constants
sub lock_file {
    my ($fh) = @_;
    flock ($fh, LOCK_EX) or LOGDIE ("Cannot lock output file with reports: $!\n");
    seek ($fh, 0, SEEK_END) or LOGDIE ("Cannot seek output file with reports: $!\n");
}

sub unlock_file {
    my ($fh) = @_;
    flock ($fh, LOCK_UN)
        or LOGDIE ("Cannot unlock output file with reports: $!\n");
}

1;


=pod

=head1 NAME

Monitor::Simple::Output - See documentation in Monitor::Simple

=head1 VERSION

version 0.2.8

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC-KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
