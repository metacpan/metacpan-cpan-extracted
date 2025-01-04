package MooseX::Getopt; # git description: v0.77-2-g8fbc1b5
# ABSTRACT: A Moose role for processing command line options
# KEYWORDS: moose extension command line options attributes executable flags switches arguments

our $VERSION = '0.78';

use Moose::Role 0.56;
use namespace::autoclean;

with 'MooseX::Getopt::GLD';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Getopt - A Moose role for processing command line options

=head1 VERSION

version 0.78

=head1 SYNOPSIS

  ## In your class
  package My::App;
  use Moose;

  with 'MooseX::Getopt';

  has 'out' => (is => 'rw', isa => 'Str', required => 1);
  has 'in'  => (is => 'rw', isa => 'Str', required => 1);

  # ... rest of the class here

  ## in your script
  #!/usr/bin/perl

  use My::App;

  my $app = My::App->new_with_options();
  # ... rest of the script here

  ## on the command line
  % perl my_app_script.pl -in file.input -out file.dump

=head1 DESCRIPTION

This is a role which provides an alternate constructor for creating
objects using parameters passed in from the command line.

=head1 METHODS

=head2 C<< new_with_options (%params) >>

This method will take a set of default C<%params> and then collect
parameters from the command line (possibly overriding those in C<%params>)
and then return a newly constructed object.

The special parameter C<argv>, if specified should point to an array
reference with an array to use instead of C<@ARGV>.

If L<Getopt::Long/GetOptions> fails (due to invalid arguments),
C<new_with_options> will throw an exception.

If L<Getopt::Long::Descriptive> is installed and any of the following
command line parameters are passed, the program will exit with usage
information (and the option's state will be stored in the help_flag
attribute). You can add descriptions for each option by including a
B<documentation> option for each attribute to document.

  -?
  --?
  -h
  --help
  --usage

If you have L<Getopt::Long::Descriptive> the C<usage> parameter is also passed to
C<new> as the usage option.

=head2 C<ARGV>

This accessor contains a reference to a copy of the C<@ARGV> array
as it originally existed at the time of C<new_with_options>.

=head2 C<extra_argv>

This accessor contains an arrayref of leftover C<@ARGV> elements that
L<Getopt::Long> did not parse.  Note that the real C<@ARGV> is left
untouched.

B<Important>: By default, L<Getopt::Long> will reject unrecognized I<options>
(that is, options that do not correspond with attributes using the C<Getopt>
trait). To disable this, and allow options to also be saved in C<extra_argv>
(for example to pass along to another class's C<new_with_options>), you can either enable the
C<pass_through> option of L<Getopt::Long> for your class:  C<< use Getopt::Long
qw(:config pass_through); >> or specify a value for L<MooseX::Getopt::GLD>'s C<getopt_conf> parameter.

=head2 C<usage>

This accessor contains the L<Getopt::Long::Descriptive::Usage> object (if
L<Getopt::Long::Descriptive> is used).

=head2 C<help_flag>

This accessor contains the boolean state of the --help, --usage and --?
options (true if any of these options were passed on the command line).

=head2 C<print_usage_text>

This method is called internally when the C<help_flag> state is true.
It prints the text from the C<usage> object (see above) to C<STDOUT>
(and then after this method is called, the
program terminates normally).  You can apply a method modification (see
L<Moose::Manual::MethodModifiers>) if different behaviour is desired, for
example to include additional text.

=head2 C<meta>

This returns the role meta object.

=head2 C<process_argv (%params)>

This does most of the work of C<new_with_options>, analyzing the parameters
and C<argv>, except for actually calling the constructor. It returns a
L<MooseX::Getopt::ProcessedArgv> object. C<new_with_options> uses this
method internally, so modifying this method via subclasses/roles will affect
C<new_with_options>.

=for stopwords DWIM metaclass

This module attempts to DWIM as much as possible with the command line
parameters by introspecting your class's attributes. It will use the name
of your attribute as the command line option, and if there is a type
constraint defined, it will configure L<Getopt::Long> to handle the option
accordingly.

You can use the trait L<MooseX::Getopt::Meta::Attribute::Trait> or the
attribute metaclass L<MooseX::Getopt::Meta::Attribute> to get non-default
command-line option names and aliases.

You can use the trait L<MooseX::Getopt::Meta::Attribute::Trait::NoGetopt>
or the attribute metaclass L<MooseX::Getopt::Meta::Attribute::NoGetopt>
to have C<MooseX::Getopt> ignore your attribute in the command-line options.

By default, attributes which start with an underscore are not given
command-line argument support, unless the attribute's metaclass is set
to L<MooseX::Getopt::Meta::Attribute>. If you don't want your accessors
to have the leading underscore in their name, you can do this:

  # for read/write attributes
  has '_foo' => (accessor => 'foo', ...);

  # or for read-only attributes
  has '_bar' => (reader => 'bar', ...);

This will mean that MooseX::Getopt will not handle a --foo parameter, but your
code can still call the C<foo> method.

=for stopwords configfile

If your class also uses a configfile-loading role based on
L<MooseX::ConfigFromFile>, such as L<MooseX::SimpleConfig>,
L<MooseX::Getopt>'s C<new_with_options> will load the configfile
specified by the C<--configfile> option (or the default you've
given for the configfile attribute) for you.

Options specified in multiple places follow the following
precedence order: command-line overrides configfile, which
overrides explicit new_with_options parameters.

=head2 Supported Type Constraints

=over 4

=item I<Bool>

A I<Bool> type constraint is set up as a boolean option with
L<Getopt::Long>. So that this attribute description:

  has 'verbose' => (is => 'rw', isa => 'Bool');

would translate into C<verbose!> as a L<Getopt::Long> option descriptor,
which would enable the following command line options:

  % my_script.pl --verbose
  % my_script.pl --noverbose

=for stopwords Str

=item I<Int>, I<Float>, I<Str>

These type constraints are set up as properly typed options with
L<Getopt::Long>, using the C<=i>, C<=f> and C<=s> modifiers as appropriate.

=item I<ArrayRef>

An I<ArrayRef> type constraint is set up as a multiple value option
in L<Getopt::Long>. So that this attribute description:

  has 'include' => (
      is      => 'rw',
      isa     => 'ArrayRef',
      default => sub { [] }
  );

would translate into C<includes=s@> as a L<Getopt::Long> option descriptor,
which would enable the following command line options:

  % my_script.pl --include /usr/lib --include /usr/local/lib

=item I<HashRef>

A I<HashRef> type constraint is set up as a hash value option
in L<Getopt::Long>. So that this attribute description:

  has 'define' => (
      is      => 'rw',
      isa     => 'HashRef',
      default => sub { {} }
  );

would translate into C<define=s%> as a L<Getopt::Long> option descriptor,
which would enable the following command line options:

  % my_script.pl --define os=linux --define vendor=debian

=back

=head2 Custom Type Constraints

=for stopwords subtype

It is possible to create custom type constraint to option spec
mappings if you need them. The process is fairly simple (but a
little verbose maybe). First you create a custom subtype, like
so:

  subtype 'ArrayOfInts'
      => as 'ArrayRef'
      => where { scalar (grep { looks_like_number($_) } @$_)  };

Then you register the mapping, like so:

  MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
      'ArrayOfInts' => '=i@'
  );

Now any attribute declarations using this type constraint will
get the custom option spec. So that, this:

  has 'nums' => (
      is      => 'ro',
      isa     => 'ArrayOfInts',
      default => sub { [0] }
  );

Will translate to the following on the command line:

  % my_script.pl --nums 5 --nums 88 --nums 199

This example is fairly trivial, but more complex validations are
easily possible with a little creativity. The trick is balancing
the type constraint validations with the L<Getopt::Long> validations.

Better examples are certainly welcome :)

=head2 Inferred Type Constraints

If you define a custom subtype which is a subtype of one of the
standard L</Supported Type Constraints> above, and do not explicitly
provide custom support as in L</Custom Type Constraints> above,
MooseX::Getopt will treat it like the parent type for Getopt
purposes.

For example, if you had the same custom C<ArrayOfInts> subtype
from the examples above, but did not add a new custom option
type for it to the C<OptionTypeMap>, it would be treated just
like a normal C<ArrayRef> type for Getopt purposes (that is,
C<=s@>).

=head2 More Customization Options

=for stopwords customizations

See L<Getopt::Long/Configuring Getopt::Long> for many other customizations you
can make to how options are parsed. Simply C<use Getopt::Long qw(:config
other_options...)> in your class to set these.

Note in particular that the default setting for case sensitivity has changed
over time in L<Getopt::Long::Descriptive>, so if you rely on a particular
setting, you should set it explicitly, or enforce the version of
L<Getopt::Long::Descriptive> that you install.

=head1 SEE ALSO

=over 4

=item *

L<MooseX::Getopt::Usage>, an extension to generate man pages, with colour

=item *

L<MooX::Options>, similar functionality for L<Moo>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Getopt>
(or L<bug-MooseX-Getopt@rt.cpan.org|mailto:bug-MooseX-Getopt@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Tomas Doran Stevan Little Yuval Kogman Florian Ragwitz Brandon L Black Shlomi Fish Hans Dieter Pearcey Olaf Alders Dave Rolsky Nelo Onyiah Ryan D Johnson Ricardo SIGNES Ævar Arnfjörð Bjarmason Damien Krotkine Hinrik Örn Sigurðsson Andreas Koenig Chris Prather Devin Austin Gregory Oschwald Jose Luis Martinez Todd Hepler Dagfinn Ilmari Mannsåker Damyan Ivanov Drew Taylor Gordon Irving Jesse Luehrs John Goulah Jonathan Swartz Justin Hunter Michael Schout Stuart A Johnston

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Brandon L Black <blblack@gmail.com>

=item *

Shlomi Fish <shlomif@cpan.org>

=item *

Hans Dieter Pearcey <hdp@weftsoar.net>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Nelo Onyiah <nelo.onyiah@gmail.com>

=item *

Ryan D Johnson <ryan@innerfence.com>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Ævar Arnfjörð Bjarmason <avarab@gmail.com>

=item *

Damien Krotkine <dkrotkine@weborama.com>

=item *

Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>

=item *

Andreas Koenig <andk@cpan.org>

=item *

Chris Prather <chris@prather.org>

=item *

Devin Austin <dhoss@cpan.org>

=item *

Gregory Oschwald <goschwald@maxmind.com>

=item *

Jose Luis Martinez <jlmartinez@capside.com>

=item *

Todd Hepler <thepler@employees.org>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Damyan Ivanov <dmn@debian.org>

=item *

Drew Taylor <drew@drewtaylor.com>

=item *

Gordon Irving <goraxe@goraxe.me.uk>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

John Goulah <jgoulah@cpan.org>

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Justin Hunter <justin.d.hunter@gmail.com>

=item *

Michael Schout <mschout@gkg.net>

=item *

Stuart A Johnston <saj_git@thecommune.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
