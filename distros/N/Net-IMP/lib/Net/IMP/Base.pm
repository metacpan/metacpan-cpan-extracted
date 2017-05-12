use strict;
use warnings;

package Net::IMP::Base;
use Net::IMP qw(:DEFAULT IMP_PASS_IF_BUSY);
use Carp 'croak';
use fields (
    'factory_args', # arguments given to new_factory
    'meta',         # hash with meta data given to new_analyzer
    'analyzer_cb',  # callback, set from new_analyzer or with set_callback
    'analyzer_rv',  # collected results for polling or callback, set
		    # from add_results
    'ignore_rv',    # hash with return values like IMP_PAUSE or
		    # IMP_REPLACE_LATER which are unsupported by the data
		    # provider and can be ignored
    'busy',         # if data provider is busy
);

use Net::IMP::Debug;


############################################################################
# API plugin methods
############################################################################

# creates new factory
sub new_factory {
    my ($class,%args) = @_;
    my Net::IMP::Base $factory = fields::new($class);
    $factory->{factory_args} = \%args;
    return $factory;
}

# make string from hash config, using URL encoding to escape special chars
sub cfg2str {
    my (undef,%cfg) = @_;
    return join('&', map {
	my $v = $cfg{$_};
	# only encode really necessary stuff
	s{([=&%\x00-\x20\x7f-\xff])}{ sprintf("%%%02X",ord($1)) }eg; # key
	if ( defined $v ) { # value
	    $v =~s{([&%\x00-\x20\x7f-\xff])}{ sprintf("%%%02X",ord($1)) }eg;
	    "$_=$v"
	} else {
	    "$_"
	}
    } sort keys %cfg);
}

# make has config from string created by cfg2str
sub str2cfg {
    my (undef,$str) = @_;
    my %cfg;
    for my $kv (split('&',$str)) {
	my ($k,$v) = $kv =~m{^([^=]+)(?:=(.*))?};
	$k =~s{%([\dA-F][\dA-F])}{ chr(hex($1)) }ieg;
	exists $cfg{$k} and croak "duplicate definition for key $k";
	$v =~s{%([\dA-F][\dA-F])}{ chr(hex($1)) }ieg if defined $v;
	$cfg{$k} = $v;
    }
    return %cfg;
}

# validate config, return list of errors
sub validate_cfg {
    my (undef,%cfg) = @_;
    delete $cfg{eventlib}; # accepted everywhere
    return %cfg ? "unexpected config keys ".join(', ',keys %cfg) : ();
}

############################################################################
# API factory methods
############################################################################

# create new analyzer
sub new_analyzer {
    my Net::IMP::Base $factory = shift;
    my %args = @_;
    my $cb = delete $args{cb};

    my $analyzer = fields::new(ref($factory));
    %$analyzer = (
	%$factory,          # common properties of all analyzers
	%args,              # properties of this analyzer
	analyzer_rv => [],  # reset queued return values
	busy => undef,      # busy per dir
    );
    $analyzer->set_callback(@$cb) if $cb;
    return $analyzer;
}

# get available interfaces
# returns factory for the given interface
# might be a new one or same as called on
sub set_interface {
    my Net::IMP::Base $factory = shift;
    my $want = shift;
    my ($if) = $factory->get_interface($want) or return;

    my %ignore = map { $_+0 => $_ }
	( IMP_PAUSE, IMP_CONTINUE, IMP_REPLACE_LATER );
    delete @ignore{ map { $_+0 } @{$if->[1]}};
    $factory->{ignore_rv} = %ignore ? \%ignore : undef;

    if ( my $adaptor = $if->[2] ) {
	# use adaptor
	return $adaptor->new_factory(factory => $factory)
    } else {
	return $factory
    }
}

# returns list of available [ if, adaptor_class ], restricted by given  @if
sub INTERFACE { die "needs to be implemented" }
sub get_interface {
    my Net::IMP::Base $factory = shift;
    my @local = $factory->INTERFACE;

    # return all supported interfaces if none are given
    return @local if ! @_;

    # find matching interfaces
    my @match;
    for my $if (@_) {
	my ($in,$out) = @$if;
	for my $lif (@local) {
	    my ($lin,$lout,$adaptor) = @$lif;
	    if ( $lin and $lin != $in ) {
		# no match data type/proto
		debug("data type mismatch: want $in have $lin");
		next;
	    }

	    if ( ! $out || ! @$out ) {
		# caller will accept any return types
	    } else {
		# any local return types from not in out?
		my %lout = map { $_ => 1 } ( @$lout, IMP_FATAL );
		delete @lout{
		    @$out,
		    # these don't need to be supported
		    (IMP_PAUSE, IMP_CONTINUE, IMP_REPLACE_LATER)
		};
		if ( %lout ) {
		    # caller does not support all return types
		    debug("no support for return types ".join(' ',keys %lout));
		    next;
		}
	    }

	    if ( $adaptor ) {
		# make sure adaptor class exists
		if ( ! eval "require $adaptor" ) {
		    debug("failed to load $adaptor: $@");
		    next;
		}
	    }

	    # matches
	    push @match, [ $in,$out,$adaptor ];
	    last;
	}
    }

    return @match;
}

############################################################################
# API analyzer methods
############################################################################

# set callback
sub set_callback {
    my Net::IMP::Base $analyzer = shift;
    my ($sub,@args) = @_;
    $analyzer->{analyzer_cb} = $sub ? [ $sub,@args ]:undef;
    $analyzer->run_callback if $analyzer->{analyzer_rv};
}

# return queued results
sub poll_results {
    my Net::IMP::Base $analyzer = shift;
    my $rv = $analyzer->{analyzer_rv};
    $analyzer->{analyzer_rv} = [];
    return @$rv;
}

sub data { die "needs to be implemented" }

sub busy {
    my Net::IMP::Base $analyzer = shift;
    my ($dir,$busy) = @_;
    if ( $busy ) {
	return if $analyzer->{busy}
	    && $analyzer->{busy}[$dir]; # no change - stay busy
	$analyzer->{busy}[$dir] = 1; # unbusy -> busy
    } elsif ( ! $analyzer->{busy}
	|| ! $analyzer->{busy}[$dir] ) {
	return; # no change - stay not busy
    } else {
	# set to no busy on $dir, maybe no busy at all
	$analyzer->{busy}[$dir] = 0;  # busy -> unbusy
	if ( ! grep { $_ } @{$analyzer->{busy}} ) {
	    # all dir are not busy anymore
	    $analyzer->{busy} = undef;
	}
    }

    # run callback, either for important stuff on busy or for
    # all stuff if not busy
    $analyzer->run_callback;
}


############################################################################
# internal analyzer methods
############################################################################

sub add_results {
    my Net::IMP::Base $analyzer = shift;
    if ( my $ignore = $analyzer->{ignore_rv} ) {
	push @{$analyzer->{analyzer_rv}}, grep { ! $ignore->{$_->[0]+0} } @_;
    } else {
	push @{$analyzer->{analyzer_rv}},@_;
    }
}

{
    my %important = do {
	my $p = IMP_PASS_IF_BUSY;
	map { $p->[$_]+0 => $_+1 } (0..$#$p)
    };

    sub run_callback {
	my Net::IMP::Base $analyzer = shift;
	my $rv = $analyzer->{analyzer_rv}; # get collected results
	if (@_) {
	    # add more results
	    if ( my $ignore = $analyzer->{ignore_rv} ) {
		push @$rv, grep { ! $ignore->{$_->[0]+0} } @_;
	    } else {
		push @$rv,@_;
	    }
	}
	if ( my $cb = $analyzer->{analyzer_cb} ) {
	    my ($sub,@args) = @$cb;
	    if ( my $busy = $analyzer->{busy} ) {
		# at least one dir is busy
		my (@important,@nobusy,@busy);
		for( @$rv ) {
		    if ( my $lvl = $important{ $_->[0]+0 } ) {
			push @important,[ $_, $lvl ]
		    } elsif ( $busy->[$_->[1]] ) {
			push @busy,$_
		    } else {
			push @nobusy,$_
		    }
		}
		# sort by importance
		@important =
		    map { $_->[0] } sort { $a->[1] <=> $b->[1] } @important
		    if @important;
		if (@nobusy || @important) {
		    $analyzer->{analyzer_rv} = \@busy;
		    $sub->(@args,@important,@nobusy);
		} else {
		    # nothing important enough to call back
		}
	    } elsif (@$rv) {
		$analyzer->{analyzer_rv} = []; # reset
		$sub->(@args,@$rv); # and call back
	    }
	}
    }
}


1;
__END__

=head1 NAME

Net::IMP::Base - base class to make writing of Net::IMP analyzers easier

=head1 SYNOPSIS

    package myPlugin;
    use base 'Net::IMP::Base';
    use fields qw(... local fields ...);

    # plugin methods
    # sub new_factory ...  - has default implementation
    # sub cfg2str ...      - has default implementation
    # sub str2cfg ...      - has default implementation
    sub validate_cfg ...   - needs to be implemented

    # factory methods
    sub INTERFACE ...      - needs to be implemented
    # sub get_interface .. - has default implementation using sub INTERFACE
    # sub set_interface .. - has default implementation using sub INTERFACE
    # sub new_analyzer ... - has default implementation

    # analyzer methods
    sub data ...           - needs to be implemented
    # sub poll_results ... - has default implementation
    # sub set_callback ... - has default implementation

=head1 DESCRIPTION

C<Net::IMP::Base> is a class to make it easier to write IMP analyzers.
It can not be used on its own but should be used as a base class in new
analyzers.

It provides the following interface for the global plugin API as required for
all L<Net::IMP> plugins.

=over 4

=item cfg2str|str2cfg

These functions are used to convert a C<%config> to or from a C<$string>.
In this implementation the <$string> is a single line, encoded similar to the
query_string in HTTP URLs.

There is no need to re-implement this function unless you want to serialize the
config into a different format.

=item $class->validate_cfg(%config) -> @errors

This function is used to verify the config and thus should be re-implemented in
each sub-package. It is expected to return a list of errors or an empty list if
the config has no errors.

The only valid entry for %config in the implementation in this package is
C<eventlib>, which provides a way for analyzers to hook into the data providers
event handling.
If there are any other entries are left in C<%config> it will complain.
Thus all arguments specific to the derived analyzer should be handled in a
derived C<validate_cfg> method and removed from C<%config> before calling the
method in this base class.

=item $class->new_factory(%args)

This function is used to create a new factory class.
C<%args> will be saved into C<$factory->{factory_args}> and later used when
creating the analyzer.
There is usually no need to re-implement this method.

The only argument provided by some data providers to this base class is
C<eventlib>, which provides an interface to the data providers event handling.
It must be defined as an object with the following API, so that analyzers can
hook into it:

=over 8

=item $ev->onread( filehandle,[ callback ])

Sets or removes callback for read events on filehandle.

=item $ev->onwrite( filehandle,[ callback ])

Sets or removes callback for write events on filehandle.

=item $ev->timer( after, callback, [ interval ])

Sets C<callback> to be executed after C<after> seconds.
Reschedules timer afterwards every C<interval> seconds if C<interval> is given.
Returns object which must be preserved by the caller, the timer will be
cancelled if the object gets undefined.

=item $ev->now

Returns the eventlibs idea of the current time.

=back

If C<eventlib> is not given some classes might refuse creation of the factory
object.

=back

The following methods are implemented on factory objects as required by
L<Net::IMP>:

=over 4

=item $factory->get_interface(@caller_if) => @plugin_if

This method provides an implementation of the C<get_interface> API function.
This implementation requires the implementation of a function C<INTERFACE> like
this:

  sub INTERFACE { return (
    [
      # require HTTP data types
      IMP_DATA_HTTP,          # input data types/protocols
      [ IMP_PASS, IMP_LOG ]   # output return types
    ],[
      # we can handle stream data too if we use a suitable adaptor
      IMP_DATA_STREAM,
      [ IMP_PASS, IMP_LOG ],
      'Net::IMP::Adaptor::STREAM2HTTP',
    ]
  )}

There is no need to re-implement method C<get_interface>, but C<INTERFACE>
should be implemented.
If your plugin can handle any data types you can set the type to C<undef>
in the interface description.

=item $factory->set_interface($want_if) => $new_factory

This method provides an implementation of the C<set_interface> API function.
This implementation requires the implementation of C<INTERFACE> like described
for C<get_interface>.
There is no need to re-implement method C<set_interface>, but C<INTERFACE>
should be implemented.

=item $factory->new_analyzer(%args)

This method is called from C<<$factory->new_analyzer(%fargs)>> for creating the
analyzer for a new pair of data streams.

This implementation will create a new analyzer object based on the factory
object, e.g. it will use %args for the fields in the analyzer but also provide
access to the args given when creating the factory within field C<factory_args>.

If the interface required an adaptor it will wrap the newly created analyzer
into the adaptor with C<< $analyzer = $adaptor_class->new($analyzer) >>.

Derived classes should handle (and remove) all local settings from C<%args>
and then call C<<$class->SUPER::new_analyzer(%rest_args)>> to construct
C<$analyzer>.

This method might generate results already.
This might be the case, if it needs to analyze only one direction (e.g. issue
IMP_PASS with IMP_MAXOFFSET for the other direction) or if it needs to only
intercept data but not deny or modify based on the data (e.g. issue IMP_PREPASS
with IMP_MAXOFFSET).

C<Net::IMP::Base> supports only two elements in C<%args>, any other elements
will cause an error:

=over 8

=item meta

This will be stored in C<$analyzer->{meta}>.
Usually used for storing context specific information from the application.
Some modules (like L<Net::IMP::SessionLog>) depend on C<meta> providing a hash
reference with specific entries.

=item cb

This is the callback and will be stored in C<$analyzer->{analyzer_cb}>.
Callback should be specified as an array reference with C<[$sub,@args]>.
See C<set_callback> method for more information.

If you set the callback this way, you have to be prepared to handle calls to
the callback immediatly, even if C<new_analyzer> did not return yet.
If you don't want this, use C<set_callback> after creating the analyzer
instead.

=back

The following methods are implemented on analyzer objects as required by
L<Net::IMP>:

=over 4

=item $analyzer->set_callback($sub,@args)

This will set the callback (C<$analyzer->{analyzer_cb}>).
This method will be called from the user of the analyzer.
The callback will be used within C<run_callback> and called with
C<< $sub->(@args,@results) >>.

If there are already collected results, the callback will be executed
immediately.
If you don't want this, remove these results upfront with C<poll_results>.

=item $analyzer->poll_results

This will return the current C<@results> and remove them from collected
results.
It will only be used from the caller of the analyzer if no callback is set.

=item $analyzer->data($dir,$data,$offset,$dtype)

This method should be defined for all analyzers.
The implementation in this package will just croak.

=item $analyzer->busy($dir,0|1)

This method sets direction $dir to busy.
The analyzer should not propagate results for this direction until it gets
unbusy again (e.g. will accumulate results for later).
The exception are results which might help to solve the busy state, like
IMP_DENY. Also, results not specific for this dir should still be delivered.

=back

Also the following methods are defined for analyzers and can be used inside
your own analyzer.

=over 4

=item $analyzer->add_results(@results)

This method adds new results to the list of collected results.
Each result is an array reference, see L<Net::IMP> for details.

It will usually be used in the analyzer from within the C<data> method.

=item $analyzer->run_callback(@results)

Like C<add_results> this will add new results to the list of collected results.
Additionally it will propagate the results using the callback provided by the
user of the analyzer.
It will propagate all spooled results and new results given to this method.

=back


=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT

Copyright by Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
