package Mnet::Opts;

=head1 NAME

Mnet::Opts - Work with Mnet::Opts objects

=head1 SYNOPSIS

    # requried to use this module
    use Mnet::Opts;

    # some options can be set as pragmas
    use Mnet::Opts::Set::Debug;

    # options objects can be created
    my $opts = Mnet::Opts({ default => 1 });

    # options can be accessed via hash keys
    my $value = $opts->{default};

    # options can be accessed via method call
    $value = $opts->default;

=head1 DESCRIPTION

Mnet::Opts can be used to work with new Mnet::Opts objects, as shown in the
example above.

Refer also to L<Mnet::Opts::Cli> module, used for parsing command line options.

=head1 METHODS

Mnet::Opts implements the methods listed below.

=cut

# required modules
use warnings;
use strict;
use Carp;
use Mnet::Dump;
use Mnet::Log::Conditional qw( DEBUG INFO WARN FATAL NOTICE );
use Mnet::Opts::Set;
use Storable;

# declare global var for autoload
our $AUTOLOAD;



sub new {

=head2 new

    $opts = Mnet::Opts->new(\%opts)

The Mnet::Opts->new class method returns an Mnet::Opts option object.

The input opts hash reference argument is not required. Any
An input hash reference of options can be supplied but is not required.

Note that any L<Mnet::Opts::Set> sub-modules that have been used will be set in
the output Mnet::Opts object.

=cut

    # read input class and optional opts hash ref
    my $class = shift // croak("missing class arg");
    my $opts = shift // {};

    # create new object from input opts hash ref
    #   dclone is used to avoid worries if caller edits hash values
    my $self = bless(Storable::dclone($opts), $class);

    # apply opts set via pragma use commands
    #   these opts are not applied if already set in input
    my $pragmas = Mnet::Opts::Set::pragmas();
    foreach my $opt (keys %$pragmas) {
        next if exists $self->{$opt};
        $self->{$opt} = $pragmas->{$opt};
    }

    # log options, including who called us
    my $log = Mnet::Log::Conditional->new($opts);
    $log->debug("no opts") if not keys %$self;
    $log->debug("$_ = ".Mnet::Dump::line($self->{$_})) foreach sort keys %$self;

    # finished new method, return Mnet::Opts object
    return $self;
}



sub AUTOLOAD {

=head2 option methods

    $value = $opts->$option

Option values may be accessed using autoloaded method calls, for example:

    use Mnet::Opts;
    my $opts = Mnet::Opts({ default => 1 });
    my $value = $opts->default;

Note that the universal 'can' method call does not work for these autoloaded
option name methods. Method calls for options that do not exist will return
a value of undefined.

It is also ok to directly access the values of hash keys in the options object.

=cut

    # skip global destruction, return value for options that exist or undef
    my $self = shift;
    return if $AUTOLOAD =~ /::DESTROY$/;
    return if $AUTOLOAD !~ /::([^:]+)$/;
    return $self->{$1} if exists $self->{$1};
    return undef;
}



=head1 SEE ALSO

L<Mnet>

L<Mnet::Opts::Cli>

L<Mnet::Opts::Set>

=cut

# normal package return
1;

