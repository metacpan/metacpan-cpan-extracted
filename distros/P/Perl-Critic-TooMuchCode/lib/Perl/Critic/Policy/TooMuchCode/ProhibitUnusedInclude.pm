package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedInclude;

use strict;
use warnings;
use Scalar::Util qw(refaddr);
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

sub supported_parameters {
    return (
        +{
            name => 'ignore',
            description => 'List of modules to be disregarded. Separated by whitespaces.',
            behavior => 'string list',
        }
    )
}

#---------------------------------------------------------------------------

use constant {
    ## Some modules works like pragmas -- their very existence in the code implies that they are used.
    PRAGMATIST => {
        map { $_ => 1 }
        qw(
              Moose
              Mouse
              Moo
              Mo
              Test::NoWarnings
        )
    },

    TRY_FAMILY => {
        map { $_ => 1 }
        qw(Try::Tiny Try::Catch Try::Lite TryCatch Try)
    },

    ## These are the modules that, when used, the module name itself appears in the code.
    USE_BY_MODULE_NAME => {
        map { $_ => 1 }
        qw(Hijk HTTP::Tiny HTTP::Lite LWP::UserAgent File::Spec)
    },

    ## this mapping fines a set of modules with behaviour that introduce
    ## new words as subroutine names or method names when they are `use`ed
    ## without arguments.
    #### for mod in $(perlbrew list-modules) Test2::V0; do perl -M${mod} -l -e 'if (my @e = grep /\A\w+\z/, (@'$mod'::EXPORT) ) { print "### \x27'$mod'\x27 => [qw(@e)],"; }' \;  2>/dev/null | grep '^### ' | cut -c 5- ; done
    DEFAULT_EXPORT => {
        'App::ModuleBuildTiny'         => [qw(modulebuildtiny)],
        'B::Hooks::EndOfScope'         => [qw(on_scope_end)],
        'Carp::Assert'                 => [qw(assert affirm should shouldnt DEBUG assert affirm should shouldnt DEBUG)],
        'Carp::Assert::More'           => [qw(assert_all_keys_in assert_arrayref assert_coderef assert_defined assert_empty assert_exists assert_fail assert_hashref assert_in assert_integer assert_is assert_isa assert_isa_in assert_isnt assert_lacks assert_like assert_listref assert_negative assert_negative_integer assert_nonblank assert_nonempty assert_nonnegative assert_nonnegative_integer assert_nonref assert_nonzero assert_nonzero_integer assert_numeric assert_positive assert_positive_integer assert_undefined assert_unlike)],
        'Class::Method::Modifiers'     => [qw(before after around)],
        'Compress::Raw::Bzip2'         => [qw(BZ_RUN BZ_FLUSH BZ_FINISH BZ_OK BZ_RUN_OK BZ_FLUSH_OK BZ_FINISH_OK BZ_STREAM_END BZ_SEQUENCE_ERROR BZ_PARAM_ERROR BZ_MEM_ERROR BZ_DATA_ERROR BZ_DATA_ERROR_MAGIC BZ_IO_ERROR BZ_UNEXPECTED_EOF BZ_OUTBUFF_FULL BZ_CONFIG_ERROR)],
        'Compress::Raw::Zlib'          => [qw(ZLIB_VERSION ZLIB_VERNUM OS_CODE MAX_MEM_LEVEL MAX_WBITS Z_ASCII Z_BEST_COMPRESSION Z_BEST_SPEED Z_BINARY Z_BLOCK Z_BUF_ERROR Z_DATA_ERROR Z_DEFAULT_COMPRESSION Z_DEFAULT_STRATEGY Z_DEFLATED Z_ERRNO Z_FILTERED Z_FIXED Z_FINISH Z_FULL_FLUSH Z_HUFFMAN_ONLY Z_MEM_ERROR Z_NEED_DICT Z_NO_COMPRESSION Z_NO_FLUSH Z_NULL Z_OK Z_PARTIAL_FLUSH Z_RLE Z_STREAM_END Z_STREAM_ERROR Z_SYNC_FLUSH Z_TREES Z_UNKNOWN Z_VERSION_ERROR WANT_GZIP WANT_GZIP_OR_ZLIB crc32 adler32 DEF_WBITS)],
        'Cookie::Baker'                => [qw(bake_cookie crush_cookie)],
        'Cpanel::JSON::XS'             => [qw(encode_json decode_json to_json from_json)],
        'Crypt::RC4'                   => [qw(RC4)],
        'DBIx::DSN::Resolver::Cached'  => [qw(dsn_resolver)],
        'DBIx::DisconnectAll'          => [qw(dbi_disconnect_all)],
        'Data::Clone'                  => [qw(clone)],
        'Data::Compare'                => [qw(Compare)],
        'Data::Dump'                   => [qw(dd ddx)],
        'Data::NestedParams'           => [qw(expand_nested_params collapse_nested_params)],
        'Data::UUID'                   => [qw(NameSpace_DNS NameSpace_OID NameSpace_URL NameSpace_X500)],
        'Data::Validate::Domain'       => [qw(is_domain is_hostname is_domain_label)],
        'Data::Validate::IP'           => [qw(is_ip is_ipv4 is_ipv6 is_innet_ipv4 is_multicast_ipv4 is_testnet_ipv4 is_anycast_ipv4 is_loopback_ipv4 is_private_ipv4 is_unroutable_ipv4 is_linklocal_ipv4 is_public_ipv4 is_loopback_ipv6 is_orchid_ipv6 is_special_ipv6 is_multicast_ipv6 is_private_ipv6 is_linklocal_ipv6 is_ipv4_mapped_ipv6 is_documentation_ipv6 is_teredo_ipv6 is_discard_ipv6 is_public_ipv6 is_linklocal_ip is_loopback_ip is_multicast_ip is_private_ip is_public_ip)],
        'Data::Walk'                   => [qw(walk walkdepth)],
        'Devel::CheckCompiler'         => [qw(check_c99 check_c99_or_exit check_compile)],
        'Devel::CheckLib'              => [qw(assert_lib check_lib_or_exit check_lib)],
        'Devel::GlobalDestruction'     => [qw(in_global_destruction)],
        'Dist::CheckConflicts'         => [qw(conflicts check_conflicts calculate_conflicts dist)],
        'Email::MIME::ContentType'     => [qw(parse_content_type parse_content_disposition)],
        'Encode'                       => [qw(decode decode_utf8 encode encode_utf8 str2bytes bytes2str encodings find_encoding find_mime_encoding clone_encoding)],
        'Eval::Closure'                => [qw(eval_closure)],
        'ExtUtils::MakeMaker'          => [qw(WriteMakefile prompt os_unsupported)],
        'File::HomeDir'                => [qw(home)],
        'File::Listing'                => [qw(parse_dir)],
        'File::Path'                   => [qw(mkpath rmtree)],
        'File::ShareDir::Install'      => [qw(install_share delete_share)],
        'File::Which'                  => [qw(which)],
        'File::Zglob'                  => [qw(zglob)],
        'File::pushd'                  => [qw(pushd tempd)],
        'Graphics::ColorUtils'         => [qw(rgb2yiq yiq2rgb rgb2cmy cmy2rgb rgb2hls hls2rgb rgb2hsv hsv2rgb)],
        'HTML::Escape'                 => [qw(escape_html)],
        'HTTP::Date'                   => [qw(time2str str2time)],
        'HTTP::Negotiate'              => [qw(choose)],
        'IO::All'                      => [qw(io)],
        'IO::HTML'                     => [qw(html_file)],
        'IO::Socket::SSL'              => [qw(SSL_WANT_READ SSL_WANT_WRITE SSL_VERIFY_NONE SSL_VERIFY_PEER SSL_VERIFY_FAIL_IF_NO_PEER_CERT SSL_VERIFY_CLIENT_ONCE SSL_OCSP_NO_STAPLE SSL_OCSP_TRY_STAPLE SSL_OCSP_MUST_STAPLE SSL_OCSP_FAIL_HARD SSL_OCSP_FULL_CHAIN GEN_DNS GEN_IPADD)],
        'IPC::Run3'                    => [qw(run3)],
        'JSON'                         => [qw(from_json to_json jsonToObj objToJson encode_json decode_json)],
        'JSON::MaybeXS'                => [qw(encode_json decode_json JSON)],
        'JSON::PP'                     => [qw(encode_json decode_json from_json to_json)],
        'JSON::Types'                  => [qw(number string bool)],
        'JSON::XS'                     => [qw(encode_json decode_json)],
        'LWP::MediaTypes'              => [qw(guess_media_type media_suffix)],
        'Lingua::JA::Regular::Unicode' => [qw(hiragana2katakana alnum_z2h alnum_h2z space_z2h katakana2hiragana katakana_h2z katakana_z2h space_h2z)],
        'Locale::Currency::Format'     => [qw(currency_format currency_name currency_set currency_symbol decimal_precision decimal_separator thousands_separator FMT_NOZEROS FMT_STANDARD FMT_COMMON FMT_SYMBOL FMT_HTML FMT_NAME SYM_UTF SYM_HTML)],
        'Log::Minimal'                 => [qw(critf critff warnf warnff infof infoff debugf debugff croakf croakff ddf)],
        'MIME::Charset'                => [qw(body_encoding canonical_charset header_encoding output_charset body_encode encoded_header_len header_encode)],
        'Math::Round'                  => [qw(round nearest)],
        'Module::Build::Tiny'          => [qw(Build Build_PL)],
        'Module::Find'                 => [qw(findsubmod findallmod usesub useall setmoduledirs)],
        'Module::Functions'            => [qw(get_public_functions)],
        'Module::Spy'                  => [qw(spy_on)],
        'PLON'                         => [qw(encode_plon decode_pson)],
        'Path::Class'                  => [qw(file dir)],
        'Path::Tiny'                   => [qw(path)],
        'Proc::Wait3'                  => [qw(wait3)],
        'Readonly'                     => [qw(Readonly)],
        'SQL::QueryMaker'              => [qw(sql_op sql_raw sql_and sql_or sql_in sql_not_in sql_ne sql_not sql_like sql_is_not_null sql_is_null sql_ge sql_gt sql_eq sql_lt sql_le sql_between sql_not_between)],
        'Smart::Args'                  => [qw(args args_pos)],
        'Socket'                       => [qw(PF_802 PF_AAL PF_APPLETALK PF_CCITT PF_CHAOS PF_CTF PF_DATAKIT PF_DECnet PF_DLI PF_ECMA PF_GOSIP PF_HYLINK PF_IMPLINK PF_INET PF_INET6 PF_ISO PF_KEY PF_LAST PF_LAT PF_LINK PF_MAX PF_NBS PF_NIT PF_NS PF_OSI PF_OSINET PF_PUP PF_ROUTE PF_SNA PF_UNIX PF_UNSPEC PF_USER PF_WAN PF_X25 AF_802 AF_AAL AF_APPLETALK AF_CCITT AF_CHAOS AF_CTF AF_DATAKIT AF_DECnet AF_DLI AF_ECMA AF_GOSIP AF_HYLINK AF_IMPLINK AF_INET AF_INET6 AF_ISO AF_KEY AF_LAST AF_LAT AF_LINK AF_MAX AF_NBS AF_NIT AF_NS AF_OSI AF_OSINET AF_PUP AF_ROUTE AF_SNA AF_UNIX AF_UNSPEC AF_USER AF_WAN AF_X25 SOCK_DGRAM SOCK_RAW SOCK_RDM SOCK_SEQPACKET SOCK_STREAM SOL_SOCKET SO_ACCEPTCONN SO_ATTACH_FILTER SO_BACKLOG SO_BROADCAST SO_CHAMELEON SO_DEBUG SO_DETACH_FILTER SO_DGRAM_ERRIND SO_DOMAIN SO_DONTLINGER SO_DONTROUTE SO_ERROR SO_FAMILY SO_KEEPALIVE SO_LINGER SO_OOBINLINE SO_PASSCRED SO_PASSIFNAME SO_PEERCRED SO_PROTOCOL SO_PROTOTYPE SO_RCVBUF SO_RCVLOWAT SO_RCVTIMEO SO_REUSEADDR SO_REUSEPORT SO_SECURITY_AUTHENTICATION SO_SECURITY_ENCRYPTION_NETWORK SO_SECURITY_ENCRYPTION_TRANSPORT SO_SNDBUF SO_SNDLOWAT SO_SNDTIMEO SO_STATE SO_TYPE SO_USELOOPBACK SO_XOPEN SO_XSE IP_HDRINCL IP_OPTIONS IP_RECVOPTS IP_RECVRETOPTS IP_RETOPTS IP_TOS IP_TTL MSG_BCAST MSG_BTAG MSG_CTLFLAGS MSG_CTLIGNORE MSG_CTRUNC MSG_DONTROUTE MSG_DONTWAIT MSG_EOF MSG_EOR MSG_ERRQUEUE MSG_ETAG MSG_FASTOPEN MSG_FIN MSG_MAXIOVLEN MSG_MCAST MSG_NOSIGNAL MSG_OOB MSG_PEEK MSG_PROXY MSG_RST MSG_SYN MSG_TRUNC MSG_URG MSG_WAITALL MSG_WIRE SHUT_RD SHUT_RDWR SHUT_WR INADDR_ANY INADDR_BROADCAST INADDR_LOOPBACK INADDR_NONE SCM_CONNECT SCM_CREDENTIALS SCM_CREDS SCM_RIGHTS SCM_TIMESTAMP SOMAXCONN IOV_MAX UIO_MAXIOV sockaddr_family pack_sockaddr_in unpack_sockaddr_in sockaddr_in pack_sockaddr_in6 unpack_sockaddr_in6 sockaddr_in6 pack_sockaddr_un unpack_sockaddr_un sockaddr_un inet_aton inet_ntoa)],
        'String::Format'               => [qw(stringf)],
        'String::ShellQuote'           => [qw(shell_quote shell_quote_best_effort shell_comment_quote)],
        'Sub::Name'                    => [qw(subname)],
        'Sub::Quote'                   => [qw(quote_sub unquote_sub quoted_from_sub qsub)],
        'Sub::Retry'                   => [qw(retry)],
        'Teng::Plugin::TextTable'      => [qw(draw_text_table)],
        'Test2::V0'                    => [qw(ok pass fail diag note todo skip plan skip_all done_testing bail_out intercept context gen_event def do_def cmp_ok warns warning warnings no_warnings subtest can_ok isa_ok DOES_ok set_encoding imported_ok not_imported_ok ref_ok ref_is ref_is_not mock mocked dies lives try_ok is like isnt unlike match mismatch validator hash array bag object meta meta_check number float rounded within string subset bool in_set not_in_set check_set item field call call_list call_hash prop check all_items all_keys all_vals all_values etc end filter_items T F D DF E DNE FDNE U event fail_events exact_ref)],
        'Test::BinaryData'             => [qw(is_binary)],
        'Test::Deep'                   => [qw(Isa blessed obj_isa all any array array_each arrayelementsonly arraylength arraylengthonly bag bool cmp_bag cmp_deeply cmp_methods cmp_set code eq_deeply hash hash_each hashkeys hashkeysonly ignore isa listmethods methods noclass none noneof num re reftype regexpmatches regexponly regexpref regexprefonly scalarrefonly scalref set shallow str subbagof subhashof subsetof superbagof superhashof supersetof useclass)],
        'Test::Differences'            => [qw(eq_or_diff eq_or_diff_text eq_or_diff_data unified_diff context_diff oldstyle_diff table_diff)],
        'Test::Exception'              => [qw(dies_ok lives_ok throws_ok lives_and)],
        'Test::Fatal'                  => [qw(exception)],
        'Test::Kantan'                 => [qw(Feature Scenario Given When Then subtest done_testing setup teardown describe context it before_each after_each expect ok diag ignore spy_on skip_all)],
        'Test::LongString'             => [qw(is_string is_string_nows like_string unlike_string contains_string lacks_string)],
        'Test::Mock::Guard'            => [qw(mock_guard)],
        'Test::More'                   => [qw(ok use_ok require_ok is isnt like unlike is_deeply cmp_ok skip todo todo_skip pass fail eq_array eq_hash eq_set plan done_testing can_ok isa_ok new_ok diag note explain subtest BAIL_OUT)],
        'Test::Object'                 => [qw(object_ok)],
        'Test::Output'                 => [qw(output_like stderr_from output_isnt stderr_is stdout_unlike combined_isnt output_is combined_is stdout_is stderr_isnt stdout_like combined_unlike stderr_unlike output_from combined_from stdout_isnt output_unlike combined_like stdout_from stderr_like)],
        'Test::Simple'                 => [qw(ok)],
        'Test::Spec'                   => [qw(runtests describe xdescribe context xcontext it xit they xthey before after around yield spec_helper share shared_examples_for it_should_behave_like)],
        'Test::Stub'                   => [qw(stub make_stub)],
        'Test::SubCalls'               => [qw(sub_track sub_calls sub_reset sub_reset_all)],
        'Test::TempDir::Tiny'          => [qw(tempdir in_tempdir)],
        'Test::TCP'                    => [qw(empty_port test_tcp wait_port)],
        'Test::Warn'                   => [qw(warning_is warnings_are warning_like warnings_like warnings_exist)],
        'Text::Diff'                   => [qw(diff)],
        'Time::Piece'                  => [qw(localtime gmtime)],
        'Try::Tiny'                    => [qw(try catch finally)],
        'URI::Find'                    => [qw(find_uris)],
        'URL::Builder'                 => [qw(build_url build_url_utf8)],
        'UUID::Tiny'                   => [qw(UUID_NIL UUID_NS_DNS UUID_NS_URL UUID_NS_OID UUID_NS_X500 UUID_V1 UUID_V3 UUID_V4 UUID_V5 UUID_SHA1_AVAIL create_UUID create_UUID_as_string is_UUID_string UUID_to_string string_to_UUID version_of_UUID time_of_UUID clk_seq_of_UUID equal_UUIDs)],
        'Want'                         => [qw(want rreturn lnoreturn)],
        'XML::Simple'                  => [qw(XMLin XMLout)],
        'YAML'                         => [qw(Dump Load)],
    }
};

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @includes = grep {
        my $mod = $_->module;
        !$_->pragma && $mod && (! $self->{_ignore}{$mod})
    } @{ $doc->find('PPI::Statement::Include') ||[] };

    return () unless @includes;

    return () if grep { $_->module eq 'Module::Functions' } @includes;

    my %uses;
    $self->gather_uses_pragmatists(\@includes, $doc, \%uses);
    $self->gather_uses_try_family(\@includes, $doc, \%uses);
    $self->gather_uses_generic(\@includes, $doc, \%uses);

    return map {
        $self->violation(
            "Unused include: " . $_->module,
            "A module is `use`-ed but not really consumed in other places in the code",
            $_
        )
    } grep {
        my $mod = $_->module;
        (! $uses{refaddr($_)}) && (TRY_FAMILY->{$mod} || DEFAULT_EXPORT->{$mod} || USE_BY_MODULE_NAME->{$mod})
    } @includes;
}

sub gather_uses_pragmatists {
    my ( $self, $includes, $doc, $uses ) = @_;
    for (grep { PRAGMATIST->{$_->module} } @$includes) {
        my $r = refaddr($_);
        $uses->{$r} = 1;
    }
}

sub gather_uses_generic {
    my ( $self, $includes, $doc, $uses ) = @_;

    my @words = grep { ! $_->statement->isa('PPI::Statement::Include') } @{ $doc->find('PPI::Token::Word') || []};
    my @mods = grep { !$uses->{$_} } map { $_->module } @$includes;

    my @inc_without_args;
    for my $inc (@$includes) {
        if ($inc->arguments) {
            my $r = refaddr($inc);
            $uses->{$r} = -1;
        } else {
            push @inc_without_args, $inc;
        }
    }

    for my $word (@words) {
        for my $inc (@inc_without_args) {
            my $mod = $inc->module;
            my $r   = refaddr($inc);
            next if $uses->{$r};
            $uses->{$r} = 1 if ($word->content =~ /\A $mod (\z|::)/x) || (grep { $_ eq $word } @{DEFAULT_EXPORT->{$mod} ||[]}) || ("$word" eq "$inc");
        }
    }
}

sub gather_uses_try_family {
    my ( $self, $includes, $doc, $uses ) = @_;

    my @uses_tryish_modules = grep { TRY_FAMILY->{$_->module} } @$includes;
    return unless @uses_tryish_modules;

    my $has_try_block = 0;
    for my $try_keyword (@{ $doc->find(sub { $_[1]->isa('PPI::Token::Word') && $_[1]->content eq 'try' }) ||[]}) {
        my $try_block = $try_keyword->snext_sibling or next;
        next unless $try_block->isa('PPI::Structure::Block');
        $has_try_block = 1;
        last;
    }
    return unless $has_try_block;

    $uses->{refaddr($_)} = 1 for @uses_tryish_modules;
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedInclude -- Find unused include statements.

=head1 DESCRIPTION

This critic policy scans for unused include statement according to their documentation.

For example, L<Try::Tiny> implicitly introduce a C<try> subroutine that takes a block. Therefore, a
lonely C<use Try::Tiny> statement without a C<try { .. }> block somewhere in its scope is considered
to be an "Unused Include".

Notice: This module use a hard-coded list of commonly-used CPAN
modules with symbols exported from them. Although it is relatively
static, it needs to be revised from time to time.

=cut
