package PDF::Builder::Win32;  ## no critic

use strict;
use warnings;
#no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.022'; # VERSION
my $LAST_UPDATE = '3.021'; # manually update whenever code is changed

use Win32::TieRegistry qw( :KEY_ );  # creates $Registry, et al.

=head1 NAME

PDF::Builder::Win32 - font file- and registry-related support routines for Windows operating system

=cut

our $wf = {};

$Registry->Delimiter('/');

# e.g., "C:\Windows\Fonts". $Registry->{} is a hash reference to Fonts element
my $fontdir = $Registry->{'HKEY_CURRENT_USER/Software/Microsoft/Windows/CurrentVersion/Explorer/Shell Folders/Fonts'};

# $Registry->{} should be a hash reference containing elements which are the
# names of .ttf etc. files found in $fontdir. 
# E.g., $Registry->{'Arial (TrueType)'} = 'arial.ttf'
my $subKey = $Registry->Open('LMachine', {Access=>KEY_READ(), Delimiter=>'/'}) or die "error opening LMachine: $^E\n";
$subKey = $subKey->Open('SOFTWARE/Microsoft/Windows NT/CurrentVersion/Fonts/') or die "error accessing Fonts entry: $^E\n";

foreach my $k (sort keys %{$subKey}) {
    # $k should be something like 'Arial (TrueType)'
    # $subKey->{$k} would then be 'arial.ttf'
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

# this one seems to be optional (often missing)
$subKey = $Registry->Open('LMachine', {Access=>KEY_READ(), Delimiter=>'/'}) or die "error opening LMachine for T1 fonts: $^E\n";
$subKey = $subKey->Open('SOFTWARE/Microsoft/Windows NT/CurrentVersion/Type 1 Installer/Type 1 Fonts/') or die "error accessing T1 Fonts entry: $^E\n";

foreach my $k (sort keys %{$subKey}) {
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

# return hash of fonts, key=lc name w/o fileext, value=full name 
# e.g., {'arial'} = 'Arial (TrueType)'
sub enumwinfonts {
    my $self = shift;

    return map { $_ => $wf->{$_}->{'display'} } keys %$wf;
}

sub winfont {
    my $self = shift;
    my $key = lc(shift());
    my %opts = @_;
    $key =~ s/[^a-z0-9]+//g;

    # $wf is hash reference
    return unless defined $wf and defined $wf->{$key};

    # ttfile is complete path and name of a file
    if (defined $wf->{$key}->{'ttfile'}) {
        return $self->ttfont($wf->{$key}->{'ttfile'}, @_);
    } else {
        return $self->psfont($wf->{$key}->{'pfbfile'}, -pfmfile => $wf->{$key}->{'pfmfile'}, @_);
    }
}

1;
