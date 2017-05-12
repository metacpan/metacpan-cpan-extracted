=head1 NAME

Template::Plugin::EnvHash - Environment Variable Hash for TT2

=head1 SYNOPSIS

 [% USE env = EnvHash %]
 [% env.SOME_ENV_VAR %]


=head1 DESCRIPTION

This is a trivial Template::Toolkit plugin to  allow any template writer to suck
environment variables  into their  template. I wrote  it  because i was  sick of
passing %ENV as one of the contents of the vars hash that  i pass to the process
method of Template.

=head1 NAMING

I've named this module EnvHash  rather than Env because most Template::Plugin::X
modules are wrappers around module  X. Whereas this  is I<not> a wrapper  around
Perl's Env module.   This is because  the purpose  of that  module is to  export
environment variables   into a package. I   did not  want  to export environment
variables  into  my template    as  environment variables as  most   environment
variables tend to have capitalised names (by  popular convention) and this might
cause confusion with the  tt2 style of using capitalised  words for  its control
structure syntax.

Of course someone  else might come along and  not care  about  this, so i  leave
Template::Plugin::Env free for such a person.

=head1 USING ENVIRONMENT VARIABLES IN TEMPLATES

As well  as this  being  a useful module for   sucking in  standard  environment
variables it also allows you to configure template via the environment.

Some might say  using the  environment variables  to configure  your template is
dangerous, and in  an I<uncontrolled environment> i  would agree. However if you
have a I<controlled>  environment it can be incredibly  useful. Say  for example
you  quickly  want to fire  your  usual apache  server, but  on a different port
(perhaps because u  want to test  two  sets of changes  simultaneous, or perhaps
just because   someone else is using    that port).  Then  using  an environment
variable to pass the port number can be quick dirty and useful.

Config files are generally better in the long run for most  things, but as i say
it can be useful in a I<controlled> environment.

=cut



package Template::Plugin::EnvHash;



# pragmata
use 5.006;
use base qw(Template::Plugin);
use strict;
use warnings;

# Standard Perl Library and CPAN modules

our $VERSION = '1.06';


sub new {
	my($class, $rh_args) = @_;

	my($self);

	$self = \%ENV;
	bless $self, $class;
	$self;
}


1;


=head1 INSTALLATION

This module uses Module::Build for its installation. To install this module type
the following:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install


If you do not have Module::Build type:

  perl Makefile.PL

to fetch it. Or use CPAN or CPANPLUS and fetch it "manually".

=head1 KNOWN ISSUES

The curernt implementation simply blesses %ENV. This causes a problem for the
environment variable $VERSION as this gets overwritten by the module's own
$VERSION. I will change the implementation at some point, but do feel free to
email me and hurry me along if this is stopping you from being able to use this
module

Environment Variables with names begining with an underscore are not supported.

=head1 BUGS

To report a  bug or request an enhancement  use CPAN's excellent Request
Tracker:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-EnvHash>

=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in svn.

http://sourceforge.net/projects/sagar-r-shah/

=head1 AUTHOR

Sagar R. Shah

=head1 COPYRIGHT

Copyright 2003-2007, Sagar R. Shah, All rights reserved

This program  is free software; you can  redistribute it  and/or modify it under
the same terms as Perl itself.

=cut
