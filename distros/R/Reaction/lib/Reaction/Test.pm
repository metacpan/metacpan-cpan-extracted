package Reaction::Test;

use base qw/Test::Class Reaction::Object/;
use Reaction::Class;

sub simple_mock_context {
  my ($q_p, $b_p, $path) = ({}, {}, 'test/path');
  my $req = bless({
    query_parameters => sub { $q_p }, body_parameters => sub { $b_p },
    path => sub { shift; $path = shift if @_; $path; },
  }, 'Reaction::Test::Mock::Request');
  my %res_info = (content_type => '', body => '', status => 200, headers => {});
  my $res = bless({
    (map {
      my $key = $_;
      ($key => sub { shift; $res_info{$key} = shift if @_; $res_info{$key} });
    } keys %res_info),
    header => sub {
      shift; my $h = shift;
      $res_info{headers}{$h} = shift if @_;
      $res_info{headers}{$h};
    },
  }, 'Reaction::Test::Mock::Response');
  return bless({
    req => sub { $req }, res => sub { $res },
  }, 'Reaction::Test::Mock::Context');
}
  
=head1 NAME

Reaction::Test

=head1 DESCRIPTION

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut


package Reaction::Test::Mock::Context;

sub isa {
  shift; return 1 if (shift eq 'Catalyst');
}

sub view {
  return $_[0]->{view}->(@_);
}

sub req {
  return $_[0]->{req}->(@_);
}

sub res {
  return $_[0]->{res}->(@_);
}

package Reaction::Test::Mock::Request;

sub query_parameters {
  return $_[0]->{query_parameters}->(@_);
}

sub body_parameters {
  return $_[0]->{body_parameters}->(@_);
}

sub path {
  return $_[0]->{path}->(@_);
}

package Reaction::Test::Mock::Response;

sub body {
  return $_[0]->{body}->(@_);
}

sub content_type {
  return $_[0]->{content_type}->(@_);
}

sub status {
  return $_[0]->{status}->(@_);
}

sub headers {
  return $_[0]->{headers}->(@_);
}

sub header {
  return $_[0]->{header}->(@_);
}

1;
