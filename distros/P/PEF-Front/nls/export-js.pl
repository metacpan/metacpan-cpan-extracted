#!/usr/bin/perl
use DBIx::Connector;
use Encode;
use JSON;
use Data::Dumper;

my $dbuser = ((getpwuid $>)[0]);
my $dbname = $dbuser;
my $dbpass = "";
my $conn;
my $fname;
my $lang;

for (my $i = 0; $i < @ARGV; ++$i) {
	if ($ARGV[$i] =~ /^-\S/) {
		$ARGV[$i] =~ /^-dbname/ && do {
			$dbname = $ARGV[$i + 1];
			++$i;
		};
		$ARGV[$i] =~ /^-dbuser/ && do {
			$dbuser = $ARGV[$i + 1];
			++$i;
		};
		$ARGV[$i] =~ /^-dbpass/ && do {
			$dbpass = $ARGV[$i + 1];
			++$i;
		};
		$ARGV[$i] =~ /^-lang/ && do {
			$lang = $ARGV[$i + 1];
			++$i;
		};
	} else {
		$fname = $ARGV[$i];
	}
}

if (!$lang && $fname) {
	($lang) = $fname =~ /[^a-z]([a-z]{2})\./i;
	$lang = lc $lang if $lang;
}

die <<USAGE if not $fname or not $lang;
export-js.pl [options] filename
  -dbname  full dsn or PostreSQL db name
  -dbuser  db user
  -dbpass  db password
  -lang    short lang code (ISO 639-1:2002) or language name
USAGE

sub db_connect {
	$dbname = "dbi:Pg:dbname=$dbname" if $dbname !~ /^dbi:/;
	my ($driver) = $dbname =~ /^dbi:([^:]+):/;
	my $attrs = {
		AutoCommit          => 1,
		PrintError          => 0,
		AutoInactiveDestroy => 1,
		RaiseError          => 1,
	};
	$attrs->{pg_enable_utf8}    = 1 if $driver eq 'Pg';
	$attrs->{mysql_enable_utf8} = 1 if $driver eq 'mysql';
	$conn = DBIx::Connector->new($dbname, $dbuser, $dbpass, $attrs)
		or die "SQL_connect: " . DBI->errstr();
	$conn->mode('fixup');
	$conn;
}

sub _quote_var {
	my $s = $_[0];
	my $d = Data::Dumper->new([$s]);
	$d->Terse(1);
	my $qs = $d->Dump;
	substr($qs, -1, 1, '') if substr($qs, -1, 1) eq "\n";
	return $qs;
}

db_connect;

my $nls_lang = $conn->run(
	sub {
		if ($lang =~ /^[a-z]{2}$/) {
			$_->selectrow_hashref('select * from nls_lang where short = ?', undef, $lang);
		} else {
			$_->selectrow_hashref('select * from nls_lang where name = ?', undef, $lang);
		}
	}
) or die "unknown -lang: $lang";

(my $plural_func = $nls_lang->{plural_forms}) =~ s/\$n/n/g;

my $messages = $conn->run(
	sub {
		$_->selectall_arrayref(
			q{
				select coalesce(context, '') context, msgid, message_json  
				from nls_msgid join nls_message using (id_nls_msgid) 
				where short = ? 
				union 
				select coalesce(context, '') context, msgid_plural, message_json  
				from nls_msgid join nls_message using (id_nls_msgid) 
				where short = ? and msgid_plural is not null
			}, {Slice => {}}, $nls_lang->{short}, $nls_lang->{short}
		);
	}
);

my %ctx;
for my $row (@$messages) {
	my $decoded_msg = from_json($row->{message_json});
	my $message     = $row->{message_json};
	if (ref $decoded_msg eq 'ARRAY' && @$decoded_msg == 1) {
		substr($message, 0,  1, '');
		substr($message, -1, 1, '');
	}
	$ctx{$row->{context}}{$row->{msgid}} = $message;
}

my $messages_with_contexts = '';
for my $ctx (keys %ctx) {
	$messages_with_contexts .= '    ' . _quote_var($ctx) . ": {\n";
	for my $msgid (keys %{$ctx{$ctx}}) {
		$messages_with_contexts .= '      ' . _quote_var($msgid) . ": " . $ctx{$ctx}{$msgid} . ",\n"
	}
	$messages_with_contexts .= "    },\n";
}

my $i18n_tmpl = <<EOT;
if (typeof i18n === 'undefined')
  var i18n = {};
i18n.$nls_lang->{short} = {
  nplurals: $nls_lang->{nplurals},
  plural: function (n) {
    return $plural_func;
  },
  context: {
$messages_with_contexts
  }
}

EOT

if($fname eq '-') {
	print $i18n_tmpl;
} else {
	open my $fout, ">", $fname or die "Error writing file $fname: $!";
	print $fout $i18n_tmpl;
	close $fout;
}
