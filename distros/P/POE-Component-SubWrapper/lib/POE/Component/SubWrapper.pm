package POE::Component::SubWrapper;

=head1 NAME

POE::Component::SubWrapper - event based wrapper for subs

=head1 SYNOPSIS

  use POE::Component::SubWrapper;
  POE::Component::SubWrapper->spawn('main');
  $kernel->post('main', 'my_sub', [ $arg1, $arg2, $arg3 ], 'callback_state');

=head1 DESCRIPTION

This is a module which provides an event based wrapper for subroutines.


=head1 METHODS

=cut

use warnings;
use strict;

use Carp qw(croak);
use POE;
use Devel::Symdump;

use Exporter::Lite;
our @EXPORT = qw(poeize);


our $VERSION = '2.01';

use constant DEBUG => 0;

=head2 spawn

  POE::Component::SubWrapper->spawn('main');

SubWrapper components are not normal objects, but are instead 'spawned' as
separate sessions.  This is done with with PoCo::SubWrapper's 'spawn'
method, which takes one required and one optional argument.  The first
argument is the package name to wrap. This is required. The second argument
is optional and contains an alias to give to the session created. If no
alias is supplied, the package name is used as an alias.

=cut

sub spawn { #{{{
    DEBUG && print "PoCo::SubWrapper->spawn: Entering\n";
    
    my $type = shift;
    my $package = shift;
    my $alias = shift;

    croak "Too many args" if scalar @_;
    $alias = $package unless defined($alias) and length($alias);

    DEBUG && print "PoCo::SubWrapper->spawn: type = [$type], package = [$package], alias = [$alias]\n";

    # get subroutines defined by package.
    my @subs;

    my $sym = Devel::Symdump->new($package);
    {
        no strict 'refs';
        foreach my $function ($sym->functions) {
            *p = *$function;
            my $coderef = *p{CODE};
            my ($key) = ($function =~ /([^:]*)$/);

            use Data::Dumper;
            DEBUG && print "Symbol is $function\n";
            DEBUG && print "key is $key\n";
            DEBUG && print "Coderef is [", Dumper($coderef), "]\n";

            push @subs, { name => $key, code => $coderef };      
        }
    }

    my %states;
    foreach my $sub (@subs) {
        DEBUG && print "Building state for ", $sub->{name}, "\n";
        $states{$sub->{name}} = build_handler($package, $sub->{code});
    }

    $states{'_start'} = \&wrapper_start;
    $states{'_stop'} = sub {};

    my $s = POE::Session->create(
        inline_states => \%states,
        heap => {
            alias => $alias,
        }
    );
    return $s;
} #}}}


=head2 poeize

  poeize My::Package;

Another way to create SubWrapper components is to use the C<poeize> method,
which is included in the default export list of the package. You can simply
do:

  poeize Data::Dumper;

and Data::Dumper will be wrapped into a session with the alias
'Data::Dumper'.

=cut

sub poeize (*) { #{{{
  my $package = shift;
  spawn($package, $package);
} #}}}

=begin devel

=head2 wrapper_start

Sets our alias

=cut

sub wrapper_start { #{{{
    $_[KERNEL]->alias_set($_[HEAP]->{alias});
} #}}}


=head2 shutdown

Provides a way to forcibly shutdown our session. 
This is done by removing our alias. Assuming there are no events on the
queue for us, we should shut down immediately.

=cut

sub shutdown { #{{{
    $_[KERNEL]->alias_remove($_[HEAP]->{alias});
} #}}}

=head2 build_handler

return a closure that knows how to call the specified sub and post
the results back.

=cut

sub build_handler { #{{{
    my ($package, $sub) = @_;

    my $ref = sub {
        my ($kernel, $heap, $args_ref, $callback, $context, $sender) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, SENDER];
        warn Dumper($kernel->alias_list($_[SESSION]));
        DEBUG && print "Handler called for package=[$package], sub = [$sub]\n"; 
        
        my @sub_args = @$args_ref;
        my $result;
        #my $name = "${package}::${sub}";
        DEBUG && print "handler: calling [$sub]\n";
        
        if (defined($context) and $context eq 'SCALAR') {
            # scalar context. default if not supplied.
            DEBUG && print "handler: calling in scalar context\n";
            
            $result = scalar &{$sub}(@sub_args);
        } else {
            # array context.
            my @result;
            DEBUG && print "handler: calling in array context\n";
            @result = &{$sub}(@sub_args);
            $result = \@result;
        }

        $kernel->post($sender, $callback, $result);
        return;
    };

    return $ref;
} #}}}

1;

__END__

=end devel

=head1 STATES

When a SubWrapper component is created, it scans the package named for
subroutines, and creates one state in the session created with the same name
of the subroutine.

The states each accept 3 arguments:

=over 4

=item *

An arrayref to a list of arguments to give the subroutine.

=item *

A state to callback with the results.

=item *

A string, either 'SCALAR', or 'ARRAY', allowing you to decide which
context the function handled by this state will be called in.

The states all call the function with the name matching the state, and
give it the supplied arguments. They then postback the results to the named
callback state. The results are contained in C<ARG0> and are either a scalar
if the function was called in scalar context, or an arrayref of results
if the function was called in list context.

=back

=head1 EXAMPLES

The test scripts are the best place to look for examples of
POE::Component::Subwrapper usage. A short example is given here:

  use Data::Dumper;
  poeize Data::Dumper;
  $kernel->post('Data::Dumper', 'Dumper', [ { a => 1, b => 2 } ], 'callback_state', 'SCALAR');

  sub callback_handler {
    my $result = @_[ARG0];
    # do something with the string returned by Dumper({ a => 1, b => 2})
  }

Data::Dumper is the wrapped module, Dumper is the function called, C<{a =E<gt>
1, b =E<gt> 2}> is the data structure that is dumped, and C<$result> is the
resulting string form.

=head2 EXPORT

The module exports the following functions by default:

=over 4

=item C<poeize>

A function called with a single bareword argument specifying the package
to be wrapped.

=back

=head1 AUTHOR

Matt Cashner (sungo@pobox.com)

Michael Stevens - michael@etla.org

=head1 LICENSE

Copyright (c) 2000-2002 Michael Stevens

Copyright (c) 2002-2004 Matt Cashner

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

=over 4

=item * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.  

=item * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

=item * Neither the name of Matt Cashner nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# sungo // vim: ts=4 sw=4 et
