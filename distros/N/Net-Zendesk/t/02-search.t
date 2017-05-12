use strict;
use warnings;
use Test::More;

################
## Below are tests for the internal parsing of query data
################

use Net::Zendesk;

my $data;

$data = Net::Zendesk->_parse_search_args({
    type => 'ticket'
});
is_deeply($data, ['type:ticket'], 'basic equality');

$data = Net::Zendesk->_parse_search_args({
    subject => 'long text'
});
is_deeply($data, ['subject:"long text"'], 'basic equality (long text)');

$data = Net::Zendesk->_parse_search_args({
    subject => undef
});
is_deeply($data, ['subject:none'], 'basic equality (no data)');

$data = Net::Zendesk->_parse_search_args({
    subject => 'photo*'
});
is_deeply($data, ['subject:photo*'], 'basic equality (wildcard)');

$data = Net::Zendesk->_parse_search_args({
    type => { '=' => 'ticket' }
});
is_deeply($data, ['type:ticket'], 'hashref equality');

$data = Net::Zendesk->_parse_search_args({
    subject => { '=' => 'long text' }
});
is_deeply($data, ['subject:"long text"'], 'hashref equality (long text)');

$data = Net::Zendesk->_parse_search_args({
    priority => { '=' => undef }
});
is_deeply($data, ['priority:none'], 'hashref equality (no data)');

$data = Net::Zendesk->_parse_search_args({
    priority => { '>' => 'normal' }
});
is_deeply($data, ['priority>normal'], 'basic inequality (>)');

$data = Net::Zendesk->_parse_search_args({
    priority => { '>=' => 'normal' }
});
is_deeply($data, ['priority>=normal'], 'basic inequality (>=)');

$data = Net::Zendesk->_parse_search_args({
    priority => { '<' => 'normal' }
});
is_deeply($data, ['priority<normal'], 'basic inequality (<)');

$data = Net::Zendesk->_parse_search_args({
    priority => { '<=' => 'normal' }
});
is_deeply($data, ['priority<=normal'], 'basic inequality (<=)');

$data = Net::Zendesk->_parse_search_args({
    priority => { '!=' => 'normal' }
});
is_deeply($data, ['-priority:normal'], 'basic exclusion (!=)');

$data = Net::Zendesk->_parse_search_args({
    -priority => 'normal',
});
is_deeply($data, ['-priority:normal'], 'basic exclusion (-)');

$data = Net::Zendesk->_parse_search_args({
    -priority => { '>' => 'normal' }
});
is_deeply($data, ['-priority>normal'], 'negation with inequality');

$data = Net::Zendesk->_parse_search_args({
    status => ['new', 'open'],
});
is_deeply($data, ['status:new', 'status:open'], 'OR-ed data');

$data = Net::Zendesk->_parse_search_args({
    status => ['new', undef],
});
is_deeply($data, ['status:new', 'status:none'], 'OR-ed with no data');

$data = Net::Zendesk->_parse_search_args({
    status => { '=' => ['new', undef] },
});
is_deeply($data, ['status:new', 'status:none'], 'hashref (=) with with no data');

$data = Net::Zendesk->_parse_search_args({
    status => { 'or' => ['new', undef] },
});
is_deeply($data, ['status:new', 'status:none'], 'hashref (or) with with no data');

$data = Net::Zendesk->_parse_search_args({
    status => { 'and' => ['new', undef] },
});
is_deeply($data, ['status:new none'], 'hashref (and) with with no data');

$data = Net::Zendesk->_parse_search_args({
    nonsense => { '>' => undef, '<=' => 'long text', '=' => 'str' },
});
is_deeply(
    [ sort @$data ],
    ['nonsense:str', 'nonsense<="long text"', 'nonsense>none'],
    'hashref with multiple conditions'
);

done_testing;
