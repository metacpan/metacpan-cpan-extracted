#!/usr/bin/perl
use DBIx::Connector;
use Locale::PO;
use JSON;
use Encode;
use SQL::Abstract;

my $dbuser = ((getpwuid $>)[0]);
my $dbname = $dbuser;
my $dbpass = "";
my $conn;
my $fname;
my $language;

for (my $i = 0 ; $i < @ARGV ; ++$i) {
	if ($ARGV[$i] =~ /^-/) {
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
	} else {
		$fname = $ARGV[$i];
	}
}

die <<USAGE if not $fname;
import-po.pl [options] filename
  -dbname  full dsn or PostreSQL db name
  -dbuser  db user
  -dbpass  db password
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

my $aref = Locale::PO->load_file_asarray($fname);

if (Locale::PO->dequote($aref->[0]->msgid) ne '') {
	die "unknown PO-file format $fname";
}

my $header       = Locale::PO->dequote($aref->[0]->msgstr);
my %header_lines = map {
	my ($h, $v) = split /:/, $_, 2;
	$v =~ s/^\s+//;
	($h => $v)
} split /\\n/, $header;

$language = $header_lines{Language}
  or die "no Language header in PO-file $fname";

db_connect;
my $nls_lang = $conn->run(
	sub {
		if ($language =~ /^[a-z]{2}$/) {
			$_->selectrow_hashref('select * from nls_lang where short = ?', undef, $language);
		} else {
			$_->selectrow_hashref('select * from nls_lang where name = ?', undef, $language);
		}
	}
) or die "unknown nls_lang";

my $inserted  = 0;
my $updated   = 0;
my $abs_where = SQL::Abstract->new;

for my $msg (@$aref) {
	next if Locale::PO->dequote($msg->msgid) eq '';
	my $msgctxt = $msg->msgctxt;
	$msgctxt = Locale::PO->dequote(decode_utf8 $msgctxt) if defined $msgctxt;
	my $nls_msgid = $conn->run(
		sub {
			my $cond = {
				msgid   => Locale::PO->dequote(decode_utf8 $msg->msgid),
				context => $msgctxt
			};
			my ($where, @bind) = $abs_where->where($cond);
			$_->selectrow_hashref('select * from nls_msgid ' . $where, undef, @bind);
		}
	);
	my $plural =
	  $msg->msgid_plural
	  ? Locale::PO->dequote(decode_utf8 $msg->msgid_plural)
	  : undef;
	if (!$nls_msgid) {
		$nls_msgid = $conn->run(
			sub {
				if ($plural) {
					my $cond = {msgid => $plural, context => $msgctxt};
					my ($where, @bind) = $abs_where->where($cond);
					$_->do('delete from nls_msgid ' . $where, undef, @bind);
				}
				$_->do(
					'insert into nls_msgid (msgid, msgid_plural, context) values(?, ?, ?)',
					undef, Locale::PO->dequote(decode_utf8 $msg->msgid),
					$plural, $msgctxt
				);
				$_->selectrow_hashref('select * from nls_msgid where msgid = ?',
					undef, Locale::PO->dequote(decode_utf8 $msg->msgid));
			}
		);
	} else {
		if (   ($plural || $nls_msgid->{msgid_plural})
			&& ((!$msgctxt && !$nls_msgid->{context}) || $msgctxt eq $nls_msgid->{context})
			&& $nls_msgid->{msgid_plural} ne $plural)
		{
			my $cond = {
				msgid   => $nls_msgid->{msgid},
				context => $msgctxt
			};
			my ($where, @bind) = $abs_where->where($cond);
			$conn->run(
				sub {
					$_->do('update nls_msgid set msgid_plural = ? ' . $where, undef, $plural, @bind);
				}
			);
		}
	}
	my $nls_message = $conn->run(
		sub {
			$_->selectrow_hashref(
				'select * from nls_message where id_nls_msgid = ? and short = ?',
				undef, $nls_msgid->{id_nls_msgid},
				$nls_lang->{short}
			);
		}
	);

	my $msgstr;
	if ($msg->msgstr) {
		$msgstr = [Locale::PO->dequote(decode_utf8 $msg->msgstr)];
	} elsif ($msg->msgstr_n && %{$msg->msgstr_n}) {
		my $hrf = $msg->msgstr_n;
		$msgstr = [];
		my %msgh           = %{$msg->msgstr_n};
		my $have_non_empty = 0;
		for my $km (keys %msgh) {
			$msgstr->[$km] = Locale::PO->dequote(decode_utf8 $msgh{$km});
			$have_non_empty = 1 if $msgstr->[$km] ne '';
		}
		if (!$have_non_empty) {
			$msgstr = [$nls_msgid->{msgid}, $plural];
		}
	} else {
		$msgstr = [$nls_msgid->{msgid}];
		push @$msgstr, $plural if $plural;
	}
	if (@$msgstr > 1 || $msgstr->[0] ne '') {
		if ($nls_message) {
			if (to_json($msgstr) ne $nls_message->{message_json}) {
				$conn->run(
					sub {
						$_->do(
							'update nls_message set message_json = ? where id_nls_msgid = ? and short = ?',
							undef, to_json($msgstr), $nls_msgid->{id_nls_msgid},
							$nls_lang->{short}
						);
					}
				);
				++$updated;
			}
		} else {
			$conn->run(
				sub {
					$_->do(
						'insert into nls_message (id_nls_msgid, short, message_json) values(?, ?, ?)',
						undef, $nls_msgid->{id_nls_msgid},
						$nls_lang->{short}, to_json($msgstr)
					);
				}
			);
			++$inserted;
		}
	}
}

print "Updated $language; updated $updated records; inserted $inserted new records\n";
