package PEF::Front::NLS;
use strict;
use warnings;
use PEF::Front::Config;
use PEF::Front::Connector;
use Geo::IPfree;
use JSON;
use Storable;
use MLDBM::Sync;
use MLDBM qw(MLDBM::Sync::SDBM_File Storable);
use Fcntl qw(:DEFAULT :flock);

use base 'Exporter';

our @EXPORT = qw{
  msg_get
  msg_get_n
};

sub msg_peek {
	my ($lang, $msgid) = @_;
	my $found = 1;
	my $id_nls_msgid;
	my $message_json;
	if (cfg_no_nls) {
		$message_json = to_json([$msgid]);
	} else {
		db_connect->run(
			sub {
				($message_json, $id_nls_msgid) = $_->selectrow_array(
					q{
						select message_json, id_nls_msgid
						from nls_message join nls_msgid using (id_nls_msgid)
						where (msgid = ? or msgid_plural = ?) and short = ?
					},
					undef, $msgid, $msgid, $lang
				);
				if (not defined $message_json) {
					$found = 0;
					($id_nls_msgid) = $_->selectrow_array(
						q{
							select id_nls_msgid
						   	from nls_msgid
						   	where msgid = ? or msgid_plural = ?
						},
						undef, $msgid, $msgid
					);
				}
			}
		);
	}
	return {
		message_json => $message_json,
		found        => $found,
		msgid        => $msgid,
		id_nls_msgid => $id_nls_msgid
	};
}

sub msg_get {
	my ($lang, $msgid, @params) = @_;
	my $ret = msg_peek($lang, $msgid);
	my $decode_msg = sub {
		my $msgstr = eval { from_json $ret->{message_json} };
		if ($@) {
			$ret->{found} = 0;
			warn "from_json: $@";
		} else {
			$ret->{message} = $msgstr->[0];
		}
	};
	if (not $ret->{found}) {
		if (cfg_collect_unknown_msgid and not defined $ret->{id_nls_msgid}) {
			tie (my %dbm, 'MLDBM::Sync', cfg_unknown_msgid_db, O_CREAT | O_RDWR, 0666) or warn "$!";
			$dbm{$msgid} = 'singular';
		}
		if (not cfg_no_multilang_support and defined $ret->{id_nls_msgid}) {
			my ($alt_lang) = db_connect->run(
				sub {
					$_->selectrow_array(q{select alternative from nls_lang where short = ?}, undef, $lang);
				}
			);
			$alt_lang ||= cfg_default_lang;
			$ret = msg_peek($lang, $msgid);
		}
		if ($ret->{found}) {
			$decode_msg->();
		}
	} else {
		if (cfg_no_nls) {
			$ret->{message} = $msgid;
		} else {
			$decode_msg->();
		}
	}
	$ret->{message} = $msgid if not $ret->{found};
	$ret->{message} =~ s/\$(\d+)/$params[$1-1]/g if @params;
	delete $ret->{id_nls_msgid};
	delete $ret->{message_json};
	return $ret;
}

my %plurals_sub = ();

sub msg_get_n {
	my ($lang, $msgid, $num, @params) = @_;
	my $ret           = msg_peek($lang, $msgid);
	my $selected_lang = $lang;
	my $decode_msg    = sub {
		my $idx = 0;
		if (not exists $plurals_sub{$selected_lang}) {
			my $plural_forms = db_connect->run(
				sub {
					$_->selectrow_array(q{select plural_forms from nls_lang where short = ?}, undef, $selected_lang);
				}
			);
			my $sub = eval "sub {my \$n = \$_[0]; 0 + ($plural_forms)}";
			if ($sub) {
				$plurals_sub{$selected_lang} = $sub;
			} else {
				warn "plural_forms($selected_lang): $@";
			}
		}
		if (exists $plurals_sub{$selected_lang}) {
			$idx = $plurals_sub{$selected_lang}->($num);
		}
		my $msgstr = eval { from_json $ret->{message_json} };
		if ($@) {
			$ret->{found} = 0;
			warn "from_json: $@";
		} else {
			$ret->{message} = $msgstr->[$idx];
		}
	};
	if (not $ret->{found}) {
		if (cfg_collect_unknown_msgid and not defined $ret->{id_nls_msgid}) {
			tie (my %dbm, 'MLDBM::Sync', cfg_unknown_msgid_db, O_CREAT | O_RDWR, 0666) or warn "$!";
			$dbm{$msgid} = 'plural';
		}
		if (not cfg_no_multilang_support and defined $ret->{id_nls_msgid}) {
			my ($alt_lang) = db_connect->run(
				sub {
					$_->selectrow_array(q{select alternative from nls_lang where short = ?}, undef, $lang);
				}
			);
			$alt_lang ||= cfg_default_lang;
			$ret = msg_peek($lang, $msgid);
			$selected_lang = $alt_lang if $ret->{found};
		}
		if ($ret->{found}) {
			$decode_msg->();
		}
	} else {
		if (cfg_no_nls) {
			$ret->{message} = $msgid;
		} else {
			$decode_msg->();
		}
	}
	$ret->{message} = $msgid if not $ret->{found};
	$ret->{message} =~ s/\$(\d+)/$params[$1-1]/g if @params;
	delete $ret->{id_nls_msgid};
	delete $ret->{message_json};
	return $ret;
}

my $gi = Geo::IPfree->new;

sub check_avail_lang {
	return if cfg_no_multilang_support;
	my $lang = $_[0];
	my ($avail) = db_connect->run(
		sub {
			$_->selectrow_array(q{select short from nls_lang where short = ? and is_active}, undef, $lang);
		}
	);
	defined $avail;
}

sub guess_lang {
	my $request    = $_[0];
	my $cookie_ref = $request->cookies;
	my $lang =
	  (exists ($cookie_ref->{'lang'}) ? $cookie_ref->{'lang'} : undef);
	$lang = undef
	  if $lang
	  and $lang ne cfg_default_lang
	  and not check_avail_lang $lang;
	if (cfg_no_multilang_support and not $lang) {
		$lang = cfg_default_lang;
	} elsif (not $lang) {
		my $al = $request->header('Accept-Language');
		if ($al) {
			my @al = map { $_->{short} }
			  reverse
			  sort {
				if ($a->{pref} == 1 && $b->{pref} == 1) {
					1;
				} else {
					$a->{pref} <=> $b->{pref};
				}
			  }
			  map {
				my ($l, undef, $q) = $_ =~ /([\w-]+)(;\s*q=)?(\d\.\d+)?/;
				$l =~ s/-.*//;
				$q
				  ? {short => $l, pref => $q}
				  : {short => $l, pref => 1}
			  }
			  split /,/, $al;
			my %alset;
			for my $tl (@al) {
				next if exists $alset{$tl};
				$alset{$tl} = undef;
				if (check_avail_lang $tl) {
					$lang = $tl;
					last;
				}
			}
		}
		if (not $lang) {
			my $country = lc (($gi->LookUp($request->remote_ip))[0]);
			($lang) = db_connect->run(
				sub {
					$_->selectrow_array(q{select short from nls_geo where country = ?}, undef, $country);
				}
			);
			$lang = cfg_default_lang if not check_avail_lang $lang;
		}
		$lang = cfg_default_lang if not defined $lang;
	}
	return $lang;
}

1;

__END__

=head1 NAME
 
PEF::Front::NLS - Localization support

=head1 SYNOPSIS

  my $comments_number_text = msg_get_n(
    $context->{lang}, 
    '$1 comments', 
    $comment_count, 
    $comment_count
  )->{message};

=head1 DESCRIPTION

Sometimes application has to return localized messages.

=head1 FUNCTIONS

=head2 msg_get($lang, $msgid, @params)

Returns localized text for message C<$msgid> and language C<$lang>. 
It supports parameterized messages like:

  my $message = msg_get($context->{lang}, 'Hello $1', $user->{name});.

=head2 msg_get_n($lang, $msgid, $num, @params)

This works like Cmsg_get> but supports singular/plural forms. 
C<$num> is used to select right form.

=head2 msg_peek($lang, $msgid)

Checks whether there's localized text for given C<$lang, $msgid> in database.

=head2 guess_lang($request)

Returns short (ISO 639-1) language code. 
This function automatically detect language based on URL, HTTP headers,
cookies and Geo IP. You can turn it off 
setting C<cfg_no_multilang_support> to true. When it can't detect
language or language detection is off then it returns C<cfg_default_lang>.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
