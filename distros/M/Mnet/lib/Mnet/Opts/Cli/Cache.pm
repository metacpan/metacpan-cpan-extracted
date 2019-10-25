package Mnet::Opts::Cli::Cache;

# purpose: functions to get/set cli opts, used internally by other Mnet modules



# required modules
#   importing symbols from Mnet::Log::Conditional causes compile errors,
#       apparently because Mnet::Log::Conditional uses this module,
#       it causes a catch-22 for imports to work before Exporter runs,
#       workaround is call with path, example: Mnet::Log::Conditional::INFO()
use warnings;
use strict;
use Carp;
use Mnet::Log::Conditional;
use Mnet::Opts::Set;



# init global vars used for cached cli opt hash ref and extra cli args list
#   opts is undefined until Mnet::Opts::Cli::Cache::set() is called
INIT {
    my $opts = undef;
    my @extras = ();
}



sub debug_error {

# $value = $Mnet::Opts::Cli::Cache::debug_error()
# purpose: called from Mnet::Log to get cached --debug-error cli opt value

    # return --debug-error cli option value, if it exists
    return undef if not exists $Mnet::Opts::Cli::Cache::opts->{debug_error};
    return $Mnet::Opts::Cli::Cache::opts->{debug_error};
}



sub set {

# Mnet::Opts::Cli::Cache::set(\%opts, @extras)
# purpose: called from Mnet::Opts::Cli->new to cache cli opts and extra args
# \%opts: Mnet::Opts::Cli object parsed by Mnet::Opts::Cli->new
# @extras: extra cli arguments parsed by Mnet::Opts::Cli->new
# note: this is meant to be called from Mnet::Opts::Cli only

    # set global cache variables with input opts object and extra args
    #   output debug if unexpectantly called other than from Mnet::Opts::Cli
    my ($opts, @extras) = (shift, @_);
    if (not defined $opts) {
        $Mnet::Opts::Cli::Cache::opts = undef;
    } else {
        $Mnet::Opts::Cli::Cache::opts = { %$opts };
    }
    @Mnet::Opts::Cli::Cache::extras = @extras;
    Mnet::Log::Conditional::DEBUG("set called from ".caller)
        if caller ne "Mnet::Opts::Cli";
    return;
}



sub get {

# \%opts = Mnet::Opts::Cli::Cache::get(\%input);
#   or (\%opts, @extras) = Mnet::Opts::Cli::Cache::get(\%input);
#
# purpose: return pragmas, subset of Mnet opts, extra cli args, and input opts
#          opts subset: batch/debug/quiet/record/replay/quiet/silent/tee/test
#          Mnet::Opts::Set pragmas are also included in returned opts hash
#          input opts, if specified, are overlaid on top of these other options
#
# note: there's a couple of ways this function can be called, detailed below:
#
#   \%opts = Mnet::Opts::Cli::Cache::get();
#       no input defined, opts is undef if Mnet::Opts::Cli->new not yet called
#       can also be called in list context, to return @ARGV values as @extras
#
#   \%opts = Mnet::Opts::Cli::Cache::get(shift // {});
#       common in subroutines, \%input hash ref is arg to sub, or set empty
#       returns input opts merged over Mnet opts and Mnet::Opts::Set pragmas
#       subroutines can inherit/override/use these Mnet log and test opts
#       comes in handy for objects inheriting Mnet::Log methods, test code, etc
#       can also be called in list context, to return parsed extra cli args
#
# note: this function is meant to be used by other Mnet modules only

    # read input options hash ref
    my $input = shift;

    # return undef if Mnet::Opts::Cli was not used for cli option parsing
    return undef if not $input and not $Mnet::Opts::Cli::Cache::opts;

    # init output opts from Mnet::Opts::Set pragmas, if any are loaded
    my $opts = Mnet::Opts::Set::pragmas();

    # init output extra cli args, from ARGV if Mnet::Opts::Cli is not loaded
    my @extras = @Mnet::Opts::Cli::Cache::extras;
    @extras = @ARGV if not $INC{"Mnet/Opts/Cli.pm"};

    # next overlay output opts with Mnet opts read from Mnet::Opts::Cli->new
    #   opts with dashes would be a pain, because of need to xlate underscores
    if ($INC{"Mnet/Opts/Cli.pm"}) {
        foreach my $opt (keys %$Mnet::Opts::Cli::defined) {
            if ($opt =~ /^(batch|debug|quiet|record|replay|silent|tee|test)$/) {
                $opts->{$opt} = $Mnet::Opts::Cli::Cache::opts->{$opt};
            }
        }
    }

    # finally overlay input options on top of any Mnet pragma and Mnet options
    $opts->{$_} = $input->{$_} foreach keys %$input;

    # finished new method, return opts hash, and extra args in list context
    return wantarray ? ($opts, @extras) : $opts
}



# normal package return
1;

