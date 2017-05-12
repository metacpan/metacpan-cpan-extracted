# $Id: TestSuite.pm 493 2014-02-05 19:00:07Z whynot $

use strict;
use warnings;
package t::TestSuite;

use version 0.50; our $VERSION = qv q|0.2.6|;
use base qw| Exporter |;
use lib   q|./blib/lib|;

use Cwd;
use Test::Differences;
use Module::Build;

our @EXPORT_OK = qw| RCD_process_patterns |;

$ENV{PERL5LIB} = getcwd . q|/blib/lib|;

=item I<$Verbose>

    use t::TestSuite;
    note 'BOOM!' if t::TestSuite::Verbose;

A build-wide cache of verbosity level cache.

=cut

# XXX:201402052027:whynot: Shortest form;  otherwise fails during first run.
our $Verbose = eval { Module::Build->current->runtime_params( q|verbose| ) };

=item I<$Y_Choice>

    use t::TestSuite;
    $t::TestSuite::Y_Choice->[0] eq 'xs' or die;

Storage for cached YAML engine choice.
Contents is an ARRAY of I<$nick> and I<$engine>.
The latter is an actual name of module to use.

=cut

our $Y_Choice;
foreach my $y_eng
( [qw| syck YAML::Syck |],
  [qw| xs   YAML::XS   |],
  [qw| tiny YAML::Tiny |],
  [qw| old  YAML       |] ) {
  #[qw| data Data::YAML::Reader |],
    $ENV{RCD_YAML_ENGINE} && $y_eng->[0] ne $ENV{RCD_YAML_ENGINE}    and next;
    eval qq|require $y_eng->[1]|                                      or next;
    $Y_Choice = $y_eng;
                        last }
$Y_Choice or Test::More::BAIL_OUT( q|none known YAML reader has been found| );

=item B<RCD_show_y_choice()>

    t::TestSuite::RCD_show_y_choice;

Shows what YAML engine has been choosen.

=cut

sub RCD_show_y_choice ( ) { print qq|$Y_Choice->[1]\n| }

=item B<RCD_load>_patterns()>

    use t::TestSuite;
    %patterns = t::TestSuite::RCD_load_patterns;

Returns a hash of pattern sets.
A filename to load from is automagically recovered from calling test-unit's
filename
(F<t/preferences.t> becomes F<t/preferences.yaml>).
File is supposed to be YAML.
Engine to use is set by I<$Y_Choice>.
Supported engines are:

=over

=item *

B<Data::YAML>, nick -- C<data>;

=item *

B<YAML>, nick -- C<old>;

=item *

B<YAML::Syck>, nick -- C<syck>;

=item *

B<YAML::Tiny>, nick -- C<tiny>;

=item *

B<YAML::XS>, nick -- C<xs>.

=back

=cut

sub RCD_load_patterns ( )               {
    my $fn = (caller)[1];
    $fn =~ s{\.t$}{.yaml};
    if( $Y_Choice->[0] eq q|tiny|    ) {
        my $yaml = YAML::Tiny->read( $fn );
        defined $yaml                                 or Test::More::BAIL_OUT(
          qq|YAML::Tiny has this to say: | . YAML::Tiny->errstr );
                          %{$yaml->[0]} }
    elsif( $Y_Choice->[0] eq q|old|  ) {
        my $yaml;
        eval { $yaml = YAML::LoadFile( $fn ); 1 }     or Test::More::BAIL_OUT(
          qq|YAML::Old has this to say; $@| );
                                 %$yaml }
    elsif( $Y_Choice->[0] eq q|xs|   ) {
        my $yaml;
        eval { $yaml = YAML::XS::LoadFile( $fn ); 1 } or Test::More::BAIL_OUT(
          qq|YAML::XS has this to say: $@| );
                                 %$yaml }
    elsif( $Y_Choice->[0] eq q|data| ) {
        my $yaml;
        open my $fh, q|<|, $fn                        or Test::More::BAIL_OUT(
          qq|Data::YAML has this to say ($fn): $!| );
        eval { $yaml = Data::YAML::Reader->new->read( $fh ); 1 }            or
          Test::More::BAIL_OUT(
            qq|Data::YAML (probably) has this to say: $@| );
                                 %$yaml }
    elsif( $Y_Choice->[0] eq q|syck| ) {
        my $yaml;
# FIXME:201402030125:whynot: How to trigger that croak?
        eval { $yaml = YAML::Syck::LoadFile( $fn ); 1 }                     or
        Test::More::BAIL_OUT( qq|YAML::Syck (probably) has this to say: $@| );
                                 %$yaml }}

=item B<RCD_save_patterns()>

    use t::TestSuite;
    t::TestSuite::RCD_save_patterns $filename, %patterns;

Debugging service routine.
Saves I<%patterns> in I<$filename> file using engine set by I<$Y_Choice>.

=cut

sub RCD_save_patterns ( $\% )             {
    my( $fn, $data ) = ( @_ );
    if( $Y_Choice->[0] eq q|tiny|    )    {
        my $yaml = YAML::Tiny->new;
        $yaml->[0] = $data;
        $yaml->write( $fn )               }
    elsif( $Y_Choice->[0] eq q|old|  )   {
        open my $fh, q|>|, $fn;
        print $fh YAML::Dump( $data )     }
    elsif( $Y_Choice->[0] eq q|syck| )   {
        YAML::Syck::DumpFile( $fn, $data )}}

=item B<RCD_process_patterns()>

    use t::TestSuite qw/ RCD_process_patterns /;
    RCD_process_patterns
      patterns   =>  $patterns{match_pattern},
      re_m    =>   qr|^$RE{debian}{pattern}$|,
      re_g => qr|$RE{debian}{pattern}{-keep}|;

Processes patterns in requested data-set (I<$patterns>) using I<$re_m> and
I<$re_g> appropriately.

=cut

sub RCD_process_patterns ( % )                                              {
    my %args = @_;

    foreach my $ptn ( @{$args{patterns}} ) {
        my @in = @$ptn;
        my @out =
        ( $ptn->[0],
         ($ptn->[0] =~ $args{re_m} ? '+' : '-'),
          $ptn->[0] =~ $args{re_g} );
        my $dump = sprintf q|%s %s|, $ptn->[1], quotemeta $ptn->[0];
        $dump =~ s{\n}{\\n}g;
        eq_or_diff_data \@out, \@in, $dump  }

    Test::More::diag( sprintf q|processed patterns (%s): %i|,
    ( caller 1 )[3] || ( caller )[1], scalar @{$args{patterns}}) if $Verbose }

sub RCD_trial_patterns ( % ) {
    my %args = @_;
    my @rc;

    push @rc, [ $_, (m[$args{re_m}] ? '+' : '-'), m[$args{re_g}] ]
      foreach @{$args{patterns}};
    @rc                       }

sub RCD_count_patterns ( )         {
    opendir my $dh, q|t|;
    while( my $fn = readdir $dh ) {
        index( $fn, '.' ) && $fn =~ m{.yaml}                          or next;
        my %patterns;
        if( $Y_Choice->[0] eq q|tiny| )    {
            my $yaml = YAML::Tiny->read(qq|t/$fn|);
            %patterns = %{$yaml->[0]}       }
        elsif( $Y_Choice->[0] eq q|old| )  {
            my( $yaml, $buf );
            open my $fh, q|<|, qq|t/$fn|;
            read $fh, $buf, -s $fh;
            $yaml = YAML::Load( $buf );
            %patterns = %$yaml              }
        elsif( $Y_Choice->[0] eq q|syck| ) {
            my $yaml = YAML::Syck::LoadFile( qq|t/$fn| );
            %patterns = %$yaml              }
        printf qq|%23s => % 4i\n|, $_, scalar @{$patterns{$_}}
          foreach keys %patterns   }}

1;
