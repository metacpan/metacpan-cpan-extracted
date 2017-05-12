#-*-perl-*-
#
# Copyright (c) 1997 Kevin Johnson <kjj@pobox.com>.
# Copyright (c) 2001 Rob Brown <rob@roobik.com>.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Resolv.pm,v 1.5 2002/04/18 02:22:47 rob Exp $

require 5.003;

package Net::Bind::Resolv;

use strict;
use vars qw($VERSION);
use Carp;
use IO::File;
use Net::Bind::Utils qw(valid_domain valid_ip valid_netmask);

$VERSION = '0.05';

=head1 NAME

Net::Bind::Resolv - a class to munge /etc/resolv.conf data.

=head1 SYNOPSIS

C<use Net::Bind::Resolv;>

=head1 DESCRIPTION

This class provides an object oriented perl interface to
C</etc/resolv.conf> data.

Here is an example snippet of code:

  use Net::Bind::Resolv;
  my $res = new Net::Bind::Resolv;
  print $res->domain, "\n";

Or how about:

  use Net::Bind::Resolv;
  use IO::File;
  my $res = new Net::Bind::Resolv '';
  $res->comment("Programmatically generated\nDo not edit by hand");
  $res->domain('arf.fz');
  $res->nameservers('0.0.0.0');
  $res->options('debug');
  print $res->as_string;

=head1 METHODS

=head2 new([$filename])

Returns a reference to a new C<Net::Bind::Resolv> object.  If
no C<$filename> is supplied, /etc/resolv.conf is used as a default.
A non-empty C<$filename> will be passed to C<read_from_file>.

=cut

sub new {
  my $class = shift;
  my $file = shift;
  $file = "/etc/resolv.conf" if !defined $file;

  my $self = {};

  bless $self, $class;

  $self->clear;

  return undef if (length($file) && !$self->read_from_file($file));

  return $self;
}

=head2 read_from_string($string)

Populates the object with the parsed contents of C<$string>.  Returns
C<1> if no errors were encounters, otherwise it returns C<0>.

The following directives are understood.

=over 2

=item * domain DOMAIN

=item * search SEARCHLIST...

If a C<search> directive and domain directive are found in the same
file, the last one encountered will be recorded and all previous ones
will be ignored.

=item * nameserver IP_ADDR

Each instance of a C<nameserver> directive will cause the given
C<IP_ADDR> to be remembered.

=item * sortlist SORTLIST...

=item * options OPTIONS...

=back

There are very few requirements placed on the data in C<$string>.
Multiple entries of certain directives, while technically incorrect,
will cause the last occurrence of the given directive to be the one
remembered.  If there is sufficient precedence for this to be
otherwise, let me know.

There is no requirement for the arguments to the directives to be
valid pieces of data.  That job is delagated to local policy methods
to be applied against the object.

=cut

sub read_from_string {
  my $self = shift;
  my $string = shift;
  local $_;

  my $errors = 0;

  my @lines = split(/\n/, $string);

  my $line = 0;
  for (@lines) {
    chomp;
    $line++;
    s/\s+$//;
    s/^\s+//;
    next if /^$/;
    next if /^[;\#]/;
    my ($keyword, $value) = split(/\s+/, $_, 2);
    if ($keyword eq 'domain') {
      $self->{Domain} = $value;
      $self->{Searchlist} = undef;
    } elsif ($keyword eq 'search') {
      $self->{Searchlist} = [split(/\s+/, $value)];
      $self->{Domain} = undef;
    } elsif ($keyword eq 'nameserver') {
      push @{$self->{Nameservers}}, $value;
    } elsif ($keyword eq 'sortlist') {
      $self->{Sortlist} = [split(/\s+/, $value)];
    } elsif ($keyword eq 'options') {
      $self->{Options} = [split(/\s+/, $value)];
    } else {
      carp "unknown keyword on line $line: $keyword\n";
      $errors++;
    }
  }
  return ($errors ? 0 : 1);
}

=head2 read_from_file($filename)

Populates the object with the parsed contents of C<$filename>.  This
really just a wrapper around C<read_from_string>.  Returns C<0> if
errors were encountered, otherwise it returns C<1>.

=cut

sub read_from_file {
  my $self = shift;
  my $file = shift;

  my $errors = 0;

  my $fh = new IO::File($file) or return undef;

  local $/ = undef;

  my $string = <$fh>;
  $fh->close;

  return $self->read_from_string($string);
}

=head2 clear

Zeros out the internal data in the object.  This needs to be done if
multiple C<read_from_string> methods are called on a given
C<Net::Bind::Resolv> object and you do not want to retain the previous
values in the object.

=cut

sub clear {
  my $self = shift;

  $self->{Comments} = undef;
  $self->{Domain} = undef;
  $self->{Nameservers} = undef;
  $self->{Searchlist} = undef;
  $self->{Sortlist} = undef;
  $self->{Options} = undef;

  return 1;
}
###############################################################################

=head2 domain([$domain])

Returns the value of the C<domain> directive.  If C<$domain> is
specified, then set the domain to the given value and the
C<searchlist>, if defined in the object, is undefined.

=cut

sub domain {
  my $self = shift;
  my $domain = shift;

  if (defined($domain)) {
    $self->{Domain} = $domain;
    $self->{Searchlist} = undef;
  }
  return $self->{Domain};
}

=head2 nameservers([@values])

Returns (in order) the list of C<nameserver> entries.  If called in an
array context it returns an array, otherwise it returns an array
reference.

If C<@values> is specified, then set the nameserver list to the given
values.  Any items in C<@values> that are list references are
dereferences as they are added.

=cut

sub nameservers {
  my $self = shift;

  if (@_) {
    $self->{Nameservers} = [];
    for my $item (@_) {
      push @{$self->{Nameservers}}, (UNIVERSAL::isa($item, 'ARRAY') ?
				     @$item : $item);
    }
  }

  return wantarray ? @{$self->{Nameservers}} : $self->{Nameservers};
}

=head2 searchlist([@values])

Returns an array reference containing the items for the C<search>
directive.  If called in an array context it returns an array,
otherwise it returns an array reference.

If a list of values is specified, then set the searchlist to those
values and the C<domain>, if defined in the object, is undefined.  Any
items in C<@values> that are list references are dereferenced as they
are added.

=cut

sub searchlist {
  my $self = shift;

  if (@_) {
    $self->{Searchlist} = [];
    for my $item (@_) {
      push @{$self->{Searchlist}}, (UNIVERSAL::isa($item, 'ARRAY') ?
				    @$item : $item);
    }
  }

  return wantarray ? @{$self->{Searchlist}} : $self->{Searchlist};
}

=head2 sortlist([@values])

Returns an array reference containing the items for the C<sortlist>
directive.  If called in an array context it returns an array,
otherwise it returns an array reference.

If a list of values is specified, then set the sortlist to those
values.  Any items in C<@values> that are list references are
dereferenced as they are added.

=cut

sub sortlist {
  my $self = shift;

  if (@_) {
    $self->{Sortlist} = [];
    for my $item (@_) {
      push @{$self->{Sortlist}}, (UNIVERSAL::isa($item, 'ARRAY') ?
				  @$item : $item);
    }
  }

  return wantarray ? @{$self->{Sortlist}} : $self->{Sortlist};
}

=head2 options([@values])

Returns the items for the C<options> directive.  If called in an array
context it returns an array, otherwise it returns an array reference.

If a list of values is specified, then set the options to those
values.  Any items in C<@values> that are list references are
dereferenced as they are added.

=cut

sub options {
  my $self = shift;

  if (@_) {
    $self->{Options} = [];
    for my $item (@_) {
      push @{$self->{Options}}, (UNIVERSAL::isa($item, 'ARRAY') ?
				 @$item : $item);
    }
  }

  return wantarray ? @{$self->{Options}} : $self->{Options};
}

=head2 comments([@strings])

Returns the comments for the object.  If called in an array context it
returns an array, otherwise it returns an array reference.

If a list of strings is specified, then set the comments to those
values after splitting the items on a C<NEWLINE> boundary.  This
allows several combinations of arrays, array refs, or strings with
embedded newlines to be specified.  There is no need to prefix any of
the comment lines with a comment character (C<[;\#]>); the
C<as_string> automagically commentifies (:-) the comment strings.

Any items in C<@strings> that are list references are dereferenced as
they are added.

=cut

sub comments {
  my $self = shift;

  if (@_) {
    $self->{Comments} = [];
    for my $comment (@_) {
      for my $line (split(/\n/, (UNIVERSAL::isa($comment, 'ARRAY') ?
                                 join("\n", @$comment) : $comment))) {
        push @{$self->{Comments}}, $line;
      }
    }
  }

  return wantarray ? @{$self->{Comments}} : $self->{Comments};
}

=head2 as_string

Returns a string representing the contents of the object.
Technically, this string could be used to populate a C<resolv.conf>
file, but use C<print> for that.  The <print> method is a wrapper
around this method.  The data is generated in the following order:

  comments
  domain	(mutually exclusive with search)
  search	(mutually exclusive with domain)
  nameservers   (one line for each nameserver entry)
  sortlist
  options

=cut

sub as_string {
  my $self = shift;
  my $str;

  if (my $comments = $self->comments) {
    $str .= "; " . join("\n; ", @{$comments}) . "\n";
  }
  if (my $domain = $self->domain) {
    $str .= "domain $domain\n";
  }
  if (my $searchlist = $self->searchlist) {
    $str .= "search " . join(' ', @{$searchlist}) . "\n";
  }
  for my $server (@{$self->{Nameservers}}) {
    $str .= "nameserver $server\n";
  }
  if (my $sortlist = $self->sortlist) {
    $str .= "sortlist " . join(' ', @{$sortlist}) . "\n";
  }
  if (my $options = $self->options) {
    $str .= "options " . join(' ', @{$options}) . "\n";
  }
  return $str;
}

=head2 print($fh)

A wrapper around C<as_string> that prints a valid C<resolver(5)>
representation of the data in the object to the given filehandle.

=cut

sub print { $_[1]->print($_[0]->as_string) }

###############################################################################

=head2 check([$policy])

Performs a policy/validity check of the data contained in the object
using the given subroutine C<&policy>.  The given C<$policy> routine
is called as C<&$policy($self)>.  If C<$policy> is not given it
defaults to using C<default_policy_check>.  It returns the return
status of the policy check routine.

=cut

sub check {
  my $self = shift;
  my $check = shift;

  return defined($check) ? &$check($self) : $self->default_policy_check;
}

=head2 default_policy_check

A simple wrapper around various C<check_*> methods.

=cut

sub default_policy_check {
  my $self = shift;

  return 0 if ($self->domain && !$self->check_domain);
  return 0 if ($self->searchlist && !$self->check_searchlist);
  return 0 unless $self->check_nameservers;
  return 0 unless $self->check_sortlist;
  return 0 unless $self->check_options;

  return 0 unless ($self->domain || $self->searchlist);

  return 1;
}

=head2 check_domain

Returns C<1> if the domain member of the object is defined and is a
valid rfc1035 domain name, otherwise returns C<0>.

=cut

sub check_domain { return valid_domain($_[0]->domain) }

=head2 check_searchlist

Returns C<1> if the searchlist member of the object is defined and
contains only valid rfc1035 domain names, otherwise returns C<0>.

=cut

sub check_searchlist {
  my $self = shift;

  return 0 unless ($self->searchlist);

  for my $fqdn ($self->searchlist) {
    return 0 unless valid_domain($fqdn);
  }
  return 1;
}

=head2 check_nameservers

Returns C<1> if the nameservers member of the object is defined and
contains only ip-addresses, otherwise returns C<0>.

Uses C<valid_ip> to do the real work.

=cut

sub check_nameservers {
  my $self = shift;

  return 0 unless ($self->nameservers);

  for my $ip ($self->nameservers) {
    return 0 unless valid_ip($ip);
  }
  return 1;
}

=head2 check_sortlist

Returns C<1> if the sortlist member of the object is defined and
contains only ip-address/netmasks, otherwise returns C<0>.

Uses C<valid_netmask> to do the real work.

=cut

sub check_sortlist {
  my $self = shift;

  return 1 unless defined($self->sortlist);

  for my $item ($self->sortlist) {
    return 0 unless ($item =~ /^([^\/]+)(?:\/(.+))?$/);
    return 0 unless valid_ip($1);
    return 0 if (defined($2) && !valid_netmask($2));
  }

  return 1;
}

=head2 check_options

Returns C<1> if the options member of the object is empty or contains
only valid options, otherwise returns C<0>.

Currently recognized options are:

=over 2

=item * debug

=item * ndots:N

=back

=cut

sub check_options {
  my $self = shift;

  return 1 unless defined($self->options);

  for my $option ($self->options) {
    return 0 if (($option ne 'debug') && ($option !~ /^ndots:\d+$/));
  }
  return 1;
}

###############################################################################

=head2 qtynameservers

Returns the quantity of nameserver entries present.

=cut

sub qtynameservers { return $#{scalar($_[0]->{Nameservers})} + 1 }

###############################################################################

=head1 CAVEATS

The C<read_from_{file|string}> methods and the C<print> method are not
isomorphic.  Given an arbitrary file or string which is read in, the
output of C<print> is not guaranteed to be an exact duplicate of the
original file.  In the special case of files that are generated with
this module, the results will be isomorphic, assuming no modifications
were made to the data between when it was read in and subsequently
written back out.

Since Net::Bind::Resolv does not impose many requirements on the values
of the various directives present in a C</etc/resolv.conf> file, it is
important to apply the appropriate policy methods against the object
before writing it to a file that will be used by the resolver.
Consider yourself warned!

=head1 AUTHORS

Kevin Johnson <kjj@pobox.com>
Rob Brown <rob@roobik.com>

=head1 COPYRIGHT

Copyright (c) 1997 Kevin Johnson <kjj@pobox.com>.
Copyright (c) 2001 Rob Brown <rob@roobik.com>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
