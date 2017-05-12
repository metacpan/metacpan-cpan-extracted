package Build::Spec;
use strict;
use warnings;
use Exporter ();
use Carp qw( croak );
use constant DEFAULT_AUTHOR => 'Burak Gursoy <burak@cpan.org>';
use constant OS_ERROR       => qr{OS \s+ unsupported}xms;
use base qw( Exporter );

BEGIN {
   our $VERSION   = '0.80';
   our @EXPORT    = qw( spec    );
   our @EXPORT_OK = qw( mm_spec );
}

sub spec {
    my %opt  = @_;
    my $file = 'SPEC';
    my $spec = do $file;

    my %rv   =
      $@                     ? do { croak $@ =~ OS_ERROR ? $@ : "Couldn't parse $file: $@" }
    : ! defined $spec && $!  ? croak "Couldn't do $file: $!"
    : ! $spec                ? croak "$file did not return a true value"
    : ref($spec) ne 'HASH'   ? croak "Return type of $file is not HASH"
    : ! $spec->{module_name} ? croak "The specification returned from $file does"
                                    .q{ not have the mandatory 'module_name' key}
    : %{ $spec };
    ;

    # these needs to be set here
    $rv{dist_author} ||= DEFAULT_AUTHOR;
    $rv{recommends}  ||= {};
    $rv{requires}    ||= {};
    my $breq = $rv{build_requires} ||= {};
    $breq->{'Test::More'} = '0.40' if ! exists $breq->{'Test::More'};

    delete $rv{BUILDER} if ! $opt{builder};

    return %rv;
}

sub trim {
    my $s = shift;
    return $s if ! $s;
    $s =~ s{ \A \s+    }{}xms;
    $s =~ s{    \s+ \z }{}xms;
    return $s;
}

# Makefile.PL related things

sub mm_spec {
    my %spec = spec();
    (my $file = $spec{module_name}) =~ s{::}{/}xmsg;
    $spec{VERSION_FROM} = "lib/$file.pm";
    $spec{PREREQ_PM}    = { %{ $spec{requires} }, %{ $spec{build_requires} } };
    _mm_recommend( %spec );
    $spec{ABSTRACT}  = _mm_abstract( $spec{VERSION_FROM} );
    $spec{EXE_FILES} = $spec{script_files} ? $spec{script_files} : [];
    return %spec;
}

sub _mm_recommend {
    my %spec = @_;
    return if ! $spec{recommends};
    my %rec  = %{ $spec{recommends} } or return;
    my $info = "\nRecommended Modules:\n\n";
    foreach my $m ( sort keys %rec ) {
        $info .= sprintf "\t%s\tv%s\n", $m, $rec{$m};
    }
    my $pok = print "$info\n";
    return;
}

sub _mm_abstract {
    my $file = shift;
    require IO::File;
    my $fh = IO::File->new;
    $fh->open( $file, 'r' ) || croak "Can not read $file: $!";
    binmode $fh;
    while ( my $line = <$fh> ) {
        chomp $line;
        last if $line eq '=head1 NAME';
    }
    my $buf;
    while ( my $line = <$fh> ) {
        chomp $line;
        last if $line =~ m{ \A =head }xms;
        $buf .= $line;
    }
    $fh->close || croak "Can not close $file: $!";
    croak 'Unable to get ABSTRACT' if ! $buf;
    $buf = trim( $buf );
    my($mod, $desc) = split m{\-}xms, $buf, 2;
    $desc = trim( $desc ) || croak 'Unable to get ABSTRACT';
    return $desc;
}

1;

__END__
