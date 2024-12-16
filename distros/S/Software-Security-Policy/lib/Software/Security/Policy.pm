use strict;
use warnings;
package Software::Security::Policy;
# ABSTRACT: packages that provide templated Security Policys

our $VERSION = '0.01'; # VERSION

use Data::Section -setup => { header_re => qr/\A__([^_]+)__\Z/ };
use Text::Template ();


sub new {
  my ($class, $arg) = @_;

  Carp::croak "no maintainer is specified" unless $arg->{maintainer};

  bless $arg => $class;
}


sub support_years { $_[0]->{support_years} || '10'}

sub timeframe { $_[0]->{timeframe} || '5 days'    }

sub maintainer { $_[0]->{maintainer}     }

sub _dotless_maintainer {
  my $maintainer = $_[0]->maintainer;
  $maintainer =~ s/\.$//;
  return $maintainer;
}


sub program { $_[0]->{program} || $_[0]->{Program} || 'this program' }


sub Program { $_[0]->{Program} || $_[0]->{program} || 'This program' }


sub summary { shift->_fill_in('SUMMARY') }


sub security_policy { shift->_fill_in('SECURITY-POLICY') }


sub fulltext {
  my ($self) = @_;
  return join "\n", $self->summary, $self->security_policy;
}


sub version  {
  my ($self) = @_;
  my $pkg = ref $self ? ref $self : $self;
  $pkg =~ s/.+:://;
  my (undef, @vparts) = split /_/, $pkg;

  return unless @vparts;
  return join '.', @vparts;
}


# sub meta1_name    { return undef; } # sort this out later, should be easy
sub meta_name     { return undef; }

# FIXME : are there any meta attributes for this?
sub meta2_name {
  my ($self) = @_;
  my $meta1 = $self->meta_name;

  return undef unless defined $meta1;

  return $meta1
    if $meta1 =~ /\A(?:open_source|restricted|unrestricted|unknown)\z/;

  return undef;
}

sub _fill_in {
  my ($self, $which) = @_;

  Carp::confess "couldn't build $which section" unless
    my $template = $self->section_data($which);

  return Text::Template->fill_this_in(
    $$template,
    HASH => { self => \$self },
    DELIMITERS => [ qw({{ }}) ],
  );
}


1;

=pod

=encoding UTF-8

=head1 NAME

Software::Security::Policy - packages that provide templated Security Policys

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $policy = Software::Security::Policy::SingleDeveloper->new({
    maintainer => 'Timothy Legge',
  });

  print $output_fh $policy->fulltext;

=head1 METHODS

=head2 new

  my $policy = $subclass->new(\%arg);

This method returns a new security policy object for the given
security policy class.  Valid arguments are:

=head2 support_years

=head2 timeframe

=head2 maintainer

These methods are attribute readers.

=head2 program

Name of software for using in the middle of a sentence.

The method returns value of C<program> constructor argument (if it evaluates as true, i. e.
defined, non-empty, non-zero), or value of C<Program> constructor argument (if it is true), or
"this program" as the last resort.

=head2 Program

Name of software for using at the beginning of a sentence.

The method returns value of C<Program> constructor argument (if it is true), or value of C<program>
constructor argument (if it is true), or "This program" as the last resort.

=head2 name

This method returns the name of the policy, suitable for shoving in the middle
of a sentence, generally with a leading capitalized "The."

=head2 url

This method returns the URL at which a canonical text of the security policy can be
found, if one is available.  If possible, this will point at plain text, but it
may point to an HTML resource.

=head2 summary

This method returns a snippet of text, usually a few lines, indicating the
maintainer as well as an indication of the policy under which the software
is maintained.

=head2 security_policy

This method returns the full text of the policy.

=head2 fulltext

This method returns the complete text of the policy.

=head2 version

This method returns the version of the policy.  If the security policy is not
versioned, this method will return false.

=head2 meta_name

This method returns the string that should be used for this security policy in the CPAN
META.yml file, according to the CPAN Meta spec v1, or undef if there is no
known string to use.

=head2 meta2_name

This method returns the string that should be used for this security policy in the CPAN
META.json or META.yml file, according to the CPAN Meta spec v2, or undef if
there is no known string to use.  If this method does not exist, and
C<meta_name> returns open_source, restricted, unrestricted, or unknown, that
value will be used.

=for :list = maintainer
the current maintainer for the distibrution; required
= program
the name of software for use in the middle of a sentence
= Program
the name of software for use in the beginning of a sentence

C<program> and C<Program> arguments may be specified both, either one or none.
Each argument, if not specified, is defaulted to another one, or to properly
capitalized "this program", if both arguments are omitted.

=head1 LOOKING UP LICENSE CLASSES

FIXME: Remove - unneeded
If you have an entry in a F<META.yml> or F<META.json> file, or similar
metadata, and want to look up the Software::Security::Policy class to use, there are
useful tools in L<Software::Security::Policy::Utils>.

=head1 TODO

=for :list * register policys with aliases to allow $registry->get('gpl', 2);

=head1 SEE ALSO

The specific policy:

=for :list * L<Software::Security::Policy::Individual>

Extra policys are maintained on CPAN in separate modules.

FIXME Remove
The L<App::Software::Security::Policy> module comes with a script
L<software-policy|https://metacpan.org/pod/distribution/App-Software-Security::Policy/script/software-policy>,
which provides a command-line interface to Software::Security::Policy.

=head1 COPYRIGHT

This module is based extensively on Software::License.  Only the
changes required for this module are attributable to the author of
this module.  All other code is attributable to the author of
Software::License.

=head1 AUTHOR

Timothy Legge <timlegge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Timothy Legge <timlegge@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__SUMMARY__
This is the Security Policy for the {{ $self->program }} distribution.

Report issues to:

  {{ $self->maintainer }}
