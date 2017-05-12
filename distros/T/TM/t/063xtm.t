use strict;
use warnings;

use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;
use TM::Materialized::AsTMa;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

#== TESTS ===========================================================================

require_ok ('TM::Materialized::XTM');

{
    my $tm = new TM::Materialized::XTM;
    ok ($tm->isa('TM::Materialized::XTM'),     'correct class 1');
    ok ($tm->isa('TM::Materialized::Stream'),  'correct class 2');
    ok ($tm->isa('TM'),                        'correct class 3');
}

my $tm = new TM::Materialized::AsTMa (baseuri=>"tm://", inline=> '
nackertes_topic 

atop
bn: just a topic

btop (ctop)
bn: something
bn@ascope: some other thing

ctop
bn: over the top!
in: something
in: somemore
oc: http://somewhere
in@ascope: scoped
in@ascope (sometype): also typed
oc (sometype): http://typedoc
oc @ascope (sometype): http://typedandscopedoc

(sucks-more-than)
sucker: ctop
winner: atop
winner: others

(sucks-more-than) @ascope
sucker: nobody
winner: nobody

thistop reifies http://rumsti
bn: reification
in: reification
sin: http://nowhere.never.ever
sin: http://nowhere.ever.never

(sucks-more-than) is-reified-by atop
winner: nobody
sucker: nobody

')->sync_in;

Class::Trait->apply ($tm, "TM::Serializable::XTM");

{
    my $tm2 = new TM::Materialized::XTM (baseuri=>"tm://", inline => $tm->serialize)->sync_in;

    is_deeply( $tm->{mid2iid},    $tm2->{mid2iid},    'toplet structure identical' );
    is_deeply( $tm->{assertions}, $tm2->{assertions}, 'asserts structure identical' );
}

eval {
  my $tm2 = new TM::Materialized::XTM (url => 'file:xxx');
  $tm2->sync_in;
}; like ($@, qr/unable to load/, _chomp ($@));

eval {
  my $tm2 = new TM::Materialized::XTM (file => 'xxx.xxx');
  is ($tm2->url, 'file:xxx.xxx', 'url ok');
};

eval {
    my $tm2 = new TM::Materialized::XTM (inline => q|<topicMap version="2.1">
</topicMap>
|)->sync_in;
}; like ($@, qr/unsupported/, 'version unsupported');

__END__

{
    my $tm2 = new TM::Materialized::XTM (inline => q|<?xml version="1.0"?>
<topicMap xmlns='http://www.topicmaps.org/xtm/1.0/' xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1">

<topic id="aaa">
  <baseName>
     <instanceOf><topicRef xlink:href="#bbb"/></instanceOf>
     <baseNameString>AAA</baseNameString>
  </baseName>
  <occurrence>
     <instanceOf><topicRef xlink:href="#bbb"/></instanceOf>
     <scope><topicRef xlink:href="#sss"/></scope>
     <resourceData>sldfsdlf</resourceData>
  </occurrence>
</topic>

<topic id="bbb"/>

<association>
  <instanceOf><topicRef xlink:href="#atype"/></instanceOf>
  <member>
     <roleSpec><topicRef xlink:href="#role2"/></roleSpec>
     <topicRef xlink:href="#player1"/>
  </member>
  <member>
     <roleSpec><topicRef xlink:href="#role1"/></roleSpec>
     <topicRef    xlink:href="#player2"/>
     <resourceRef xlink:href="http://player3/"/>
  </member>
</association>

</topicMap>
|)->sync_in;

warn Dumper $tm2;

warn    $tm2->serialize (version => '2.0');

}



__END__


