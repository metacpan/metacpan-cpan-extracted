
=head1 Name

QBit::TimeLog - class for hierarchical time logging.

=head1 Synopsis

 #!/usr/bin/perl

 use qbit;
 use QBit::TimeLog;

 my $timelog = QBit::TimeLog->new();

 $timelog->start('Main prog');

 $timelog->start('1');
 sleep(1);
 $timelog->finish();

 $timelog->start('2');
     $timelog->start('3');
     sleep(3);
     $timelog->finish();
 $timelog->finish();

 $timelog->finish();

 print $timelog . '';

Result:

 4.000617 sec: main prog
     0.000028 sec: Working
     1.000207 sec: 1
     0.000089 sec: Working
     3.000287 sec: 2
         0.000028 sec: Working
         3.000232 sec: 3
         0.000027 sec: Working
     0.000006 sec: Working

=cut

package QBit::TimeLog;
$QBit::TimeLog::VERSION = '0.5';
use qbit;

use base qw(QBit::Class);

use Time::HiRes qw(gettimeofday tv_interval);

use overload
  '""'   => sub {shift->as_string()},
  'bool' => sub {TRUE},
  ;

=head1 Variables

=over

=item

$UNKNOWN_ACTION - name of actions between time logging. Default: C<Working>.

=back

=cut

our $UNKNOWN_ACTION = 'Working';

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    weaken($self->{'parent'}) if exists($self->{'parent'});
}

=head1 Methods

=head2 start

Start new timeline.

B<Arguments:>

=over

=item

B<$description> - string, description of timeline.

=back

=cut

sub start {
    my ($self, $description) = @_;

    if (exists($self->{'__CUR__'})) {
        $self->{'__CP__'} = [] unless exists($self->{'__CP__'});
        push(
            @{$self->{'__CUR__'}->{'__CP__'}},
            $self->{'__CUR__'} = ref($self)->new(parent => $self->{'__CUR__'})->start($description)
        );
    } else {
        $self->{'__START__'} = [gettimeofday()];
        $self->{'__DESCR__'} = $description;
        $self->{'__CUR__'}   = $self;
        weaken($self->{'__CUR__'});
    }

    return $self->{'__CUR__'};
}

=head2 finish

Finish current timeline.

B<No arguments.>

=cut

sub finish {
    my ($self) = @_;

    $self->{'__CUR__'}{'__FINISH__'} = [gettimeofday()];
    $self->{'__CUR__'} = $self->{'__CUR__'}{'parent'};
    weaken($self->{'__CUR__'});

    return $self;
}

=head2 as_string

Return timelog as string.

B<No arguments.>

=cut

sub as_string {
    my ($self) = @_;

    return $self->_as_string([$self->_analyze()]);
}

=head2 print

Print timelog to STDERR.

B<No arguments.>

=cut

sub print {
    my ($self) = @_;

    l($self->_as_string([$self->_analyze()]));
}

sub _analyze {
    my ($self, $first, $last, $prev_time) = @_;
    my @res;

    push(@res, [$UNKNOWN_ACTION, tv_interval($self->{'parent'}{'__START__'}, $self->{'__START__'})])
      if $first && defined($self->{'parent'});

    push(@res, [$UNKNOWN_ACTION, tv_interval($prev_time, $self->{'__START__'})])
      if !$first && defined($prev_time);

    my $cnt = 0;
    my $cp_count = @{$self->{'__CP__'} || []};
    my $prev_finish;
    my @sublogs;
    foreach my $log (@{$self->{'__CP__'} || []}) {
        push(@sublogs, $log->_analyze($cnt == 0, $cnt == $cp_count - 1, $prev_finish));
        $prev_finish = $log->{'__FINISH__'};
        $cnt++;
    }

    push(@res,
        [$self->{'__DESCR__'}, tv_interval($self->{'__START__'}, $self->{'__FINISH__'}), (@sublogs ? \@sublogs : ())]);

    push(@res, [$UNKNOWN_ACTION, tv_interval($self->{'__FINISH__'}, $self->{'parent'}{'__FINISH__'})])
      if $last && defined($self->{'parent'});

    return @res;
}

sub _calc_percent {
    my ($self, $log, $parent_time) = @_;

    foreach my $l (@$log) {
        $self->_calc_percent($l->[2], $l->[1]) if exists($l->[2]);
        $l->[1] = {
            t   => $l->[1],
            prc => (defined($parent_time) ? $l->[1] / $parent_time * 100 : 100)
        };
    }

    return $log;
}

sub _as_string {
    my ($self, $log, $offset) = @_;

    $offset ||= 0;

    my $offset_s = "    " x $offset;

    my $res = '';

    foreach my $l (@$log) {
        $res .= $offset_s . gettext("%f sec: %s\n", $l->[1], $l->[0]);
        if ($l->[2]) {
            $res .= $self->_as_string($l->[2], $offset + 1)
              if exists($l->[2]);
        }
    }

    return $res;
}

TRUE;
