package Mojar::Google::Analytics::Response;
use Mojo::Base -base;

our $VERSION = 1.011;

use Mojar::Util 'snakecase';

# Attributes

has [qw(code content error message success)];

has start_index => 1;
has contains_sampled_data => !!0;
has column_headers => sub {[]};
has total_results => 0;
has rows => sub {[]};
has [qw(items_per_page profile_info next_link totals_for_all_results)];

# Public methods

sub parse {
  my ($self, $res) = @_;

  if ($res->is_success) {
    delete @$self{qw(code content error message)};
    my $j = $res->json;
    $self->{snakecase($_)} = $j->{$_} for keys %$j;
    return $self->success(1);
  }
  else {
    # Got a transaction-level error
    $self->success(undef)->code($res->code || 408)
      ->message($res->message // 'Possible timeout')
      ->error(sprintf 'Error (%u): %s', $_[0]->code, $_[0]->message);

    if ($res and my $j = $res->json) {
      # Got JSON body in response
      $self->content($j);
      my $m = ref($j->{error}) ? $j->{error} : {message => $j->{error} // ''};

      # Got message record
      $self->code($m->{code}) if $m->{code};
      # Take note of headline error
      my $msg = ($m->{message} // $j->{message}) ."\n";

      for my $e (@{$m->{errors} // []}) {
        # Take note of next listed error
        $msg .= sprintf "%s at %s\n%s\n",
            $e->{reason}, ($e->{location} // $e->{domain}), $e->{message};
      }
      $self->message($msg);
    }
    return undef;
  }
}

sub columns {
  my $self = shift;
  return undef unless my $rows = $self->rows;
  return undef unless my $height = @$rows;
  return undef unless my $width = @{$$rows[0]};

  my @cols = map [], 1 .. $width;
  for (my $j = 0; $j < $height; ++$j) {
    for (my $i = 0; $i < $width; ++$i) {
      push @{$cols[$i]}, $$rows[$j][$i]
    }
  }
  return \@cols;
}
# See https://gist.github.com/niczero/cc792d919ff7c32cbccf04fa821a1cb0 for bm

1;
__END__

=head1 NAME

Mojar::Google::Analytics::Response - Response object from GA reporting.

=head1 SYNOPSIS

  use Mojar::Google::Analytics::Response;
  $response = Mojar::Google::Analytics::Response->new(
    auth_user => q{1234@developer.gserviceaccount.com},
    private_key => $pk,
    profile_id => q{5678}
  );

=head1 DESCRIPTION

Container object returned from Google Analytics Core Reporting.

=head1 ATTRIBUTES

=over 4

=item success

Boolean result status.

=item code

Error code.

=item message

Error message.

=item domain

Defaults to C<global>.

=item error

String containing C<code> and C<message>.

=item start_index

Reported start index; should match your request.

=item items_per_page

Reported result set size; should match your request.

=item contains_sampled_data

Boolean.

=item profile_info

Summary of profile.

=item column_headers

Arrayref of headers records, including titles and types.

=item total_results

Reported total quantity of records available.  (Can fluctuate from one
response to the next.)

=item rows

Array ref containing the result set.

=item columns

Array ref containing the result set transposed into columns.  This can be
desirable for fast database insertion.

=item totals_for_all_results

Overall totals for your requested metrics.

=back

=head1 METHODS

=over 4

=item parse

  $success = $res->parse($tx->res)

Populates the Response using the supplied transaction response, returning
a boolean denoting whether the transaction was successful.

=back

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<Net::Google::Analytics> is similar, main differences being dependencies and
means of getting tokens.
