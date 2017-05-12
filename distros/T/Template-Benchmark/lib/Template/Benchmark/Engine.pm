package Template::Benchmark::Engine;

use warnings;
use strict;

our $VERSION = '1.09';
our %feature_syntaxes = ();

sub feature_syntax
{
    my ( $self, $feature_name ) = @_;
    my ( $pkg, %their_syntaxes );

    $pkg = ref( $self ) || $self;

    {
        no strict 'refs';
        %their_syntaxes = %{"${pkg}::feature_syntaxes"};
    }

    return( undef ) unless %their_syntaxes;
    return( $their_syntaxes{ $feature_name } );
}

sub preprocess_template
{
    my ( $self, $template ) = @_;

    return( $template );
}

sub benchmark_descriptions
{
    return( {} );
}

sub benchmark_functions_for_uncached_string
{
    my ( $self ) = @_;

    return( undef );
}

sub benchmark_functions_for_uncached_disk
{
    my ( $self ) = @_;

    return( undef );
}

sub benchmark_functions_for_disk_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
}

sub benchmark_functions_for_shared_memory_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
}

sub benchmark_functions_for_memory_cache
{
    my ( $self, $template_dir, $cache_dir ) = @_;

    return( undef );
}

sub syntax_type
{
    return( undef );
}

sub pure_perl
{
    return( undef );
}

1;

__END__

=pod

=head1 NAME

Template::Benchmark::Engine - Base class for Template::Benchmark template engine plugins.

=head1 SYNOPSIS

  package Template::Benchmark::Engines::TemplateSandbox;

  use warnings;
  use strict;

  use base qw/Template::Benchmark::Engine/;

  our $VERSION = '0.99_02';

  our %feature_syntaxes = (
      literal_text              =>
          join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
      scalar_variable           =>
          '<: expr scalar_variable :>',
      );

  #  rest of module...

=head1 DESCRIPTION

Provides a base class for L<Template::Benchmark> template engine plugins.

=head1 SUBCLASSING

To write your own L<Template::Benchmark> plugin you'll need to subclass
this class (L<Template::Benchmark::Engine>) and put your package in the
C<Template::Benchmark::Engines::> namespace.

The naming convention within that namespace is to strip the :: from the
name of the I<template engine> and retain capitalization, thus
L<Template::Sandbox> becomes plugin
L<Template::Benchmark::Engines::TemplateSandbox>,
L<HTML::Template> becomes L<Template::Benchmark::Engines::HTMLTemplate>.

The notable exception is that L<Template> becomes
L<Template::Benchmark::Engines::TemplateToolkit>, because everyone calls
it Template::Toolkit rather than Template.

=head2 Supported or Unsupported?

Throughout the sections below are references to whether a I<template feature>
or I<cache type> is supported or unsupported in the I<template engine>.

Indicating that something is unsupported is fairly simple, you just return
an C<undef> value in the appropriate place, but what constitutes
"unsupported"?

It doesn't neccessarily mean that it's I<impossible> to perform that task
with the given I<template engine>, but generally if it requires some
significant chunk of DIY code or boilerplate or subclassing by the
developer using the I<template engine>, it should be considered to be
I<unsupported> by the I<template engine> itself.

This of course is a subjective judgement, but a general rule of thumb
is that if you can tell the I<template engine> to do it, it's supported;
and if the I<template engine> allows I<you> to do it, it's I<unsupported>,
even though it's I<possible>.

=head2 Methods To Subclass

=over

=item B<< $template_snippet = Plugin->feature_syntax( >> I<$template_feature> B<)>

Your plugin doesn't need to provide this method directly, it can
be inherited from L<Template::Benchmark::Engine> where it will
access the I<%feature_syntaxes> variable in your plugin's namespace,
using I<$template_feature> as a key.

Obviously I<%feature_syntaxes> can't be a private variable for this
to work, so declare it as a global or with C<our>.

For example:

  our %feature_syntaxes = (
      literal_text              =>
          join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 ),
      scalar_variable           =>
          '<: expr scalar_variable :>',
      hash_variable_value       =>
          '<: expr hash_variable.hash_value_key :>',
  # ...
      );

Any feature that isn't supported by the I<template engine> should
have an C<undef> value.

Please see the section L</"Feature Syntaxes"> for a list of the
different I<template features> and what their requirements are.

=item B<< $template = Plugin->preprocess_template( >> I<$template> B<)>

After the template has been generated from the snippets for each of the
enabled I<template features>, it is passed to
C<< Plugin->preprocess_template() >> in case the plugin needs to do any
final changes to the template.

In the majority of cases the default C<< preprocess_template() >> will
be sufficient, but for some I<template engines> which require unique
labels for their loops, there may need to be a rewrite pass done here
to ensure that the copies inserted by the C<template_repeats> parameter
have unique names.

C<< preprocess_template() >> should B<not> perform any template execution,
it is simply a stage to ensure that a well-formed template is generated
from the I<feature snippets>.

This method was added in version 1.08.

=item B<< $descriptions = Plugin->benchmark_descriptions() >>

This method must be defined, to return a hashref of I<benchmark function>
names to a useful description, for example:

  sub benchmark_descriptions
  {
      return( {
          TS    =>
              "Template::Sandbox ($Template::Sandbox::VERSION) without caching",
          TS_CF =>
              "Template::Sandbox ($Template::Sandbox::VERSION) with " .
              "Cache::CacheFactory ($Cache::CacheFactory::VERSION) caching",
          TS_CHI =>
              "Template::Sandbox ($Template::Sandbox::VERSION) with " .
              "CHI ($CHI::VERSION) caching",
          TS_FMM =>
              "Template::Sandbox ($Template::Sandbox::VERSION) with " .
              "Cache::FastMmap ($Cache::FastMmap::VERSION) caching",
          } );
  }

It's generally very useful to include version numbers like the example,
don't waste half an hour figuring out why your benchmarks are slow
before you realise it's benchmarking the last version from CPAN
rather than your fancy new development copy, all because you forgot to set
your library path.

Uh, not that I'd make such a basic mistake.

The name of the different benchmarks shouldn't clash with anyone else's
otherwise things will get confusing, and an underscore (_) should only
be used to distinguish between different functions returned by the same
plugin.

Best bet is to look at the plugins already written and choose something
written along similar lines, but distinctive to your template engine,
it needs to be short though because it will be being used as
a column heading and row title for the benchmark results, and they're
pretty wide already.

The convention I've used is to use initials of the package's namespace,
T for Template::, H for HTML::, Te for Text::, then sufficient initials
to disambiguate the rest of the package name.

So L<Template::Toolkit> is TT, L<Template::Sandbox> is TS,
L<HTML::Template> is HT, L<Text::Template> is TeTe as opposed
to L<Text::Tmpl> being TeTmpl.

Additional initials might be added if the I<template engine>
can accept different template syntaxes, which is handled by several
plugins:

L<Template::Alloy> gets TATT (running in L<Template::Toolkit> mode)
and TAHT (running in L<HTML::Template> mode), and if you want long-winded
there's TeMMTeTe - L<Text::MicroMason> running in L<Text::Template> mode.

It should be obvious by now why there needs to be a nice clear description
to accompany these names.

Within a plugin, if there are several different configuration options,
caching choices, or other tweaks to be benchmarked, this is indicated
by a suffix after an underscore (_).

So L<Template::Sandbox> using L<Cache::CacheFactory> for caching
becomes TS_CF, and using L<CHI> for caching is TS_CHI, this lets you
easily see within the results that both TS_CF and TS_CHI are produced
using the same I<template engine> plugin.

=item B<< $template_functions = Plugin->benchmark_functions_for_uncached_string() >>

=item B<< $template_functions = Plugin->benchmark_functions_for_uncached_disk( >> I<$template_dir> B<)>

These methods need to return a hashref of names to I<benchmark function>
references, if the I<cache type> is unsupported it should return
C<undef>.

Each name needs to be listed in the hashref returned from
C<< Plugin->benchmark_descriptions() >>.

For uncached_string, each I<benchmark function> needs to accept the
contents of the template as the first argument and then two hashrefs
of I<template variables> to set.

For uncached_disk, each I<benchmark function> needs to accept the
leaf filename of the template as the first argument and then two
hashrefs of I<template variables> to set.

The I<benchmark function> should return the content of the processed template.

For example:

  sub benchmark_functions_for_uncached_string
  {
      my ( $self ) = @_;

      return( {
          TS =>
              sub
              {
                  my $t = Template::Sandbox->new();
                  $t->set_template_string( $_[ 0 ] );
                  $t->add_vars( $_[ 1 ] );
                  $t->add_vars( $_[ 2 ] );
                  ${$t->run()};
              },
          } );
  }

Please see the section L</"Cache Types"> for a list of the
different I<cache types> and what restrictions apply to
the I<benchmark functions> in each.

=item B<< $template_functions = Plugin->benchmark_functions_for_disk_cache( >> I<$template_dir>, I<$cache_dir> B<)>

=item B<< $template_functions = Plugin->benchmark_functions_for_shared_memory_cache( >> I<$template_dir>, I<$cache_dir> B<)>

=item B<< $template_functions = Plugin->benchmark_functions_for_memory_cache( >> I<$template_dir>, I<$cache_dir> B<)>

=item B<< $template_functions = Plugin->benchmark_functions_for_instance_reuse( >> I<$template_dir>, I<$cache_dir> B<)>

Each of these methods need to return a hashref of names to
I<benchmark function> references like
C<< Plugin->benchmark_functions_for_uncached_string() >>, however
they have slightly different arguments.  If the I<cache type> is
unsupported it should return C<undef>.

I<$template_dir> provides you with the location of the temporary directory
in which the template will be written.

I<$cache_dir> provides you with the location of the temporary directory
created for any cache you wish to create.

Note that the cache directory is unique to your plugin, however it is shared
for every I<benchmark function> returned by your plugin, if you have
multiple I<benchmark functions> you will need to set things up yourself
within that cache directory to prevent them stomping on each-other's toes.

Each I<benchmark function> needs to accept the leaf filename of the template
as the first argument and then two hashrefs of I<template variables> to set.

The leaf filename is the final bit after the directory if you're wondering,
so if the template was
C</tmp/KJJFKav/TemplateSandbox/TemplateSandbox.txt>
then you'd get
C</tmp/KJJFKav/TemplateSandbox> as C<$template_dir>, and
C<TemplateSandbox.txt> passed as the first argument to your
I<benchmark function>.

The I<benchmark function> should return the content of the processed template.

For example:

  sub benchmark_functions_for_disk_cache
  {
      my ( $self, $template_dir, $cache_dir ) = @_;
      my ( $cf, $chi );

      $cf = Cache::CacheFactory->new(
          storage    => { 'file' => { cache_root => $cache_dir, }, },
          );
      $chi = CHI->new(
          driver   => 'File',
          root_dir => $cache_dir,
          );

      return( {
          TS_CF =>
              sub
              {
                  my $t = Template::Sandbox->new(
                      cache         => $cf,
                      template_root => $template_dir,
                      template      => $_[ 0 ],
                      ignore_module_dependencies => 1,
                      );
                  $t->add_vars( $_[ 1 ] );
                  $t->add_vars( $_[ 2 ] );
                  ${$t->run()};
              },
          TS_CHI =>
              sub
              {
                  my $t = Template::Sandbox->new(
                      cache         => $chi,
                      template_root => $template_dir,
                      template      => $_[ 0 ],
                      ignore_module_dependencies => 1,
                      );
                  $t->add_vars( $_[ 1 ] );
                  $t->add_vars( $_[ 2 ] );
                  ${$t->run()};
              },
          } );
  }

Please see the section L</"Cache Types"> for a list of the
different I<cache types> and what restrictions apply to
the I<benchmark functions> in each.

=item B<< $syntax_type = Plugin->syntax_type() >>

This informative method should return the type of syntax this
I<template engine> uses.
Broadly speaking, most I<template engines> fall into either the
'mini-language' or 'embedded-perl' camps, so return one of those
two strings.

=item B<< $purity = Plugin->pure_perl() >>

This informative method should return C<1> if the
I<template engine> is written in pure perl, and C<0>
if the engine makes use of XS code, is a wrapper around a C
library or in some other way mandates the use of non-perl
dependencies.

The default method returns undef and will treat the I<engine>
as not being pure-perl.
This may raise a warning or error in future versions.

If a plugin has several benchmark names, some pure-perl and
some otherwise, this method should return a hashref of name
to C<0> or C<1> for the respective answers.

For example, from L<Template::Benchmark::Engines::TemplateTolkit>:

  sub pure_perl
  {
      return( {
          TT      => 1,
          TT_X    => 0,
          TT_XCET => 0,
          } );
  }

=back

=head2 Cache Types

Comparing a I<template engine> that's running with a memory cache to a
completely uncached I<engine> is like comparing apples with oranges, so
each I<cache type> is designed to simulate a different environment
in which the I<template engine> is running, this lets L<Template::Benchmark>
group results so that a fair comparison can be made between engines at
performing a similar task.

With this in mind, each I<cache type> has its own restrictions that
should be adhered to when writing a plugin.

Common to each I<cache type> is the requirement to accept two
seperate hashrefs of I<template variables>, and behave as if they
might be different between invocations of the I<benchmark function>.
(Currently the contents of the variable hashrefs do B<not> change,
however that may change in future versions, and regardless, they
should be treated as if they have changed each time.)

=over

=item uncached_string

This I<cache type> explicitly disallows caching of any kind, and
must take the template as the supplied scalar value and process it
"from scratch" each time.

This broadly simulates running in an uncached CGI environment if you're
thinking of web applications, or the performance of a cache-miss in
a cached environment.

=item uncached_disk

This I<cache type> explicitly disallows caching of any kind, and
must take the template as the contents of the supplied filename,
read it from disk freshly each time and process it "from scratch"
each time.

This broadly simulates running in an uncached CGI environment if you're
thinking of web applications, or the performance of a cache-miss in
a cached environment.

=item disk_cache

This I<cache type> requires that the template be read from disk,
from the filename given, and may cache intermediate stages on the
disk too.

No template data may be kept in-memory between invocations.

This broadly simulates running in a CGI environment with a disk
cache to store compiled templates between requests.

=item shared_memory_cache

This I<cache type> requires that the template be read from disk,
from the filename given, and may cache intermediate stages in shared
memory.

No template data may be kept in non-shared memory between invocations.

It's quite normal for I<template engines> not to provide shared memory
support, so not many plugins provide this I<cache type>.

This broadly simulates running in a mod_perl environment with the
templates loaded into a shared memory cache before the webserver
forks.

=item memory_cache

This I<cache type> requires that the template be read from disk,
from the filename given, and may cache intermediate stages in memory.

While template data may be stored in-memory, it must be accessed by
instantiating a new copy of the template engine with the provided
filename, and not simply by reusing an instance or compiled
subroutine reference from a previous run.

ie: The I<benchmark function> itself should store no stateful information.

This broadly simulates running in a mod_perl environment without
using shared memory.

An example:

  sub benchmark_functions_for_memory_cache
  {
      my ( $self, $template_dir, $cache_dir ) = @_;
      my ( @template_dirs );

      @template_dirs = ( $template_dir );

      return( {
          HT =>
              sub
              {
                  my $t = HTML::Template->new(
                      type              => 'filename',
                      path              => \@template_dirs,
                      source            => $_[ 0 ],
                      case_sensitive    => 1,
                      cache             => 1,
                      die_on_bad_params => 0,
                      );
                  $t->param( $_[ 1 ] );
                  $t->param( $_[ 2 ] );
                  $t->output();
              },
          } );
  }

As can be seen, on each invocation the same code is run, with
no stateful information carried between invocations.

=item instance_reuse

This I<cache type> requires that the template be read from disk,
from the filename given, and may cache intermediate stages in memory.

This I<cache type> should be provided B<only if> there is some
degree of reuse of data-structures from a previous invocation,
such as reusing a previously-created template instance, or a
compiled subroutine reference, by the I<benchmark function> itself.

For example, if the I<benchmark function> instantiates a copy of
the I<template engine> on the first run, loading the filename
given, and then stores that instance in a local variable, then
on subsequent invocations reuses that instance rather than starting
from the beginning each time.

Or, an instance is created, the template loaded and compiled to
a subroutine reference, that reference is stored, and subsequent
invocations resume from that point.

Some examples:

  sub benchmark_functions_for_instance_reuse
  {
      my ( $self, $template_dir, $cache_dir ) = @_;
      my ( $tt, $tt_x, $tt_xcet, @template_dirs );

      @template_dirs = ( $template_dir );

      $tt     = Template->new(
          STASH        => Template::Stash->new(),
          INCLUDE_PATH => \@template_dirs,
          );
      return( {
          TT =>
              sub
              {
                  my $out;
                  $tt->process( $_[ 0 ], { %{$_[ 1 ]}, %{$_[ 2 ]} }, \$out );
                  $out || $tt->error();
              },
          } );
  }

This example shows the L<Template::Toolkit> instance being reused
between invocations.

  sub benchmark_functions_for_instance_reuse
  {
      my ( $self, $template_dir, $cache_dir ) = @_;
      my ( $t );

      return( {
          TeMMHM =>
              sub
              {
                  $t = Text::MicroMason->new()->compile(
                      file => File::Spec->catfile( $template_dir, $_[ 0 ] )
                      )
                      unless $t;
                  $t->( ( %{$_[ 1 ]}, %{$_[ 2 ]} ) );
              },
          } );
  }

And this example shows that an intermediate stage is preserved
as a function reference on the first invocation, then subsequent
invocations just invoke that reference.

This I<cache type> simulates running in a mod_perl environment
with some form of memory caching, but the end-user of the template
system would need to write some DIY caching themselves,
and the benchmark doesn't include the overhead of just what that
caching might be.

=back

=head2 Template Features

Different I<template engines> support different I<template features>,
so L<Template::Benchmark> allows the person performing the benchmarks
to mix-and-match the features they wish to benchmark.

Those I<template engines> that support the feature will be benchmarked
and the end-user will be informed of which I<template engines> didn't
support which features.

To this end, L<Template::Benchmark> queries the plugin for the I<template
syntax> required to implement each feature.  That is, to generate the
correct output from the given I<template variables>, in the correct
manner.

To ensure that like-for-like comparisons are being made, there are
several variants of some basic I<template features>, aimed to reflect
nuances of common use.

=over

=item C<literal_text>

A chunk of literal text, dumped through to the output largely unchanged
from its form in the template. ("Largely unchanged" means unescaping
backslashes or the equivilent is fine.)

The block of literal text to be used is:

  foo foo foo foo foo foo foo foo foo foo foo foo
  foo foo foo foo foo foo foo foo foo foo foo foo
  foo foo foo foo foo foo foo foo foo foo foo foo
  foo foo foo foo foo foo foo foo foo foo foo foo
  foo foo foo foo foo foo foo foo foo foo foo foo

As produced by:

  join( "\n", ( join( ' ', ( 'foo' ) x 12 ) ) x 5 )

=item C<scalar_variable>

Interpolation of a I<template variable> named C<scalar_variable>.

=item C<hash_variable_value>

Interpolation of a I<template variable> stored in the hashref
named C<hash_variable> with key C<'hash_value_key'>.

=item C<array_variable_value>

Interpolation of a I<template variable> stored in the arrayref
named C<array_variable> with index C<2>.

=item C<deep_data_structure_value>

Interpolation of a I<template variable> stored in the hashref
named C<this> with nested keys C<'is'>, C<'a'>, C<'very'>, C<'deep'>,
C<'hash'>, C<'structure'>.

This I<feature> is designed to stress the speed that the I<template engine>
traverses deep data-structures.

=item C<array_loop_value>

=item C<array_loop_template>

Loop through the arrayref I<template variable> named C<array_loop>,
inserting each element into the template output in turn.

No delimiter is expected so if C<array_loop> had value

  [ 'one', 'two', 'three' ]

the output would look like

  onetwothree

The reason there's no delimiter between records is to keep the
template simple and to avoid any situations where differing
behaviour creeps in from different I<template engines>: for example
if a newline was output after each element, some I<template engines>
would insert (or trim) additional white space as part of the flow
control block, and while there may be ways to configure that
behaviour within the I<template engine>, that constitutes doing
additional work over that done by other I<engines> and would skew
the benchmark's result away from being I<just> the cost of doing
the loop.

The C<_value> version of this I<template feature> permits any
method of generating the content containing the value from the
array, whereas the C<_template> version requires that the output
be produced by a block of template.

An example of this distinction would be from
L<Template::Benchmark::Engines::TextTemplate>:

      array_loop_value          =>
          '{ $OUT .= $_ foreach @array_loop; }',

While a loop can be executed in the embedded perl, it can only
build a literal string to be inserted back into the template output,
there is no way to say that the loop means 'repeat this section of
template' like that allowed, for example, in L<Template::Toolkit>:

    array_loop_template       =>
        '[% FOREACH i IN array_loop %][% i %][% END %]',

While it may be possible to coerce some embedded perl examples to
do something similar by creating a new I<template engine> instance
and running a template fragment on it, that falls into the realms
of DIY solutions discussed in L</"Supported or Unsupported?">

This distinction is important because it determines how easy it is
to have large repeated sections of template without having to fall
back to generating them within perl (which is presumably what you
were trying to avoid by using a template system in the first place.)

=item C<hash_loop_value>

=item C<hash_loop_template>

Loop through the hashref I<template variable> named C<hash_loop>,
in alphabetic order of the keys, inserting each key and value into
the template output.

The key and value should be seperated by C<': '> but between
key/value pairs there's no delimiter.

  { 'one' => 1, 'two' => 2, 'three' => 3 }

would produce

  one: 1three: 3two: 2

The C<_value> and C<_template> versions of this
I<template feature> follow the same rules as documented
for C<array_loop_value> and C<array_loop_template>.

=item C<records_loop_value>

=item C<records_loop_template>

Loop across an arrayref of hashrefs, much like that returned from
a L<DBI> C<fetchall_arrayref( {} )>, for each 'record' output the
value of the C<'name'> and C<'age'> keys.

As with C<hash_loop_value>, a C<': '> seperates name from age, and
no delimiter between records.

  [
    { name => 'Andy MacAndy',  age => 12, },
    { name => 'Joe Jones',     age => 10, },
    { name => 'Jenny Jenkins', age => 11, },
  ]

would give

  Andy MacAndy: 12Joe Jones: 10Jenny Jenkins: 11

The C<_value> and C<_template> versions of this
I<template feature> follow the same rules as documented
for C<array_loop_value> and C<array_loop_template>.

=item C<constant_if_literal>

=item C<constant_if_template>

Conditionally choose to insert some content if a constant literal C<1>
is true.

In the case of C<constant_if_literal> the content is the literal text
C<'true'> and for C<constant_if_template> the content is the result of
a template block inserting the content of I<template variable>
C<template_if_true>.

The distinction between C<_literal> and C<_template> versions of this
test are similar to those between C<array_loop_value> and
C<array_loop_template>: the C<_template> version must result from
executing a block of the template markup rather than perl string
manipulation.

=item C<variable_if_literal>

=item C<variable_if_template>

Conditionally choose to insert some content if the I<template variable>
C<variable_if> is true.

In the case of C<variable_if_literal> the content is the literal text
C<'true'> and for C<variable_if_template> the content is the result of
a template block inserting the content of I<template variable>
C<template_if_true>.

The distinction between C<_literal> and C<_template> versions of this
test are similar to those between C<array_loop_value> and
C<array_loop_template>: the C<_template> version must result from
executing a block of the template markup rather than perl string
manipulation.

=item C<constant_if_else_literal>

=item C<constant_if_else_template>

Conditionally choose to insert some content if a constant literal C<1>
is true, or some other content if it's false.

In the case of C<constant_if_else_literal> the content is the literal text
C<'true'> for true, and C<'false'> for false, and for
C<constant_if_else_template> the content is the result of
a template block inserting the content of I<template variable>
C<template_if_true> if true, or C<template_if_false> if false.

The distinction between C<_literal> and C<_template> versions of this
test are similar to those between C<array_loop_value> and
C<array_loop_template>: the C<_template> version must result from
executing a block of the template markup rather than perl string
manipulation.

=item C<variable_if_else_literal>

=item C<variable_if_else_template>

Conditionally choose to insert some content if the I<template variable>
C<variable_if_else> is true, or some other content if it's false.

In the case of C<variable_if_else_literal> the content is the literal text
C<'true'> for true, and C<'false'> for false, and for
C<variable_if_else_template> the content is the result of
a template block inserting the content of I<template variable>
C<template_if_true> if true, or C<template_if_false> if false.

The distinction between C<_literal> and C<_template> versions of this
test are similar to those between C<array_loop_value> and
C<array_loop_template>: the C<_template> version must result from
executing a block of the template markup rather than perl string
manipulation.

=item C<constant_expression>

Insert the result of the constant expression C<10 + 12>.

Note that the template should actually calculate this, don't just put a
literal C<22> in the template, as the purpose of this I<feature> is to
determine if constants are subjected to constant-folding optimizations
by the I<template engine> and to give some indication of what gains
are made by the I<engine> in that situation.

=item C<variable_expression>

Insert the result of multiplying the I<template variables>
C<variable_expression_a> and C<variable_expression_b>, ie
doing:

  variable_expression_a * variable_expression_b

=item C<complex_variable_expression>

Insert the result of the following expression:

  ( ( variable_expression_a * variable_expression_b ) +
    variable_expression_a - variable_expression_b ) /
  variable_expression_b

Note that the brackets should be included, even if the I<template engine>
would sort out precedence correctly, because processing of brackets and
precedence is part of what is being benchmarked by this I<feature>.

Also note that the values of C<variable_expression_a> and
C<variable_expression_b> are chosen so that the entire operation acts
on integers and results in an integer value, so there is no need to
worry about different floating-point precisions or output formats.

This I<feature> is intended to be a slightly more stressful version of
C<variable_expression>, to allow comparision between the two results
to isolate the expression engine performance of a I<template engine>.

=item C<constant_function>

Perform a function call (or equivilent, such as vmethod) within a
template expression, on a constant literal.

The expression should do the equivilent of the perl:

  substr( 'this has a substring', 11, 9 )

Like the difference between C<constant_expression> and C<variable_expression>
this is to detect/benchmark any constant-folding optimizations.

=item C<variable_function>

Perform a function call (or equivilent, such as vmethod) within a
template expression, on the I<template variable> C<variable_function_arg>.

The expression should do the equivilent of the perl:

  substr( $variable_function_arg, 4, 2 )

=back

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl at illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Benchmark::Engine


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Benchmark>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Benchmark>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Benchmark>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Benchmark/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Paul Seamons for creating the the bench_various_templaters.pl
script distributed with L<Template::Alloy>, which was the ultimate
inspiration for this module.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Sam Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
