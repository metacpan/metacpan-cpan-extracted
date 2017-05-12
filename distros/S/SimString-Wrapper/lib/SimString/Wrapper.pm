package SimString::Wrapper;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.03';

#use FileHandle;
#use IPC::Open2;

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub simstring {
  my $self = shift;

  my $query = shift;
  my $database = shift;
  my $threshold = shift;

#  my $pid = open2(*Reader, *Writer, "simstring -d ../sample/names.2");
#  print Writer "$query\n";
#  my $got = <Reader>;

  open( my $reader, "echo $query | simstring -d $database -t $threshold -q|");
  my @got = <$reader>;
  return map { chomp($_);$_ =~ s/^\s+//;$_ } @got;
  return @got;
}

sub _options {
  my $self = shift;
  my $options = shift;
  my $attributes = {
    'b'     => sub { $_[0] ? ' --build' : '';},
    'build' => sub { $_[0] ? ' --build' : '';},
    'd'     => sub { $_[0] ? ' --database' : '';},
    'database' => sub { $_[0] ? ' --database' : '';},
    'u'     => sub { $_[0] ? ' --unicode' : '';},
    'unicode'     => sub { $_[0] ? ' --unicode' : '';},
    'm'     => sub { $_[0] ? ' --mark' : '';},
    'mark'     => sub { $_[0] ? ' --mark' : '';},
    'n'     => sub { ($_[0] && $_[0] =~ m/^[1-9][0-9]*$/x ) ? ' --ngram='.$_[0] : '';},
    'ngram'     => sub { ($_[0] && $_[0] =~ m/^[1-9][0-9]*$/x ) ? ' --ngram='.$_[0] : '';},
    's'     => sub {
       ($_[0] && $_[0] =~ /^(exact|dice|cosine|jaccard|overlap)$/)
         ? ' --similarity='.$_[0] : '';
    },
    'similarity'     => sub {
       ($_[0] && $_[0] =~ /^(exact|dice|cosine|jaccard|overlap)$/)
         ? ' --similarity='.$_[0] : '';
    },
    't'     => sub {
      ($_[0] && $_[0] =~ m/^(?:0\.[0-9]+|1)$/x ) ? ' --threshold='.$_[0] : '';
    },
    'threshold'     => sub {
      ($_[0] && $_[0] =~ m/^(?:0\.[0-9]+|1)$/x ) ? ' --threshold='.$_[0] : '';
    },
    'e'     => sub { $_[0] ? ' --echo-back' : '';},
    'echo-back'     => sub { $_[0] ? ' --echo-back' : '';},
    'q'     => sub { $_[0] ? ' --quiet' : '';},
    'quiet'     => sub { $_[0] ? ' --quiet' : '';},
    'p'     => sub { $_[0] ? ' --benchmark' : '';},
    'benchmark'     => sub { $_[0] ? ' --benchmark' : '';},
    'v'     => sub { $_[0] ? ' --version' : '';},
    'version'     => sub { $_[0] ? ' --version' : '';},
    'h'     => sub { $_[0] ? ' --help' : '';},
    'help'     => sub { $_[0] ? ' --help' : '';},

  };
  $self->{options} = '';
  for my $option (sort keys %$options) {
    if (exists $attributes->{$option} && $options->{$option}) {
      $self->{options} .= $attributes->{$option}->($options->{$option});
    }
  }
  return $self->{options};
}

=pod

  -b, --build           build a database for strings read from STDIN
  -d, --database=DB     specify a database file
  -u, --unicode         use Unicode (wchar_t) for representing characters
  -n, --ngram=N         specify the unit of n-grams (DEFAULT=3)
  -m, --mark            include marks for begins and ends of strings
  -s, --similarity=SIM  specify a similarity measure (DEFAULT='cosine'):
      exact                 exact match
      dice                  dice coefficient
      cosine                cosine coefficient
      jaccard               jaccard coefficient
      overlap               overlap coefficient
  -t, --threshold=TH    specify the threshold (DEFAULT=0.7)
  -e, --echo-back       echo back query strings to the output
  -q, --quiet           suppress supplemental information from the output
  -p, --benchmark       show benchmark result (retrieved strings are suppressed)
  -v, --version         show this version information and exit
  -h, --help            show this help message and exit


=cut

1;

__END__

=encoding utf-8

=head1 NAME

SimString::Wrapper - Interface to SimString

=head1 SYNOPSIS

  use SimString::Wrapper;

=head1 DESCRIPTION

SimString::Wrapper wraps an object over the command line interface of SimString.

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
