#!/usr/bin/perl

=head1 NAME

Sys::Facter - collect facts about operating system

=head1 SYNOPSIS

  use Sys::Facter;
  use Data::Dumper;

  my $facter = new Sys::Facter(modules => ["/some/where"]);

  # load some facts manually and print them
  $facter->load("kernel", "lsbrelease", "lsbid");
  print Dumper $facter->facts;

  # print some facts (they'll be loaded automatically)
  print $facter->hostname;
  print $facter->get("memorytotal");

=head1 DESCRIPTION

This module is a wrapper over Pfacter. Pfacter is a Facter
(L<http://puppetlabs.com/puppet/related-projects/facter/>) port to Perl.

The idea is to have a set of modules that detect various things about the host
operating system, but also to easily extend this set by new, possibly
user-written, modules. This is achieved through defining an API for additional
plugins.

Pfacter specifies some API for plugins, but completely lacks documentation,
and usage in Perl code is troublesome. This module simplifies Pfacter usage
while preserving its API (somebody could already have some plugins written).

You can find a plugin API specification in this document, in
L</"FACT PLUGIN API"> section.

=cut

#-----------------------------------------------------------------------------

package Sys::Facter;

use warnings;
use strict;

use POSIX qw{uname};
use Carp;

#-----------------------------------------------------------------------------

our $VERSION = '1.01';

#-----------------------------------------------------------------------------

=head1 METHODS

Following methods are available:

=over

=cut

#-----------------------------------------------------------------------------

=item C<new(%opts)>

Constructor.

Following options are honoured:

=over

=item C<< modules => [...] >> (optional)

List of directories to be searched additionally to C<@INC> for Pfacter
modules.

These directories have the precedence over C<@INC> and are searched in the
order of appearance.

Plugins in these directories should be placed under F<Pfacter> subdirectory,
as it would be for C<@INC> directories.

=back

=cut

sub new {
  my ($class, %opts) = @_;

  my @modules = @{ $opts{modules} || [] };

  my ($hostname, $domainname) = split /\./, (uname)[1], 2;

  my $self = bless {
    pfact => {
      # the first and only pfact detected here
      kernel   => (uname)[0],
      hostname => $hostname,
    },
    var   => {
      modules => \@modules,
      loaded  => {
        kernel   => 1,
        hostname => 1,
      },
    },
  }, $class;

  if (defined $domainname) {
    $self->{pfact}{domain} = $domainname;
    $self->{var}{loaded}{domain} = 1;
  }

  $self->load(qw{operatingsystem domain});

  return $self;
}

#-----------------------------------------------------------------------------

=item C<load(@facts)>

Load and cache specified facts.

If you don't specify any facts at all, Sys::Facter will load all of them.

=cut

sub load {
  my ($self, @facts) = @_;

  # XXX: yes, this is lower case
  my @invalid = grep { not m{^[a-z0-9_]+$} } @facts;
  if (@invalid) {
    croak "Invalid fact names: @invalid\n";
  }

  if (not @facts) {
    @facts = map { (split m{[/.]})[-2] }
             grep { m{/[a-z0-9_]+\.pm$} && -f $_ }
             map { glob "$_/Pfacter/*.pm" }
             @{ $self->{var}{modules} }, @INC;
  }

  for my $fact (grep { not $self->{var}{loaded}{$_} } @facts) {
    my $module = "Pfacter::$fact";
    my ($file) = grep { -f $_ }
                 map { "$_/Pfacter/$fact.pm" }
                 @{ $self->{var}{modules} }, @INC;

    if (not defined $file) {
      carp "Couldn't load fact `$fact'";
      next;
    }

    my $result = eval { require $file; $module->pfact($self) };
    die $@ if $@;

    $self->{var}{loaded}{$fact} = 1;

    if ($result) {
      chomp $result;
      $self->{pfact}{$fact} = $result;
    }
  }
}

#-----------------------------------------------------------------------------

=item C<facts()>

Return currently loaded facts as a %hashmap.

=cut

sub facts {
  my ($self) = @_;

  return $self->{pfact};
}

#-----------------------------------------------------------------------------

=item C<get($fact)>

Return the value of specified fact, loading it if necessary.

=cut

sub get {
  my ($self, $fact) = @_;

  $self->load($fact);
  return $self->{pfact}{$fact};
}

#-----------------------------------------------------------------------------

=item C<${fact_name}()>

For convenience, facts can be accessed with methods named by their names. For
example, C<< $facter->get("kernel") >> is equivalent to
C<< $facter->kernel >>.

Of course, facts called "get", "new", "facts" and "load" can't be fetched this
way, but from these only "load" could be useful name.

=back

=cut

#-----------------------------------------------------------------------------

sub AUTOLOAD {
  my ($self) = @_;

  our $AUTOLOAD;
  my $fact = (split /::/, $AUTOLOAD)[-1];

  # it's a proper fact name
  if ($fact =~ m{^[a-z0-9_]+$}) {
    return $self->get($fact);
  }

  croak "Unknown method $AUTOLOAD for object @{[ref $self]}";
}

sub DESTROY {
  my ($self) = @_;

  # nuffin();
}

#-----------------------------------------------------------------------------

=head1 FACT PLUGIN API

Pfacter doesn't provide an API documentation, so this is a short reference.

Pfacter plugin is a separate Perl module of name C<Pfacter::${plugin_name}>.
C<${plugin_name}> is all-lowercase with numbers and underscore (it should
match regexp C</^[a-z0-9_]+$/>).

The module needs to have C<pfact()> function defined. This function has two
arguments provided: package name and a %hash-like object that contains
"pfact" key with facts hashmap. This can be used to determine way of
collecting facts about the system.

C<pfact()> function is expected to return a single-line string. If it returns
non-TRUE value, the fact is considered to be loaded but non-applicable to this
system and will not be listed in C<< $facter->facts() >>.

Example module:

  package Pfacter::example;

  sub pfact {
    my ($pkg, $facter) = @_;
    my $facts = $facter->{pfact};

    if ($facts->{kernel} eq "Linux") {
      return "single-line";
    } else {
      return undef;
    }
  }

  # remember to return TRUE
  1;

Note that while C<$facter> in code above will be C<Sys::Facter> reference, the
plugin should not use anything except C<< $facter->{pfact} >> field. This is
to keep compatibility with original F<pfacter> command line tool.

Modules may assume that following facts are pre-loaded:

=over

=item - C<kernel>

Under Linux it will be "Linux"

=item - C<operatingsystem>

Under Linux it could be "Debian", "RedHat", "Gentoo", "SuSE" or similar.

=item - C<hostname>

Host name, up to (but not including) first dot, if any.

=item - C<domain>

Domain name. If output of C<uname -n> contains dots, everything after first
dot. Otherwise, autodetected.

=back

=cut

#-----------------------------------------------------------------------------

=head1 AUTHOR

Stanislaw Klekot, C<< <cpan at jarowit.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-facter at rt.cpan.org>, or
through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-Facter>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stanislaw Klekot.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<pffacter(1)>, L<Sys::Info(3)>

=cut

#-----------------------------------------------------------------------------
1;
# vim:ft=perl
