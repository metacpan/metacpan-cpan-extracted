package Pod::Coverage::TrustMe::Parser;
use strict;
use warnings;

our $VERSION = '0.002001';
$VERSION =~ tr/_//d;

use Pod::Simple ();
our @ISA = qw(Pod::Simple);
use Carp qw(croak);

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->accept_targets_as_text('Pod::Coverage');
  $self->{+__PACKAGE__} = {};
  return $self;
}

sub ignore_empty {
  my $self = shift;
  my $me = $self->{+__PACKAGE__};
  if (@_) {
    $me->{ignore_empty} = shift;
  }
  return $me->{ignore_empty};
}

sub _handle_element_start {
  my $self = shift;
  my $me = $self->{+__PACKAGE__};
  my ($name, $attr) = @_;
  if ($name eq 'for') {
    push @{ $me->{in} }, $attr;
  }
  elsif ($name eq 'L' && $attr->{type} eq 'pod' && defined $attr->{to}) {
    my $to = "$attr->{to}";
    push @{ $me->{links} }, $to
      unless $me->{links_hash}{$to}++;
  }
  elsif ($name eq 'item-text' || $name eq 'item-bullet' || $name =~ /\Ahead[2-9]\z/) {
    delete $me->{maybe_covered};
    $me->{consider} = $name;
    $me->{consider_text} = '';
  }
  elsif ($name =~ /\Ahead1\z/) {
    delete $me->{maybe_covered};
  }
  $self->SUPER::_handle_element_start(@_);
}
sub _handle_element_end {
  my $self = shift;
  my $me = $self->{+__PACKAGE__};
  my ($name) = @_;
  if ($name eq 'for') {
    pop @{ $self->{+__PACKAGE__}{in} };
  }
  elsif ($name eq ($me->{consider}||'')) {
    delete $me->{consider};
    my $text = delete $me->{consider_text};
    my @covered = $text =~ /([^\s\|,\/]+)/g;
    for my $covered ( @covered ) {
      # looks like a method
      $covered =~ s/.*->//;
      # looks fully qualified
      $covered =~ s/\A\w+(?:::\w+)*::(\w+)/$1/;
      # looks like it includes parameters
      $covered =~ s/(\w+)[;\(].*/$1/;
    }
    @covered = grep /\A\w+\z/, @covered;
    if ($self->ignore_empty) {
      push @{ $me->{maybe_covered} }, @covered;
    }
    else {
      push @{ $me->{covered} },
        grep !$me->{covered_hash}{$_}++,
        @covered;
    }
  }
  $self->SUPER::_handle_element_end(@_);
}

sub _handle_text {
  my $self = shift;
  my $me = $self->{+__PACKAGE__};
  my ($text) = @_;
  my $in = $me->{in};
  if ($in && @$in && $in->[-1]{target} =~ /\APod::Coverage(?:::Trust(?:Me|Pod))?\z/) {
    for my $token ($text =~ /(\S+)/g) {
      my $re;
      if ($token eq '*EVERYTHING*') {
        $re = qr{.?};
      }
      else {
        $re = eval { qr{\A(?:$token)\z} };
        if (!$re) {
          my $file = $self->{source_filename} || '<input>';
          my $line = $in->[-1]{start_line} || '<unknown>';
          croak "Error compiling Pod::Coverage regex /$token/ at $file line $line: $@";
        }
      }
      push @{ $me->{trusted} }, $re
        unless $me->{trusted_hash}{$re}++;
    }
  }
  elsif ($me->{consider}) {
    $me->{consider_text} .= $text;
  }
  elsif ($me->{maybe_covered}) {
    push @{ $me->{covered} },
      grep !$me->{covered_hash}{$_}++,
      @{ delete $me->{maybe_covered} };
  }
  $self->SUPER::_handle_text(@_);
}

sub links {
  my $self = shift;
  return $self->{+__PACKAGE__}{links} ||= [];
}

sub trusted {
  my $self = shift;
  return $self->{+__PACKAGE__}{trusted} ||= [];
}

sub covered {
  my $self = shift;
  return $self->{+__PACKAGE__}{covered} ||= [];
}

1;
__END__

=head1 NAME

Pod::Coverage::TrustMe::Parser - Parse pod for checking coverage

=head1 SYNOPSIS

  my $parser = Pod::Coverage::TrustMe::Parser->new;
  $parser->parse_file($pod_file);

  $parser->
  if ($self->{nonwhitespace}) {
    $parser->ignore_empty(1);
  }


=head1 DESCRIPTION

A subclass of L<Pod::Simple> which extracts headings and items to check for
covered symbols.

=head1 METHODS

=over 4

=item ignore_empty

  $parser->ignore_empty(1);

Can be called to set if empty sections should be in ignored when checking for
covered symbols.

=item covered

Returns an arrayref of symbols that are covered by the pod.

=item links

Returns an arrayref of the modules that are linked to in the pod.

=item trusted

Returns an arrayref of symbols listed as trusted using C<=for Pod::Coverage>
annotations.

=back

=head1 AUTHORS

See L<Pod::Coverage::TrustMe> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Pod::Coverage::TrustMe> for the copyright and license.

=cut
