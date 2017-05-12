package Net::Lyskom::MiscInfo;
use base qw{Net::Lyskom::Object};

use strict;
use warnings;
use Carp;

=head1 NAME

Net::Lyskom::MiscInfo - objects holding misc_info data for texts.

=head1 SYNOPSIS

  $mi = Net::Lyskom::MiscInfo->new(type => "recpt", data => 6);

=head1 DESCRIPTION

Object that holds misc_info information.

=head2 Methods

=over

=item ->type()

Returns the type of the misc_info. Can be one of the following strings:

 recpt, cc_recpt, comm_to, comm_in, footn_to, footn_in, loc_no,
 rec_time, sent_by, sent_at, bcc_recpt

=item ->data()

The data corresponding to the type. Numbers in all cases except for
C<rec_time>, where it is a L<Net::Lyskom::Time> object.

=item ->loc_no()

The local text number. Exists in the C<compact> versions of the
C<recpt> types.

=item ->rec_time()

As above, but for C<rec_time>.

=item ->sent_by()

As above, but for C<sent_by>.

=item ->sent_at()

As above, but for C<sent_by>.

=item ->compact()

Class method rather than object method. Takes a misc_info list and
puts the recipient metadata in the recipient type objects. This makes
it very much easier to process misc_info arrays with C<foreach>,
C<map> and other such functions.

=cut

our %type = (
	     recpt => 0,
	     cc_recpt => 1,
	     comm_to => 2,
	     comm_in => 3,
	     footn_to => 4,
	     footn_in => 5,
	     loc_no => 6,
	     rec_time => 7,
	     sent_by => 8,
	     sent_at => 9,
	     bcc_recpt => 15
	    );

our %epyt = reverse %type;

sub new {
    my $s = {};
    my $class = shift;
    my %a = @_;

    $class = ref($class) if ref($class);
    bless $s,$class;

    if (!defined($type{$a{type}})) {
	croak "Unknown MiscInfo type: $a{type}\n";
    }
    $s->{type} = $type{$a{type}};
    $s->{data} = $a{data};

    return $s;
}

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $arg = $_[0];

    $class = ref($class) if ref($class);
    bless $s, $class;

    $s->{type} = shift @{$arg};

    if ($s->{type} == $type{recpt}) {
	$s->{data} = shift @{$arg};
    } elsif ($s->{type} == $type{cc_recpt}) {
	$s->{data} = shift @{$arg};
    } elsif ($s->{type} == $type{comm_to}) {
	$s->{data} = shift @{$arg};
    } elsif ($s->{type} == $type{comm_in}) {
	$s->{data} = shift @{$arg};
    } elsif ($s->{type} == $type{footn_to}) {
	$s->{data} = shift @{$arg};
    } elsif ($s->{type} == $type{footn_in}) {
	$s->{data} = shift @{$arg};
    } elsif ($s->{type} == $type{loc_no}) {
	$s->{data} = shift @{$arg};
    } elsif ($s->{type} == $type{rec_time}) {
	$s->{data} = Net::Lyskom::Time->new_from_stream($arg);
    } elsif ($s->{type} == $type{sent_by}) {
	$s->{data} = shift @{$arg};
    } elsif ($s->{type} == $type{sent_at}) {
	$s->{data} = Net::Lyskom::Time->new_from_stream($arg);
    } elsif ($s->{type} == $type{bcc_recpt}) {
	$s->{data} = shift @{$arg};
    } else {
	croak "Unknown misc_info type recieved from server: $s->{type}";
    }
    return $s;
}

sub type {
    my $s = shift;

    return $epyt{$s->{type}};
}

sub data {
    my $s = shift;

    $s->{data} = $_[0] if $_[0];
    return $s->{data};
}

sub loc_no {my $s = shift; return $s->{loc_no}}
sub rec_time {my $s = shift; return $s->{rec_time}}
sub sent_by {my $s = shift; return $s->{sent_by}}
sub sent_at {my $s = shift; return $s->{sent_at}}

sub compact {
    my $s = shift;
    my @res;
    my $last;

    $last = shift @_;
    foreach my $s (@_) {
	if ($s->{type} == $type{recpt}) {
	    push @res,$last;
	    $last = $s;
	} elsif ($s->{type} == $type{cc_recpt}) {
	    push @res,$last;
	    $last = $s;
	} elsif ($s->{type} == $type{comm_to}) {
	    push @res,$last;
	    $last = $s;
	} elsif ($s->{type} == $type{comm_in}) {
	    push @res,$last;
	    $last = $s;
	} elsif ($s->{type} == $type{footn_to}) {
	    push @res,$last;
	    $last = $s;
	} elsif ($s->{type} == $type{footn_in}) {
	    push @res,$last;
	    $last = $s;
	} elsif ($s->{type} == $type{loc_no}) {
	    $last->{loc_no} = $s->{data};
	} elsif ($s->{type} == $type{rec_time}) {
	    $last->{rec_time} = $s->{data};
	} elsif ($s->{type} == $type{sent_by}) {
	    $last->{sent_by} = $s->{data};
	} elsif ($s->{type} == $type{sent_at}) {
	    $last->{sent_at} = $s->{data};
	} elsif ($s->{type} == $type{bcc_recpt}) {
	    push @res,$last;
	    $last = $s;
	} else {
	    croak "Unknown misc_info type in compact(): $s->{type}";
	}
    }
    push @res,$last;
    return @res;
}

return 1;
