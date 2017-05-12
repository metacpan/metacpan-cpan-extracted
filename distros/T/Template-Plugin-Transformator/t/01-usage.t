#!perl

use Test::More tests => ( 4 * 2 ) + 2;

BEGIN {
    use_ok('Template');
}

my $template = Template->new;

is( ref $template => 'Template' );

my ( $tt, $rs );

sub test {
    my ( $in, $out, $stack, $testname ) = @_;
    my $tmp = '';
    ok( $template->process( \$in, $stack || {}, \$tmp ) );
    diag $template->error if $template->error;
    is( $tmp, $out, $testname );
}

test <<'EOA', <<'EOB';
[%- USE Transformator; FILTER $Transformator 'jade' -%]
span
	| Hi!
[% END %]
EOA
<span>Hi!</span>
EOB

test <<'EOA', <<'EOB', { vars => { name => 'Peter' } };
[%- USE Transformator; FILTER $Transformator 'jade', vars -%]
span
	| Hi #{name}!
[% END %]
EOA
<span>Hi Peter!</span>
EOB

test <<'EOA', <<'EOB';
[%- USE jade = Transformator 'jade'; FILTER $jade -%]
span
	| Hi!
[% END %]
EOA
<span>Hi!</span>
EOB

test <<'EOA', <<'EOB', { vars => { name => 'Peter' } };
[%- USE jade = Transformator engine => 'jade'; FILTER $jade vars -%]
span
	| Hi #{name}!
[% END %]
EOA
<span>Hi Peter!</span>
EOB

done_testing;
