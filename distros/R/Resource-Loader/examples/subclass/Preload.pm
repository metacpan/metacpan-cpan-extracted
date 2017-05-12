# Preloaded.pm - subclass Resource::Loader to simplify usage
#
# Joshua Keroes - 25 Apr 2003
#
# Subclassing Resource::Loader lets you use the same set of
# resources in multiple applications. Write once, use everywhere.
# It also makes the target code cleaner. See the adjoining
# file, preload.pl for usage.

package Preloaded;

use strict;
use base qw/Resource::Loader/;

# In:  The same args you might give Resource::Loader::new()
# Out: Resource::Loader::loaded() output
#
# This new() works differently than the one in Resource::Loader.
# Resource::Loader returns an object. Here, we just want the 
# results so I just cut to the chase, run load(), and return
# the results.
sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    bless $self, $class;

    my $parent = $self->SUPER::new(
         testing => 0,
         verbose => 0,
         cont    => 0,
         resources =>
           [
             { name => 'never',
               when => sub { 0 },
               what => sub { die "this will never be loaded" },
             },
             { name => 'sometimes',
               when => sub { int rand 2 > 0 }, # true 50% of the time
               what => sub { "'sometimes' was loaded. args: [@_]" },
               args => [ qw/foo bar baz/ ],
             },
             { name => 'always',
               when => sub { 1 },
               what => sub { "'always' was loaded" },
             },
           ],
	@_, # override the above with any user-provided args
    );

    # Don't need the keys (the state names), just the values (the resources).
    return values %{ $parent->load };
}

1; # do not delete this line
