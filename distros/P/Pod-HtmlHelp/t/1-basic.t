# $File: //member/autrijus/Pod-HtmlHelp/t/1-basic.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 672 $ $DateTime: 2002/08/16 18:51:54 $

#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 2 }

require Pod::WinHtml;
ok(1);
require Pod::HtmlHelp;
ok(1);

exit;
