# vim:syntax=perl
#!/usr/bin/perl -w

use strict;

my %uniforms = (
'psyc://:d' => { 
    'unl' => 'psyc://:d',
    'transport' => 'd',
    'scheme' => 'psyc',
},
'psyc://funky-subdomain.test_host.er:34c' => {
    'unl' => 'psyc://funky-subdomain.test_host.er:34c',
    'port' => 34,
    'host' => 'funky-subdomain.test_host.er',
    'transport' => 'c',
    'scheme' => 'psyc',
},
'mailto:test@sample.org:9999' => { 
    'unl' => 'mailto:test@sample.org:9999',
    'scheme' => 'mailto',
    'user' => 'test',
    'host' => 'sample.org',
    'port' => 9999,
},
'xmpp:test@sample.org' => {
    'unl' => 'xmpp:test@sample.org',
    'scheme' => 'xmpp',
    'user' => 'test',
    'host' => 'sample.org',
},
'psyc://test@sample.org:56d/~hey' => {
    'unl' => 'psyc://test@sample.org:56d/~hey',
    'user' => 'test',
    'host' => 'sample.org',
    'object' => '~hey',
    'transport' => 'd',
    'port' => 56,
    'scheme' => 'psyc',
},
# some that should produce errors:
'xmpp:test@sample.org:c' => 0,
'psyc://test@samplüe.org:56d/~hey' => 0,
# we do not support punicode yet.
);

# this stream contains several packets to make error detection easier
my $mmp_stream = <<X;
:_source	blub
:_target	wupp
.
=_source	blub
=_target	wupp

.

:_uah	wua
:_blua  dua
wuark
sldjf södflkjsdl kjf
.

.
+_wurst	ist lecker

_lsdkjfldkfjdlkfjg
dlkfjgd+
dlfkjg
dflkjg...
.
X

my @mmp_results = (
[ 
  {
  '_source' => 'blub',
  '_target' => 'wupp',
  },
  ''
],
[ 
  {
  '=_source' => 'blub',
  '=_target' => 'wupp',
  '_target' => 'wupp',
  '_source' => 'blub',
  },
  ''
],
[ 
  {},
  ":_uah	wua\n:_blua  dua\nwuark\nsldjf södflkjsdl kjf"
],
[
  {},
  ''
],
[
  { '+_wurst' => 'ist lecker' },
  "_lsdkjfldkfjdlkfjg\ndlkfjgd+\ndlfkjg\ndflkjg..."
],
);

require Test::Simple;
import Test::Simple tests => scalar( keys %uniforms) + 1;

use Net::PSYC qw(setDEBUG parse_psyc parse_mmp parse_uniform);

# different tyoes of uniforms to parse... with results
#
# missing entries are ''

sub test_uniform {
    my ($url, $result) = @_;
    my $u = parse_uniform($url);

    return $result == $u unless ($result);
    
    foreach (keys %$u) {
	if ($_ eq 'port' && $u->{$_} ne '') {
	    unless (exists $result->{$_} && $u->{$_} == $result->{$_}) {
    print STDERR "\t $_ does not match. '$u->{$_}' vs '$result->{$_}'\n";
		return 0;
	    }
	} elsif ($u->{$_} eq '') {
	    if (exists $result->{$_}) {
    print STDERR "\t $_ does not match. '' vs '$result->{$_}'\n";
		return 0;
	    }
	} else { 
	    unless (exists $result->{$_} && $result->{$_} eq $u->{$_}) {
    print STDERR "\t $_ does not match. '$u->{$_}' vs '$result->{$_}'\n";
		return 0;
	    }
	}
    }
    1;
}

sub test_mmp {
    my ($mmp_stream, @mmp_results) = @_;
    
    use Storable qw(freeze);
    $Storable::canonical = 1;

    foreach (@mmp_results) {
	my ($vars, $data) = parse_mmp(\$mmp_stream);

	unless ($vars) {
    print STDERR "\t The parser says: $data. We are supposed to use correct ".
	    "mmp-packets for testing only.\n";
	    return 0;
	}

	unless ($_->[1] eq $data) {
    print STDERR "\t The data is not equal: '$data' vs '$_->[1]'.\n";
	    return 0;
	}

	unless (freeze($_->[0]) eq freeze($vars)) {
    print STDERR sprintf "\t The variable hashes are not equal.\n '%s' vs '%s'\n",
		    freeze($_->[0]), freeze($vars);
	    return 0;
	}
    }

    if ($mmp_stream ne '') {
	print STDERR "\t The parser did not eat everything. Rest: '$mmp_stream'.\n";
	return 0;
    }

    1;
}

print STDERR "Testing the uniform parser:\n";
foreach (keys %uniforms) {
    ok( test_uniform($_, $uniforms{$_}), "Parsing '$_'" );
}

print STDERR "\nTesting the mmp parser:\n\n";
ok( test_mmp($mmp_stream, @mmp_results), 'Parsing mmp.');

__END__
