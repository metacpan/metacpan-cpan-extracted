#
# (c) Johnny Wang <johnnywang1991@msn.com>
#
# vim: set ts=2
# vim: set sw=2
# vim: set tw=0
# vim: set expandtab

=encoding UTF-8

=head1 NAME

Rex::Inline::Base - write Rex in perl, Base module

=head1 DESCRIPTION

Rex::Inline::Base is an superclass of Rex::Inline task object

=head1 GETTING HELP
 
=over 3
 
=item * Web Site: L<http://rexify.org/>
 
=item * IRC: irc.freenode.net #rex
 
=item * Bug Tracker: L<https://github.com/RexOps/Rex/issues>
 
=back

=head1 SYNOPSIS

  package Test;
  use Moose;
  use Rex -feature => ['1.0'];
  extends 'Rex::Inline::Base';

  sub func {
    my $self = shift;

    return sub {
      my $output = run "uptime";
      say $output;
      say $self->input;
    }
  }

  __PACKAGE__->meta->make_immutable;

=cut
package Rex::Inline::Base;

use strict;
use warnings;

use utf8;

our $VERSION = '0.0.8'; # VERSION

use Moose;
use MooseX::AttributeShortcuts;

use JSON;

use namespace::autoclean;

=head1 ATTRIBUTES

=over 7

=item id

set/get task id (String)

default is random number

=cut
has id => (is => 'ro', builder => 1);

=item server

server address used when ssh connection

This param is required.

=cut
has server => (is => 'ro', required => 1);
=item user

username used when ssh connection

=item password

password used when ssh connection

=item private_key

private_key filename used when ssh connection

=item public_key

public_key filename used when ssh connection

=item sudo [TRUE|FALSE]

use sudo when execute commands

default is C<undef>

=cut
has user => (is => 'ro', default => '');
has [qw(password private_key public_key sudo)] => (is => 'ro');
=item input

input param for tasklist module in any format you need

=cut
has input => (is => 'rw');
=back

=cut
has name => (is => 'ro', lazy => 1, builder => 1);
has task_auth => (is => 'ro', lazy => 1, builder => 1);

sub _build_id { time ^ $$ ^ unpack "%L*", `ps axww | gzip` }
sub _build_name { join('_',grep {$_} (split(/::/, shift->meta->{package}))[qw(-2 -1)]) }
sub _build_task_auth {
  my %auth;
  $auth{user} = $_[0]->{user};
  $auth{password} = $_[0]->{password} if $_[0]->{password};
  $auth{public_key} = $_[0]->{public_key} if $_[0]->{public_key};
  $auth{private_key} = $_[0]->{private_key} if $_[0]->{private_key};
  $auth{sudo} = $_[0]->{sudo} if $_[0]->{sudo};
  return {%auth};
}

__PACKAGE__->meta->make_immutable;
