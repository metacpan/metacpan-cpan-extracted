use strict;
use warnings;

package Package::Debug::Object;
BEGIN {
  $Package::Debug::Object::AUTHORITY = 'cpan:KENTNL';
}
{
  $Package::Debug::Object::VERSION = '0.2.2';
}

# ABSTRACT: Object oriented guts to Package::Debug


my %env_key_styles = ( default => 'env_key_from_package', );


my %env_key_prefix_styles = ( default => 'env_key_prefix_from_package', );


my %log_prefix_styles = (
  short => 'log_prefix_from_package_short',
  long  => 'log_prefix_from_package_long',
);


my %debug_styles = (
  'prefixed_lines' => 'debug_prefixed_lines',
  'verbatim'       => 'debug_verbtaim',
);


sub new {
  my ( $self, %args ) = @_;
  return bless \%args, $self;
}


sub debug_style {
  return $_[0]->{debug_style} if exists $_[0]->{debug_style};
  return ( $_[0]->{debug_style} = 'prefixed_lines' );
}

sub set_debug_style {
  $_[0]->{debug_style} = $_[1];
  return $_[0];
}


sub env_key_aliases {
  return $_[0]->{env_key_aliases} if exists $_[0]->{env_key_aliases};
  return ( $_[0]->{env_key_aliases} = [] );
}

sub set_env_key_aliases {
  $_[0]->{env_key_aliases} = $_[1];
  return $_[0];
}


sub env_key_prefix_style {
  return $_[0]->{env_key_prefix_style} if exists $_[0]->{env_key_prefix_style};
  return ( $_[0]->{env_key_prefix_style} = 'default' );
}

sub set_env_key_prefix_style {
  $_[0]->{env_key_prefix_style} = $_[1];
  return $_[0];
}


sub env_key_style {
  return $_[0]->{env_key_style} if exists $_[0]->{env_key_style};
  return ( $_[0]->{env_key_style} = 'default' );
}

sub set_env_key_style {
  $_[0]->{env_key_style} = $_[1];
  return $_[0];
}


sub into {
  return $_[0]->{into} if exists $_[0]->{into};
  die 'Cannot vivify ->into automatically, pass to constructor or ->set_into() or ->auto_set_into()';
}

sub set_into {
  $_[0]->{into} = $_[1];
  return $_[0];
}


sub into_level {
  return $_[0]->{into_level} if exists $_[0]->{into_level};
  return ( $_[0]->{into_level} = 0 );
}

sub set_into_level {
  $_[0]->{into_level} = $_[1];
  return $_[0];
}


sub sub_name {
  return $_[0]->{sub_name} if exists $_[0]->{sub_name};
  return ( $_[0]->{sub_name} = 'DEBUG' );
}

sub set_sub_name {
  $_[0]->{sub_name} = $_[1];
  return $_[0];
}


sub value_name {
  return $_[0]->{value_name} if exists $_[0]->{value_name};
  return ( $_[0]->{value_name} = 'DEBUG' );
}

sub set_value_name {
  $_[0]->{value_name} = $_[1];
  return $_[0];
}


sub env_key {
  return $_[0]->{env_key} if exists $_[0]->{env_key};
  my $style = $_[0]->env_key_style;
  if ( not exists $env_key_styles{$style} ) {
    die "No such env_key_style $style, options are @{ keys %env_key_styles }";
  }
  my $method = $env_key_styles{$style};
  return ( $_[0]->{env_key} = $_[0]->$method() );
}

sub set_env_key {
  $_[0]->{env_key} = $_[1];
  return $_[0];
}


sub env_key_prefix {
  return $_[0]->{env_key_prefix} if exists $_[0]->{env_key_prefix};
  my $style = $_[0]->env_key_prefix_style;
  if ( not exists $env_key_prefix_styles{$style} ) {
    die "No such env_key_prefix_style $style, options are @{ keys %env_key_prefix_styles }";
  }
  my $method = $env_key_prefix_styles{$style};
  return ( $_[0]->{env_key_prefix} = $_[0]->$method() );
}

sub set_env_key_prefix {
  $_[0]->{env_key_prefix} = $_[1];
  return $_[0];
}


sub debug_sub {
  return $_[0]->{debug_sub} if exists $_[0]->{debug_sub};
  my $style = $_[0]->debug_style;
  if ( not exists $debug_styles{$style} ) {
    die "No such debug_style $style, options are @{ keys %debug_styles }";
  }
  my $method = $debug_styles{$style};
  return ( $_[0]->{debug_sub} = $_[0]->$method() );
}

sub set_debug_sub {
  $_[0]->{debug_sub} = $_[1];
  return $_[0];
}


sub log_prefix_style {
  return $_[0]->{log_prefix_style} if exists $_[0]->{log_prefix_style};
  my $style = 'short';
  $style = $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE} if $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE};
  return ( $_[0]->{log_prefix_style} = $style );
}

sub set_log_prefix_style {
  $_[0]->{log_prefix_style} = $_[1];
  return $_[0];
}


sub log_prefix {
  return $_[0]->{log_prefix} if exists $_[0]->{log_prefix};
  my $style = $_[0]->log_prefix_style;
  if ( not exists $log_prefix_styles{$style} ) {
    die "Unknown prefix style $style, should be one of @{ keys %log_prefix_styles }";
  }
  my $method = $log_prefix_styles{$style};
  return ( $_[0]->{log_prefix} = $_[0]->$method() );
}

sub set_log_prefix {
  $_[0]->{log_prefix} = $_[1];
  return $_[0];
}


sub is_env_debugging {
  return $_[0]->{is_env_debugging} if exists $_[0]->{is_env_debugging};
  if ( $ENV{PACKAGE_DEBUG_ALL} ) {
    return ( $_[0]->{is_env_debugging} = 1 );
  }
  for my $key ( $_[0]->env_key, @{ $_[0]->env_key_aliases } ) {
    next unless exists $ENV{$key};
    next unless $ENV{$key};
    return ( $_[0]->{is_env_debugging} = 1 );
  }
  return ( $_[0]->{is_env_debugging} = 0 );
}

sub set_is_env_debugging {
  $_[0]->{is_env_debugging} = $_[1];
  return $_[0];
}


sub into_stash {
  return $_[0]->{into_stash} if exists $_[0]->{into_stash};
  require Package::Stash;
  return ( $_[0]->{into_stash} = Package::Stash->new( $_[0]->into ) );
}

sub set_into_stash {
  $_[0]->{into_stash} = $_[1];
  return $_[0];
}


sub auto_set_into {
  my ( $self, $add ) = @_;
  $_[0]->{into} = [ caller( $self->into_level + $add ) ]->[0];
  return $self;
}


# Note: Heavy hand-optimisation going on here, this is the hotpath
sub debug_prefixed_lines {
  my $self   = shift;
  my $prefix = $self->log_prefix;
  return sub {
    my (@message) = @_;
    for my $line (@message) {
      *STDERR->print( '[' . $prefix . '] ' ) if defined $prefix;
      *STDERR->print($line);
      *STDERR->print("\n");
    }
  };
}


sub debug_verbatim {
  my $self = shift;
  return sub {
    *STDERR->print(@_);
  };
}


sub env_key_from_package {
  return $_[0]->env_key_prefix() . '_DEBUG';
}


sub env_key_prefix_from_package {
  my $package = $_[0]->into;
  $package =~ s{
    ::
  }{_}msxg;
  return uc $package;
}


sub log_prefix_from_package_short {
  my $package = $_[0]->into;
  if ( ( length $package ) < 10 ) {
    return $package;
  }
  my (@tokens) = split /::/msx, $package;
  my ($suffix) = pop @tokens;
  for (@tokens) {
    if ( $_ =~ /[[:upper:]]/msx ) {
      $_ =~ s/[[:lower:]]+//msxg;
      next;
    }
    $_ = substr $_, 0, 1;
  }
  my ($prefix) = join q{:}, @tokens;
  return $prefix . q{::} . $suffix;
}


sub log_prefix_from_package_long {
  return $_[0]->into;
}


sub inject_debug_value {
  my $value_name = $_[0]->value_name;
  return if not defined $value_name;
  my $value = $_[0]->is_env_debugging;
  my $stash = $_[0]->into_stash;
  if ( $stash->has_symbol( q[$] . $value_name ) ) {
    $value = $stash->get_symbol( q[$] . $value_name );
    $stash->remove_symbol( q[$] . $value_name );
  }
  $stash->add_symbol( q[$] . $value_name, \$value );
  return $_[0];
}

sub _wrap_debug_sub {
  my $sub_name = $_[0]->sub_name;
  return if not defined $sub_name;
  my $value_name       = $_[0]->value_name;
  my $is_env_debugging = $_[0]->is_env_debugging;
  if ( not defined $value_name and not $is_env_debugging ) {
    return sub { };
  }
  my $real_debug = $_[0]->debug_sub;
  my $symbol     = $_[0]->into_stash->get_symbol( q[$] . $value_name );
  return sub {
    return unless ${$symbol};
    goto $real_debug;
  };
}


sub inject_debug_sub {
  $_[0]->into_stash->add_symbol( q[&] . $_[0]->sub_name, $_[0]->_wrap_debug_sub );
  return $_[0];
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Package::Debug::Object - Object oriented guts to Package::Debug

=head1 VERSION

version 0.2.2

=head1 METHODS

=head2 C<new>

    my $object = Package::Debug::Object->new(%args);

=head2 C<debug_style>

=head2 C<set_debug_style>

=head2 C<env_key_aliases>

=head2 C<set_env_key_aliases>

=head2 C<env_key_prefix_style>

=head2 C<set_env_key_prefix_style>

=head2 C<env_key_style>

=head2 C<set_env_key_style>

=head2 C<into>

=head2 C<set_into>

=head2 C<into_level>

=head2 C<set_into_level>

=head2 C<sub_name>

=head2 C<set_sub_name>

=head2 C<value_name>

=head2 C<set_value_name>

=head2 C<env_key>

=head2 C<set_env_key>

=head2 C<env_key_prefix>

=head2 C<set_env_key_prefix>

=head2 C<debug_sub>

=head2 C<set_debug_sub>

=head2 C<log_prefix_style>

=head2 C<set_log_prefix_style>

=head2 C<log_prefix>

=head2 C<set_log_prefix>

=head2 C<is_env_debugging>

=head2 C<set_is_env_debugging>

=head2 C<into_stash>

=head2 C<set_into_stash>

=head2 C<auto_set_into>

This method any plumbing will want to call.

    $object->auto_set_into( $number_of_additional_stack_levels );

Takes a parameter to indicate the expected additional levels of stack will be need.

For instance:

    sub import {
        my ($self, %args ) = @_;
        my $object = ...->new(%args);
        $object->auto_set_into(1); # needs to be bound to the caller to import->()
    }

Or

    sub import {
        my ($self, %args ) = @_;
        my $object = ...->new(%args);
        __PACKAGE__->bar($object);

    }
    sub bar {
        $_[1]->auto_set_into(2); # skip up to caller of bar, then to caller of import
    }

And in both these cases, the end user just does:

    package::bar->import( into_level =>  0 ); # inject at this level

=head2 C<debug_prefixed_lines>

    my $code = $object->debug_prefixed_lines;
    $code->( $message );

This Debug implementation returns a C<DEBUG> sub that treats all arguments as lines of message,
and formats them as such:

    [SomePrefix::Goes::Here] this is your messages first line\n
    [SomePrefix::Goes::Here] this is your messages second line\n

The exact prefix used is determined by L<< C<log_prefix>|/log_prefix >>,
and the prefix will be omitted if C<log_prefix> is not defined.

( Note: this will likely require explicit passing of

    log_prefix => undef

)

=head2 C<debug_verbatim>

This Debug implementation returns a C<DEBUG> sub that simply
passes all parameters to C<< *STDERR->print >>, as long as debugging is turned on.

    my $code = $object->debug_verbatim;
    $code->( $message );

=head2 C<env_key_from_package>

This C<env_key_style> simply appends C<_DEBUG> to the C<env_key_prefix>

    my $key = $object->env_key_from_package;

=head2 C<env_key_prefix_from_package>

This L<< C<env_key_prefix_style>|/env_prefix_style >> converts L<< C<into>|/into >> to a useful C<%ENV> name.

    Hello::World::Bar -> HELLO_WORLD_BAR

Usage:

    my $prefix = $object->env_key_prefix_from_package;

=head2 C<log_prefix_from_package_short>

This L<< C<log_prefix_style>|/log_prefix_style >> determines a C<short> name by mutating C<into>.

When the name is C<< <10 chars >> it is passed unmodified.

Otherwise, it is tokenised, and all tokens bar the last are reduced to either

=over 4

=item a - groups of upper case only characters

=item b - failing case a, single lower case characters.

=back

    Hello -> H
    HELLO -> HELLO
    DistZilla -> DZ
    mutant -> m

And then regrouped and the last attached

    This::Is::A::Test -> T:I:A::Test
    NationalTerrorismStrikeForce::SanDiego::SportsUtilityVehicle -> NTSF:SD::SportsUtilityVehicle

Usage:

    my $prefix = $object->log_prefix_from_package_short;

=head2 C<log_prefix_from_package_long>

This L<< C<log_prefix_style>|/log_prefix_style >> simply returns C<into> as-is.

Usage:

    my $prefix = $object->log_prefix_from_package_long;

=head2 C<inject_debug_value>

Optimistically injects the desired C<$DEBUG> symbol into the package determined by C<value_name>.

Preserves the existing value if such a symbol already exists.

    $object->inject_debug_value();

=head2 C<inject_debug_sub>

Injects the desired code reference C<DEBUG> symbol into the package determined by C<sub_name>

    $object->inject_debug_sub();

=head1 ATTRIBUTES

=head2 C<debug_style>

The debug printing style to use.

    'prefixed_lines'

See L<< C<debug_styles>|/debug_styles >>

=head2 C<env_key_aliases>

A C<[]> of C<%ENV> keys that also should trigger debugging on this package.

    []

=head2 C<env_key_prefix_style>

The mechanism for determining the C<prefix> for the C<%ENV> key.

    'default'

See  L<< C<env_key_prefix_styles>|/env_key_prefix_styles >>

=head2 C<env_key_style>

The mechanism for determining the final C<%ENV> key for turning on debug.

    'default'

See L<< C<env_key_styles>|/env_key_styles >>

=head2 C<into>

The package we're injecting into.

B<IMPORTANT>: This field cannot vivify itself and be expected to work.

Because much code in this module depends on this field,
if this field is B<NOT> populated explicitly by the user, its likely
to increase the stack depth, invalidating any value if L<< C<into_level>|/into_level >> that was specified.

See L<< C<auto_set_into>|/auto_set_into >>

=head2 C<into_level>

The number of levels up to look for C<into>

Note, that this value is expected to be provided by a consuming class somewhere, and is expected to be
simply passed down from a user.

See  L<< C<auto_set_into>|/auto_set_into >> for how to set C<into> sanely.

=head2 C<sub_name>

The name of the C<CODEREF> that will be installed into C<into>

    'DEBUG'

=head2 C<value_name>

The name of the C<$SCALAR> that will be installed into C<into>

    'DEBUG' ## $DEBUG

=head2 C<env_key>

The name of the primary C<%ENV> key that controls debugging of this package.

If unspecified, will be determined by the L<< C<env_key_style>|/env_key_style >>

Usually, this will be something like

    <env_key_prefix>_DEBUG

And where C<env_key_prefix> is factory,

    <magictranslation(uc(into))>_DEBUG

Aka:

    SOME_PACKAGE_NAME_DEBUG

=head2 C<env_key_prefix>

The name of the B<PREFIX> to use for C<%ENV> keys for this package.

If unspecified, will be determined by the L<< C<env_key_prefix_style>|/env_key_prefix_style >>

Usually, this will be something like

    <magictranslation(uc(into))>

Aka:

    SOME_PACKAGE_NAME

=head2 C<debug_sub>

The actual code ref to install to do the real debugging work.

This is mostly an implementation detail, but if you were truly insane, you could pass a custom C<coderef>
to construction, and it would install the C<coderef> you passed instead of the one we generate.

Generated using L<< C<debug_style>|/debug_style >>

=head2 C<log_prefix_style>

The default style to use for C<log_prefix>.

If not set, defaults to the value of C<$ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE}> if it exists,
or simply C<'short'> if it does not.

See L<< C<log_prefix_styles>|/log_prefix_styles >>

=head2 C<log_prefix>

The string to prefix to log messages for debug implementations which use prefixes.

If not specified, will be generated from the style specified by L<< C<log_prefix_style>|/log_prefix_style >>

Which will be usually something like

    Foo::Package::Bar # 'long'
    F:P::Bar          # 'short'

=head2 C<is_env_debugging>

The determination as to whether or not the C<%ENV> indicates debugging should be enabled.

Will always be C<true> if C<$ENV{PACKAGE_DEBUG_ALL}>

And will be C<true> if either L<< C<env_key>|/env_key >> or one of L<< C<env_key_aliases>|/env_key_aliases >>
is C<true>.

B<NOTE:> This value I<BINDS> the first time it is evaluated, so for granular control of debugging at run-time,
you should not be lexically changing C<%ENV>.

Instead, you should be modifying the value of C<$My::Package::Name::DEBUG>

=head2 C<into_stash>

Contains a L<< C<Package::Stash>|Package::Stash >> object for the target package.

=head1 STYLES

=head2 C<env_key_styles>

=head3 C<default>

Uses L<< C<env_key_from_package>|/env_key_from_package >>

=head2 C<env_key_prefix_styles>

=head3 C<default>

Uses L<< C<env_key_prefix_from_package>|/env_key_prefix_from_package >>

=head2 C<log_prefix_styles>

=head3 C<short>

Uses L<< C<log_prefix_from_package_short>|/log_prefix_from_package_short >>

=head3 C<long>

Uses L<< C<log_prefix_from_package_long>|/log_prefix_from_package_long >>

=head2 C<debug_styles>

=head3 C<prefixed_lines>

Uses L<< C<debug_prefixed_lines>|/debug_prefixed_lines >>

=head3 C<verbatim>

Uses L<< C<debug_verbatim>|/debug_verbatim >>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Package::Debug::Object",
    "interface":"class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
