package Tail::Stat::Plugin;

=head1 NAME

Tail::Stat::Plugin - Abstract plugin class

=head1 SYNOPSIS

    package Tail::Stat::Plugin::apache;

    use strict;
    use warnings qw(all);

    use base qw(Tail::Stat::Plugin);

    sub regex { qr/^(\d+)\s+(\d+)/ }

    sub process_data {
        my ($self,$lref,$pub,$win) = @_;

        $pub->{param1} += $lref->[0];
        $win->{param2} += $lref->[1];
        $win->{count}++;
    }

    sub process_window {
        my ($self,$pub,$prv,$wins) = @_;

        $pub->{last_param2} = sum ( map { $_->{param2} || 0 } @$wins ) || 0;
    }

=cut

use strict;
use warnings qw(all);

use Carp qw(confess);


=head1 METHODS

=head2 new

Plugin instance constructor.
Usually you don't need to override it's default behavior.

=cut

sub new {
	my ($class,%opts) = @_;

	my $self = \%opts;
	bless $self, $class;
	$self->{regex} ||= $self->regex;
	$self->{regex} = qr|$self->{regex}|ox;
	return $self;
}


=head2 regex

Accessor to main regular expression.
Called once during initialization (from constructor).

=cut

sub regex {
	confess __PACKAGE__.'::regex is abstract method to override in subclass';
}


=head2 init_zone($zone,\%public,\%private,\%window)

Called once on zone creating. Usually you can assigns some default values
in public statistics.

=cut

sub init_zone {
}


=head2 process_line($line)

Parse single log line and returns array of successfully captured values.
Method must returns true value in scalar context, otherwise message will
be logged about unprocessed line.

=cut

sub process_line {
	my ($self,$line) = @_;

	$line =~ $self->{regex};
}


=head2 process_data(\@ref,\%public,\%private,\%window)

Receives reference to array of captured values and modify public, private
or current window statistics.

=cut

sub process_data {
	my ($self,$ref,$pub,$prv,$win) = @_;

	$pub->{'arg_'.$_} += $ref->[$_] for 0 .. $#$ref;
	return 1;
}


=head2 process_window(\%public,\%private,\@windows)

Called during closing current window. Common usage is calculate averages
from complete windows and save results in public or private statistics.

=cut

sub process_window {
}


=head2 process_timer($name,\%public,\%private,\@windows)

Processing named timer. Receives timer name and zone statistics.
Timer will be renewed unless handler returns false value.

=cut

sub process_timer {
	1
}


=head2 dump_zone($zone,\%public,\%private,\@windows)

Stringify accumulated statistics.

=cut

sub dump_zone {
	my ($self,$zone,$pub,$prv,$wins) = @_;

	map { $_.': '.$pub->{$_} } sort keys %$pub;
}


=head2 stats_zone($zone,\%public,\%private,\@windows)

Optionally preprocess, and stringify accumulated statistics.

=cut

sub stats_zone {
	shift()->dump_zone(@_);
}


=head2 parse_error

Returns default logging level for unparsed lines.

=cut

sub parse_error {
	'debug'
}


=head1 AUTHOR

Oleg A. Mamontov, C<< <oleg@mamontov.net> >>


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1;

