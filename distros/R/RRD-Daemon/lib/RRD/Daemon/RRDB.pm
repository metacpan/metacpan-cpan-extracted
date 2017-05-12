package RRD::Daemon::RRDB;

=head1 NAME

RRD::Daemon::RRDB - RRDTool database (i.e., an rrdtool file)

=cut

# pragmata ----------------------------

use strict;
use warnings;
use feature  qw( :5.10 );

# utility -----------------------------

use base qw( Params::Check );

use Carp                 qw( croak );
use Log::Log4perl        qw( :levels );
use Memoize              qw( memoize );
use RRDs                 qw( );
use Params::Attr         qw( check_string );
use POSIX                qw( ceil );

use RRD::Daemon::Util  qw( FTIME_INC_EPOCH
                           ftime
                           debug trace lwrite tdump tdumps
                           mlhash
                         );

use RRD::Daemon::RRDB::DS     qw( );
use RRD::Daemon::RRDB::RRA    qw( );

# UTILITY FUNCTIONS ----------------------------------------------------------

# INSTANCE OBJECT ------------------------------------------------------------

=head2 new

=over 4

=item ARGUMENTS

=over 4

=item fn

=item create

A hashref.  If not defined, an exception is thrown if the rrd file does not
already exist.  If defined, the rrd file will be created as needed with the
given parameters.

Hashref Keys:

=over 4

=item create

If true, then we B<only> create - an exception will be thrown if the RRD file
already exists.

=back

=back

=back

=cut

sub new : CheckP(qw( S S ; HR )) {
  my ($class, $fn, $create) = @_;

  my $self = bless { fn => $fn };

  if ( $create ) {
    croak "(rrd) file already exists: '$fn'\n"
      if -e $fn and $create->{create};
    $self->_create($fn, $create)
      unless -e $fn;
  } else {
    croak "no such (rrd) file: '$fn'\n"
      unless -e $fn;
  }

  return $self;
}

# -------------------------------------

=head2 createspec

the "cmdline" spec used to create the RRD based on the given parameters
as an arrayref

=cut

sub createspec : CheckP(qw( _ S HR(create,names,ds_type,min,max,interval) )) {
  my ($self, $fn, $args) = @_;

  my $names = $args->{names}
    or croak "no names given to create rrd\n";
  my $ds_type = $args->{ds_type} // 'GAUGE';
  my ($min, $max) = map $_//'U', @{$args}{qw( min max )};
  my $interval = $args->{interval} || 60;

  return $self->_create_spec($interval, $names, 'MAX', 'GAUGE', $min, $max);
}

# -------------------------------------

sub _create : CheckP(qw( _ S HR )) {
  my ($self, $fn, $args) = @_;
  my $names = $args->{names};
  my $spec = $self->createspec($fn, $args);
  debug "creating rrd in $fn for %s\n", join ',', @$names;
  trace 'RRDs::create %s', join ' ', $fn, @$spec;
  RRDs::create $fn => @$spec;
}

# -------------------------------------

# step range from 1s to 10m
sub _create_spec : CheckP(qw( _ i(1..600) AR S S S S)) {
  my ($self, $step, $names, $rra, $ds_type, $min, $max) = @_;

  croak "invalid ds name: $_"
    for grep !/^\w+$/, @$names; # validity [a-zA-Z0-9_] as per man rddcreate
  check_string('RRA type', $rra,     [qw( AVERAGE MIN MAX LAST )]);
  check_string('DS type',  $ds_type, [qw( GAUGE COUNTER )]);

  # Data Sources (Primary Data Points)
  #
  # GAUGE: flat counter
  # max 300 seconds between valid data points.  Anything more, and the
  #   inbetweens become 'unknown'
  # min/max of 0--100.  Anthing outside of these ranges are considered unknown.
  my @ds = map "DS:$_:$ds_type:300:$min:$max", @$names;

  # Round Robin Archives
  #
  # MAX: choose the maximum value
  # 0.7: x-files factor.  How much data may be 'unknown' before the aggregate
  #      (in this case, the MAX) is considered unknown.
  # steps:rows  e.g., 10:1440  steps is the number of PDPs in a consolidation;
  #                            hence 10, with a -s of 60 is 10 minutes;
  #                            1440, is 10 days ((1440*10) / (60*24))

  my @rra;
  # each val is step in minutes and rows in days
  # every minute for two days
  # every ten minutes for ten days
  # every thirty minutes for thirty days
  # every 3 hours for 10 years
  for my $dur ([1 => 2], [10 => 10], [30 => 30], [3*60 => 10*366]) {
    my ($step_m, $rows_d) = @$dur;
    my $step_pdp = ceil 60*$step_m/$step;
    my $rows     = $rows_d*24*60 / $step_m;

    push @rra, sprintf 'RRA:%s:0.7:%d:%d', 
                       $rra, $step_pdp, $rows;
  }

  return [ -s => $step, @ds, @rra ];
}

# -------------------------------------

sub fn { $_[0]->{fn} }

# -------------------------------------

sub info_mlhash {
  my ($self) = @_;

  my $info = mlhash(RRDs::info($self->fn), qr/\./);
}
memoize 'info_mlhash';

# -------------------------------------

sub last_update { $_[0]->info_mlhash->{last_update} }
sub step        { $_[0]->info_mlhash->{step} }

# -------------------------------------

sub dss {
  my ($self) = @_;
  my $info_mlhash = $self->info_mlhash;
  my %dss = map +($_ => $info_mlhash->{"ds[$_]"}),
                 map /^ds\[(\w{1,19})\]$/ && $1 || (), sort keys %$info_mlhash;
  return map RRD::Daemon::RRDB::DS->new($_, $dss{$_}), sort keys %dss;
}
memoize 'dss';

# -------------------------------------

sub rras {
  my ($self) = @_;
  my $info_mlhash = $self->info_mlhash;
  my @rras = map $info_mlhash->{"rra[$_]"},
             sort map /^rra\[(\d+)\]$/ ? $1 : (), keys %$info_mlhash;
  return map RRD::Daemon::RRDB::RRA->new($_, $self, $rras[$_]), 0..$#rras;
}
memoize 'rras';

# -------------------------------------

sub info_string {
  my ($self) = @_;

  my $info = $self->info_mlhash;
  my $text = '';

  for my $_ (qw( filename last_update rrd_version step )) {
    when ( [ qw( filename rrd_version step ) ] )
      { $text .= sprintf "%-12s: %s\n", $_, $info->{$_} }

    when ( 'last_update' )
      { $text .= "$_ : " . scalar gmtime($info->{$_}) . " GMT\n" }
  }

  my @dss  = $self->dss;
  my @rras = $self->rras;
  $text .= $_->info_string
    for @dss, @rras;

  return $text;
}

# -------------------------------------

sub update {
  my ($self, $time, $value) = @_;

  $time ||= 'N';

  my $fn = $self->fn;
  tdump fn => $fn, time => $time, value => $value;
  my $result = RRDs::updatev $fn, "$time:$value";
  my $err = RRDs::error;
  croak sprintf "failed to update %s: %s", $self->fn, $err
    if $err;

  tdump fn => $fn, time => $time, value => $value, result => $result;

  my @infos;
  for my $_ (sort keys %$result) {
    when ( 'return_value' )
      { } # do nothing

    # pdp is the # primary data points per row; e.g., with a step of 60(seconds),
    # it's the number of minutes that the RRA is taken over
    when ( /\[(?<time>\d{10})\]
            RRA\[(?<rra_type>\w+)\] \[(?<pdp>\d+)\]
            DS\[(?<ds_name>\w+)\]$/x )
      { push @infos, +{ map(($_ => $+{$_}), qw( time ds_name rra_type pdp )),
                        value => $result->{$_} } }

    default
      { warn "unparsed key in updatev return: >>$_<<" }
  }

  my $i = 0;
  while ( $i < @infos ) {
    my $info = $infos[$i];
    my ($time, $ds_name, $rra_type, $pdp, $value) =
      @{$info}{qw( time ds_name rra_type pdp value )};

    tdumps info => $info;

    if ( defined $value ) {
      _set_debug($time, $ds_name, $rra_type, $pdp, $value);
      $i++;
    } else {
      if ( $i >= @infos - 3
           or grep defined $infos[$_]->{value}, $i+1..$i+3 ) {
        _set_debug($time, $ds_name, $rra_type, $pdp);
        $i++;
      } else {
        _set_debug($time, $ds_name, $rra_type, $pdp);
        debug '...';
        $i++
          while $i < $#infos and ! defined $infos[$i+1]->{value};
      }
    }
  }
}

sub _set_info   { _set_lwrite($INFO, @_)  }
sub _set_debug  { _set_lwrite($DEBUG, @_) }
sub _set_lwrite {
  my ($level, $time, $ds_name, $rra_type, $pdp, $value) = @_;
  lwrite $level, '[%s] set [%s:%s(%d)] to %s',
         ftime($time, FTIME_INC_EPOCH), $ds_name, $rra_type, $pdp,
         defined $value ? sprintf('%3.1f', $value) : '-';
}

# ----------------------------------------------------------------------------

1; # keep require happy
