package Data::Random::WordList;

# Based on Data::Random::WorldList by Adekunle Olonoh
# Replaces the built-in with something a bit faster...
use Data::Random::WordList;

use IO::File;
use File::Basename qw(dirname);

our $VERSION = '-1 pangloss';
our $SINGLETON;

sub new {
    return $SINGLETON if $SINGLETON;

    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $wordlist = dirname($INC{'Data/Random.pm'}).'/Random/dict';

    my $fh = IO::File->new( $wordlist ) or die "couldn't open $wordlist : $!";

    # just slurp the whole file... eats more memory, but that's not a problem
    # for our purposes.
    my @words = <$fh>;
    chomp @words;
    $fh->close;

    $SINGLETON = bless { size => scalar @words, words => \@words }, $class;
}

sub close { 1 }    # for compat

sub get_words {
    my $self = shift;
    my $num  = shift || 1;

    # Perform some error checking
    die 'the size value must be a positive integer' if $num < 0 || $num != int($num);

    die "$num words were requested but only $self->{size} words exist in the wordlist"
      if $num > $self->{size};

    my @rand_indexes = map { int rand $self->{size} } 1 .. $num;
    my @rand_words   = @{$self->{words}}[@rand_indexes];

#warn "selecting (", join(', ', @rand_indexes), ") = (",
#  join(', ', @rand_words), ") from wordlist $self\n";

    return wantarray ? @rand_words : \@rand_words;
}

1;
