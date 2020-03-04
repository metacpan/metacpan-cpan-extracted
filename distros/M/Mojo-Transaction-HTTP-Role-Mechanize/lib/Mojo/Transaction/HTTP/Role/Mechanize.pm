package Mojo::Transaction::HTTP::Role::Mechanize;

use Mojo::Base -role;
use Mojo::UserAgent::Transactor;

our $VERSION = '0.05';

requires qw{error res};

sub extract_forms {
  my $self = shift;

  my $forms
    = $self->res->dom->find('form')->each(sub { $_->with_roles('+Form') });

  return $forms;
}

sub submit {
  my ($self, $selector, $overlay) = (shift);
  $overlay  = pop   if @_ && ref($_[-1]) eq 'HASH';
  $selector = shift if @_ % 2;
  $overlay ||= {@_};

  # cannot continue from error state
  return if $self->error;

  # extract form
  my $form = $self->extract_forms->grep(sub { $_->at($selector // '') })->first
    or return;

  return unless (my ($method, $target, $type) = $form->target($selector));
  $target = $self->req->url->new($target);
  $target = $target->to_abs($self->req->url) unless $target->is_abs;

  # values from form
  my $state = $form->val($selector);

  # merge in new values of form elements
  my @keys = grep { exists $overlay->{$_} } keys %$state;
  @$state{@keys} = @$overlay{@keys};

  # build a new transaction ...
  return Mojo::UserAgent::Transactor->new->tx(
    $method => $target,
    {}, form => $state
  );
}

1;

=encoding utf8

=begin html

<a href="https://travis-ci.com/kiwiroy/mojo-transaction-http-role-mechanize">
  <img alt="Travis Build Status"
       src="https://travis-ci.com/kiwiroy/mojo-transaction-http-role-mechanize.svg?branch=master" />
</a>
<a href="https://kritika.io/users/kiwiroy/repos/7509235145731088/heads/master/">
  <img alt="Kritika Analysis Status"
       src="https://kritika.io/users/kiwiroy/repos/7509235145731088/heads/master/status.svg?type=score%2Bcoverage%2Bdeps" />
</a>
<a href="https://coveralls.io/github/kiwiroy/mojo-transaction-http-role-mechanize?branch=master">
  <img alt="Coverage Status"
       src="https://coveralls.io/repos/github/kiwiroy/mojo-transaction-http-role-mechanize/badge.svg?branch=master" />
</a>
<a href="https://badge.fury.io/pl/Mojo-Transaction-HTTP-Role-Mechanize">
  <img alt="CPAN version" height="18"
       src="https://badge.fury.io/pl/Mojo-Transaction-HTTP-Role-Mechanize.svg" />
</a>

=end html

=head1 NAME

Mojo::Transaction::HTTP::Role::Mechanize - Mechanize Mojo a little

=head1 SYNOPSIS

  use Mojo::UserAgent;
  use Mojo::Transaction::HTTP::Role::Mechanize;

  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->get('/')->with_roles('+Mechanize');

  # call submit immediately
  my $submit_tx = $tx->submit('#submit-id', username => 'fry');
  $ua->start($submit_tx);

  # first extract form values
  my $values = $tx->extract_forms->first->val;
  $submit_tx = $tx->submit('#submit-id', counter => $values->{counter} + 3);
  $ua->start($submit_tx);

=head1 DESCRIPTION

L<Role::Tiny> based role to compose a form submission I<"trait"> into
L<Mojo::Transaction::HTTP>.

=head1 METHODS

L<Mojo::Transaction::HTTP::Role::Mechanize> implements the following method.

=head2 extract_forms

  $collection = $tx->extract_forms;

Returns a L<Mojo::Collection> of L<Mojo::DOM> elements with activated L<Mojo::DOM::Role::Form>
that contains all the forms of the page.

=head2 submit

  # result using selector
  $submit_tx = $tx->submit('#id', username => 'fry');

  # result without selector using default submission
  $submit_tx = $tx->submit(username => 'fry');

  # passing hash, rather than list, of values
  $submit_tx = $tx->submit({username => 'fry'});

  # passing hash, rather than list, of values and a selector
  $submit_tx = $tx->submit('#id', {username => 'fry'});

Build a new L<Mojo::Transaction::HTTP> object with
L<Mojo::UserAgent::Transactor/"tx"> and the contents of the C<form> with the
C<$id> and merged values.  If no selector is given, the first non-disabled
button or appropriate input element (of type button, submit, or image)
will be used for the submission.

=head1 AUTHOR

kiwiroy - Roy Storey C<kiwiroy@cpan.org>

=head1 CONTRIBUTORS

tekki - Rolf Stöckli C<tekki@cpan.org>

lindleyw - William Lindley C<wlindley+remove+this@wlindley.com>

=head1 LICENSE

This library is free software and may be distributed under the same terms as
perl itself.

=head1 SEE ALSO

L<Mojo::DOM::Role::Form>, L<Mojolicious>.

=cut
