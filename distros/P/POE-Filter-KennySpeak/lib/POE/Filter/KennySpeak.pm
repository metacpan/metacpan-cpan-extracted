package POE::Filter::KennySpeak;
$POE::Filter::KennySpeak::VERSION = '1.02';
#ABSTRACT: Mmm PfmPpfMpp Mpfmffpmffmpmpppff fmpmfpmmmfmp fmppffmmmpppfmmpmfmmmfmpmppfmm fmpppf mmmpppmpm mpfpffppfppm PmpmppppppppffmFmmpfmmppmmmpmp

use strict;
use warnings;

use base qw(POE::Filter);

my $kenny   = _generateKenny();          # encoding table
my $dekenny = _generateDeKenny($kenny);  # decoding table

sub new {
  my $class = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  $opts{BUFFER} = [];
  return bless \%opts, $class;
}

sub get_one_start {
  my ($self, $raw) = @_;
  push @{ $self->{BUFFER} }, $_ for @$raw;
}

sub get_one {
  my $self = shift;
  my $events = [];

  my $event = shift @{ $self->{BUFFER} };
  if ( defined $event ) {
    my $record = _translate($event,1);
    push @$events, $record if $record;
  }
  return $events;
}

sub get_pending {
  my $self = shift;
  return $self->{BUFFER};
}

sub put {
  my ($self, $events) = @_;
  my $raw_lines = [];

  foreach my $event (@$events) {
     if ( defined $event ) {
	my $record = _translate($event);
	push @$raw_lines, $record if $record;
     }
  }

  return $raw_lines;
}

sub clone {
  my $self = shift;
  my $nself = { };
  $nself->{$_} = $self->{$_} for keys %{ $self };
  $nself->{BUFFER} = [ ];
  return bless $nself, ref $self;
}

##### Generate KennySpeak encoding table

sub _generateKenny {
    my %kenny;

    # lower case characters

    my ($a, $b, $c) = (0,0,0);
    for my $char ("a".."z") {
	my $foo = $a.$b.$c;
	$foo =~ tr/012/mpf/;
	$kenny{$char} = $foo;
	$c++;
	if ($c == 3) {
	    $c=0;
	    $b++;
	    if ($b == 3) {
		$b=0;
		$a++;
	    }
	}
    }

    # upper case characters

    map { $kenny{uc $_} = ucfirst $kenny{$_} } keys %kenny;

    return \%kenny;
}



##### Generate KennySpeak decoding table

sub _generateDeKenny {
    my %dekenny;
    my $kenny = $_[0];
    foreach my $key (keys %{$kenny})
    {
	my ($a, $b, $c) = split //, $kenny->{$key};
	if (! exists $dekenny{$a}) {
	    $dekenny{$a} = {};
	}
	if (! exists $dekenny{$a}->{$b}) {
	    $dekenny{$a}->{$b} = {};
	}
	$dekenny{$a}->{$b}->{$c} = $key;
    }

    return \%dekenny;
}


##### Encode/decode a given line

sub _translate {
    my $in  = shift;
    my $dialect = shift;
    my $out = '';
    if ($dialect) {
        $out .= exists $kenny->{$1} ? $kenny->{$1} : $1 while ($in =~ s/^(.)//);
    }
    else {
        my @chars = split //, $in;
        while (@chars) {
            if ((@chars > 2) and (exists $dekenny->{$chars[0]}->{$chars[1]}->{$chars[2]})) {
                $out .= $dekenny->{$chars[0]}->{$chars[1]}->{$chars[2]};
                shift @chars;
                shift @chars;
                shift @chars;
            }
	    else {
                $out .= shift @chars;
            }
        }
    }
    return $out;
}


'Fmpmmmpmfpmp pmfmffpmpmpp Pmpmppppppppffm!';

#
# kenny.pl -- translate from and to KennySpeak
#
# $Revision: 1.7 $
#
# Licensed unter the Artistic License:
# http://www.perl.com/language/misc/Artistic.html
#
# (C) 2001,2002 by Christian Garbs <mitch@cgarbs.de>, http://www.cgarbs.de
#                  Alan Eldridge <alane@geeksrus.net>
#
# KennySpeak invented by Kohan Ikin <syneryder@namesuppressed.com>
#                        http://www.namesuppressed.com/kenny/

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Filter::KennySpeak - Mmm PfmPpfMpp Mpfmffpmffmpmpppff fmpmfpmmmfmp fmppffmmmpppfmmpmfmmmfmpmppfmm fmpppf mmmpppmpm mpfpffppfppm PmpmppppppppffmFmmpfmmppmmmpmp

=head1 VERSION

version 1.02

=head1 SYNOPSIS

        # A Kennyspeak echo server

	use strict;
	use warnings;

	use POE;
	use POE::Component::Server::TCP;
	use POE::Filter::Stackable;
	use POE::Filter::Line;
	use POE::Filter::KennySpeak;

	POE::Component::Server::TCP->new(
	    Port => 12345,
	    ClientInputFilter => POE::Filter::Stackable->new(
		Filters => [
			POE::Filter::Line->new(),
			POE::Filter::KennySpeak->new(),
		],
	    ),
	    ClientOutputFilter => POE::Filter::Line->new(),
	    ClientInput => sub {
	      $_[HEAP]{client}->put($_[ARG0]);
	      return;
	    },
	);

	POE::Kernel->run();
	exit;

=head1 DESCRIPTION

POE::Filter::KennySpeak is a L<POE::Filter> that translates given text to and from KennySpeak L<http://www.namesuppressed.com/kenny/>.

It is intended to be used in a stackable filter, L<POE::Filter::Stackable>, with L<POE::Filter::Line>.

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::KennySpeak object.

=back

=head1 METHODS

=over

=item C<get>

=item C<get_one_start>

=item C<get_one>

Takes an arrayref which contains lines of text, returns an arrayref of lines translated into Kennyspeak.

=item C<get_pending>

Returns the filter's partial input buffer.

=item C<put>

Takes an arrayref which contains lines of Kennyspeak and returns an arrayref of lines translated back to C<normal>.

=item C<clone>

Makes a copy of the filter and clears the buffer of the copy.

=back

=head1 KUDOS

Based on kenny.pl by:

Christian Garbs <mitch@cgarbs.de>, http://www.cgarbs.de
Alan Eldridge <alane@geeksrus.net>

KennySpeak invented by Kohan Ikin <syneryder@namesuppressed.com>
                       http://www.namesuppressed.com/kenny/

=head1 SEE ALSO

L<POE::Filter>

L<POE::Filter::Stackable>

L<http://www.cgarbs.de/kenny.en.html>

L<http://www.namesuppressed.com/kenny/>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams, Christian Garbs and Alan Eldridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
