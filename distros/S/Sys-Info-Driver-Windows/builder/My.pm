package My;
use strict;
use warnings;
use base qw( Build );
use File::Spec;
use Carp qw( croak );
use constant RE_CONSTANT => qr{
    \A
        \#define
           \s+?
        ((?:CF|KF|FT)_[a-zA-Z0-9_]+)
           \s+
        (0x.+?)
    \z
}xms;

our $VERSION = '0.10';

my $CMODULE = File::Spec->catfile( qw( lib Sys Info Driver Windows Constants.pm ) );
my $CHEADER = File::Spec->catfile( qw( include cpu.h ) );

sub ACTION_dist { ## no critic (NamingConventions::Capitalization)
    my $self = shift;
    $self->_generate_constants;
    warn "[DEBUG] GENERATING CONSTANTS\n";
    return $self->SUPER::ACTION_dist();
}

sub _generate_constants {
    my($self, $replace) = @_;
    my $content = $self->_fetch_constants;
    open my $FH, '>', $CMODULE or croak "Unable to open($CMODULE): $!";
    binmode $FH;
    print {$FH} qq{## no critic (ValuesAndExpressions::RequireNumberSeparators)\n},
                $content
        or croak "Can not print to FH($CMODULE): $!";
    close $FH or croak "Can not close ($CMODULE): $!";
    return;
}

sub _fetch_constants {
    my $self = shift;
    my($const_buf, $export_buf, $pod_buf) = $self->_fetch_constants_header;
    my $raw = $self->_fetch_constants_module;
    my %replace = (
        quotemeta '#define CPU Constants', $const_buf,
        quotemeta '#define CPU Exports',   $export_buf,
        quotemeta '=head1 CONSTANTS',      $pod_buf,
    );
    foreach my $key ( keys %replace ) {
        $raw =~ s/$key/$replace{$key}/xms;
    }
    return $raw;
}

sub _fetch_constants_module {
    my $self = shift;
    open my $FH, '<', $CMODULE or croak "Unable to open($CMODULE): $!";
    my $rv = do { local $/; <$FH> };
    close $FH or croak "Can not close ($CMODULE): $!";
    return $rv;
}

sub _fetch_constants_header {
    my $self = shift;
    my $const_buf  = q{};
    my $export_buf = q{};
    my $pod_buf    = q{};
    open my $FH, '<', $CHEADER or croak "Can not open ($CHEADER): $!";
    while ( defined(my $line = <$FH>) ) {
        chomp $line;
        if ( $line =~ RE_CONSTANT ) {
            $const_buf  .= qq{use constant $1 => $2;\n};
            $export_buf .= "$1\n";
            $pod_buf    .= qq{=head2 $1\n\n};
        }
    }
    close $FH or croak "Can not close ($CHEADER): $!";
    $export_buf = sprintf q/$EXPORT_TAGS{cpu} = [qw(%s)];/, "\n$export_buf\n";
    $pod_buf    = sprintf qq{=head1 CONSTANTS\n\n%s}, $pod_buf;
    return $const_buf, $export_buf, $pod_buf;
}

1;

__END__
