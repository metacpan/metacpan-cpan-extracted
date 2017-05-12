package Module::Use;

require 5.005;
use Tie::Hash;
use base qw(Tie::StdHash);
use Carp;
use strict;
use vars qw($VERSION %noargs %counts %config $_object);

$VERSION = 0.05;

=head1 NAME

Module::Use

=head1 SYNOPSIS

=over 0

=item Perl

  use Module::Use (Counting, Logger => "Debug");

=item mod_perl

  <Perl>
  use Module::Use (Counting, Logger => "Debug");
  </Perl>

  PerlChildExitHandler Module::Use
  PerlCleanupHandler Module::Use
  PerlLogHandler Module::Use

=back

=head1 DESCRIPTION

Module::Use will record the modules used over the course of the 
Perl interpreter's lifetime.  If the logging module is able, the 
old logs are read and frequently used modules are automatically 
loaded.  Note that no symbols are imported into packages.

Under mod_perl, only one Perl*Handler should be selected, 
depending on when and how often logging should take place.

=head1 OPTIONS

The following options are available when C<use>ing this module.

=over 4

=item Count

This is the number of times a module has been used for it to be automatically loaded.

=item Counting

This indicates that the number of times a module is C<require>d should be
tracked.  This option takes no arguments.

=item Decay

This number is subtracted from the count of all modules that are in the
data store but were not loaded.

=item Grow

This number is added to the count of all modules that were loaded.

=item Limit

Do not automatically load more than this many modules.

=item Logger

This is the logging module to use.  Configuration is specific to the module
chosen.  Please see the documentation for the module.

The module name is C<Module::Use::Logger> with C<Logger> replaced with the value of this option.

=item Percentage

The percentage of total module loads is used in the same manner as the C<Count>.  If both C<Percentage> and
C<Count> are given, the one with the greater counts is used.

=back

=head1 SEE ALSO

L<Module::Use::Debug>, L<Module::Use::DB_FileLock>.

=head1 AUTHOR

James G. Smith <jgsmith@jamesmith.com>

=head1 COPYRIGHT

Copyright (C) 2001 James G. Smith

Released under the same license as Perl itself.

=cut


# actual implementation:

@noargs{
    qw(Counting)
}  = ( );

sub FETCH {
    $counts{$_[1]}++ if defined $_[0] -> {$_[1]};
    $_[0] -> {$_[1]};
}

sub STORE {
    $counts{$_[1]}++;
    print "Storing $_[1]\n";
    $_[0] -> {$_[1]} = $_[2];
}

sub import { 
    my($self, @config) = @_;

    croak "@{[ref $self]} not intended to be instanced" if ref $self;

    my $op;
    while(@config) {
        $op = shift @config;
        if(exists $noargs{$op}) {
	    $config{$op} = 1;
	} else {
	    $config{$op} = shift @config;
	}
    }

    # load logging module - defines Module::Use::log
    if(defined $config{Logger}) {
	eval qq{require Module::Use::$config{Logger}};
        croak "Unable to load logger: $@" if $@;
    }

    if(defined $INC{'Apache.pm'}) {
        $config{log_at_end} = 0;
    } else {
        $config{log_at_end} = 1;
    }

    tie %INC, $self;

    $_object = tied %INC;

    if($_object -> can('_query_modules')) {
        my($modules) = $_object -> query_modules();
        require($_) for @{$modules};
    }
}

sub query_modules {
    my($self) = shift;

    my $hash = $self -> _query_modules();

    my @keys = keys %{$hash};
    my $total = 0;

    local($_);  # JIC

    $total += $hash->{$_} for @keys;

    my $p = 0;
    if($self -> {Percentage}) {
        $p = $self -> {Percentage} * $total / 100.;
    }
    if($self -> {Count}) {
        if($p < $self -> {Count}) {
            $p = $self -> {Count};
        }
    }

    my $l;    
    if($self -> {Limit}) {
        $l = $self -> {Limit};
    } else {
        $l = scalar(@keys);
    }

    @keys = sort { $hash->{$a} <=> $hash->{$b} } @keys;

    $#keys = $l-1 if $l;


    @keys = grep { $hash->{$_} > $p } @keys if $p;   # could do a binary search at this point
                         
    return \@keys;
}

sub _process_INC {
    return grep {    $_ !~ m{^Module/Use(/|\.pm)?} 
                  && $_ !~ m{^[a-z/]} 
                } keys %counts;
}

sub handler {
    no strict qw(subs);

    $_object -> log(_process_INC()) if $_object -> can("log");
    return Apache::Constants::OK;
}

END {
    # now log %INC
    $_object -> log(_process_INC()) if $config{log_at_end} && $_object -> can("log");
}

1;
