use strict;
use warnings;

use lib "lib";
use lib "t/testapp/lib";

use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;

$ENV{DANCER_CONFDIR} = 't/testapp';

require t::testapp::lib::Site;

my $app = Site->to_app;

my $incipit = <<EOINCIPIT;
<div class="incipit"><p>Lorem ipsum dolor sit amet, in phaedrum explicari constituam pro, graeco malorum et vix. Mei an habe...</p>
</div>
EOINCIPIT

my $abstract = <<EOABSTRACT;
<div class="abstract"><p>Lorem ipsum dolor sit amet, in phaedrum explicari constituam pro, graeco malorum et vix. Mei an habemus abhorreant, viris eligendi perfecto duo eu. Bonorum propriae convenire an sit. Eu qualisque adipiscing eos, vel dico stet in. Ad iuvaret delicata vim, in pro audire alterum, eos bonorum persequeris id.</p>

<p>Virtute epicurei eu vim. Usu aeque dicam id, utamur assentior ad est, te sed sale tamquam recusabo. Vim ea sanctus ancillae. Qui velit facilis tacimates ea, no alii ignota postulant vis, probo omnesque abhorreant pri cu. Eu pri maluisset persecuti, qui tale intellegebat ut.</p>

<p>Intellegat ullamcorper at vel. Pri omnes torquatos dissentiet at, nemore euismod pri ad. Id alia explicari sit, liber nihil erroribus an vel, nam omnis postea mediocritatem no. Posse etiam sea cu.</p>

<p>Illud admo...</p>
</div>
EOABSTRACT

my $text = <<EOTEXT;
<div class="text"><p>Lorem ipsum dolor sit amet, in phaedrum explicari constituam pro, graeco malorum et vix. Mei an habemus abhorreant, viris eligendi perfecto duo eu. Bonorum propriae convenire an sit. Eu qualisque adipiscing eos, vel dico stet in. Ad iuvaret delicata vim, in pro audire alterum, eos bonorum persequeris id.</p>

<p>Virtute epicurei eu vim. Usu aeque dicam id, utamur assentior ad est, te sed sale tamquam recusabo. Vim ea sanctus ancillae. Qui velit facilis tacimates ea, no alii ignota postulant vis, probo omnesque abhorreant pri cu. Eu pri maluisset persecuti, qui tale intellegebat ut.</p>

<p>Intellegat ullamcorper at vel. Pri omnes torquatos dissentiet at, nemore euismod pri ad. Id alia explicari sit, liber nihil erroribus an vel, nam omnis postea mediocritatem no. Posse etiam sea cu.</p>

<p>Illud admodum salutandi ne pri, impedit corpora antiopam et sit. Pro eloquentiam mediocritatem in, eros erat consul ne his, vel veri incorrupte scriptorem in. Vel omnium eruditi eu, tation dicant mea te, id affert aperiri aliquam vel. Oratio possim dissentias pri te, usu hinc praesent te. Id congue quodsi pro, at corpora concludaturque pri.</p>
</div>
EOTEXT

test_psgi $app, sub {
    my $cb = shift;
    my $site = "http://localhost";
    my $r = $cb->(GET '/chapter/1-test-article');

    like($r->content, qr/$incipit/, "Incipit OK");
    like($r->content, qr/$abstract/, "Abstract OK");
    like($r->content, qr/$text/, "Text OK");
};
done_testing;
