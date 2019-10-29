package Mnet::Log::Conditional;

=head1 NAME

Mnet::Log::Conditional - Use Mnet::Log if Mnet::Log is loaded

=head1 SYNOPSIS

    use Mnet::Log::Conditional qw( DEBUG INFO WARN FATAL );

    # nothing will happen unless Mnet::Log was loaded
    INFO("starting");

    # errors will still always go to stderr
    WARN("error");
    FATAL("abort");

    my $log = Mnet::Log::Conditional->new($opts);
    $log->DEBUG("object oriented interace");

=head1 DESCRIPTION

Mnet::Log::Conditional can be called to output log entries only if the
L<Mnet::Log> module has already been otherwise loaded.

This is used by other L<Mnet> modules for logging, so that they generate
log output only if the calling script is using the L<Mnet::Log> module. Users
who create custom modules may want to do the same thing.

Refer to L<Mnet::Log> for more information.

=head1 METHODS

Mnet::Log::Conditional implements the methods listed below.

=cut

# required modules
#   modules below can't import from this module due to Exporter catch-22,
#       symbols aren't available for export until import has a chance to run,
#       workaround is call with path, example: Mnet::Log::Conditional::INFO()
use warnings;
use strict;
use Carp;
use Exporter qw( import );
use Mnet::Opts::Cli::Cache;

# export function names
our @EXPORT_OK = qw( DEBUG INFO NOTICE WARN FATAL );



sub new {

=head2 new

    $log = Mnet::Log::Conditional->new(\%opts)

This class method creates a new Mnet::Log::Conditional object. The opts hash
ref argument is not requried but may be used to override any parsed cli options
parsed with the L<Mnet::Opts::Cli> module.

The returned object may be used to call other documented functions and methods
in this module, which will call the L<Mnet::Log> module if it is loaded.

Refer to the new method in perldoc L<Mnet::Log> for more information.

=cut

    # read input class and options hash ref merged with cli options
    my $class = shift // croak("missing class arg");
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # warn if log_id contains non-space characters
    croak("invalid log_id $opts->{log_id}")
        if defined $opts->{log_id} and $opts->{log_id} !~ /^\S+$/;

    # create log object from options object
    my $self = bless $opts, $class;

    # finished new method
    return $self;
}



sub debug {

=head2 debug

    $log->debug($text)

Output a debug entry using the L<Mnet::Log> module, if loaed.

=cut

    # call Mnet::Log::output if loaded or return
    my ($self, $text) = (shift, shift);
    return Mnet::Log::output($self, "dbg", 7, scalar(caller), $text)
        if $INC{"Mnet/Log.pm"};
    return 1;
}



sub info {

=head2 info

    $log->info($text)

Output an info entry using the L<Mnet::Log> module, if loaed.

=cut

    # call Mnet::Log::output if loaded or return
    my ($self, $text) = (shift, shift);
    return Mnet::Log::output($self, "inf", 6, scalar(caller), $text)
        if $INC{"Mnet/Log.pm"};
    return 1;
}



sub notice {

# $self->notice($text)
# purpose: output notice using Mnet::Log if loaded, otherwise nothing happens

    # call Mnet::Log::output if loaded or return;
    my ($self, $text) = (shift, shift);
    return Mnet::Log::output($self, "---", 5, scalar(caller), $text)
        if $INC{"Mnet/Log.pm"};
    return 1;
}



sub warn {

=head2 warn

    $log->warn($text)

Output a warn entry using the L<Mnet::Log> module, if loaed.

=cut

    # call Mnet::Log::output if loaded or warn
    my ($self, $text) = (shift, shift);
    if ($INC{"Mnet/Log.pm"}) {
        Mnet::Log::output($self, "WRN", 4, scalar(caller), $text);
    } else {
        $text =~ s/\n*$//;
        my $log_id = $self->{log_id} // "-";
        CORE::warn("WRN $log_id " . scalar(caller) . " $text\n");
    }
    return 1;
}



sub fatal {

=head2 fatal

    $log->fatal($text)

Output a fatal entry using the L<Mnet::Log> module, if loaded.

=cut

    # call Mnet::Log output if loaded or die
    #   $^S is undef while compiling/parsing, true in eval, false otherwise
    my ($self, $text) = (shift, shift);
    if ($INC{"Mnet/Log.pm"}) {
        CORE::die("$text\n") if $^S;
        Mnet::Log::output($self, "DIE", 2, scalar(caller), $text);
    } else {
        my $log_id = $self->{log_id} // "-";
        CORE::die("DIE $log_id " . scalar(caller) . " $text\n");
    }
    exit 1;
}



=head1 FUNCTIONS

Mnet::Log::Conditional also implements the functions listed below.

=cut



sub DEBUG {

=head2 DEBUG

    DEBUG($text)

Output a debug entry using the L<Mnet::Log> module, if loaed.

=cut

    # call Mnet::Log::output if loaded or return;
    my $text = shift;
    return Mnet::Log::output(undef, "dbg", 7, scalar(caller), $text)
        if $INC{"Mnet/Log.pm"};
    return 1;
}



sub INFO {

=head2 INFO

    INFO($text)

Output an info entry using the L<Mnet::Log> module, if loaed.

=cut

    # call Mnet::Log::output if loaded or return;
    my $text = shift;
    return Mnet::Log::output(undef, "inf", 6, scalar(caller), $text)
        if $INC{"Mnet/Log.pm"};
    return 1;
}



sub NOTICE {

# NOTICE($text)
# purpose: output notice using Mnet::Log if loaded, otherwise nothing happens

    # call Mnet::Log::output if loaded or return;
    my $text = shift;
    return Mnet::Log::output(undef, "---", 5, scalar(caller), $text)
        if $INC{"Mnet/Log.pm"};
    return 1;
}



sub WARN {

=head2 WARN

    WARN($text)

Output a warn entry using the L<Mnet::Log> module, if loaed.

=cut

    # call Mnet::Log::output if loaded or warn
    my $text = shift;
    if ($INC{"Mnet/Log.pm"}) {
        Mnet::Log::output(undef, "WRN", 4, scalar(caller), $text);
    } else {
        $text =~ s/\n*$//;
        CORE::warn("WRN - " . scalar(caller) . " $text\n");
    }
    return 1;
}



sub FATAL {

=head2 FATAL

    FATAL($text)

Output a fatal entry using the L<Mnet::Log> module, if loaed.

=cut

    # call Mnet::Log::output if loaded or die
    my $text = shift;
    if ($INC{"Mnet/Log.pm"}) {
        Mnet::Log::output(undef, "DIE", 2, scalar(caller), $text);
    } else {
        CORE::die("DIE - " . scalar(caller) . " $text\n");
    }
    exit 1;
}



=head1 SEE ALSO

L<Mnet>

L<Mnet::Log>

=cut

# normal end of package
1;

