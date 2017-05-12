use Test;
BEGIN { plan tests => 1 }
use Template;
use strict;

my $t = Template->new;
ok($t);
$t->process(\*DATA) or die $t->error;

__DATA__
[% 
   options = { Directory => 't/',
        Generate => 'MD5',
        Lock => 'Null',
        Serialize => 'Storable',
        Store => 'File' }
%] 

[% TRY %]
   [% USE my_sess = Session ( undef, options ) %]
[% CATCH Session %]
   Can't create/restore session id
[% CATCH %]
   Unexpected exception: [% error %]
[% END %]

[% my_sess.set('my_key' => 'foo') %]
