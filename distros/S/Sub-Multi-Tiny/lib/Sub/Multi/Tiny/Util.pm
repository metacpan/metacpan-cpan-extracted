package Sub::Multi::Tiny::Util;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);
use vars::i [
    '$VERBOSE' => 0,    # Set this to a positive int for extra output on STDERR
    '@EXPORT' => [],
    '@EXPORT_OK' => [qw(_carp _croak _hlog _line_mark_string *VERBOSE)],
];
use vars::i '%EXPORT_TAGS' => { all => [@EXPORT, @EXPORT_OK] };

our $VERSION = '0.000004'; # TRIAL


# Documentation {{{1

=head1 NAME

Sub::Multi::Tiny::Util - Internal utilities for Sub::Multi::Tiny

=head1 SYNOPSIS

Used by L<Sub::Multi::Tiny>.

=head1 VARIABLES

=head2 $VERBOSE

Set this truthy for extra debug output.  Automatically set to C<1> if the
environment variable C<SUB_MULTI_TINY_VERBOSE> has a truthy value.

=head1 FUNCTIONS

=cut

# }}}1

=head2 _croak

As L<Carp/croak>, but lazily loads L<Carp>.

=cut

sub _croak {
    require Carp;
    goto &Carp::croak;
}

=head2 _carp

As L<Carp/carp>, but lazily loads L<Carp>.

=cut

sub _carp {
    require Carp;
    goto &Carp::carp;
}

=head2 _line_mark_string

Add a C<#line> directive to a string.  Usage:

    my $str = _line_mark_string <<EOT ;
    $contents
    EOT

or

    my $str = _line_mark_string __FILE__, __LINE__, <<EOT ;
    $contents
    EOT

In the first form, information from C<caller> will be used for the filename
and line number.

The C<#line> directive will point to the line after the C<_line_mark_string>
invocation, i.e., the first line of <C$contents>.  Generally, C<$contents> will
be source code, although this is not required.

C<$contents> must be defined, but can be empty.

=cut

sub _line_mark_string {
    my ($contents, $filename, $line);
    if(@_ == 1) {
        $contents = $_[0];
        (undef, $filename, $line) = caller;
    } elsif(@_ == 3) {
        ($filename, $line, $contents) = @_;
    } else {
        _croak "Invalid invocation";
    }

    _croak "Need text" unless defined $contents;
    die "Couldn't get location information" unless $filename && $line;

    $filename =~ s/"/-/g;
    ++$line;

    return <<EOT;
#line $line "$filename"
$contents
EOT
} #_line_mark_string()

=head2 _hlog

Log information if L</$VERBOSE> is set.  Usage:

    _hlog { <list of things to log> } [optional min verbosity level (default 1)];

The items in the list are joined by C<' '> on output, and a C<'\n'> is added.
Each line is prefixed with C<'# '> for the benefit of test runs.

The list is in C<{}> so that it won't be evaluated if logging is turned off.
It is a full block, so you can run arbitrary code to decide what to log.
If the block returns an empty list, C<_hlog> will not produce any output.
However, if the block returns at least one element, C<_hlog> will produce at
least a C<'# '>.

The message will be output only if L</$VERBOSE> is at least the given minimum
verbosity level (1 by default).

If C<< $VERBOSE > 2 >>, the filename and line from which C<_hlog> was called
will also be printed.

=cut

sub _hlog (&;$) {
    return unless $VERBOSE >= ($_[1] || 1);

    my @log = &{$_[0]}();
    return unless @log;

    chomp $log[$#log] if $log[$#log];
    # TODO add an option to number the lines of the output
    (my $msg = join(' ', @log)) =~ s/^/# /gm;
    if($VERBOSE>2) {
        my ($package, $filename, $line) = caller;
        $msg .= " (at $filename:$line)";
    }
    print STDERR "$msg\n";
} #_hlog()

1;
__END__

# Rest of documentation {{{1

=head1 AUTHOR

Chris White E<lt>cxw@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) 2019 Chris White E<lt>cxw@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# }}}1
# vi: set fdm=marker: #
