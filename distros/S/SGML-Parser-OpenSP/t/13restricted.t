# 13restricted.t -- ...
#
# $Id: 13restricted.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## restricted reading
#########################################################

sub TestHandler8::new{bless{ok1=>0,ok2=>0},shift}
sub TestHandler8::error {
    my $s = shift;
    my $e = shift;
    
    return unless defined $s and defined $e;
    
    $s->{ok2}++ if $e->{Message} =~ /^E:\s+/ and
                   $e->{Type} eq 'otherError';
}
sub TestHandler8::start_element{shift->{ok1}--}

my $h8 = TestHandler8->new;

$p->handler($h8);
$p->restrict_file_reading(1);

lives_ok { $p->parse("samples/../samples/no-doctype.xml") }
  'must not read paths with ..';

is($h8->{ok1}, 0, 'must not read paths with ..');
isnt($h8->{ok2}, 0, 'must not read paths with ..');
$h8->{ok1} = 0;
$h8->{ok2} = 0;

lives_ok { $p->parse("./samples/no-doctype.xml") }
  'must not read paths with ./';

is($h8->{ok1}, 0, 'must not read paths with ./');
isnt($h8->{ok2}, 0, 'must not read paths with ./');
$h8->{ok1} = 0;
$h8->{ok2} = 0;

my $sd = File::Spec->catfile(File::Spec->rel2abs('.'), 'samples');

$p->search_dirs($sd);

lives_ok { $p->parse(File::Spec->catfile($sd, 'no-doctype.xml')) }
  'allow to read sample dir in restricted mode';

isnt($h8->{ok1}, 0, 'allow to read sample dir in restricted mode');
is($h8->{ok2}, 0, 'allow to read sample dir in restricted mode');

$p->search_dirs([]);
$p->restrict_file_reading(0);

