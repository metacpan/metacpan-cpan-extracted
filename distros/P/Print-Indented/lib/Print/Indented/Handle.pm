package Print::Indented::Handle;
use strict;
use warnings;
use Tie::Handle;
use parent -norequire => 'Tie::StdHandle';
use Scalar::Util qw(refaddr);
use Path::Tiny;
use Symbol;
use List::MoreUtils qw(any);

our (%Fh, %Packages);

sub new {
    my ($class, $target) = @_;

    my $symbol = Symbol::gensym();
    my $self = tie *$symbol, $class;

    open my $original_fh, '>&', $target or die $!;
    $self->original_fh($original_fh);

    *$target = $symbol;

    return $self;
}

sub original_fh {
    my ($self, $fh) = @_;
    if (defined $fh) {
        $Fh{ refaddr $self } = $fh;
    }
    return $Fh{ refaddr $self };
}

sub packages_re {
    my $self = shift;
    return @{ $Packages{ refaddr $self } || [] };
}

sub add_package_re {
    my $self = shift;
    push @{ $Packages{ refaddr $self } ||= [] }, @_;
}

sub PRINT {
    my ($self, @args) = @_;
    my ($pkg, $filename, $nr) = caller;

    if (any { $pkg =~ $_ } $self->packages_re) {
        my $line = (path($filename)->lines)[$nr-1];
        my ($indent) = $line =~ /^(\s*)/;
        foreach (grep length, split m<(.*$/?)>, join('', @args)) {
            print { $self->original_fh } "$indent$_";
        }
    } else {
        # do not indent
        print { $self->original_fh } @args;
    }
}

sub PRINTF {
    my ($self, $format, @args) = @_;
    @_ = ( $self, sprintf $format, @args );
    goto \&PRINT;
}

1;
