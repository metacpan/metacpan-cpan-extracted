package PDF::Builder::Win32;

use strict;
no warnings qw[ deprecated recursion uninitialized ];

# VERSION
my $LAST_UPDATE = '3.002'; # manually update whenever code is changed

use Win32::TieRegistry;

=head1 NAME

PDF::Builder::Win32 - font file- and registry-related support routines for Windows operating system

=cut

our $wf = {};

$Registry->Delimiter('/');

# e.g., "C:\Windows\Fonts". $Registry->{} is a hash reference to Fonts element
my $fontdir = $Registry->{'HKEY_CURRENT_USER/Software/Microsoft/Windows/CurrentVersion/Explorer/Shell Folders'}->{'Fonts'};

# $Registry->{} should be a hash reference containing elements which are the
# names of .ttf etc. files found in $fontdir
my $subKey = $Registry->{'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/Fonts'};

foreach my $k (sort keys %{$subKey}) {
    next unless $subKey->{$k} =~ /\.[ot]tf$/i;
    my $kk = lc($k);
    $kk =~ s|^/||;
    $kk =~ s|\s+\(truetype\).*$||g;
    $kk =~ s|\s+\(opentype\).*$||g;
    $kk =~ s/[^a-z0-9]+//g;

    $wf->{$kk} = {};

    $wf->{$kk}->{'display'} = $k;
    $wf->{$kk}->{'display'} =~ s|^/||;

    if (-e "$fontdir/$subKey->{$k}") {
        $wf->{$kk}->{'ttfile'} = "$fontdir/$subKey->{$k}";
    } else {
        $wf->{$kk}->{'ttfile'} = $subKey->{$k};
    }
}

$subKey = $Registry->{'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows NT/CurrentVersion/Type 1 Installer/Type 1 Fonts/'};

foreach my $k (sort keys %$subKey) {
    my $kk = lc($k);
    $kk =~ s|^/||;
    $kk =~ s/[^a-z0-9]+//g;

    $wf->{$kk} = {};

    $wf->{$kk}->{'display'} = $k;
    $wf->{$kk}->{'display'} =~ s|^/||;

    my $t;
    ($t, $wf->{$kk}->{'pfmfile'}, $wf->{$kk}->{'pfbfile'}) = split(/\0/, $subKey->{$k});

    if (-e "$fontdir/" . $wf->{$kk}->{'pfmfile'}) {
        $wf->{$kk}->{'pfmfile'} = "$fontdir/" . $wf->{$kk}->{'pfmfile'};
        $wf->{$kk}->{'pfbfile'} = "$fontdir/" . $wf->{$kk}->{'pfbfile'};
    }
}

sub enumwinfonts {
    my $self = shift;

    return map { $_ => $wf->{$_}->{'display'} } keys %$wf;
}

sub winfont {
    my $self = shift;
    my $key = lc(shift());
    $key =~ s/[^a-z0-9]+//g;

    return unless defined $wf and defined $wf->{$key};

    if (defined $wf->{$key}->{'ttfile'}) {
        return $self->ttfont($wf->{$key}->{'ttfile'}, @_);
    } else {
        return $self->psfont($wf->{$key}->{'pfbfile'}, -pfmfile => $wf->{$key}->{'pfmfile'}, @_);
    }
}

1;
