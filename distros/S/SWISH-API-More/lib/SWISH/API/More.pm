package SWISH::API::More;
use strict;
use warnings;
use SWISH::API;
use Carp;
use base qw( Class::Accessor::Fast );
use UNIVERSAL qw(isa);
use Class::ISA;
use Class::Inspector;

our $VERSION = '0.07';

my @subclasses = qw( Search Results Result FuzzyWord );
my %bases      = ();

__PACKAGE__->mk_accessors(
    qw(
      debug
      indexes
      log
      register
      )
);

for (@subclasses)
{
    my $p = join('::', __PACKAGE__, $_);
    eval "require $p";
    croak "can't load $p: $@" if $@;
}

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = bless({}, $class);
    $self->_init(@_);    # private init object
    $self->init(@_);     # public method
    return $self;
}

# private methods for class building
sub _set_log
{
    my $self = shift;
    unless (defined($self->log) && $self->log eq '0')
    {
        $self->{log} ||= *{STDERR};
    }
}

sub _parse_indexes
{
    my $self = shift;

    # pairs
    if (@_ and !(scalar(@_) % 2))
    {
        my %extra = @_;
        @$self{keys %extra} = values %extra;

        if (!ref $self->indexes)
        {
            $self->indexes([split(/\ +/, $self->indexes)]);
        }
    }

    # S::A style
    else
    {
        my $i = shift || 'index.swish-e';
        if (ref $i eq 'ARRAY')
        {
            $self->indexes($i);
        }
        else
        {
            $self->indexes([split(/\ +/, $i)]);
        }
    }
}

# placeholder in case subclass doesn't have one.
sub init { }

sub _init
{
    my $self = shift;
    $self->{_start} = time();
    $self->_set_log;
    $self->_parse_indexes(@_);
    $self->_register_subclasses;
    $self->setup;
    $self->_setup_subclasses;
    $self->handle(@{$self->indexes});
}

our $loaded = 0;

sub setup
{
    return if $loaded++;
    native_wrappers(
        [
            qw(
              IndexNames RankScheme Fuzzify HeaderNames
              HeaderValue AbortLastError Error ErrorString
              LastErrorMsg CriticalError
              WordsByLetter PropertyList MetaList
              )
        ],
        __PACKAGE__,
        'handle'
                   );
}

sub _register_subclasses
{

    # foreach subclass, find which one is first in ISA
    # and set that as the class->new() value for subclass()
    my $self = shift;
    my $base = ref($self);
    if (!exists $bases{$base} or $self->register)
    {
        my %map;
        my @isa = Class::ISA::self_and_super_path($base);

      SUBCLASS: for my $sc (@subclasses)
        {
          INC: for my $class (@isa)
            {
                my $package = join('::', $class, $sc);
                if (Class::Inspector->loaded($package))
                {
                    $map{$sc} = $package;
                    next SUBCLASS;
                }
            }
            if (!exists $map{$sc})
            {
                croak "no valid subclass for $sc";
            }
        }
        $bases{$base} = \%map;
    }
    $self->{_sam_subs} = $bases{$base};
}

sub _setup_subclasses
{

    # call setup() for each subclass()
    # NOTE that this allows real subclasses to override setup()
    # and then call SUPER::setup()
    # each of our @subclasses setup() should return if __PACKAGE__::loaded
    # so their setup() only happens once.
    my $self = shift;
  SC: for my $sc (@subclasses)
    {
        my $class = $self->whichnew($sc);
        $class->setup;
    }
}

sub handle
{
    my $self = shift;
    if (@_)
    {
        $self->{handle} = SWISH::API->new(join(' ', @_));
    }
    return $self->{handle};
}

sub die_on_error {
    my $self = shift;
    my $level = shift || 'error';
    die( join( ' : ', $self->{handle}->error_string, $self->{handle}->last_error_msg ) )
        if $self->{handle}->$level;
}

sub logger
{
    my $self = shift;
    return unless $self->log;
    my $t = join('', '[', scalar(localtime()), '] [', $$, ']');
    for (@_)
    {
        print {$self->log} "$t $_\n";
    }
}

sub _dispSymbols
{
    my ($hashRef) = shift;
    for (sort keys %$hashRef)
    {
        printf("%-20.20s| %s\n", $_, $hashRef->{$_});
    }
}

sub native_wrappers
{
    my ($meths, $class, $acc) = @_;
    no strict;
  M: for my $meth (@$meths)
    {
        *{"${class}::${meth}"} = sub {
            my $self = shift;
            return $self->$acc->$meth(@_);
        };

        my $friendly = SWISH::API::perlize($meth);

        *{"${class}::${friendly}"} = sub {
            my $self = shift;
            return $self->$acc->$meth(@_);
        };
    }

    #_dispSymbols(\%{$class . '::'});

}

sub whichnew
{
    my $self = shift;
    my $sub  = shift or croak "need SubClass name";
    my $s    = $self->{_sam_subs}->{$sub};
    return $s;
}

# "real" swish methods defined here
sub New_Search_Object { shift->search(@_) }
sub new_search_object { shift->search(@_) }

sub search
{
    my $self = shift;
    my $s    = $self->handle->New_Search_Object(@_);
    return $self->whichnew('Search')->new({search => $s, base => $self});
}

sub Query { shift->query(@_) }

sub query
{
    my $self = shift;
    my $r    = $self->handle->Query(@_);
    return $self->whichnew('Results')->new({results => $r, base => $self});
}

1;

__END__

=head1 NAME

SWISH::API::More - do more with the SWISH::API

=head1 SYNOPSIS

  # drop-in replacement for SWISH::API
  my $swish = SWISH::API::More->new('my/index.swish-e');
  
  # or subclass to do More
  package My::SwishAPI;
  use base qw( SWISH::API::More );
  
  sub init
  {
    my $self = shift;
    $self->SUPER::init(@_);    
  }
  
  sub do_something
  {
    my $self = shift;   # My::SwishAPI object
  }
  
  sub new_search_object
  {
    my $self = shift;
    my $swish_handle = $self->handle;
    
    # do something with $swish_handle
    # but make sure to return from superclass
    $self->SUPER::new_search_object(@_);
  }
  
  1;
    
  package main;
  
  my $swish = My::SwishAPI->new(
                indexes => [qw( path/to/index1 path/to/index2 )],
                log     => $a_filehandle
                );
                
  $swish->logger("opened a new swish-e handle");
  
  # use $swish just like you would with SWISH::API->new object.
  # only do More!
  

=head1 DESCRIPTION

SWISH::API::More is a base class for subclassing and extending SWISH::API.
Since SWISH::API is just a thin Perl XS wrapper around the Swish-e C library,
which isn't friendly for subclassing in a traditional Perlish way,
SWISH::API::More allows you to subclass SWISH::API like you would
a native Perl module.

Versions prior to 0.03 used ugly Symbol table mangling to achieve More
magic. This was not thread-safe, nor played nicely with multiple subclasses
using the same Perl process. Version 0.03 was a complete re-write.

=head1 REQUIREMENTS

L<SWISH::API>, L<Class::Accessor::Fast>, L<Class::Inspector>, L<Class::ISA>


=head1 METHODS

=head2 new( @I<args> )

Creates a new SWISH::API::More object.

I<args> may be either a string of space-separated index names (like SWISH::API uses)
or key/value pairs.

Example:

 my $swish = SWISH::API::More->new(
            indexes => [qw( my/index )],
            log   => *{STDERR},     # logger will print to stderr
            );
            
You can use the returned C<$swish> object just like a SWISH::API object. But you can
also use the defined methods in SWISH::API::More -- or create your own by subclassing
(see SYNOPSIS).

The new() method does a bunch of class magic to make sure the correct subclasses
are called. You can usually trust this to Just Work.

You probably don't want to override new() in a subclass. See init() instead.

=head2 init

If you subclass SWISH::API::More you'll likely
want to override init(). See L<SWISH::API::Stat> for an example.

init() is called internally by new() every time you create a new object. 
Override init() not new().


=head2 handle

Returns the SWISH::API handle. The handle is simply a SWISH::API object.
So this:

  my $s = SWISH::API->new;
  
and this:

  my $s = SWISH::API::More->new->handle;
  
give you the same thing. Except SWISH::API::More gives you More.

=head2 indexes

Get/set the indexes to which you connect with handle(). indexes() contains
an arrayref B<only>. The SWISH::API-style space-separated string feature in new()
is stored as an arrayref internally and that's what indexes() returns.


=head2 log

Get/set the filehandle that logger() prints to. Defaults to STDERR.
Set to C<0> to disable the default (but then don't expect logger() to work...).

=head2 logger( I<msg> )

Will print I<msg> to the filehandle set in log(). If log() is false, logger()
will just return and ignore I<msg>.

=head2 debug

Get/set the debugging flag. Default is 0 (off).

=head2 die_on_error([ I<error_name> ])

Convenience wrapper around the SWISH::API error handling methods. Will die()
with the last error messages if I<error_name> method returns true. I<error_name>
defaults to 'error'. Possible values include 'critical_error'. See SWISH::API.

=head2 register

This is a reserved accessor for use by subclasses that might want to create
subclasses during runtime. If you get that deeply into the code that you think
you might want to use register(), contact the author. Otherwise, just avoid creating
a method called B<register> in your subclasses of SWISH::API::More and you'll
not step on any toes you didn't mean to step on.

=head2 setup

This method is called for every subclass during new(). It is intended to run
only once per process. See the source code for how it is used. It is documented here
for the same reason register() is: it's a reserved method that you don't want
to override (accidentally or not) without knowing what you're doing.

=head2 search

Shortcut for new_search_object().

=head1 EXAMPLES

See the L<SWISH::API::Stat> module for a working example.

=head1 SEE ALSO

L<http://swish-e.org/>

L<SWISH::API>, L<SWISH::API::Stat>, L<SWISH::API::Object>

=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

Thanks to L<Atomic Learning|http://www.atomiclearning.com/> for supporting some
of the development of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
