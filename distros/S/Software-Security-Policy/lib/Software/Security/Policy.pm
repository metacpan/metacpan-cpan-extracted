use strict;
use warnings;
package Software::Security::Policy;
# ABSTRACT: packages that provide templated Security Policys

our $VERSION = '0.04'; # VERSION

use Data::Section -setup => { header_re => qr/\A__([^_]+)__\Z/ };
use Text::Template ();


sub new {
  my ($class, $arg) = @_;

  Carp::croak "no maintainer is specified" unless $arg->{maintainer};

  bless $arg => $class;
}


sub url { (defined $_[0]->{url} ? $_[0]->{url} :
            (defined $_[0]->{git_url} ? $_[0]->{git_url} :
                'SECURITY.md')) }

sub git_url { (defined $_[0]->{git_url} ? $_[0]->{git_url} :
            (defined $_[0]->{url} ? $_[0]->{url} :
                'SECURITY.md')) }


sub support_years { $_[0]->{support_years} || '10'}

sub timeframe {
    return $_[0]->{timeframe} if defined $_[0]->{timeframe};
    return $_[0]->{timeframe_quantity} . ' ' . $_[0]->{timeframe_units}
        if defined $_[0]->{timeframe_quantity} &&
            defined $_[0]->{timeframe_units};
    return '5 days';
}

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

version 0.04

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Software::Security::Policy::Individual;

  my $policy = Software::Security::Policy::Individual->new({
    maintainer  => 'Timothy Legge <timlegge@gmail.com>',
    program     => 'Software::Security::Policy',
    timeframe   => '7 days',
    url         => 'https://github.com/CPAN-Security/Software-Security-Policy/blob/main/SECURITY.md',
    support_years   => '10',
  });

  print $policy->fulltext, "\n";

=head1 METHODS

=over

=item new

  my $policy = $subclass->new(\%arg);

This method returns a new security policy object for the given
security policy class.  Valid arguments are:

=back

=head2 ATTRIBUTES

=over

=item maintainer

the current maintainer for the distibrution; required

=item timeframe

the time to expect acknowledgement of a security issue.  Should
include the units such as '5 days or 2 weeks'; defaults to 5 days

=item timeframe_quantity

the amount of time to expect an acknowledgement of a security issue.
Only used if timeframe is undefined and timeframe_units is defined
(eg. '5')

=item timeframe_units

the units of time to expect an acknowledgement of a security issue.
Only used if timeframe is undefined and timeframe_quantity is defined
(eg. 'days')

=item url

a url where the most current security policy can be found.

=item git_url

a git url where the most current security policy can be found.

=item support_years

the number of years for which past major versions of Perl would be
supported

=item program

the name of software for use in the middle of a sentence

=item Program

the name of software for use in the beginning of a sentence

C<program> and C<Program> arguments may be specified both, either one or none.
Each argument, if not specified, is defaulted to another one, or to properly
capitalized "this program", if both arguments are omitted.

=back

=head2 support_years

Get the number of years of support to be expected

=head2 timeframe

Get the expected response time. Defaults to 5 days and uses
timeframe_quantity and timeframe_units if the timeframe attribute
us undefined.

=head2 maintainer

Get the maintainer that should be contacted for security issues.

=head2 url

Get the URL of the latest security policy version.

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

=head2 git_url

This method returns the git URL at which a canonical text of the security policy can be
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

This method returns the version of the policy.  If the security
policy is not versioned, this method will return false.

=head1 SEE ALSO

The specific policy:

=for :list * L<Software::Security::Policy::Individual>

Extra policys are maintained on CPAN in separate modules.

=head1 COPYRIGHT

This software is copyright (c) 2024-2025 by Timothy Legge <timlegge@gmail.com>.

This module is based extensively on Software::License.  Only the
changes required for this module are attributable to the author of
this module.  All other code is attributable to the author of
Software::License.

=head1 AUTHOR

Timothy Legge <timlegge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Timothy Legge <timlegge@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__SUMMARY__
This is the Security Policy for the {{ $self->program }} distribution.

Report issues to:

  {{ $self->maintainer }}
