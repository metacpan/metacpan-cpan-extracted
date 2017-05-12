# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Notify;
use SVK::I18N;
use SVK::Util qw( abs2rel $SEP to_native from_native get_encoding);
use strict;

=head1 NAME

SVK::Notify - svk entry status notification

=head1 SYNOPSIS

    $notify = SVK::Notify->new;
    $notify->node_status ('foo/bar', 'M');
    $notify->prop_status ('foo/bar', 'M');
    $notify->hist_status ('foo/bar', '+',
	'file://home/foo/.svk/local/trunk/bar', 13);
    $notify->node_baserev ('foo/bar', 42);
    $notify->flush ('foo/bar');
    $notify->flush_dir ('foo');

=head1 DESCRIPTION



=cut

sub flush_print {
    my ($path, $status, $extra) = @_;
    no warnings 'uninitialized';
    $extra = " - $extra" if $extra;
    print sprintf ("%1s%1s%1s \%s\%s\n", @{$status}[0..2],
		   length $path ? $path : '.', $extra);
}

sub skip_print {
    my ($path) = @_;
    print "    ", loc("%1 - skipped\n", $path);
}

sub print_report {
    my ($print, $is_copath, $report, $target) = @_;
    my $enc = Encode::find_encoding (get_encoding);
    # XXX: $report should already be in native encoding, so this is wrong
    my $print_native = $enc->name eq 'utf8'
	? $print
	: sub { to_native($_[0], 'path', $enc);
		goto \&$print;
	    };
    return $print_native unless defined $report;
    $report = "$report";
    from_native($report, 'path', $enc);
    sub {
	my $path = shift;
	if ($target) {
	    if ($target eq $path) {
		$path = '';
	    }
	    else {
		$path = abs2rel($path, $target => undef, $is_copath ? () : '/');
	    }
	}
	if (length $path) {
	    $print_native->($is_copath ? SVK::Path::Checkout->copath ($report, $path)
			               : length $report ? "$report/$path" : $path, @_);
	}
	else {
	    my $r = length $report ? $report : '.';
	    $print_native->($is_copath ? SVK::Path::Checkout->copath('', $r) : $r,
			    @_);
	}
    };
}

sub new {
    my ($class, @arg) = @_;
    my $self = bless {}, $class;
    %$self = @arg;
    return $self;
}

sub new_with_report {
    my ($class, $report, $target, $is_copath) = @_;
    $report =~ s/\Q$SEP\E$//o if $report; # strip trailing slash
    $class->new	( cb_skip => print_report (\&skip_print, $is_copath, $report),
		  cb_flush => print_report (\&flush_print, $is_copath, $report, $target));
}

sub notify_translate {
    my ($self, $translate) = @_;

    for (qw/cb_skip cb_flush/) {
	my $sub = $self->{$_} or next;
	$self->{$_} = sub { my $path = shift;
			    $translate->($path);
			    $sub->($path, @_);
#			    unshift @_, $path; goto &$sub
			};
    }
}

sub node_status {
    my ($self, $path, $s) = @_;
    Carp::cluck unless defined $path;
    $self->{status}{$path}[0] = $s if defined $s;
    return exists $self->{status}{$path} ? $self->{status}{$path}[0] : undef;
}

my %prop = ( 'U' => 0, 'g' => 1, 'G' => 2, 'M' => 3, 'C' => 4);

sub prop_status {
    my ($self, $path, $s) = @_;
    my $st = $self->{status}{$path} ||= ['', ''];
    $st->[1] = $s if defined $s
	# node status allow prop
	&& !($st->[0] && ($st->[0] eq 'A' || $st->[0] eq 'R'))
	    # not overriding things more informative
	    && (!$st->[1] || $prop{$s} > $prop{$st->[1]});
    return $st->[1];
}

sub hist_status {
    my ($self, $path, $s, $from_path, $from_rev) = @_;
    if (defined $s) {
	$self->{status}{$path}[2] = $s;
	$self->{copyfrom}{$path} = [$from_path, $from_rev]
	    if $self->{flush_baserev};
    }
    return $self->{status}{$path}[2];
}

sub node_baserev {
    my ($self, $path, $baserev) = @_;
    return unless $self->{flush_baserev};
    $self->{baserev}{$path} = $baserev if defined $baserev;
}

sub flush {
    my ($self, $path, $anchor) = @_;
    return if $self->{quiet};
    my $status = $self->{status}{$path};
    if ($status && ($self->{flush_unchanged} || grep {$_} @{$status}[0..1])) {
	$self->{cb_flush}->($path, $status, $self->{flush_baserev} ?
		($self->{baserev}{$path}, $self->{copyfrom}{$path}[0], $self->{copyfrom}{$path}[1]) : undef)
	    if $self->{cb_flush};
    }
    elsif (!$status && !$anchor) {
	$self->{cb_skip}->($path) if $self->{cb_skip};
    }
    delete $self->{status}{$path};
}

sub flush_dir {
    my ($self, $path) = @_;
    return if $self->{quiet};
    for (grep {$path ? index($_, "$path/") == 0 : $_}
	 sort keys %{$self->{status}}) {
	$self->flush ($_, $path eq $_);
    }
    $self->flush ($path, 1);
}

sub progress {
    my $self = shift;
    require Time::Progress;
    return if $self->{quiet};
    my $progress = Time::Progress->new();
    $progress->attr (@_);
    return $progress;

}

1;
