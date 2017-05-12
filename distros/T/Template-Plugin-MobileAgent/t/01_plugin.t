use strict;
use Template::Test;

$ENV{HTTP_USER_AGENT} = "J-PHONE/2.0/J-DN02";

test_expect(\*DATA);

__END__
-- test --
[%- USE agent = MobileAgent('DoCoMo/1.0/F504i/c10/TB') -%]
[% IF agent.is_docomo -%]
DoCoMo
[% ELSE %]
not DoCoMo
[% END -%]
-- expect --
DoCoMo

-- test --
[%- USE MobileAgent -%]
[% MobileAgent.name %]
-- expect --
J-PHONE

